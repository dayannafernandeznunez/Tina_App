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
| 5 | `migrations/20261114000003_cuentas_de_clientas.sql` | Crea la fila de clienta sola al registrarse y deja que cada una vea la suya. |
| 6 | `migrations/20261118000004_pedidos_reales.sql` | Pedidos reales: crea el pedido descontando el stock, con descuentos y el envío de $5.000; contraentrega en Cali; cambios de estado; cada clienta ve sus pedidos. |

| 7 | `migrations/20261118000005_pago_wompi.sql` | Pago en línea: cada pedido tiene su llave (`token_publico`), los intentos de pago y las funciones que usan las funciones del servidor para iniciar el pago, recibir el aviso de Wompi y consultar o cancelar un pedido. |
| 8 | `migrations/20261119000006_fotos_por_color.sql` | Cada foto de un producto puede ser de un color: al elegir ese color en la tienda se ven sus fotos. |
| 9 | `migrations/20261119000007_aviso_whatsapp.sql` | Aviso por WhatsApp: marca cada pedido como avisado (para no repetirlo) y arma lo que lleva el mensaje. |

Los scripts nuevos se agregan al final: si ya ejecutaste los anteriores, solo
ejecuta los que falten, en orden. La prueba de que funcionan está en
[`pruebas/`](pruebas/LEEME.md).

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

## Pago en línea con Wompi

El pago usa dos funciones del servidor, que viven en `functions/`:

| Función | Qué hace |
|---|---|
| `iniciar-pago` | La app le dice qué pedido quiere pagar. Toma el monto **de la base de datos**, lo firma con el secreto de integridad y devuelve la dirección de la página de pago de Wompi. |
| `wompi-eventos` | Wompi le avisa aquí cuando un pago se aprueba o se rechaza. Comprueba la firma del aviso, y la base de datos verifica el monto y marca el pedido como pagado (con su comprobante). |

Los secretos **nunca** van en el código ni en el chat: se escriben solo en
Supabase.

### Activarlo (modo de pruebas)

1. **Ejecuta el script 7** (y el 6 si todavía no lo has hecho) en el *SQL Editor*.
2. **Guarda los secretos.** En Supabase: *Edge Functions* → *Secrets* → *Add new
   secret*. Son cuatro:

   | Nombre | Valor |
   |---|---|
   | `WOMPI_PUBLIC_KEY` | La llave pública de pruebas (`pub_test_…`). |
   | `WOMPI_INTEGRITY_SECRET` | El secreto de integridad de pruebas (`test_integrity_…`), de Wompi → *Desarrolladores*. |
   | `WOMPI_EVENTS_SECRET` | El secreto de eventos de pruebas (`test_events_…`), en el mismo lugar. |
   | `SITIO_URL` | Dónde está la tienda, sin `/` al final. Para probar en tu computador: `http://localhost:5000`. |

3. **Crea las dos funciones.** *Edge Functions* → *Deploy a new function* → *Via
   Editor*. Una por una, con el nombre exacto (`iniciar-pago`, `wompi-eventos`),
   pega el contenido de su `index.ts` y despliega. **En las dos, apaga
   *Verify JWT*** (en *Function settings*): `wompi-eventos` la llama Wompi, que no
   tiene una llave de Supabase, y se protege con la firma de cada aviso;
   `iniciar-pago` se protege con la llave de cada pedido.
4. **Dile a Wompi dónde avisar.** En Wompi, con el modo de pruebas (*sandbox*):
   *Desarrolladores* → *URL de Eventos* →
   `https://nklkvmxqtipdvvmmmaan.supabase.co/functions/v1/wompi-eventos`.
5. **Corre la tienda en el puerto fijo** (tiene que coincidir con `SITIO_URL`):

   ```bash
   flutter run -d chrome --web-port 5000
   ```

6. **Prueba una compra.** Elige un producto, llena el envío (fuera de Cali, o en
   Cali con Wompi) y paga. En la página de Wompi usa la tarjeta de pruebas
   `4242 4242 4242 4242` (se aprueba) o `4111 1111 1111 1111` (se rechaza), con
   cualquier fecha futura y un CVC de 3 números. Al volver, la tienda confirma
   el pago; en el panel el pedido debe quedar en **Pagado**, con su comprobante.

### Pasar a producción

Cambia los tres secretos de Wompi por los de producción (`pub_prod_…`,
`prod_integrity_…`, `prod_events_…`), pon en `SITIO_URL` la dirección real de la
tienda y pon la *URL de Eventos* también en el ambiente de producción de Wompi.

### Si algo no funciona

- **"El pago en línea todavía no está configurado"**: falta algún secreto.
- **La página de Wompi no abre**: en *Edge Functions* → `iniciar-pago` → *Logs*
  está el motivo.
- **Pagué pero el pedido sigue pendiente**: casi siempre es la *URL de Eventos*
  mal puesta o `WOMPI_EVENTS_SECRET` equivocado; mira los *Logs* de
  `wompi-eventos` (un aviso con firma mala responde 401).
- Un pedido que se queda sin pagar **no se cancela solo**: tiene el stock
  apartado hasta que la vendedora lo cancele desde el panel.

## Aviso por WhatsApp de los pedidos

Cada pedido nuevo te llega por WhatsApp con la clienta (y un enlace para
escribirle), los artículos, el total, la dirección y, si es contraentrega, el
recordatorio de coordinar la transferencia:

- **Contraentrega:** el aviso sale apenas la clienta hace el pedido.
- **Pago con Wompi:** sale cuando Wompi confirma el pago (no antes).
- Un pedido cancelado no se avisa, y cada pedido se avisa **una sola vez**.

Lo manda la función `avisar-pedido` por **CallMeBot**, un servicio gratis que
escribe a tu propio WhatsApp (solo sirve para recibir los avisos tú; es de uso
personal y no oficial, así que si algún día deja de funcionar, la tienda sigue
igual y los pedidos se ven en el panel).

### Activarlo

1. **Ejecuta el script 9** en el *SQL Editor*.
2. **Activa CallMeBot** (una sola vez): guarda el contacto **+34 644 44 21 48**
   en tu celular, escríbele por WhatsApp exactamente `I allow callmebot to send me
   messages` y espera su respuesta: trae tu **clave** (si no llega en 2 minutos,
   se reintenta a las 24 horas).
3. **Guarda dos secretos** en *Edge Functions* → *Secrets*:

   | Nombre | Valor |
   |---|---|
   | `VENDEDORA_TELEFONO` | Tu número con el código del país, por ejemplo `+573001234567`. |
   | `CALLMEBOT_APIKEY` | La clave que te respondió CallMeBot. |

4. **Crea la función `avisar-pedido`** igual que las otras (*Via Editor*, con el
   contenido de `functions/avisar-pedido/index.ts` y *Verify JWT* apagado).
5. **Vuelve a desplegar `wompi-eventos`** con el `index.ts` nuevo: ahora avisa
   cuando se aprueba un pago.
6. **Prueba:** haz una compra con contraentrega en Cali. En unos segundos debe
   llegarte el mensaje.

Si faltan los secretos no pasa nada malo: la tienda funciona y simplemente no se
avisa. Si no llega el mensaje, mira los *Logs* de `avisar-pedido`.

## Qué nunca se sube a GitHub

El repositorio es público. La llave **service_role** (en paneles nuevos,
*secret*) da control total sobre la base de datos: no la pegues en el código, en
el chat ni en ningún archivo del repositorio.

## Quién puede qué

- **Cualquier visitante** puede ver el catálogo, las promociones y las fotos.
- **Solo la administradora** puede crear, cambiar o borrar productos, fotos y
  ajustes del sitio, y es la única que ve pedidos, clientas y pagos.
- **Las clientas** compran con funciones del servidor que calculan los precios,
  los descuentos y el stock; ven solo sus propios pedidos. Quien compra sin
  cuenta sigue su pedido con la llave que le da la tienda.
