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
  create role anon nologin; create role authenticated nologin; create role service_role nologin;
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
  'migrations/20261118000005_pago_wompi.sql',
  'migrations/20261119000006_fotos_por_color.sql',
  'migrations/20261119000007_aviso_whatsapp.sql',
  'migrations/20261124000008_charm_bar_y_colecciones.sql',
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
  grant usage on schema public, auth to anon, authenticated, service_role;
  grant all on all tables in schema public to anon, authenticated;
  grant all on all sequences in schema public to anon, authenticated;
  grant select on auth.users to authenticated;
`);
console.log('Los 9 scripts corren sin errores.\n');

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


// ============================================================ pago con Wompi
console.log('\n--- Pago con Wompi: token, intentos y resultado');
await como(null);   // una visitante, sin sesión
const ref = (id, n) => `TINA-${String(id).padStart(4, '0')}-${n}`;
const COMO_SERVICIO = async (f) => { await db.exec('set role service_role'); try { return await f(); } finally { await db.exec('reset role'); } };
const estadoDe = async (id) => (await uno('select estado_actual from pedido where id_pedido=$1', [id])).estado_actual;
const pagoDe = async (id) => await uno('select * from pago where id_pedido=$1', [id]);

const stockAntesW = await stock(11);                                  // pulsera L, 17.000
r = await pedir([{ id_variante: 11, cantidad: 1 }]);
const idW = r.id_pedido, tokW = r.token, totalW = r.total;
igual('crear_pedido devuelve el token del pedido', typeof tokW, 'string');
igual('el total incluye el envío', totalW, 17000 + 5000);

await db.exec('set role anon');
const veo = (await uno('select public.ver_estado_pedido($1, $2::uuid) as r', [idW, tokW])).r;
igual('con su token la compradora ve el estado', [veo.estado, veo.total, veo.pago_estado], ['pendiente', totalW, 'pendiente']);
await falla('con otro token no ve nada', `select public.ver_estado_pedido($1, '00000000-0000-0000-0000-000000000000'::uuid)`, [idW], 'No encontramos ese pedido');
await falla('la app no puede iniciar un pago por su cuenta', `select public.iniciar_pago($1, $2::uuid)`, [idW, tokW], 'permission denied');
await falla('ni registrar un resultado de pago', `select public.registrar_resultado_pago('TINA-0001-1','APPROVED',100,'x')`, [], 'permission denied');
await falla('ni aprobar un pago', `select public.aprobar_pago($1)`, [idW], 'permission denied');
await db.exec('reset role');

let ini = (await COMO_SERVICIO(() => uno('select public.iniciar_pago($1, $2::uuid) as r', [idW, tokW]))).r;
igual('primer intento: referencia nueva', ini.referencia, ref(idW, 1));
igual('el monto sale del pedido, en centavos', ini.monto_en_centavos, totalW * 100);
await falla('con un token ajeno no se inicia el pago', `select public.iniciar_pago($1, '00000000-0000-0000-0000-000000000000'::uuid)`, [idW], 'No encontramos ese pedido').catch(() => {});
await COMO_SERVICIO(() => falla('token ajeno', `select public.iniciar_pago($1, '00000000-0000-0000-0000-000000000000'::uuid)`, [idW], 'No encontramos ese pedido'));

await COMO_SERVICIO(() => falla('un monto distinto no aprueba nada', `select public.registrar_resultado_pago($1,'APPROVED',100,'t0')`, [ref(idW, 1)], 'no coincide'));
igual('el pedido sigue pendiente', await estadoDe(idW), 'pendiente');
await COMO_SERVICIO(() => falla('una referencia ajena se rechaza', `select public.registrar_resultado_pago('OTRA-TIENDA-1','APPROVED',2200000,'t0')`, [], 'no es de esta tienda'));

let res = (await COMO_SERVICIO(() => uno(`select public.registrar_resultado_pago($1,'DECLINED',$2,'t1') as r`, [ref(idW, 1), totalW * 100]))).r;
igual('un pago rechazado queda rechazado', [res.resultado, (await pagoDe(idW)).estado], ['rechazado', 'rechazado']);
igual('y el pedido sigue pendiente para reintentar', await estadoDe(idW), 'pendiente');

ini = (await COMO_SERVICIO(() => uno('select public.iniciar_pago($1, $2::uuid) as r', [idW, tokW]))).r;
igual('el reintento usa otra referencia', ini.referencia, ref(idW, 2));
igual('y el pago vuelve a pendiente', (await pagoDe(idW)).estado, 'pendiente');

res = (await COMO_SERVICIO(() => uno(`select public.registrar_resultado_pago($1,'APPROVED',$2,'t2') as r`, [ref(idW, 2), totalW * 100]))).r;
igual('el pago aprobado pasa el pedido a pagado', [res.resultado, await estadoDe(idW)], ['aprobado', 'pagado']);
const pg = await pagoDe(idW);
igual('el pago guarda la referencia y queda aprobado', [pg.estado, pg.referencia], ['aprobado', ref(idW, 2)]);
igual('se crea el comprobante', (await q('select c.numero from comprobante c join pago p on p.id_pago=c.id_pago where p.id_pedido=$1', [idW])).map((x) => x.numero), [`C-${String(idW).padStart(4, '0')}`]);
await COMO_SERVICIO(() => db.query(`select public.registrar_resultado_pago($1,'APPROVED',$2,'t2')`, [ref(idW, 2), totalW * 100]));
igual('si Wompi repite el aviso no se duplica nada', (await q('select 1 from comprobante c join pago p on p.id_pago=c.id_pago where p.id_pedido=$1', [idW])).length, 1);
igual('el historial dice quién lo pagó', (await q(`select u.rol from historial_estado h join usuario u on u.id_usuario=h.id_usuario where h.id_pedido=$1 and h.estado_nuevo='pagado'`, [idW])).map((x) => x.rol), ['sistema']);
await COMO_SERVICIO(() => falla('un pedido ya pagado no se vuelve a cobrar', `select public.iniciar_pago($1, $2::uuid)`, [idW, tokW], 'ya no está pendiente'));
igual('el stock quedó descontado', await stock(11), stockAntesW - 1);

console.log('\n--- Anulación, cancelar y pagos tardíos');
r = await pedir([{ id_variante: 11, cantidad: 1 }]);
const idV = r.id_pedido;
await COMO_SERVICIO(() => db.query(`select public.registrar_resultado_pago($1,'APPROVED',$2,'tv')`, [ref(idV, 1), r.total * 100]));
const stockPagado = await stock(11);
await COMO_SERVICIO(() => db.query(`select public.registrar_resultado_pago($1,'VOIDED',$2,'tv')`, [ref(idV, 1), r.total * 100]));
igual('un pago anulado cancela el pedido', await estadoDe(idV), 'cancelado');
igual('y devuelve el stock', await stock(11), stockPagado + 1);

r = await pedir([{ id_variante: 11, cantidad: 1 }]);
const idC = r.id_pedido, tokC = r.token, stockC = await stock(11);
await db.exec('set role anon');
await falla('cancelar con un token ajeno no se puede', `select public.cancelar_pedido_propio($1, '00000000-0000-0000-0000-000000000000'::uuid)`, [idC], 'No encontramos ese pedido');
await db.query('select public.cancelar_pedido_propio($1, $2::uuid)', [idC, tokC]);
await db.exec('reset role');
igual('con su token la compradora cancela su pedido pendiente', await estadoDe(idC), 'cancelado');
igual('y el stock vuelve', await stock(11), stockC + 1);
await db.exec('set role anon');
await falla('un pedido cancelado no se cancela otra vez', `select public.cancelar_pedido_propio($1, $2::uuid)`, [idC, tokC], 'sigue pendiente');
await db.exec('reset role');

res = (await COMO_SERVICIO(() => uno(`select public.registrar_resultado_pago($1,'APPROVED',$2,'tc') as r`, [ref(idC, 1), r.total * 100]))).r;
igual('un pago que llega a un pedido cancelado queda marcado para devolver', [res.resultado, await estadoDe(idC), (await pagoDe(idC)).estado], ['pago_en_pedido_cancelado', 'cancelado', 'aprobado']);

r = await pedir([{ id_variante: 6, cantidad: 1 }], 'contraentrega', envio('Cali', 'Valle del Cauca'));
await COMO_SERVICIO(() => falla('la contraentrega no se paga con Wompi', `select public.iniciar_pago($1, $2::uuid)`, [r.id_pedido, r.token], 'no se paga con Wompi'));

// La administradora sigue pudiendo cancelar (ahora con la función interna).
await como(ADMIN);
r = await pedir([{ id_variante: 11, cantidad: 1 }]);
const stockAdmin = await stock(11);
await db.query(`select public.cambiar_estado_pedido($1, 'cancelado')`, [r.id_pedido]);
igual('la administradora cancela y el stock vuelve', [await estadoDe(r.id_pedido), await stock(11)], ['cancelado', stockAdmin + 1]);
await como(null);

// ---- Fotos por color: la administradora las sube, todos las ven.
await como(ADMIN);
await db.query(`insert into imagen_producto (id_producto, url, ruta, orden, color) values (1, 'https://x/general.jpg', 'p1/g.jpg', 1, null), (1, 'https://x/blanco.jpg', 'p1/b.jpg', 2, 'Blanco')`);
await como(null);
await db.exec('set role anon');
igual('una visitante ve las fotos con su color', (await q(`select color from imagen_producto where id_producto = 1 order by orden`)).map((f) => f.color), [null, 'Blanco']);
await falla('una visitante no puede subir fotos', `insert into imagen_producto (id_producto, url, ruta, orden, color) values (1, 'https://x/z.jpg', 'p1/z.jpg', 3, 'Rojo')`, [], '');
await db.exec('reset role');

// ---- Aviso por WhatsApp: cuándo toca avisar y que no se repita.
console.log('\n--- Aviso por WhatsApp');
const reclamar = (id, tok = null) => COMO_SERVICIO(() => uno('select public.reclamar_aviso_pedido($1, $2::uuid) as a', [id, tok]).then((x) => x.a));

r = await pedir([{ id_variante: 6, cantidad: 2 }], 'contraentrega', envio('Cali', 'Valle del Cauca'));
const idCE = r.id_pedido, tokCE = r.token;
await db.exec('set role anon');
await falla('una visitante no puede pedir avisos directamente', 'select public.reclamar_aviso_pedido($1, $2::uuid)', [idCE, tokCE], 'permission denied');
await db.exec('reset role');
await COMO_SERVICIO(() => falla('con la llave de otro pedido no se encuentra', "select public.reclamar_aviso_pedido($1, '00000000-0000-0000-0000-000000000000'::uuid)", [idCE], 'No encontramos ese pedido'));

let av = await reclamar(idCE, tokCE);
igual('una contraentrega se avisa apenas se crea', [av.codigo, av.metodo_pago, av.estado, av.cliente], [`TINA-${String(idCE).padStart(4, '0')}`, 'contraentrega', 'pendiente', 'Isabella']);
igual('el aviso trae la dirección y el total', [av.ciudad, av.direccion, av.costo_envio, av.total === r.total], ['Cali', 'Calle 1 #2-3', 0, true]);
igual('y los artículos con color, talla y cantidad', [av.lineas.length, av.lineas[0].cantidad, typeof av.lineas[0].nombre, typeof av.lineas[0].color], [1, 2, 'string', 'string']);
igual('la segunda vez no se avisa (ya se avisó)', await reclamar(idCE, tokCE), null);
await COMO_SERVICIO(() => db.query('select public.liberar_aviso_pedido($1)', [idCE]));
igual('si el envío falló, liberado se puede avisar otra vez', (await reclamar(idCE)).codigo, av.codigo);

r = await pedir([{ id_variante: 11, cantidad: 1 }]);
const idPW = r.id_pedido;
igual('un pedido de Wompi sin pagar no se avisa', await reclamar(idPW), null);
await COMO_SERVICIO(() => db.query("select public.registrar_resultado_pago($1, 'APPROVED', $2, 'tx-aviso')", [ref(idPW, 1), r.total * 100]));
av = await reclamar(idPW);
igual('al aprobarse el pago, sí se avisa (sin llave: lo pide el servidor)', [av.codigo, av.metodo_pago, av.estado], [`TINA-${String(idPW).padStart(4, '0')}`, 'wompi', 'pagado']);
igual('y solo una vez', await reclamar(idPW), null);

r = await pedir([{ id_variante: 6, cantidad: 1 }], 'contraentrega', envio('Cali', 'Valle del Cauca'));
await db.query('update pedido set estado_actual = $2 where id_pedido = $1', [r.id_pedido, 'cancelado']);
igual('un pedido cancelado no se avisa', await reclamar(r.id_pedido), null);


// ---- Charm Bar, colecciones y suscripción.
console.log('\n--- Charm Bar, colecciones y suscripción');
await como(null);
await db.exec('set role anon');
igual('una visitante ve las categorías Charm Bar y Charms', (await q("select nombre from categoria where nombre in ('Charm Bar','Charms') order by nombre")).map((c) => c.nombre), ['Charm Bar', 'Charms']);
igual('el collar base y los charms de ejemplo están ocultos para ella', (await q("select count(*)::int n from producto where id_categoria in (select id_categoria from categoria where nombre in ('Charm Bar','Charms'))"))[0].n, 0);
await db.exec('reset role');
igual('el collar base trae sus colores y modos (8 variantes)', (await q("select count(*)::int n from variante_producto v join producto p using (id_producto) join categoria c using (id_categoria) where c.nombre = 'Charm Bar'"))[0].n, 8);
igual('y hay 8 charms de ejemplo, sin stock', (await q("select count(*)::int n, coalesce(sum(v.stock),0)::int s from variante_producto v join producto p using (id_producto) join categoria c using (id_categoria) where c.nombre = 'Charms'"))[0], { n: 8, s: 0 });
await como(ADMIN);
await db.query("insert into coleccion (nombre, subtitulo, activa) values ('Feria', 'Piezas de la feria', true), ('Borrador', '', false)");
await como(null);
await db.exec('set role anon');
igual('una visitante ve solo las colecciones activas', (await q('select nombre from coleccion order by nombre')).map((c) => c.nombre), ['Feria']);
await falla('una visitante no puede crear colecciones', "insert into coleccion (nombre) values ('Mía')", [], '');
await db.exec('reset role');
await como(ADMIN);
await db.query("update producto set id_coleccion = (select id_coleccion from coleccion where nombre = 'Feria') where id_producto = 1");
await db.query("delete from coleccion where nombre = 'Feria'");
igual('al borrar una colección sus productos quedan sin colección', (await q('select id_coleccion from producto where id_producto = 1'))[0].id_coleccion, null);
await como(null);
await db.exec('set role anon');
await db.query("select public.suscribirse('  Laura@Correo.com ')");
await db.query("select public.suscribirse('laura@correo.com')");
await falla('un correo inválido no se guarda', "select public.suscribirse('no-es-correo')", [], 'correo válido');
igual('una visitante no ve la lista de suscripciones (la regla de seguridad la deja vacía)', (await q('select * from suscripcion')).length, 0);
await db.exec('reset role');
igual('el mismo correo no se repite y se guarda en minúsculas', (await q('select correo from suscripcion')).map((c) => c.correo), ['laura@correo.com']);
igual('hay lugares para las fotos del Charm Bar', (await q("select clave from ajuste_sitio where clave like '%charm_bar%' order by clave")).map((c) => c.clave), ['banner_charm_bar', 'charm_bar_portada']);

console.log(`\n${ok} bien, ${mal} mal`);
process.exit(mal ? 1 : 0);
