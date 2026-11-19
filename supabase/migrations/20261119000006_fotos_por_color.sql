-- Fotos por color.
--
-- Cada foto de un producto puede ser de un color (por ejemplo "Blanco"): cuando
-- la clienta elige ese color en la tienda, ve esas fotos. Si `color` queda
-- vacío, la foto es general (la portada del producto) y se ve cuando el color
-- elegido no tiene fotos propias.
--
-- Las reglas de seguridad no cambian: ya valen para toda la tabla.

alter table public.imagen_producto
  add column if not exists color text;

create index if not exists imagen_producto_producto_color_idx
  on public.imagen_producto (id_producto, color);
