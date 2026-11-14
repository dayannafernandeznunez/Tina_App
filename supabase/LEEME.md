# Supabase de Tina

Aquí están los scripts para armar la base de datos y el almacenamiento de fotos
de la tienda. Se ejecutan **una sola vez**, en este orden, desde el *SQL Editor*
de tu proyecto en Supabase.

| Orden | Archivo | Qué hace |
|---|---|---|
| 1 | `migrations/20261114000001_esquema.sql` | Crea las tablas del modelo entidad-relación y la tabla de fotos del sitio. |
| 2 | `migrations/20261114000002_seguridad_y_fotos.sql` | Pone las reglas de seguridad y crea las carpetas de fotos `productos` y `sitio`. |
| 3 | `seed.sql` | Carga las 4 categorías, los 8 productos con sus variantes, las 2 promociones y los 4 lugares de fotos del sitio. |
| 4 | `crear_administradora.sql` | Convierte tu cuenta en administradora (antes cambia `TU_CORREO_AQUI`). |

## Paso a paso

1. **Crea el proyecto.** En supabase.com: *New project*. Ponle el nombre `tina`,
   elige la región más cercana (South America, São Paulo) y guarda la
   contraseña de la base de datos en un lugar seguro.
2. **Ejecuta los scripts 1, 2 y 3.** En el menú izquierdo abre *SQL Editor* →
   *New query*, pega el contenido del archivo y presiona *Run*. Hazlo en orden y
   uno por uno.
3. **Crea tu cuenta.** *Authentication* → *Users* → *Add user* → *Create new
   user*, con tu correo y una contraseña. Activa *Auto Confirm User*.
4. **Ejecuta el script 4**, con tu correo en lugar de `TU_CORREO_AQUI`.
5. **Revisa.** En *Table Editor* deben aparecer 8 filas en `producto`. En
   *Storage* deben aparecer las carpetas `productos` y `sitio`.
6. **Copia dos datos** de *Project Settings* → *API*: la **Project URL** y la
   llave **anon** (en paneles nuevos se llama *publishable*). Esas dos se pueden
   compartir y van en la app.

## Qué nunca se sube a GitHub

El repositorio es público. La llave **service_role** (en paneles nuevos,
*secret*) da control total sobre la base de datos: no la pegues en el código, en
el chat ni en ningún archivo del repositorio.

## Quién puede qué

- **Cualquier visitante** puede ver el catálogo, las promociones y las fotos.
- **Solo la administradora** puede crear, cambiar o borrar productos, fotos y
  ajustes del sitio, y es la única que ve pedidos, clientas y pagos.
- La compra de las clientas se abre más adelante, con funciones en el servidor.
