-- Pago en línea con Wompi.
--
-- Qué hace este script:
--   * Cada pedido recibe un `token_publico`: con él (y no solo con el número) una
--     compradora sin cuenta puede pagar, consultar o cancelar SU pedido.
--   * Cada intento de pago tiene su propia referencia (TINA-0012-1, TINA-0012-2...),
--     porque Wompi no deja repetir una referencia.
--   * `iniciar_pago` prepara el pago; `registrar_resultado_pago` aplica lo que
--     avisa Wompi (aprobado, rechazado, anulado), comprobando el monto. Las dos
--     solo las llaman las funciones del servidor, nunca la app.
--   * `ver_estado_pedido` y `cancelar_pedido_propio` son para la compradora, con
--     el token de su pedido.
--   * `crear_pedido` ahora también devuelve el token.

alter table public.pedido
  add column token_publico uuid not null default gen_random_uuid();
alter table public.pago
  add column intentos integer not null default 0;

-- ------------------------------------------------------------ crear pedido --

create or replace function public.crear_pedido(
  p_items   jsonb,
  p_envio   jsonb,
  p_cliente jsonb,
  p_metodo  text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid         uuid := auth.uid();
  v_cliente     public.cliente%rowtype;
  v_item        record;
  v_var         public.variante_producto%rowtype;
  v_prod        public.producto%rowtype;
  v_unidades    integer := 0;
  v_subtotal    integer := 0;
  v_lineas      jsonb := '[]'::jsonb;
  v_pct_vol     integer;
  v_promo_vol   bigint;
  v_pct_prim    integer;
  v_promo_prim  bigint;
  v_pct         integer := 0;
  v_promo       bigint;
  v_descuento   integer;
  v_costo_envio integer;
  v_total       integer;
  v_pedido      bigint;
  v_sistema     bigint;
  v_ciudad      text;
  v_depto       text;
  v_token       uuid;
begin
  if p_metodo is null or p_metodo not in ('wompi', 'apple_pay', 'contraentrega') then
    raise exception 'El método de pago no es válido.';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'El carrito está vacío.';
  end if;
  if nullif(trim(p_envio ->> 'nombre_destinatario'), '') is null
     or nullif(trim(p_envio ->> 'telefono'), '') is null
     or nullif(trim(p_envio ->> 'departamento'), '') is null
     or nullif(trim(p_envio ->> 'ciudad'), '') is null
     or nullif(trim(p_envio ->> 'direccion'), '') is null then
    raise exception 'Faltan datos de envío.';
  end if;

  -- Quién compra: la clienta con sesión, o una fila sin cuenta con ese correo.
  if v_uid is not null then
    select * into v_cliente from public.cliente where id_auth = v_uid;
  end if;
  if v_cliente.id_cliente is null then
    if nullif(trim(p_cliente ->> 'correo'), '') is null
       or nullif(trim(p_cliente ->> 'nombre'), '') is null then
      raise exception 'Faltan el nombre y el correo de quien compra.';
    end if;
    select * into v_cliente
    from public.cliente
    where not cuenta_registrada
      and id_auth is null
      and lower(correo) = lower(trim(p_cliente ->> 'correo'))
    limit 1;
    if v_cliente.id_cliente is null then
      insert into public.cliente (nombre, correo, telefono, cuenta_registrada)
      values (
        trim(p_cliente ->> 'nombre'),
        trim(p_cliente ->> 'correo'),
        coalesce(trim(p_cliente ->> 'telefono'), ''),
        false
      )
      returning * into v_cliente;
    end if;
  end if;

  -- Cada artículo: se bloquea su fila, se comprueba el stock y se descuenta. Si
  -- algo falla más abajo, todo se deshace (es una sola operación).
  for v_item in
    select (e ->> 'id_variante')::bigint as id_variante,
           (e ->> 'cantidad')::integer as cantidad
    from jsonb_array_elements(p_items) as e
    order by 1
  loop
    if v_item.cantidad is null or v_item.cantidad < 1 then
      raise exception 'La cantidad no es válida.';
    end if;

    select * into v_var
    from public.variante_producto
    where id_variante = v_item.id_variante
    for update;
    if not found then
      raise exception 'Uno de los artículos ya no existe.';
    end if;

    select * into v_prod from public.producto where id_producto = v_var.id_producto;
    if not v_prod.activo then
      raise exception '% ya no está disponible.', v_prod.nombre;
    end if;
    if v_var.stock < v_item.cantidad then
      raise exception 'No hay stock suficiente de %.', v_prod.nombre;
    end if;

    update public.variante_producto
    set stock = stock - v_item.cantidad
    where id_variante = v_var.id_variante;

    v_unidades := v_unidades + v_item.cantidad;
    v_subtotal := v_subtotal + v_prod.precio * v_item.cantidad;
    v_lineas := v_lineas || jsonb_build_object(
      'id_variante', v_var.id_variante,
      'cantidad', v_item.cantidad,
      'precio', v_prod.precio
    );
  end loop;

  -- Descuentos: por volumen, y por primera compra con cuenta. No se acumulan:
  -- se aplica el mayor.
  select p.id_promocion, p.porcentaje into v_promo_vol, v_pct_vol
  from public.promocion p
  where p.activa and p.tipo = 'volumen' and v_unidades >= p.cantidad_minima
  order by p.porcentaje desc
  limit 1;

  if v_uid is not null and not exists (
    select 1 from public.pedido
    where id_cliente = v_cliente.id_cliente and estado_actual <> 'cancelado'
  ) then
    select p.id_promocion, p.porcentaje into v_promo_prim, v_pct_prim
    from public.promocion p
    where p.activa and p.tipo = 'primera_compra'
    order by p.porcentaje desc
    limit 1;
  end if;

  if coalesce(v_pct_vol, 0) >= coalesce(v_pct_prim, 0) then
    v_pct := coalesce(v_pct_vol, 0);
    v_promo := v_promo_vol;
  else
    v_pct := v_pct_prim;
    v_promo := v_promo_prim;
  end if;
  v_descuento := round(v_subtotal * v_pct / 100.0)::integer;

  -- Envío: fijo; sin costo en la contraentrega, que solo existe en Cali.
  v_ciudad := translate(lower(trim(p_envio ->> 'ciudad')), 'áéíóúü', 'aeiouu');
  v_depto  := translate(lower(trim(p_envio ->> 'departamento')), 'áéíóúü', 'aeiouu');
  if p_metodo = 'contraentrega' then
    if v_ciudad <> 'cali' or v_depto not in ('valle del cauca', 'valle') then
      raise exception 'La contraentrega solo está disponible en Cali, Valle del Cauca.';
    end if;
    v_costo_envio := 0;
  else
    select coalesce(
      (select valor::integer from public.ajuste_tienda where clave = 'costo_envio'),
      5000
    ) into v_costo_envio;
  end if;

  v_total := v_subtotal - v_descuento + v_costo_envio;

  insert into public.pedido (
    id_cliente, id_promocion, estado_actual, subtotal, descuento, total, metodo_pago
  )
  values (
    v_cliente.id_cliente, v_promo, 'pendiente', v_subtotal, v_descuento, v_total, p_metodo
  )
  returning id_pedido, token_publico into v_pedido, v_token;

  -- El precio se copia al detalle: un cambio de precio posterior no altera
  -- este pedido.
  insert into public.detalle_pedido (
    id_pedido, id_variante, cantidad, precio_unitario, subtotal
  )
  select v_pedido,
         (l ->> 'id_variante')::bigint,
         (l ->> 'cantidad')::integer,
         (l ->> 'precio')::integer,
         (l ->> 'precio')::integer * (l ->> 'cantidad')::integer
  from jsonb_array_elements(v_lineas) as l;

  insert into public.envio (
    id_pedido, nombre_destinatario, telefono, departamento, ciudad, direccion, costo
  )
  values (
    v_pedido,
    trim(p_envio ->> 'nombre_destinatario'),
    trim(p_envio ->> 'telefono'),
    trim(p_envio ->> 'departamento'),
    trim(p_envio ->> 'ciudad'),
    trim(p_envio ->> 'direccion'),
    v_costo_envio
  );

  insert into public.pago (id_pedido, referencia, monto, estado, proveedor)
  values (v_pedido, null, v_total, 'pendiente', p_metodo);

  select id_usuario into v_sistema from public.usuario where rol = 'sistema' limit 1;
  insert into public.historial_estado (
    id_pedido, id_usuario, estado_anterior, estado_nuevo, notificado
  )
  values (v_pedido, v_sistema, null, 'pendiente', false);

  return jsonb_build_object(
    'id_pedido', v_pedido,
    'codigo', 'TINA-' || lpad(v_pedido::text, 4, '0'),
    'id_cliente', v_cliente.id_cliente,
    'subtotal', v_subtotal,
    'descuento', v_descuento,
    'costo_envio', v_costo_envio,
    'total', v_total,
    'estado', 'pendiente',
    'metodo_pago', p_metodo,
    'token', v_token
  );
end;
$$;

grant execute on function public.crear_pedido(jsonb, jsonb, jsonb, text)
  to anon, authenticated;

-- ----------------------------------------------------------- cancelar (interno) --

-- Cancela el pedido y devuelve el stock. Solo la usan otras funciones.
create or replace function public.cancelar_pedido_interno(
  p_id      bigint,
  p_usuario bigint default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_antes text;
  v_quien bigint;
begin
  select estado_actual into v_antes
  from public.pedido where id_pedido = p_id for update;
  if not found then
    raise exception 'El pedido no existe.';
  end if;
  if v_antes = 'cancelado' then
    return;
  end if;

  select coalesce(
    p_usuario,
    (select id_usuario from public.usuario where rol = 'sistema' limit 1)
  ) into v_quien;

  update public.variante_producto v
  set stock = v.stock + d.cantidad
  from public.detalle_pedido d
  where d.id_pedido = p_id and d.id_variante = v.id_variante;

  update public.pago
  set estado = 'rechazado'
  where id_pedido = p_id and estado = 'pendiente';

  update public.pedido set estado_actual = 'cancelado' where id_pedido = p_id;
  insert into public.historial_estado (
    id_pedido, id_usuario, estado_anterior, estado_nuevo, notificado
  )
  values (p_id, v_quien, v_antes, 'cancelado', false);
end;
$$;

revoke execute on function public.cancelar_pedido_interno(bigint, bigint)
  from public, anon, authenticated;
grant execute on function public.cancelar_pedido_interno(bigint, bigint)
  to service_role;

-- La administradora cambia estados; cancelar usa la función de arriba.
create or replace function public.cambiar_estado_pedido(p_id bigint, p_estado text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_antes   text;
  v_usuario bigint;
begin
  if not public.es_admin() then
    raise exception 'No tienes permiso para cambiar pedidos.';
  end if;
  if p_estado not in (
    'pendiente', 'pagado', 'preparacion', 'enviado', 'entregado', 'cancelado'
  ) then
    raise exception 'El estado no es válido.';
  end if;

  select id_usuario into v_usuario from public.usuario where id_auth = auth.uid();

  select estado_actual into v_antes
  from public.pedido where id_pedido = p_id for update;
  if not found then
    raise exception 'El pedido no existe.';
  end if;
  if v_antes = p_estado then
    return;
  end if;
  if v_antes = 'cancelado' then
    raise exception 'Un pedido cancelado no se puede reactivar. Crea uno nuevo.';
  end if;

  if p_estado = 'pagado' and v_antes = 'pendiente' then
    perform public.aprobar_pago(p_id, null, v_usuario);
    return;
  end if;
  if p_estado = 'cancelado' then
    perform public.cancelar_pedido_interno(p_id, v_usuario);
    return;
  end if;

  update public.pedido set estado_actual = p_estado where id_pedido = p_id;
  insert into public.historial_estado (
    id_pedido, id_usuario, estado_anterior, estado_nuevo, notificado
  )
  values (p_id, v_usuario, v_antes, p_estado, false);
end;
$$;

grant execute on function public.cambiar_estado_pedido(bigint, text) to authenticated;

-- aprobar_pago la llamará también el aviso de Wompi (con la llave de servicio).
grant execute on function public.aprobar_pago(bigint, text, bigint) to service_role;

-- ------------------------------------------------------------- iniciar pago --

-- Prepara un intento de pago con Wompi: comprueba que el pedido es de quien lo
-- pide (por su token), que sigue pendiente y que se paga con Wompi, y le da una
-- referencia nueva. El monto sale del pedido, nunca del navegador.
create or replace function public.iniciar_pago(p_id bigint, p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pedido   public.pedido%rowtype;
  v_cliente  public.cliente%rowtype;
  v_envio    public.envio%rowtype;
  v_intentos integer;
  v_ref      text;
begin
  select * into v_pedido
  from public.pedido
  where id_pedido = p_id and token_publico = p_token
  for update;
  if not found then
    raise exception 'No encontramos ese pedido.';
  end if;
  if v_pedido.estado_actual <> 'pendiente' then
    raise exception 'Este pedido ya no está pendiente de pago.';
  end if;
  if v_pedido.metodo_pago <> 'wompi' then
    raise exception 'Este pedido no se paga con Wompi.';
  end if;

  update public.pago
  set intentos = intentos + 1, estado = 'pendiente'
  where id_pedido = p_id
  returning intentos into v_intentos;

  v_ref := 'TINA-' || lpad(p_id::text, 4, '0') || '-' || v_intentos;
  update public.pago set referencia = v_ref where id_pedido = p_id;

  select * into v_cliente from public.cliente where id_cliente = v_pedido.id_cliente;
  select * into v_envio from public.envio where id_pedido = p_id;

  return jsonb_build_object(
    'referencia', v_ref,
    'monto_en_centavos', v_pedido.total::bigint * 100,
    'moneda', 'COP',
    'correo', v_cliente.correo,
    'nombre', v_envio.nombre_destinatario,
    'telefono', v_envio.telefono
  );
end;
$$;

revoke execute on function public.iniciar_pago(bigint, uuid)
  from public, anon, authenticated;
grant execute on function public.iniciar_pago(bigint, uuid) to service_role;

-- ------------------------------------------------- resultado de un pago --

-- Aplica lo que avisa Wompi. La referencia dice de qué pedido es; el monto debe
-- coincidir exactamente con el del pedido, o no se aprueba nada.
-- p_estado: APPROVED, DECLINED, ERROR, VOIDED o PENDING (los de Wompi).
create or replace function public.registrar_resultado_pago(
  p_referencia      text,
  p_estado          text,
  p_monto_centavos  bigint,
  p_id_transaccion  text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id     bigint;
  v_pedido public.pedido%rowtype;
begin
  v_id := substring(p_referencia from '^TINA-0*([0-9]+)-[0-9]+$')::bigint;
  if v_id is null then
    raise exception 'La referencia % no es de esta tienda.', p_referencia;
  end if;

  select * into v_pedido from public.pedido where id_pedido = v_id for update;
  if not found then
    raise exception 'El pedido de la referencia % no existe.', p_referencia;
  end if;
  if p_monto_centavos <> v_pedido.total::bigint * 100 then
    raise exception 'El monto pagado (%) no coincide con el del pedido (%).',
      p_monto_centavos, v_pedido.total::bigint * 100;
  end if;

  if p_estado = 'APPROVED' then
    if v_pedido.estado_actual = 'cancelado' then
      -- Llegó un pago para un pedido que ya estaba cancelado: no se reactiva (el
      -- stock pudo venderse), pero queda registrado para devolver el dinero.
      update public.pago
      set estado = 'aprobado', referencia = p_referencia, fecha = now()
      where id_pedido = v_id;
      return jsonb_build_object('resultado', 'pago_en_pedido_cancelado', 'id_pedido', v_id);
    end if;
    perform public.aprobar_pago(v_id, p_referencia, null);
    return jsonb_build_object('resultado', 'aprobado', 'id_pedido', v_id);
  elsif p_estado in ('DECLINED', 'ERROR') then
    update public.pago
    set estado = 'rechazado'
    where id_pedido = v_id and estado = 'pendiente';
    return jsonb_build_object('resultado', 'rechazado', 'id_pedido', v_id);
  elsif p_estado = 'VOIDED' then
    update public.pago set estado = 'rechazado' where id_pedido = v_id;
    perform public.cancelar_pedido_interno(v_id, null);
    return jsonb_build_object('resultado', 'anulado', 'id_pedido', v_id);
  end if;

  return jsonb_build_object('resultado', 'sin_cambios', 'id_pedido', v_id);
end;
$$;

revoke execute on function public.registrar_resultado_pago(text, text, bigint, text)
  from public, anon, authenticated;
grant execute on function public.registrar_resultado_pago(text, text, bigint, text)
  to service_role;

-- -------------------------------------- consultar o cancelar mi pedido --

-- La compradora (con o sin cuenta) ve el estado de su pedido con el token.
create or replace function public.ver_estado_pedido(p_id bigint, p_token uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_resultado jsonb;
begin
  select jsonb_build_object(
    'id_pedido', p.id_pedido,
    'codigo', 'TINA-' || lpad(p.id_pedido::text, 4, '0'),
    'estado', p.estado_actual,
    'metodo_pago', p.metodo_pago,
    'subtotal', p.subtotal,
    'descuento', p.descuento,
    'costo_envio', e.costo,
    'total', p.total,
    'pago_estado', g.estado,
    'referencia', g.referencia,
    'comprobante', c.numero
  )
  into v_resultado
  from public.pedido p
  join public.pago g on g.id_pedido = p.id_pedido
  join public.envio e on e.id_pedido = p.id_pedido
  left join public.comprobante c on c.id_pago = g.id_pago
  where p.id_pedido = p_id and p.token_publico = p_token;

  if v_resultado is null then
    raise exception 'No encontramos ese pedido.';
  end if;
  return v_resultado;
end;
$$;

grant execute on function public.ver_estado_pedido(bigint, uuid) to anon, authenticated;

-- Cancelar un pedido propio que todavía está pendiente (por ejemplo, si no se
-- pudo abrir la página de pago). Devuelve el stock.
create or replace function public.cancelar_pedido_propio(p_id bigint, p_token uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_estado text;
begin
  select estado_actual into v_estado
  from public.pedido
  where id_pedido = p_id and token_publico = p_token;
  if not found then
    raise exception 'No encontramos ese pedido.';
  end if;
  if v_estado <> 'pendiente' then
    raise exception 'Solo se puede cancelar un pedido que sigue pendiente.';
  end if;
  perform public.cancelar_pedido_interno(p_id, null);
end;
$$;

grant execute on function public.cancelar_pedido_propio(bigint, uuid) to anon, authenticated;
