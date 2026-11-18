// Prueba de los scripts de Supabase contra un Postgres de verdad (PGlite), sin
// internet y sin tocar tu proyecto. Ver LEEME.md de esta carpeta.
import { PGlite } from '@electric-sql/pglite';
import fs from 'node:fs';

// Los scripts de la carpeta de arriba (supabase/).
const RAIZ = new URL('..', import.meta.url);
const leer = (r) => fs.readFileSync(new URL(r, RAIZ), 'utf8');

const db = new PGlite();

// Lo mínimo de Supabase que los scripts necesitan: roles, auth y storage.
await db.exec(`
  create role anon nologin; create role authenticated nologin;
  create schema auth;
  create table auth.users (id uuid primary key default gen_random_uuid(),
    email text, raw_user_meta_data jsonb default '{}'::jsonb);
  create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  create schema storage;
  create table storage.buckets (id text primary key, name text, public boolean,
    file_size_limit bigint, allowed_mime_types text[]);
  create table storage.objects (bucket_id text, name text);
  alter table storage.objects enable row level security;
`);

for (const f of [
  'migrations/20261114000001_esquema.sql',
  'migrations/20261114000002_seguridad_y_fotos.sql',
  'migrations/20261114000003_cuentas_de_clientas.sql',
  'seed.sql',
  'migrations/20261118000004_pedidos_reales.sql',
]) {
  try {
    await db.exec(leer(f));
  } catch (e) {
    console.log(`FALLA al ejecutar ${f}: ${e.message}`);
    process.exit(1);
  }
}
// Como en Supabase: los roles de la app pueden usar las tablas; RLS decide qué.
await db.exec(`
  grant usage on schema public, auth to anon, authenticated;
  grant all on all tables in schema public to anon, authenticated;
  grant all on all sequences in schema public to anon, authenticated;
  grant select on auth.users to authenticated;
`);
console.log('Los 5 scripts corren sin errores.\n');

let ok = 0, mal = 0;
const igual = (nombre, real, esperado) => {
  const bien = JSON.stringify(real) === JSON.stringify(esperado);
  bien ? ok++ : mal++;
  console.log(`${bien ? 'OK   ' : 'MAL  '} ${nombre}${bien ? '' : `  -> real=${JSON.stringify(real)} esperado=${JSON.stringify(esperado)}`}`);
};
const q = async (sql, p = []) => (await db.query(sql, p)).rows;
const uno = async (sql, p = []) => (await q(sql, p))[0];
const falla = async (nombre, sql, p, texto) => {
  try { await db.query(sql, p); mal++; console.log(`MAL  ${nombre}: no falló`); }
  catch (e) {
    const bien = e.message.includes(texto);
    bien ? ok++ : mal++;
    console.log(`${bien ? 'OK   ' : 'MAL  '} ${nombre}${bien ? '' : `  -> ${e.message}`}`);
  }
};
const como = async (uid) => db.query(`select set_config('request.jwt.claim.sub', $1, false)`, [uid ?? '']);

const envio = (ciudad = 'Bogotá', depto = 'Cundinamarca') => JSON.stringify({
  nombre_destinatario: 'Isabella', telefono: '3001112233',
  departamento: depto, ciudad, direccion: 'Calle 1 #2-3',
});
const invitada = JSON.stringify({ nombre: 'Isabella', correo: 'isa@correo.com', telefono: '3001112233' });
const pedir = (items, metodo = 'wompi', e = envio(), c = invitada) =>
  uno(`select public.crear_pedido($1::jsonb, $2::jsonb, $3::jsonb, $4) as r`,
    [JSON.stringify(items), e, c, metodo]).then((x) => x.r);
const stock = async (id) => (await uno('select stock from variante_producto where id_variante=$1', [id])).stock;

// ---------------------------------------------------------------- invitada
console.log('--- Compra sin cuenta, envío fijo');
let r = await pedir([{ id_variante: 1, cantidad: 2 }]);   // collar 55.000, stock 6
igual('subtotal 2 x 55.000', r.subtotal, 110000);
igual('sin descuento', r.descuento, 0);
igual('envío $5.000', r.costo_envio, 5000);
igual('total = subtotal + envío', r.total, 115000);
igual('código del pedido', r.codigo, 'TINA-0001');
igual('el stock bajó de 6 a 4', await stock(1), 4);
const p1 = await uno('select * from pedido where id_pedido=$1', [r.id_pedido]);
igual('el pedido queda pendiente', p1.estado_actual, 'pendiente');
const pago1 = await uno('select * from pago where id_pedido=$1', [r.id_pedido]);
igual('pago pendiente con el monto total', [pago1.estado, pago1.monto, pago1.proveedor], ['pendiente', 115000, 'wompi']);
const det = await uno('select * from detalle_pedido where id_pedido=$1', [r.id_pedido]);
igual('el precio unitario se copia al detalle', [det.precio_unitario, det.subtotal], [55000, 110000]);
igual('hay un registro en el historial', (await q('select * from historial_estado where id_pedido=$1', [r.id_pedido])).length, 1);
const cli = await uno('select * from cliente where correo=$1', ['isa@correo.com']);
igual('la compradora queda como cliente sin cuenta', cli.cuenta_registrada, false);
await pedir([{ id_variante: 5, cantidad: 1 }]);
igual('la misma persona reutiliza su fila de cliente', (await q(`select 1 from cliente where lower(correo)='isa@correo.com'`)).length, 1);

console.log('\n--- Descuentos');
r = await pedir([{ id_variante: 7, cantidad: 12 }, { id_variante: 8, cantidad: 2 }]);   // aretes 16.000 x 14
igual('14 unidades: 30%', [r.subtotal, r.descuento, r.total], [224000, 67200, 224000 - 67200 + 5000]);
igual('usa la promoción por volumen', (await uno('select id_promocion from pedido where id_pedido=$1', [r.id_pedido])).id_promocion, 2);
r = await pedir([{ id_variante: 9, cantidad: 13 }]).catch((e) => ({ error: e.message }));   // stock 5: no alcanza
igual('sin stock suficiente falla con mensaje claro', r.error?.includes('No hay stock suficiente de Pulsera tejida'), true);

console.log('\n--- Todo o nada si falta stock');
const antes5 = await stock(5);
await falla('un artículo sin stock cancela todo el pedido', `select public.crear_pedido($1::jsonb,$2::jsonb,$3::jsonb,'wompi')`,
  [JSON.stringify([{ id_variante: 5, cantidad: 1 }, { id_variante: 2, cantidad: 99 }]), envio(), invitada], 'No hay stock suficiente');
igual('el otro artículo no quedó descontado', await stock(5), antes5);
await falla('carrito vacío', `select public.crear_pedido('[]'::jsonb,$1::jsonb,$2::jsonb,'wompi')`, [envio(), invitada], 'carrito está vacío');
await falla('faltan datos de envío', `select public.crear_pedido($1::jsonb,'{}'::jsonb,$2::jsonb,'wompi')`,
  [JSON.stringify([{ id_variante: 5, cantidad: 1 }]), invitada], 'Faltan datos de envío');
await falla('cantidad cero', `select public.crear_pedido($1::jsonb,$2::jsonb,$3::jsonb,'wompi')`,
  [JSON.stringify([{ id_variante: 5, cantidad: 0 }]), envio(), invitada], 'cantidad no es válida');

console.log('\n--- Contraentrega');
r = await pedir([{ id_variante: 6, cantidad: 1 }], 'contraentrega', envio('Cali', 'Valle del Cauca'));
igual('en Cali no se cobra envío', [r.costo_envio, r.total, r.subtotal], [0, 18000, 18000]);
igual('el pago queda como contraentrega', (await uno('select proveedor from pago where id_pedido=$1', [r.id_pedido])).proveedor, 'contraentrega');
const idContra = r.id_pedido;
r = await pedir([{ id_variante: 6, cantidad: 1 }], 'contraentrega', envio('CALÍ', 'Valle del Cauca'));
igual('Cali con mayúsculas y tilde también vale', r.costo_envio, 0);
await falla('fuera de Cali no hay contraentrega', `select public.crear_pedido($1::jsonb,$2::jsonb,$3::jsonb,'contraentrega')`,
  [JSON.stringify([{ id_variante: 6, cantidad: 1 }]), envio('Bogotá', 'Cundinamarca'), invitada], 'solo está disponible en Cali');
await falla('Palmira tampoco', `select public.crear_pedido($1::jsonb,$2::jsonb,$3::jsonb,'contraentrega')`,
  [JSON.stringify([{ id_variante: 6, cantidad: 1 }]), envio('Palmira', 'Valle del Cauca'), invitada], 'solo está disponible en Cali');

console.log('\n--- Clienta con cuenta');
const CLIENTA = '11111111-1111-1111-1111-111111111111';
await db.query(`insert into auth.users (id, email, raw_user_meta_data) values ($1, 'sara@correo.com', '{"nombre":"Sara"}')`, [CLIENTA]);
igual('el trigger crea su fila de cliente', (await uno(`select cuenta_registrada from cliente where id_auth=$1`, [CLIENTA])).cuenta_registrada, true);
await como(CLIENTA);
r = await pedir([{ id_variante: 10, cantidad: 1 }], 'wompi', envio(), '{}');   // pulsera 17.000
igual('primera compra con cuenta: 20%', [r.subtotal, r.descuento, r.total], [17000, 3400, 17000 - 3400 + 5000]);
const idSara1 = r.id_pedido;
r = await pedir([{ id_variante: 10, cantidad: 1 }], 'wompi', envio(), '{}');
igual('la segunda compra ya no tiene el 20%', r.descuento, 0);
await db.query(`update variante_producto set stock = 40 where id_variante = 13`);
r = await pedir([{ id_variante: 13, cantidad: 14 }], 'wompi', envio(), '{}');
igual('con 14 unidades se aplica el 30%', Math.round(r.descuento / r.subtotal * 100), 30);
await como(null);

console.log('\n--- Cambios de estado (administradora)');
const ADMIN = '22222222-2222-2222-2222-222222222222';
await db.query(`insert into auth.users (id, email) values ($1, 'tina@correo.com')`, [ADMIN]);
await db.query(`insert into usuario (id_auth, nombre, correo, rol) values ($1, 'Tina', 'tina@correo.com', 'administradora')`, [ADMIN]);
await como(CLIENTA);
await falla('una clienta no puede cambiar estados', `select public.cambiar_estado_pedido($1, 'pagado')`, [idSara1], 'No tienes permiso');
await como(ADMIN);
await db.query(`select public.cambiar_estado_pedido($1, 'pagado')`, [idContra]);
let est = await uno('select estado_actual from pedido where id_pedido=$1', [idContra]);
igual('la administradora lo pasa a pagado', est.estado_actual, 'pagado');
igual('el pago queda aprobado', (await uno('select estado from pago where id_pedido=$1', [idContra])).estado, 'aprobado');
const comp = await uno('select c.numero from comprobante c join pago p on p.id_pago=c.id_pago where p.id_pedido=$1', [idContra]);
igual('se crea el comprobante', comp.numero, `C-${String(idContra).padStart(4, '0')}`);
await db.query(`select public.cambiar_estado_pedido($1, 'pagado')`, [idContra]);
igual('repetir el mismo estado no duplica nada', (await q('select 1 from comprobante')).length, 1);
await db.query(`select public.cambiar_estado_pedido($1, 'enviado')`, [idContra]);
const hist = await q('select estado_anterior, estado_nuevo from historial_estado where id_pedido=$1 order by id_historial', [idContra]);
igual('el historial guarda cada cambio con su estado anterior', hist.map((h) => `${h.estado_anterior ?? '-'}>${h.estado_nuevo}`), ['->pendiente', 'pendiente>pagado', 'pagado>enviado']);
igual('quien hizo el cambio aparece en el historial', (await uno(`select u.rol from historial_estado h join usuario u on u.id_usuario=h.id_usuario where h.id_pedido=$1 and h.estado_nuevo='enviado'`, [idContra])).rol, 'administradora');

const stockAntes = await stock(1);   // collares del primer pedido (2 unidades)
await db.query(`select public.cambiar_estado_pedido($1, 'cancelado')`, [p1.id_pedido]);
igual('al cancelar, el stock vuelve', await stock(1), stockAntes + 2);
igual('al cancelar, el pago pendiente se rechaza', (await uno('select estado from pago where id_pedido=$1', [p1.id_pedido])).estado, 'rechazado');
await falla('un pedido cancelado no se reactiva', `select public.cambiar_estado_pedido($1, 'pagado')`, [p1.id_pedido], 'no se puede reactivar');
await falla('estado inventado', `select public.cambiar_estado_pedido($1, 'volando')`, [idContra], 'no es válido');
await como(null);

console.log('\n--- Quién ve qué (RLS)');
await db.exec('set role anon');
await como(null);
igual('una visitante no ve pedidos', (await q('select 1 from pedido')).length, 0);
r = await pedir([{ id_variante: 5, cantidad: 1 }]);
igual('una visitante sí puede comprar', typeof r.id_pedido, 'number');
const upd = await db.query(`update producto set precio = 1 returning 1`);
igual('ni cambia precios (RLS la deja sin filas)', upd.rows.length, 0);
await falla('no puede aprobar pagos a mano', `select public.aprobar_pago(1)`, [], 'permission denied');
await db.exec('reset role');

await db.exec('set role authenticated');
await como(CLIENTA);
const mios = await q('select id_pedido from pedido');
const propios = await q(`select p.id_pedido from pedido p join cliente c on c.id_cliente=p.id_cliente where c.id_auth=$1`, [CLIENTA]);
igual('una clienta ve solo sus pedidos', mios.map((x) => x.id_pedido).sort(), propios.map((x) => x.id_pedido).sort());
igual('y son 3', mios.length, 3);
igual('no ve el detalle de los demás', (await q('select 1 from detalle_pedido d join pedido p on p.id_pedido=d.id_pedido join cliente c on c.id_cliente=p.id_cliente where c.id_auth <> $1 or c.id_auth is null', [CLIENTA])).length, 0);
await como(ADMIN);
igual('la administradora ve todos', (await q('select 1 from pedido')).length >= 7, true);
await db.exec('reset role');

console.log(`\n${ok} bien, ${mal} mal`);
process.exit(mal ? 1 : 0);
