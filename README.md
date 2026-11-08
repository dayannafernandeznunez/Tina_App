# Tina — prototipo navegable en Flutter

Prototipo de la tienda en línea de Tina ("Tan latinas como tú"), hecho con
Flutter. Funciona con **datos simulados en memoria**, sin conexión a la nube.
Los datos siguen el modelo entidad-relación del proyecto (categorías, productos,
variantes con stock, clientes, pedidos, pagos, comprobantes, envíos, historial).

## Cómo ejecutarlo

```bash
flutter pub get
flutter run -d chrome
```

En Chrome, abre la ventana a un ancho de 900 px o más para ver el diseño de PC.

Las pruebas y el análisis:

```bash
flutter analyze
flutter test
```

La fuente (Bricolage Grotesque e Instrument Serif) se descarga de Google Fonts
al abrir la app, así que hace falta conexión a internet.

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
4. **Checkout** → compra como invitada o con cuenta. Para probar con cuenta:
   `valentina.rios@correo.com` y cualquier contraseña de 8 o más caracteres.
5. **Confirmación** → número de pedido, comprobante y estado. El stock baja.
6. **Cuenta** (barra inferior) → pedidos de la clienta y cierre de sesión.
7. **Panel de vendedora** (Cuenta → "Soy vendedora · ir al panel") → filtra los
   pedidos por estado y cámbialos: cada cambio queda en el historial del pedido.

## Cómo está organizado el código

```
lib/
  models/        Una clase por tabla del modelo entidad-relación
  data/          Datos simulados (coherentes con los modelos)
  logic/         Reglas sin pantalla: descuentos, primera compra, validaciones
  theme/         Colores y tipografía de Tina
  components/    Widgets reutilizables de la galería de diseño (uno por archivo)
  pages/         Pages: muestran datos y reportan con callbacks; no guardan estado
  screens/       tina_screen.dart: la Screen anfitriona
test/            Pruebas de datos, lógica, componentes y recorrido completo
```

### Estado y comunicación

- **El estado vive en la Screen anfitriona** (`TinaScreen`): catálogo con stock,
  carrito, pedidos, sesión, selección del detalle y formularios.
- **Las Pages** reciben datos y callbacks. Ninguna guarda datos de la app por su
  cuenta. Los componentes tampoco: los selectores y campos reciben el valor y
  avisan cada cambio.
- **Navegación:** `TinaScreen` mantiene una pila de rutas (`Ruta`) y la entrega
  a un `Navigator` con páginas. El botón "atrás" del sistema retrocede por esa
  pila. La barra inferior (Inicio, Categorías, Carrito, Cuenta) cambia de sección.

## Decisiones y pendientes

- **Descuentos:** si aplican los dos a la vez, se toma el mayor y no se
  acumulan. Está por confirmar.
- **Total del pedido:** `total = subtotal − descuento`, como en el diseño. El
  costo de envío ($9.000 en Cali, $12.000 en el resto) se guarda en el envío,
  pero no se suma al total. Está por confirmar.
- **Pagos:** el pago con Wompi se simula y siempre sale aprobado.
- **Fotos:** las tarjetas y la galería pintan degradados de marca donde irían
  las fotos reales.
