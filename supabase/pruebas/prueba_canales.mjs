// Prueba los canales de aviso (correo con Resend, WhatsApp con CallMeBot) de la
// función avisar-pedido tal como corren dentro de Supabase: simula `Deno` y la
// red, sin mandar nada de verdad. Ver LEEME.md de esta carpeta.
//
//   node prueba_canales.mjs
let ok = 0;
let mal = 0;
const igual = (nombre, real, esperado) => {
  const bien = JSON.stringify(real) === JSON.stringify(esperado);
  bien ? ok++ : mal++;
  console.log(
    `${bien ? 'OK   ' : 'MAL  '} ${nombre}${bien ? '' : `  -> real=${JSON.stringify(real)} esperado=${JSON.stringify(esperado)}`}`,
  );
};

const LLAVE = 'llave-de-servicio-de-prueba';
const TOKEN = '11111111-2222-3333-4444-555555555555';
const pedido = {
  id_pedido: 13, codigo: 'TINA-0013', metodo_pago: 'contraentrega', estado: 'pendiente',
  subtotal: 40000, descuento: 0, costo_envio: 0, total: 40000,
  cliente: 'Laura Caicedo', correo: 'laura@correo.com', telefono: '300 123 4567',
  destinatario: 'Laura', direccion: 'Calle 5 #38-20', ciudad: 'Cali', departamento: 'Valle del Cauca',
  lineas: [{ nombre: 'Aretes', color: 'Nude', talla: 'Única', cantidad: 1 }],
};

/**
 * Carga la función como si corriera en Supabase, con estos secretos, y devuelve
 * una función que le manda una petición y cuenta qué llamadas de red hizo.
 */
async function cargar(secretos, respuestas = {}) {
  const llamadas = [];
  const ruta = `../functions/avisar-pedido/index.ts?v=${Math.random()}`;
  let manejador;
  globalThis.Deno = {
    env: { get: (k) => ({ SUPABASE_URL: 'https://x.supabase.co', SUPABASE_SERVICE_ROLE_KEY: LLAVE, ...secretos })[k] },
    serve: (f) => { manejador = f; },
  };
  globalThis.fetch = async (url, opciones = {}) => {
    const u = String(url);
    llamadas.push({ url: u, opciones });
    if (u.includes('/rest/v1/rpc/reclamar_aviso_pedido')) {
      return new Response(JSON.stringify(pedido), { status: 200 });
    }
    if (u.includes('/rest/v1/rpc/liberar_aviso_pedido')) return new Response('null', { status: 200 });
    if (u.startsWith('https://api.resend.com')) return respuestas.resend ?? new Response('{"id":"abc"}', { status: 200 });
    if (u.startsWith('https://api.callmebot.com')) return respuestas.callmebot ?? new Response('ok', { status: 200 });
    return new Response('?', { status: 404 });
  };
  await import(ruta);
  const pedir = async () => {
    const r = await manejador(new Request('https://x.supabase.co/functions/v1/avisar-pedido', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id_pedido: 13, token: TOKEN }),
    }));
    return { estado: r.status, cuerpo: await r.json() };
  };
  const resend = () => llamadas.filter((l) => l.url.startsWith('https://api.resend.com'));
  const whatsapp = () => llamadas.filter((l) => l.url.startsWith('https://api.callmebot.com'));
  const liberadas = () => llamadas.filter((l) => l.url.includes('liberar_aviso_pedido'));
  return { pedir, resend, whatsapp, liberadas };
}

const SOLO_CORREO = { RESEND_API_KEY: 're_clave_de_prueba', VENDEDORA_CORREO: ' "tina@correo.com" ' };
const SOLO_WHATSAPP = { VENDEDORA_TELEFONO: '+573001234567', CALLMEBOT_APIKEY: '123456' };

console.log('--- Solo correo');
{
  const f = await cargar(SOLO_CORREO);
  const r = await f.pedir();
  igual('manda el aviso y responde 200', [r.estado, r.cuerpo.enviado], [200, true]);
  igual('hace una sola llamada a Resend y ninguna a CallMeBot', [f.resend().length, f.whatsapp().length], [1, 0]);
  const c = f.resend()[0];
  const cuerpo = JSON.parse(c.opciones.body);
  igual('usa la clave de Resend como Bearer', c.opciones.headers.Authorization, 'Bearer re_clave_de_prueba');
  igual('escribe al correo de la vendedora (limpio, sin comillas ni espacios)', cuerpo.to, ['tina@correo.com']);
  igual('con el remitente de pruebas de Resend', cuerpo.from, 'Tina <onboarding@resend.dev>');
  igual('y el asunto del pedido', cuerpo.subject, 'Nuevo pedido TINA-0013 (contraentrega) · $40.000 · Laura Caicedo');
  igual('el texto trae el pedido, el contacto y no lleva asteriscos', [cuerpo.text.includes('TINA-0013'), cuerpo.text.includes('Correo: laura@correo.com'), cuerpo.text.includes('*')], [true, true, false]);
}

console.log('\n--- Remitente propio');
{
  const f = await cargar({ ...SOLO_CORREO, CORREO_REMITENTE: 'Tina <avisos@tina.co>' });
  await f.pedir();
  igual('se puede cambiar el remitente', JSON.parse(f.resend()[0].opciones.body).from, 'Tina <avisos@tina.co>');
}

console.log('\n--- Solo WhatsApp');
{
  const f = await cargar(SOLO_WHATSAPP);
  const r = await f.pedir();
  igual('manda el aviso por CallMeBot y no por Resend', [r.estado, r.cuerpo.enviado, f.whatsapp().length, f.resend().length], [200, true, 1, 0]);
  const u = new URL(f.whatsapp()[0].url);
  igual('al teléfono de la vendedora con su clave', [u.searchParams.get('phone'), u.searchParams.get('apikey')], ['+573001234567', '123456']);
  igual('y el texto con el formato de WhatsApp', u.searchParams.get('text').includes('*Nuevo pedido TINA-0013*'), true);
}

console.log('\n--- Los dos canales');
{
  const f = await cargar({ ...SOLO_CORREO, ...SOLO_WHATSAPP });
  const r = await f.pedir();
  igual('manda por correo y por WhatsApp', [r.estado, f.resend().length, f.whatsapp().length], [200, 1, 1]);
}
{
  const f = await cargar({ ...SOLO_CORREO, ...SOLO_WHATSAPP }, { resend: new Response('{"message":"x"}', { status: 403 }) });
  const r = await f.pedir();
  igual('si falla el correo pero llega el WhatsApp, el aviso cuenta como enviado', [r.estado, r.cuerpo.enviado, f.liberadas().length], [200, true, 0]);
}
{
  const f = await cargar({ ...SOLO_CORREO, ...SOLO_WHATSAPP }, { callmebot: new Response('error', { status: 500 }) });
  const r = await f.pedir();
  igual('si falla el WhatsApp pero llega el correo, también', [r.estado, r.cuerpo.enviado, f.liberadas().length], [200, true, 0]);
}
{
  const f = await cargar({ ...SOLO_CORREO, ...SOLO_WHATSAPP }, {
    resend: new Response('{"message":"x"}', { status: 403 }),
    callmebot: new Response('error', { status: 500 }),
  });
  const r = await f.pedir();
  igual('si fallan los dos responde 502 y libera el pedido para reintentar', [r.estado, r.cuerpo.enviado, f.liberadas().length], [502, false, 1]);
}

console.log('\n--- Sin canales');
{
  const f = await cargar({});
  const r = await f.pedir();
  igual('sin secretos no falla ni llama a nadie', [r.estado, r.cuerpo.motivo, f.resend().length + f.whatsapp().length], [200, 'no_configurado', 0]);
}
{
  const f = await cargar({ RESEND_API_KEY: 're_x' });
  const r = await f.pedir();
  igual('con la clave de Resend pero sin correo de destino, no avisa', [r.cuerpo.motivo, f.resend().length], ['no_configurado', 0]);
}

console.log(`\n${ok} bien, ${mal} mal`);
process.exit(mal ? 1 : 0);
