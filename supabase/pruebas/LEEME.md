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
