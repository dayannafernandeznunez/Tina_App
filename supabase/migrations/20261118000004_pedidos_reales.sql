-- Pedidos reales: la compra se registra en la base de datos.
--
-- Qué hace este script:
--   * Guarda el costo de envío (5.000) como un ajuste de la tienda.
--   * Prepara los pagos para más de un proveedor (Wompi, Apple Pay) y para la
--     contraentrega.
--   * Crea la función `crear_pedido`, que arma el pedido completo en una sola
--     operación: valida el stock, lo descuenta, calcula los descuentos y el
--     envío con los precios de la base de datos (no con lo que diga el
--     navegador) y registra pedido, detalle, envío, pago e historial.
--   * Crea `cambiar_estado_pedido` (solo administradora) y `aprobar_pago`
--     (la usará también el aviso de Wompi cuando lo conectemos).
--   * Deja que cada clienta vea sus propios pedidos.

-- ------------------------------------------------------- ajustes de la tienda --

create table public.ajuste_tienda (
  clave       text primary key,
  valor       text not null,
  descripcion text not null default ''
);

alter table public.ajuste_tienda enable row level security;

create policy "ver ajustes de la tienda" on public.ajuste_tienda
  for select using (true);
create policy "admin gestiona ajustes de la tienda" on public.ajuste_tienda
  for all using (public.es_admin()) with check (public.es_admin());

insert into public.ajuste_tienda (clave, valor, descripcion) values
  ('costo_envio', '5000', 'Costo de envío fijo, en pesos')
on conflict (clave) do nothing;

-- ----------------------------------------------------------------- pagos --

-- `referencia` es la del proveedor (Wompi, Apple Pay); en la contraentrega no hay.
alter table public.pago rename column referencia_wompi to referencia;
alter table public.pago alter column referencia drop not null;
alter table public.pago
  add column proveedor text not null default 'wompi'
  check (proveedor in ('wompi', 'apple_pay', 'contraentrega'));

alter table public.pedido
  add column metodo_pago text not null default 'wompi'
  check (metodo_pago in ('wompi', 'apple_pay', 'contraentrega'));

-- Quien deja el rastro de los cambios automáticos (un pedido recién creado, un
-- pago aprobado por Wompi).
insert into public.usuario (nombre, correo, rol)
select 'Sistema', 'sistema@tina.co', 'sistema'
where not exists (select 1 from public.usuario where rol = 'sistema');

-- ------------------------------------------------------------ crear pedido --

-- p_items:   [{"id_variante": 3, "cantidad": 2}, ...]
-- p_envio:   {"nombre_destinatario", "telefono", "departamento", "ciudad", "direccion"}
-- p_cliente: {"nombre", "correo", "telefono"}   (solo se usa si no hay sesión)
-- p_metodo:  'wompi', 'apple_pay' o 'contraentrega' (esta última, solo en Cali)
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
  returning id_pedido into v_pedido;

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
    'metodo_pago', p_metodo
  );
end;
$$;

grant execute on function public.crear_pedido(jsonb, jsonb, jsonb, text)
  to anon, authenticated;

-- ---------------------------------------------------------- aprobar un pago --

-- Marca el pago como aprobado, crea su comprobante y pasa el pedido a "pagado".
-- La usan `cambiar_estado_pedido` (transferencias de contraentrega) y, más
-- adelante, el aviso de Wompi. No se puede llamar desde la app.
create or replace function public.aprobar_pago(
  p_id_pedido  bigint,
  p_referencia text default null,
  p_usuario    bigint default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_estado text;
  v_pago   bigint;
  v_quien  bigint;
begin
  select estado_actual into v_estado
  from public.pedido where id_pedido = p_id_pedido for update;
  if not found then
    raise exception 'El pedido no existe.';
  end if;
  if v_estado = 'cancelado' then
    raise exception 'El pedido está cancelado.';
  end if;

  select coalesce(
    p_usuario,
    (select id_usuario from public.usuario where rol = 'sistema' limit 1)
  ) into v_quien;

  update public.pago
  set estado = 'aprobado',
      referencia = coalesce(p_referencia, referencia),
      fecha = now()
  where id_pedido = p_id_pedido and estado <> 'aprobado'
  returning id_pago into v_pago;

  if v_pago is not null then
    insert into public.comprobante (id_pago, numero)
    values (v_pago, 'C-' || lpad(p_id_pedido::text, 4, '0'))
    on conflict do nothing;
  end if;

  if v_estado = 'pendiente' then
    update public.pedido set estado_actual = 'pagado' where id_pedido = p_id_pedido;
    insert into public.historial_estado (
      id_pedido, id_usuario, estado_anterior, estado_nuevo, notificado
    )
    values (p_id_pedido, v_quien, 'pendiente', 'pagado', false);
  end if;
end;
$$;

revoke execute on function public.aprobar_pago(bigint, text, bigint)
  from public, anon, authenticated;

-- ----------------------------------------------------- cambiar el estado --

-- Solo la administradora. Al cancelar un pedido, el stock vuelve a las
-- variantes. Un pedido cancelado no se reactiva: se crea uno nuevo.
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
    update public.variante_producto v
    set stock = v.stock + d.cantidad
    from public.detalle_pedido d
    where d.id_pedido = p_id and d.id_variante = v.id_variante;

    update public.pago
    set estado = 'rechazado'
    where id_pedido = p_id and estado = 'pendiente';
  end if;

  update public.pedido set estado_actual = p_estado where id_pedido = p_id;
  insert into public.historial_estado (
    id_pedido, id_usuario, estado_anterior, estado_nuevo, notificado
  )
  values (p_id, v_usuario, v_antes, p_estado, false);
end;
$$;

grant execute on function public.cambiar_estado_pedido(bigint, text) to authenticated;

-- ------------------------------------------- cada clienta ve sus pedidos --

create policy "ver mis pedidos" on public.pedido
  for select to authenticated
  using (exists (
    select 1 from public.cliente c
    where c.id_cliente = pedido.id_cliente and c.id_auth = auth.uid()
  ));

create policy "ver el detalle de mis pedidos" on public.detalle_pedido
  for select to authenticated
  using (exists (
    select 1 from public.pedido p
    join public.cliente c on c.id_cliente = p.id_cliente
    where p.id_pedido = detalle_pedido.id_pedido and c.id_auth = auth.uid()
  ));

create policy "ver el envio de mis pedidos" on public.envio
  for select to authenticated
  using (exists (
    select 1 from public.pedido p
    join public.cliente c on c.id_cliente = p.id_cliente
    where p.id_pedido = envio.id_pedido and c.id_auth = auth.uid()
  ));

create policy "ver el pago de mis pedidos" on public.pago
  for select to authenticated
  using (exists (
    select 1 from public.pedido p
    join public.cliente c on c.id_cliente = p.id_cliente
    where p.id_pedido = pago.id_pedido and c.id_auth = auth.uid()
  ));

create policy "ver el comprobante de mis pedidos" on public.comprobante
  for select to authenticated
  using (exists (
    select 1 from public.pago g
    join public.pedido p on p.id_pedido = g.id_pedido
    join public.cliente c on c.id_cliente = p.id_cliente
    where g.id_pago = comprobante.id_pago and c.id_auth = auth.uid()
  ));

create policy "ver el historial de mis pedidos" on public.historial_estado
  for select to authenticated
  using (exists (
    select 1 from public.pedido p
    join public.cliente c on c.id_cliente = p.id_cliente
    where p.id_pedido = historial_estado.id_pedido and c.id_auth = auth.uid()
  ));
