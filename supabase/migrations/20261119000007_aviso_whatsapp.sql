-- Aviso por WhatsApp de los pedidos nuevos.
--
-- La función del servidor `avisar-pedido` manda el mensaje a la vendedora. Estas
-- dos funciones de la base de datos deciden CUÁNDO se avisa y evitan que el
-- mismo pedido se avise dos veces:
--
--   - Un pedido de Wompi se avisa solo cuando el pago está aprobado.
--   - Una contraentrega se avisa apenas se crea (queda pendiente de transferir).
--   - Un pedido cancelado no se avisa.
--
-- `reclamar_aviso_pedido` marca el pedido como avisado y devuelve lo que lleva
-- el mensaje. Si el envío falla, `liberar_aviso_pedido` lo desmarca para poder
-- intentarlo otra vez. Solo las puede usar el servidor (service_role).

alter table public.pedido
  add column if not exists aviso_whatsapp timestamptz;

create or replace function public.reclamar_aviso_pedido(
  p_id    bigint,
  p_token uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pedido      public.pedido%rowtype;
  v_pago_estado text;
  v_resultado   jsonb;
begin
  -- Con token (la compradora) solo se encuentra su pedido; sin token (el
  -- servidor, tras un pago aprobado) vale cualquier pedido.
  select * into v_pedido
  from public.pedido
  where id_pedido = p_id
    and (p_token is null or token_publico = p_token)
  for update;
  if not found then
    raise exception 'No encontramos ese pedido.';
  end if;

  if v_pedido.aviso_whatsapp is not null then
    return null;  -- ya se avisó
  end if;
  if v_pedido.estado_actual = 'cancelado' then
    return null;
  end if;
  if v_pedido.metodo_pago = 'wompi' then
    select estado into v_pago_estado from public.pago where id_pedido = p_id;
    if v_pago_estado is distinct from 'aprobado' then
      return null;  -- todavía no está pagado
    end if;
  end if;

  update public.pedido set aviso_whatsapp = now() where id_pedido = p_id;

  select jsonb_build_object(
    'id_pedido',    p.id_pedido,
    'codigo',       'TINA-' || lpad(p.id_pedido::text, 4, '0'),
    'metodo_pago',  p.metodo_pago,
    'estado',       p.estado_actual,
    'subtotal',     p.subtotal,
    'descuento',    p.descuento,
    'costo_envio',  e.costo,
    'total',        p.total,
    'cliente',      c.nombre,
    'correo',       c.correo,
    'telefono',     coalesce(nullif(e.telefono, ''), c.telefono),
    'destinatario', e.nombre_destinatario,
    'direccion',    e.direccion,
    'ciudad',       e.ciudad,
    'departamento', e.departamento,
    'lineas', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'nombre',   pr.nombre,
          'color',    v.color,
          'talla',    v.talla,
          'cantidad', d.cantidad
        )
        order by d.id_detalle
      )
      from public.detalle_pedido d
      join public.variante_producto v on v.id_variante = d.id_variante
      join public.producto pr on pr.id_producto = v.id_producto
      where d.id_pedido = p.id_pedido
    ), '[]'::jsonb)
  )
  into v_resultado
  from public.pedido p
  join public.cliente c on c.id_cliente = p.id_cliente
  join public.envio e on e.id_pedido = p.id_pedido
  where p.id_pedido = p_id;

  return v_resultado;
end;
$$;

create or replace function public.liberar_aviso_pedido(p_id bigint)
returns void
language sql
security definer
set search_path = public
as $$
  update public.pedido set aviso_whatsapp = null where id_pedido = p_id;
$$;

revoke execute on function public.reclamar_aviso_pedido(bigint, uuid)
  from public, anon, authenticated;
grant execute on function public.reclamar_aviso_pedido(bigint, uuid) to service_role;

revoke execute on function public.liberar_aviso_pedido(bigint)
  from public, anon, authenticated;
grant execute on function public.liberar_aviso_pedido(bigint) to service_role;
