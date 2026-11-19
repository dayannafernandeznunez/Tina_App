// Prueba de las funciones del servidor de Wompi con los ejemplos de la
// documentación oficial de Wompi, sin internet. Ver LEEME.md de esta carpeta.
//
//   node prueba_wompi.mjs
import { createHash } from 'node:crypto';
import {
  firmaIntegridad,
  iniciarPago,
  urlCheckout,
} from '../functions/iniciar-pago/index.ts';
import {
  checksumEvento,
  eventoValido,
  recibirEvento,
} from '../functions/wompi-eventos/index.ts';

let ok = 0;
let mal = 0;
const igual = (nombre, real, esperado) => {
  const bien = JSON.stringify(real) === JSON.stringify(esperado);
  bien ? ok++ : mal++;
  console.log(
    `${bien ? 'OK   ' : 'MAL  '} ${nombre}${bien ? '' : `  -> real=${JSON.stringify(real)} esperado=${JSON.stringify(esperado)}`}`,
  );
};

console.log('--- Firma de integridad (ejemplo de la documentación)');
const firma = await firmaIntegridad({
  referencia: 'sk8-438k4-xmxm392-sn2m',
  montoEnCentavos: 2490000,
  moneda: 'COP',
  secreto: 'prod_integrity_Z5mMke9x0k8gpErbDqwrJXMqsI6SFli6',
});
igual('coincide con el hash oficial', firma, '37c8407747e595535433ef8f6a811d853cd943046624a0ec04662b17bbf33bf5');
igual('cambia si cambia el monto', (await firmaIntegridad({
  referencia: 'sk8-438k4-xmxm392-sn2m', montoEnCentavos: 2490001, moneda: 'COP',
  secreto: 'prod_integrity_Z5mMke9x0k8gpErbDqwrJXMqsI6SFli6' })) === firma, false);

console.log('\n--- Checksum de un aviso (ejemplo de la documentación)');
const evento = {
  event: 'transaction.updated',
  data: { transaction: { id: '1234-1610641025-49201', status: 'APPROVED', amount_in_cents: 4490000, reference: 'TINA-0012-1' } },
  signature: {
    properties: ['transaction.id', 'transaction.status', 'transaction.amount_in_cents'],
    // La documentación de Wompi muestra 3476DDA5..., pero ese número no sale de
    // su propio ejemplo (ver LEEME.md). Aquí se calcula aparte con la librería de
    // Node, siguiendo los pasos de la documentación: valores + timestamp + secreto.
    checksum: createHash('sha256').update('1234-1610641025-49201APPROVED44900001530291411prod_events_OcHnIzeBl5socpwByQ4hA52Em3USQ93Z').digest('hex').toUpperCase(),
  },
  timestamp: 1530291411,
};
const SECRETO = 'prod_events_OcHnIzeBl5socpwByQ4hA52Em3USQ93Z';
igual('el checksum coincide con el cálculo independiente de Node', (await checksumEvento(evento, SECRETO)).toUpperCase(), evento.signature.checksum);
igual('un aviso con su firma correcta es válido', await eventoValido(evento, SECRETO), true);
igual('con otro secreto no es válido', await eventoValido(evento, 'prod_events_otro'), false);
igual('si alguien cambia el estado, deja de ser válido', await eventoValido({ ...evento, data: { transaction: { ...evento.data.transaction, status: 'DECLINED' } } }, SECRETO), false);
igual('si cambia el monto, deja de ser válido', await eventoValido({ ...evento, data: { transaction: { ...evento.data.transaction, amount_in_cents: 100 } } }, SECRETO), false);
igual('un aviso sin firma no es válido', await eventoValido({ event: evento.event, data: evento.data }, SECRETO), false);

console.log('\n--- Dirección de la página de pago');
const u = new URL(urlCheckout({
  llavePublica: 'pub_test_abc', referencia: 'TINA-0012-1', montoEnCentavos: 2200000, moneda: 'COP',
  firma: 'f', redirigirA: 'https://tina.co/?pedido=12&t=x', correo: 'a@b.co', nombre: 'Laura Caicedo', telefono: '300 123 4567',
}));
igual('es el Web Checkout de Wompi', u.origin + u.pathname, 'https://checkout.wompi.co/p/');
igual('lleva la llave, la moneda, el monto y la referencia', [u.searchParams.get('public-key'), u.searchParams.get('currency'), u.searchParams.get('amount-in-cents'), u.searchParams.get('reference')], ['pub_test_abc', 'COP', '2200000', 'TINA-0012-1']);
igual('lleva la firma y a dónde volver', [u.searchParams.get('signature:integrity'), u.searchParams.get('redirect-url')], ['f', 'https://tina.co/?pedido=12&t=x']);
igual('lleva los datos de la clienta', [u.searchParams.get('customer-data:email'), u.searchParams.get('customer-data:full-name'), u.searchParams.get('customer-data:phone-number'), u.searchParams.get('customer-data:phone-number-prefix')], ['a@b.co', 'Laura Caicedo', '3001234567', '+57']);

console.log('\n--- Iniciar un pago');
const TOKEN = '11111111-2222-3333-4444-555555555555';
const llamadas = [];
const depsPago = (respuesta) => ({
  llavePublica: 'pub_test_abc',
  secretoIntegridad: 'test_integrity_secreto',
  sitioUrl: 'https://tina.co/',
  rpc: async (nombre, args) => { llamadas.push([nombre, args]); return respuesta; },
});
let r = await iniciarPago({ id_pedido: 12, token: TOKEN }, depsPago({
  datos: { referencia: 'TINA-0012-1', monto_en_centavos: 2200000, moneda: 'COP', correo: 'a@b.co', nombre: 'Laura', telefono: '3001112233' },
  error: null,
}));
igual('responde 200 con la dirección de pago', [r.estado, typeof r.cuerpo.url], [200, 'string']);
const url = new URL(r.cuerpo.url);
igual('el monto es el que dijo la base de datos', url.searchParams.get('amount-in-cents'), '2200000');
igual('la firma usa el secreto del servidor', url.searchParams.get('signature:integrity'),
  await firmaIntegridad({ referencia: 'TINA-0012-1', montoEnCentavos: 2200000, moneda: 'COP', secreto: 'test_integrity_secreto' }));
igual('Wompi devuelve a la clienta a su pedido, con el token', url.searchParams.get('redirect-url'), `https://tina.co/?pedido=12&t=${TOKEN}`);
igual('llamó a la función de la base de datos con el token', llamadas[0], ['iniciar_pago', { p_id: 12, p_token: TOKEN }]);

r = await iniciarPago({ id_pedido: 12, token: TOKEN }, depsPago({ datos: null, error: { message: 'Este pedido ya no está pendiente de pago.' } }));
igual('si la base de datos dice que no, responde 400 con su mensaje', [r.estado, r.cuerpo.error], [400, 'Este pedido ya no está pendiente de pago.']);
const antes = llamadas.length;
r = await iniciarPago({ id_pedido: 'x', token: 'no-es-uuid' }, depsPago({ datos: null, error: null }));
igual('datos inválidos: 400 y no toca la base de datos', [r.estado, llamadas.length], [400, antes]);
r = await iniciarPago({ id_pedido: 12, token: TOKEN }, { ...depsPago({}), secretoIntegridad: '' });
igual('sin secretos configurados avisa que no está listo', [r.estado, r.cuerpo.error], [500, 'El pago en línea todavía no está configurado.']);

console.log('\n--- Recibir un aviso de Wompi');
const avisos = [];
const depsEvento = (respuesta) => ({
  secretoEventos: SECRETO,
  rpc: async (nombre, args) => { avisos.push([nombre, args]); return respuesta; },
});
const aviso = (estado, monto = 4490000) => {
  const e = { event: 'transaction.updated', data: { transaction: { id: 'tx-9', status: estado, amount_in_cents: monto, reference: 'TINA-0012-2' } },
    signature: { properties: ['transaction.id', 'transaction.status', 'transaction.amount_in_cents'] }, timestamp: 1700000000 };
  return e;
};
const firmado = async (e) => ({ ...e, signature: { ...e.signature, checksum: await checksumEvento(e, SECRETO) } });

r = await recibirEvento(aviso('APPROVED'), depsEvento({ datos: {}, error: null }));
igual('un aviso sin firma se rechaza con 401', r.estado, 401);
igual('y no toca la base de datos', avisos.length, 0);

r = await recibirEvento(await firmado(aviso('APPROVED')), depsEvento({ datos: { resultado: 'aprobado' }, error: null }));
igual('un aviso firmado se aplica y responde 200', [r.estado, r.cuerpo.resultado], [200, 'aprobado']);
igual('pasa a la base de datos la referencia, el estado y el monto', avisos[0], ['registrar_resultado_pago', { p_referencia: 'TINA-0012-2', p_estado: 'APPROVED', p_monto_centavos: 4490000, p_id_transaccion: 'tx-9' }]);

r = await recibirEvento(await firmado(aviso('DECLINED')), depsEvento({ datos: { resultado: 'rechazado' }, error: null }));
igual('un pago rechazado también se aplica', [r.estado, avisos.at(-1)[1].p_estado], [200, 'DECLINED']);

r = await recibirEvento(await firmado(aviso('APPROVED', 100)), depsEvento({ datos: null, error: { message: 'El monto pagado (100) no coincide', code: 'P0001' } }));
igual('si el monto no coincide: responde 200 para que Wompi no insista', [r.estado, r.cuerpo.ok], [200, false]);

r = await recibirEvento(await firmado(aviso('APPROVED')), depsEvento({ datos: null, error: { message: 'connection reset', code: '08006' } }));
igual('si falla la conexión: responde 500 para que Wompi reintente', r.estado, 500);

const otro = await firmado({ ...aviso('APPROVED'), event: 'nequi_token.updated' });
const antesOtro = avisos.length;
r = await recibirEvento(otro, depsEvento({ datos: {}, error: null }));
igual('otros tipos de aviso se ignoran', [r.estado, avisos.length], [200, antesOtro]);

console.log(`\n${ok} bien, ${mal} mal`);
process.exit(mal ? 1 : 0);
