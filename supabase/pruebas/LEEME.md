# Prueba de la base de datos

`prueba_pedidos.mjs` ejecuta los scripts de `supabase/` en un Postgres de verdad
que corre dentro de Node (PGlite), sin internet y **sin tocar tu proyecto de
Supabase**. Comprueba con datos de prueba:

- Que crear un pedido descuenta el stock, calcula los descuentos (el mayor, no
  se acumulan) y el envío de $5.000 con los precios de la base de datos.
- Que todo se deshace si falta stock en algún artículo.
- Que la contraentrega solo vale en Cali, Valle del Cauca, y no cobra envío.
- Que solo la administradora cambia estados, y que cancelar devuelve el stock.
- Qué ve cada persona (reglas de seguridad): una visitante no ve pedidos, una
  clienta ve solo los suyos y la administradora ve todos.

## Cómo correrla

Hace falta Node.js. Desde esta carpeta:

```bash
npm install @electric-sql/pglite
node prueba_pedidos.mjs
```

Al final dice cuántas comprobaciones salieron bien y mal.

## Prueba de las funciones del servidor de Wompi

`prueba_wompi.mjs` prueba `iniciar-pago` y `wompi-eventos` sin internet: la firma
de integridad contra el ejemplo oficial de la documentación de Wompi, la
verificación de la firma de los avisos (con avisos alterados y sin firma), la
dirección de la página de pago y cómo responde cada caso. Necesita Node 22 o más
nuevo (lee los archivos `.ts` directamente):

```bash
node prueba_wompi.mjs
```

`prueba_aviso.mjs` prueba la función `avisar-pedido` (cómo se escribe el mensaje,
quién puede pedir un aviso, qué pasa si falla el envío) y que un pago aprobado
de Wompi dispare el aviso:

```bash
node prueba_aviso.mjs
```

Nota: el ejemplo de aviso de la documentación de Wompi muestra el resultado
`3476DDA5…`, pero ese número no sale de los valores que la propia documentación
usa (con ellos, SHA-256 da `5A18EC5E…`). Por eso la prueba compara con el cálculo
de la librería de Node siguiendo los pasos de la documentación.
