-- Seguridad (RLS) y almacenamiento de fotos.
--
-- Regla general: cualquier persona que visite el sitio puede VER el catálogo y
-- las fotos; solo la administradora puede crear, cambiar o borrar. Las tablas de
-- pedidos, clientas y pagos quedan cerradas al público por ahora (solo la
-- administradora). El flujo de compra se abre más adelante, con funciones en el
-- servidor, porque el pago no debe depender del navegador.

-- ¿La persona que hace la consulta es la administradora?
create or replace function public.es_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuario u
    where u.id_auth = auth.uid()
      and u.rol = 'administradora'
  );
$$;

grant execute on function public.es_admin() to anon, authenticated;

-- ------------------------------------------------- tablas que todo el mundo ve --

alter table public.categoria         enable row level security;
alter table public.producto          enable row level security;
alter table public.imagen_producto   enable row level security;
alter table public.variante_producto enable row level security;
alter table public.promocion         enable row level security;
alter table public.ajuste_sitio      enable row level security;

create policy "ver categorias" on public.categoria
  for select using (true);
create policy "ver productos activos" on public.producto
  for select using (activo or public.es_admin());
create policy "ver fotos de productos" on public.imagen_producto
  for select using (true);
create policy "ver variantes" on public.variante_producto
  for select using (true);
create policy "ver promociones" on public.promocion
  for select using (true);
create policy "ver fotos del sitio" on public.ajuste_sitio
  for select using (true);

create policy "admin gestiona categorias" on public.categoria
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona productos" on public.producto
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona fotos de productos" on public.imagen_producto
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona variantes" on public.variante_producto
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona promociones" on public.promocion
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona fotos del sitio" on public.ajuste_sitio
  for all using (public.es_admin()) with check (public.es_admin());

-- ------------------------------------------------------------- usuarios --

alter table public.usuario enable row level security;

-- Cada persona puede ver su propia fila (para saber si es administradora).
create policy "ver mi usuario" on public.usuario
  for select using (id_auth = auth.uid() or public.es_admin());
create policy "admin gestiona usuarios" on public.usuario
  for all using (public.es_admin()) with check (public.es_admin());

-- ------------------------------------------- tablas cerradas al público --

alter table public.cliente          enable row level security;
alter table public.carrito          enable row level security;
alter table public.carrito_item     enable row level security;
alter table public.pedido           enable row level security;
alter table public.detalle_pedido   enable row level security;
alter table public.pago             enable row level security;
alter table public.comprobante      enable row level security;
alter table public.envio            enable row level security;
alter table public.historial_estado enable row level security;

create policy "admin gestiona clientes" on public.cliente
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona carritos" on public.carrito
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona items de carrito" on public.carrito_item
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona pedidos" on public.pedido
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona detalles de pedido" on public.detalle_pedido
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona pagos" on public.pago
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona comprobantes" on public.comprobante
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona envios" on public.envio
  for all using (public.es_admin()) with check (public.es_admin());
create policy "admin gestiona historial" on public.historial_estado
  for all using (public.es_admin()) with check (public.es_admin());

-- ------------------------------------------------------ almacenamiento --

-- Dos carpetas de fotos: `productos` (las piezas) y `sitio` (portada, logo...).
-- Se ven desde internet; solo imágenes y de máximo 5 MB.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('productos', 'productos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('sitio',     'sitio',     true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "ver fotos publicas" on storage.objects
  for select using (bucket_id in ('productos', 'sitio'));

create policy "admin sube fotos" on storage.objects
  for insert to authenticated
  with check (bucket_id in ('productos', 'sitio') and public.es_admin());

create policy "admin cambia fotos" on storage.objects
  for update to authenticated
  using (bucket_id in ('productos', 'sitio') and public.es_admin())
  with check (bucket_id in ('productos', 'sitio') and public.es_admin());

create policy "admin borra fotos" on storage.objects
  for delete to authenticated
  using (bucket_id in ('productos', 'sitio') and public.es_admin());
