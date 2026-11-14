-- Datos iniciales: el mismo catálogo del prototipo (lib/data/datos_simulados.dart),
-- las dos promociones y los lugares de fotos del sitio. No incluye fotos: las
-- sube la administradora desde el panel.

insert into public.categoria (id_categoria, nombre, descripcion) values
  (1, 'Collares', 'Maxi collares 3D tejidos a mano con mostacilla.'),
  (2, 'Aretes',   'Aretes de porcelanicrón moldeados a mano.'),
  (3, 'Pulseras', 'Pulseras tejidas en varias tallas.'),
  (4, 'Imanes',   'Imanes de porcelanicrón para la nevera.');

insert into public.producto (id_producto, id_categoria, nombre, descripcion, tecnica, precio) values
  (1, 1, 'Maxi collar 3D con mostacilla',
      'Pieza grande y llamativa, tejida a mano con mostacilla en volumen. Cada collar sale un poquito distinto.',
      'Mostacilla tejida en volumen', 55000),
  (2, 1, 'Maxi collar 3D tropical',
      'Un collar de colores vivos para los días de calor, armado cuenta por cuenta.',
      'Mostacilla tejida en volumen', 58000),
  (3, 2, 'Aretes de porcelanicrón',
      'Aretes moldeados a mano en porcelanicrón, livianos para usarlos todo el día.',
      'Porcelanicrón moldeado a mano', 18000),
  (4, 2, 'Aretes mini flor',
      'Florecitas pequeñas pintadas a mano, para combinar con todo.',
      'Porcelanicrón moldeado a mano', 16000),
  (5, 3, 'Pulsera tejida',
      'Pulsera tejida a mano, en tres tallas para que te quede justo como es.',
      'Tejido a mano', 17000),
  (6, 3, 'Pulsera tejida con dije',
      'Nuestra pulsera tejida con un dije de porcelanicrón.',
      'Tejido a mano y porcelanicrón', 19000),
  (7, 4, 'Imán de porcelanicrón corazón',
      'Un corazón pequeño hecho a mano para tu nevera.',
      'Porcelanicrón moldeado a mano', 12000),
  (8, 4, 'Imán de porcelanicrón sol',
      'Un solcito pintado a mano que alegra cualquier superficie.',
      'Porcelanicrón moldeado a mano', 12000);

insert into public.variante_producto (id_variante, id_producto, color, talla, stock) values
  (1,  1, 'Naranja', 'Única', 6),
  (2,  1, 'Blanco',  'Única', 4),
  (3,  2, 'Rosado',  'Única', 5),
  (4,  2, 'Naranja', 'Única', 3),
  (5,  3, 'Nude',    'Única', 10),
  (6,  3, 'Blanco',  'Única', 8),
  (7,  4, 'Naranja', 'Única', 12),
  (8,  4, 'Rosado',  'Única', 9),
  (9,  5, 'Naranja', 'S', 5),
  (10, 5, 'Naranja', 'M', 7),
  (11, 5, 'Naranja', 'L', 4),
  (12, 5, 'Beige',   'S', 6),
  (13, 5, 'Beige',   'M', 8),
  (14, 5, 'Beige',   'L', 3),
  (15, 6, 'Naranja', 'S', 4),
  (16, 6, 'Naranja', 'M', 6),
  (17, 6, 'Naranja', 'L', 3),
  (18, 6, 'Rosado',  'S', 5),
  (19, 6, 'Rosado',  'M', 5),
  (20, 6, 'Rosado',  'L', 2),
  (21, 7, 'Rojo',    'Única', 15),
  (22, 7, 'Rosado',  'Única', 12),
  (23, 8, 'Naranja', 'Única', 14),
  (24, 8, 'Blanco',  'Única', 10);

insert into public.promocion (id_promocion, nombre, tipo, porcentaje, cantidad_minima) values
  (1, '20% en tu primera compra con cuenta', 'primera_compra', 20, 1),
  (2, '30% si compras 14 o más unidades',    'volumen',        30, 14);

-- Lugares de la página donde la administradora puede poner una foto.
insert into public.ajuste_sitio (clave, descripcion) values
  ('portada_inicio',  'Foto grande de la portada del inicio'),
  ('banner_mayoreo',  'Banner de compras al por mayor'),
  ('fondo_papel',     'Textura o fondo del sitio'),
  ('logo',            'Logo de Tina');

-- Como los ids se pusieron a mano, se avanza el contador para que lo siguiente
-- que se cree no choque con ellos.
select setval(pg_get_serial_sequence('public.categoria', 'id_categoria'),
              (select max(id_categoria) from public.categoria));
select setval(pg_get_serial_sequence('public.producto', 'id_producto'),
              (select max(id_producto) from public.producto));
select setval(pg_get_serial_sequence('public.variante_producto', 'id_variante'),
              (select max(id_variante) from public.variante_producto));
select setval(pg_get_serial_sequence('public.promocion', 'id_promocion'),
              (select max(id_promocion) from public.promocion));
