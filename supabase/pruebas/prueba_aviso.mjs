// Prueba del aviso por WhatsApp (función avisar-pedido) y de su conexión con el
// pago aprobado de Wompi, sin internet. Ver LEEME.md de esta carpeta.
//
//   node prueba_aviso.mjs
import {
  armarMensaje,
  avisarPedido,
  pesos,
  telefonoParaWhatsApp,
} from '../functions/avisar-pedido/index.ts';
import { checksumEvento, recibirEvento } from '../functions/wompi-eventos/index.ts';

let ok = 0;
let mal = 0;
const igual = (nombre, real, esperado) => {
  const bien = JSON.stringify(real) === JSON.stringify(esperado);
  bien ? ok++ : mal++;
  console.log(
    `${bien ? 'OK   ' : 'MAL  '} ${nombre}${bien ? '' : `  -> real=${JSON.stringify(real)} esperado=${JSON.stringify(esperado)}`}`,
  );
};

const TOKEN = '11111111-2222-3333-4444-555555555555';
const LLAVE_SERVICIO = 'llave-de-servicio-de-prueba';

const pedidoWompi = {
  id_pedido: 12,
  codigo: 'TINA-0012',
  metodo_pago: 'wompi',
  estado: 'pagado',
  subtotal: 40000,
  descuento: 4000,
  costo_envio: 5000,
  total: 41000,
  cliente: 'Laura Caicedo',
  correo: 'laura@correo.com',
  telefono: '300 123 4567',
  destinatario: 'Laura Caicedo',
  direccion: 'Calle 5 #38-20',
  ciudad: 'Bogotá',
  departamento: 'Cundinamarca',
  lineas: [
    { nombre: 'Aretes de porcelanicrón', color: 'Nude', talla: 'Única', cantidad: 2 },
    { nombre: 'Pulsera tejida', color: 'Blanco', talla: 'M', cantidad: 1 },
  ],
};
const pedidoContraentrega = {
  ...pedidoWompi,
  id_pedido: 13,
  codigo: 'TINA-0013',
  metodo_pago: 'contraentrega',
  estado: 'pendiente',
  descuento: 0,
  costo_envio: 0,
  total: 40000,
  ciudad: 'Cali',
  departamento: 'Valle del Cauca',
};

console.log('--- Cómo se escribe el mensaje');
igual('los pesos llevan punto de miles', [pesos(5000), pesos(41000), pesos(1250000)], ['$5.000', '$41.000', '$1.250.000']);
igual('un celular de 10 dígitos recibe el código de Colombia', telefonoParaWhatsApp('300 123 4567'), '573001234567');
igual('uno con código ya puesto se deja', telefonoParaWhatsApp('+57 300 123 4567'), '573001234567');
igual('un número que no sirve queda vacío', [telefonoParaWhatsApp('123'), telefonoParaWhatsApp(''), telefonoParaWhatsApp(null)], ['', '', '']);

const m = armarMensaje(pedidoWompi);
igual('lleva el código del pedido', m.includes('TINA-0012'), true);
igual('dice que ya está pagado con Wompi', m.includes('Pagado con Wompi'), true);
igual('lleva el nombre y el enlace para escribirle', [m.includes('Laura Caicedo'), m.includes('https://wa.me/573001234567')], [true, true]);
igual('lleva el teléfono y el correo para contactarla', [m.includes('*Teléfono:* 300 123 4567'), m.includes('*Correo:* laura@correo.com')], [true, true]);
igual('lista los artículos con cantidad, color y talla', [m.includes('• 2 × Aretes de porcelanicrón · Nude'), m.includes('• 1 × Pulsera tejida · Blanco (talla M)')], [true, true]);
igual('muestra el total con descuento y envío', m.includes('*Total:* $41.000 (descuento $4.000, envío $5.000)'), true);
igual('lleva a dónde enviar', m.includes('Calle 5 #38-20, Bogotá, Cundinamarca'), true);
igual('un pedido pagado no pide coordinar la transferencia', m.includes('transferencia'), false);

const mc = armarMensaje(pedidoContraentrega);
igual('la contraentrega avisa que falta la transferencia', [mc.includes('Contraentrega en Cali'), mc.includes('transferencia')], [true, true]);
igual('y no cobra envío', mc.includes('*Total:* $40.000 (sin envío)'), true);
igual('y pide coordinar la entrega', mc.includes('Coordina la entrega'), true);

const muchas = armarMensaje({
  ...pedidoWompi,
  lineas: Array.from({ length: 13 }, (_, i) => ({ nombre: `Pieza ${i + 1}`, color: 'Rojo', talla: 'Única', cantidad: 1 })),
});
igual('con muchos artículos resume los últimos', [muchas.includes('Pieza 10'), muchas.includes('Pieza 11'), muchas.includes('y 3 más')], [true, false, true]);

console.log('\n--- Avisar de un pedido');
const llamadas = [];
const enviados = [];
const deps = (extra = {}) => {
  llamadas.length = 0;
  enviados.length = 0;
  return {
    llaveServicio: LLAVE_SERVICIO,
    configurado: true,
    enviar: async (texto) => { enviados.push(texto); },
    rpc: async (nombre, args) => {
      llamadas.push([nombre, args]);
      return nombre === 'reclamar_aviso_pedido' ? { datos: pedidoContraentrega, error: null } : { datos: null, error: null };
    },
    ...extra,
  };
};

let r = await avisarPedido({ id_pedido: 13, token: TOKEN }, null, deps());
igual('con la llave del pedido manda el aviso', [r.estado, r.cuerpo.enviado, enviados.length], [200, true, 1]);
igual('pide a la base de datos con la llave de ese pedido', llamadas[0], ['reclamar_aviso_pedido', { p_id: 13, p_token: TOKEN }]);
igual('el mensaje enviado es el del pedido', enviados[0].includes('TINA-0013'), true);

r = await avisarPedido({ id_pedido: 12 }, `Bearer ${LLAVE_SERVICIO}`, deps());
igual('el servidor, con su llave, avisa sin llave de pedido', [r.estado, r.cuerpo.enviado], [200, true]);
igual('y le pide a la base de datos sin llave', llamadas[0], ['reclamar_aviso_pedido', { p_id: 12, p_token: null }]);

r = await avisarPedido({ id_pedido: 13 }, null, deps());
igual('sin llave de pedido ni de servidor se rechaza', [r.estado, llamadas.length, enviados.length], [400, 0, 0]);
r = await avisarPedido({ id_pedido: 13 }, 'Bearer otra-llave', deps());
igual('una llave de servicio falsa tampoco sirve', [r.estado, llamadas.length, enviados.length], [400, 0, 0]);
r = await avisarPedido({ id_pedido: 13, token: 'no-es-uuid' }, null, deps());
igual('una llave que no es válida se rechaza', [r.estado, llamadas.length], [400, 0]);
r = await avisarPedido({ id_pedido: 'x', token: TOKEN }, null, deps());
igual('sin número de pedido se rechaza', [r.estado, llamadas.length], [400, 0]);

r = await avisarPedido({ id_pedido: 13, token: TOKEN }, null, deps({
  rpc: async (n) => { llamadas.push([n]); return { datos: null, error: null }; },
}));
igual('si la base de datos dice que no toca (ya avisado, sin pagar...) no manda nada', [r.estado, r.cuerpo.enviado, r.cuerpo.motivo, enviados.length], [200, false, 'sin_aviso', 0]);

r = await avisarPedido({ id_pedido: 13, token: TOKEN }, null, deps({
  rpc: async () => ({ datos: null, error: { message: 'No encontramos ese pedido.' } }),
}));
igual('con la llave de otro pedido responde el error de la base de datos', [r.estado, r.cuerpo.error], [400, 'No encontramos ese pedido.']);

r = await avisarPedido({ id_pedido: 13, token: TOKEN }, null, deps({ configurado: false }));
igual('sin secretos de WhatsApp no falla: solo no avisa', [r.estado, r.cuerpo.enviado, r.cuerpo.motivo, llamadas.length], [200, false, 'no_configurado', 0]);

r = await avisarPedido({ id_pedido: 13, token: TOKEN }, null, deps({
  enviar: async () => { throw new Error('CallMeBot respondió 500'); },
}));
igual('si el envío falla responde 502', [r.estado, r.cuerpo.enviado], [502, false]);
igual('y deja el pedido libre para intentarlo otra vez', llamadas.at(-1), ['liberar_aviso_pedido', { p_id: 13 }]);

console.log('\n--- Wompi aprueba un pago');
const SECRETO = 'test_events_secreto';
const firmado = async (estado) => {
  const e = {
    event: 'transaction.updated',
    data: { transaction: { id: 'tx-1', status: estado, amount_in_cents: 4100000, reference: 'TINA-0012-1' } },
    signature: { properties: ['transaction.id', 'transaction.status', 'transaction.amount_in_cents'] },
    timestamp: 1700000000,
  };
  return { ...e, signature: { ...e.signature, checksum: await checksumEvento(e, SECRETO) } };
};
const avisados = [];
const depsEvento = (resultado, extra = {}) => ({
  secretoEventos: SECRETO,
  rpc: async () => ({ datos: { resultado, id_pedido: 12 }, error: null }),
  avisar: async (id) => { avisados.push(id); },
  ...extra,
});

avisados.length = 0;
r = await recibirEvento(await firmado('APPROVED'), depsEvento('aprobado'));
igual('un pago aprobado avisa de ese pedido', [r.estado, avisados], [200, [12]]);

avisados.length = 0;
r = await recibirEvento(await firmado('DECLINED'), depsEvento('rechazado'));
igual('un pago rechazado no avisa', [r.estado, avisados], [200, []]);

avisados.length = 0;
r = await recibirEvento(await firmado('APPROVED'), depsEvento('pago_en_pedido_cancelado'));
igual('un pago que llega a un pedido cancelado no avisa', [r.estado, avisados], [200, []]);

r = await recibirEvento(await firmado('APPROVED'), depsEvento('aprobado', { avisar: async () => { throw new Error('sin internet'); } }));
igual('si el aviso falla, el pago igual se responde 200', [r.estado, r.cuerpo.resultado], [200, 'aprobado']);

r = await recibirEvento(await firmado('APPROVED'), depsEvento('aprobado', { avisar: undefined }));
igual('sin la función de aviso conectada, sigue funcionando', r.estado, 200);

console.log(`\n${ok} bien, ${mal} mal`);
process.exit(mal ? 1 : 0);
