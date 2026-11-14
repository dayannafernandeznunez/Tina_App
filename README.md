# Tina — tienda en línea hecha con Flutter

Tienda en línea de Tina ("Tan latinas como tú"), hecha con Flutter y conectada
a **Supabase**. Los datos siguen el modelo entidad-relación del proyecto
(categorías, productos, variantes con stock, clientes, pedidos, pagos,
comprobantes, envíos, historial).

## Qué es real y qué sigue simulado

| | Estado |
|---|---|
| Catálogo (categorías, productos, variantes, promociones) | **Real**: se lee de Supabase |
| Fotos de artículos y del sitio | **Reales**: las sube la administradora desde el panel y las ve todo el mundo |
| Cuentas e ingreso (clientas y administradora) | **Reales**: Supabase Auth, un solo ingreso para todas |
| Pedidos, pagos, comprobantes y envíos | **Simulados** en memoria: aún no se guardan en la nube |
| Pago con Wompi | **Simulado**: siempre sale aprobado |

Sin conexión, o en las pruebas, la app usa **datos de ejemplo** coherentes con
el modelo.

## Cómo ejecutarlo

Desde la carpeta del proyecto (la que tiene `pubspec.yaml`):

```bash
flutter pub get
flutter run -d chrome
```

- **Chrome:** es el destino que funciona. Como app de Windows hace falta Visual
  Studio, que no es necesario para esto.
- **Windows:** activa el *Modo de desarrollador* (`Win + R` →
  `ms-settings:developers`); Flutter lo necesita para los paquetes con plugins.
- **Internet:** la fuente (Bricolage Grotesque e Instrument Serif) se descarga
  de Google Fonts, y el catálogo y las fotos vienen de Supabase.
- En Chrome, abre la ventana a un ancho de 900 px o más para ver el diseño de PC.

Las pruebas y el análisis:

```bash
flutter analyze
flutter test
```

## Conexión con Supabase

Los scripts de la base de datos están en [`supabase/`](supabase/LEEME.md): el
esquema, las reglas de seguridad, las carpetas de fotos, los datos iniciales y
la cuenta de administradora. Hay que ejecutarlos una vez, en orden, en el
*SQL Editor* de tu proyecto.

La URL del proyecto y la llave pública están en `lib/config/supabase_config.dart`.
Esa llave está hecha para ir dentro de la app: **lo que protege los datos son las
reglas de seguridad de la base de datos**, no esconderla. La llave `service_role`
o `secret` nunca debe estar en el repositorio.

## Ingreso único y panel de la vendedora

Hay **un solo ingreso** (Cuenta → Iniciar sesión) para clientas y administradora:

- Quien es **administradora** (está en la tabla `usuario` con ese rol) va directo
  al **panel de la vendedora**. En su cuenta también ve el botón "Ir al panel".
- Las **clientas** van a la tienda. No ven ningún acceso al panel.
- Las clientas se registran desde el mismo formulario. Si Supabase tiene activada
  la confirmación de correo, la app avisa que hay que confirmarlo.

El panel tiene tres secciones:

1. **Pedidos:** filtra por estado y cámbialos; cada cambio queda en el historial.
2. **Fotos de artículos:** elige un artículo; sube, ordena, haz principal o borra
   sus fotos. La primera es la que se ve en la tienda.
3. **Fotos del sitio:** cambia o quita la foto de cada lugar de la página. Por
   ahora solo la **portada del inicio** se muestra en la tienda; el logo, el
   banner de mayoreo y el fondo ya se pueden preparar, pero todavía no se ven.

Solo la administradora puede cambiar fotos: las reglas de seguridad de Supabase
rechazan cualquier subida o cambio sin su sesión, aunque se llame directo a la
base de datos.

## Diseño para PC y para celular

La app se adapta al ancho de la ventana (`lib/utils/adaptable.dart`):

- **900 px o más (PC):** barra superior con los enlaces (Inicio, Categorías,
  Carrito, Cuenta), grilla de 4 columnas, y dos columnas en el detalle del
  producto, el carrito y el checkout. La acción principal queda fija abajo a la
  derecha.
- **Menos de 900 px (celular):** barra superior simple y navegación inferior,
  grilla de 2 columnas y una sola columna.

`TinaScaffold` elige el marco según el ancho, así que las Pages son las mismas
en los dos diseños.

## Animaciones y efectos

- **Intro animada** (`TinaIntro`): al iniciar sesión o registrarte, la portada
  abre con las letras de "Tina" escribiéndose una por una con un lápiz que las
  traza y se desvanece, la estrella de la ı con un rebote y el eslogan. Sale
  suavemente, se puede saltar con un clic y solo aparece una vez por inicio de
  sesión (si entras desde el checkout, aparece al llegar a la portada).
- **Efectos al pasar el mouse** (solo en PC, `TinaHover`): los botones y las
  tarjetas suben un poco con transición suave de color; el borde de los campos
  cambia de color; las filas del resumen se resaltan; las pastillas, etiquetas y
  muestras de color crecen y giran apenas; los enlaces cambian de color y la
  flecha de "volver" se mueve; "Quitar" se oscurece. Ningún efecto usa sombras.

## Recorrido de prueba

1. **Portada** → elige una categoría o abre un producto.
2. **Detalle** → elige color, talla y cantidad (el límite es el stock) y agrega al carrito.
3. **Carrito** → cambia la cantidad, quita una línea y mira los descuentos
   (20% en la primera compra con cuenta, 30% con 14 o más unidades).
4. **Checkout** → compra como invitada o con cuenta. Para tener cuenta, crea una
   desde Cuenta → Regístrate.
5. **Confirmación** → número de pedido, comprobante y estado. El stock baja.
6. **Cuenta** (barra inferior) → pedidos de la clienta y cierre de sesión.
7. **Panel de vendedora** (entra con la cuenta de administradora) → pedidos y
   fotos.
8. **Link Del Video**
https://youtu.be/eZb26JoHPJ4

## Cómo está organizado el código

```
lib/
  config/        Datos de conexión con Supabase (URL y llave pública)
  models/        Una clase por tabla del modelo entidad-relación
  data/          Catálogo, sesión y fotos (Supabase) y datos de ejemplo
  logic/         Reglas sin pantalla: descuentos, primera compra, validaciones
  theme/         Colores y tipografía de Tina
  components/    Widgets reutilizables de la galería de diseño (uno por archivo)
  pages/         Pages: muestran datos y reportan con callbacks; no guardan estado
  screens/       tina_screen.dart: la Screen anfitriona
supabase/        Scripts SQL de la base de datos y guía para ejecutarlos
test/            Pruebas de datos, lógica, componentes, ingreso, panel y recorrido
```

### Estado y comunicación

- **El estado vive en la Screen anfitriona** (`TinaScreen`): catálogo con stock,
  fotos, carrito, pedidos, sesión, selección del detalle y formularios.
- **Las Pages** reciben datos y callbacks. Ninguna guarda datos de la app por su
  cuenta. Los componentes tampoco: los selectores y campos reciben el valor y
  avisan cada cambio.
- **Supabase detrás de interfaces:** la Screen no habla con Supabase
  directamente; usa `CatalogoRepositorio`, `SesionRepositorio` y
  `AdministradoraRepositorio`. Así las pruebas corren sin red, con versiones de
  mentira.
- **Navegación:** `TinaScreen` mantiene una pila de rutas (`Ruta`) y la entrega
  a un `Navigator` con páginas. El botón "atrás" del sistema retrocede por esa
  pila. La barra inferior (Inicio, Categorías, Carrito, Cuenta) cambia de sección.

## Decisiones y pendientes

- **Descuentos:** si aplican los dos a la vez, se toma el mayor y no se
  acumulan. Está por confirmar.
- **Total del pedido:** `total = subtotal − descuento`, como en el diseño. El
  costo de envío ($9.000 en Cali, $12.000 en el resto) se guarda en el envío,
  pero no se suma al total. Está por confirmar.
- **Pedidos y pagos:** falta guardarlos en Supabase; el pago con Wompi sigue
  simulado.
- **Publicación:** la app todavía no está publicada en internet.
- **Diseño:** pendiente darle un aspecto más artesanal, hecho a mano, con las
  fotos reales de las piezas.
