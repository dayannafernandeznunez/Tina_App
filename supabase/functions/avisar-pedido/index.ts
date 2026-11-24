// Función del servidor: avisa a la vendedora que entró un pedido, por correo
// y/o por WhatsApp (los que tengan sus secretos puestos).
//
// La llaman dos cosas:
//   - La tienda, apenas se crea una contraentrega: manda el número del pedido y
//     su llave (el token), así solo se puede avisar de un pedido propio.
//   - La función `wompi-eventos`, cuando Wompi confirma un pago: se identifica
//     con la llave de servicio de Supabase y manda solo el número del pedido.
// La base de datos decide si toca avisar (pagado, no cancelado, no avisado
// antes), así que repetir la llamada no manda dos mensajes.
//
// CORREO, con Resend (https://resend.com). Plan gratis: 100 correos al día. Sin
// verificar un dominio, solo puede escribirle al correo con el que te registraste
// en Resend, que es justo lo que se necesita aquí.
//   RESEND_API_KEY       la clave de Resend (empieza por re_)
//   VENDEDORA_CORREO     tu correo; tiene que ser el mismo de tu cuenta de Resend
//   CORREO_REMITENTE     (opcional) quién aparece como remitente. Por defecto:
//                        Tina <onboarding@resend.dev>
//
// WHATSAPP, con CallMeBot (https://www.callmebot.com), un servicio gratis que
// escribe a tu propio WhatsApp. Se activa una sola vez: guarda el contacto
// +34 644 44 21 48, escríbele "I allow callmebot to send me messages" y te
// responde con tu clave.
//   VENDEDORA_TELEFONO   tu número de WhatsApp con el código del país: +573001234567
//   CALLMEBOT_APIKEY     la clave que te respondió CallMeBot
//
// Se puede usar uno, otro o los dos. Supabase agrega solos SUPABASE_URL y
// SUPABASE_SERVICE_ROLE_KEY.
//
// Si faltan los secretos, la tienda sigue funcionando: simplemente no se avisa.

declare const Deno: any;

export type Dependencias = {
  rpc: (
    nombre: string,
    args: Record<string, unknown>,
  ) => Promise<{ datos: any; error: { message: string; code?: string } | null }>;
  /**
   * Manda el aviso a la vendedora por todos los canales configurados (correo,
   * WhatsApp). Lanza un error solo si NINGUNO lo pudo mandar.
   */
  enviar: (texto: string, asunto: string) => Promise<void>;
  /** Hay al menos un canal con sus secretos (correo o WhatsApp). */
  configurado: boolean;
  llaveServicio: string;
};

export type Respuesta = { estado: number; cuerpo: Record<string, unknown> };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function iguales(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diferencia = 0;
  for (let i = 0; i < a.length; i++) {
    diferencia |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diferencia === 0;
}

/** 55000 -> $55.000 */
export function pesos(valor: number): string {
  return '$' + Math.round(valor).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}

/**
 * El número para el enlace de WhatsApp (wa.me): solo dígitos y con el código de
 * Colombia si el número viene de 10 dígitos (3001234567). Vacío si no hay un
 * número que sirva.
 */
export function telefonoParaWhatsApp(telefono: string): string {
  const digitos = String(telefono ?? '').replace(/\D/g, '');
  if (digitos.length === 10 && digitos.startsWith('3')) return '57' + digitos;
  if (digitos.length >= 11 && digitos.length <= 15) return digitos;
  return '';
}

/** El título del correo: de un vistazo, qué pedido es, cuánto y de quién. */
export function armarAsunto(d: any): string {
  const como = d.metodo_pago === 'contraentrega' ? 'contraentrega' : 'pagado';
  return `Nuevo pedido ${d.codigo} (${como}) · ${pesos(d.total)} · ${d.cliente}`;
}

/** El mismo mensaje sin los asteriscos del formato de WhatsApp. */
export function paraCorreo(texto: string): string {
  return texto.replace(/\*/g, '');
}

const MAXIMO_LINEAS = 10;

/** El texto del aviso, con lo que la vendedora necesita para actuar. */
export function armarMensaje(d: any): string {
  const contraentrega = d.metodo_pago === 'contraentrega';
  const lineas: any[] = Array.isArray(d.lineas) ? d.lineas : [];
  const articulos = lineas.slice(0, MAXIMO_LINEAS).map((l) => {
    const talla = l.talla && l.talla !== 'Única' ? ` (talla ${l.talla})` : '';
    return `• ${l.cantidad} × ${l.nombre} · ${l.color}${talla}`;
  });
  if (lineas.length > MAXIMO_LINEAS) {
    articulos.push(`• y ${lineas.length - MAXIMO_LINEAS} más`);
  }

  const partes: string[] = [];
  partes.push(`🛍️ *Nuevo pedido ${d.codigo}*`);
  partes.push(
    contraentrega
      ? '💬 Contraentrega en Cali: está pendiente de pago por transferencia.'
      : '✅ Pagado con Wompi.',
  );
  partes.push('');
  partes.push(`*Clienta:* ${d.cliente}`);
  if (d.telefono) partes.push(`*Teléfono:* ${d.telefono}`);
  if (d.correo) partes.push(`*Correo:* ${d.correo}`);
  const tel = telefonoParaWhatsApp(d.telefono);
  if (tel) partes.push(`*Escríbele:* https://wa.me/${tel}`);
  partes.push('');
  partes.push('*Artículos*');
  partes.push(...articulos);
  partes.push('');

  let total = `*Total:* ${pesos(d.total)}`;
  const detalle: string[] = [];
  if (d.descuento > 0) detalle.push(`descuento ${pesos(d.descuento)}`);
  detalle.push(d.costo_envio > 0 ? `envío ${pesos(d.costo_envio)}` : 'sin envío');
  total += ` (${detalle.join(', ')})`;
  partes.push(total);

  partes.push('');
  partes.push('*Enviar a*');
  partes.push(`${d.destinatario}`);
  partes.push(`${d.direccion}, ${d.ciudad}, ${d.departamento}`);
  if (contraentrega) {
    partes.push('');
    partes.push('Coordina la entrega y la transferencia con la clienta.');
  }
  return partes.join('\n');
}

export async function avisarPedido(
  cuerpo: any,
  autorizacion: string | null,
  deps: Dependencias,
): Promise<Respuesta> {
  const idPedido = Number(cuerpo?.id_pedido);
  if (!Number.isInteger(idPedido) || idPedido < 1) {
    return { estado: 400, cuerpo: { error: 'Falta el número del pedido.' } };
  }

  // Quien llama es el servidor (con la llave de servicio) o la compradora (con
  // la llave de su pedido).
  const interno =
    deps.llaveServicio !== '' &&
    autorizacion !== null &&
    iguales(autorizacion, `Bearer ${deps.llaveServicio}`);
  const token = String(cuerpo?.token ?? '');
  if (!interno && !UUID.test(token)) {
    return { estado: 400, cuerpo: { error: 'Faltan los datos del pedido.' } };
  }

  if (!deps.configurado) {
    console.error(
      'Aviso de pedidos sin configurar: faltan RESEND_API_KEY y VENDEDORA_CORREO (correo), o VENDEDORA_TELEFONO y CALLMEBOT_APIKEY (WhatsApp).',
    );
    return { estado: 200, cuerpo: { enviado: false, motivo: 'no_configurado' } };
  }

  const { datos, error } = await deps.rpc('reclamar_aviso_pedido', {
    p_id: idPedido,
    p_token: interno ? null : token,
  });
  if (error) {
    return { estado: 400, cuerpo: { error: error.message } };
  }
  if (datos === null || datos === undefined) {
    // Ya se avisó, está cancelado o todavía no se paga: no toca mandar nada.
    return { estado: 200, cuerpo: { enviado: false, motivo: 'sin_aviso' } };
  }

  try {
    await deps.enviar(armarMensaje(datos), armarAsunto(datos));
  } catch (e) {
    console.error('No se pudo avisar del pedido', idPedido, e);
    // Se desmarca para poder intentarlo otra vez.
    await deps.rpc('liberar_aviso_pedido', { p_id: idPedido });
    return {
      estado: 502,
      cuerpo: { enviado: false, error: 'No se pudo mandar el aviso.' },
    };
  }
  return { estado: 200, cuerpo: { enviado: true } };
}

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function responder(r: Respuesta): Response {
  return new Response(JSON.stringify(r.cuerpo), {
    status: r.estado,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

// Solo corre dentro de Supabase (donde existe `Deno`), no en las pruebas.
if (typeof Deno !== 'undefined') {
  const urlSupabase = Deno.env.get('SUPABASE_URL')!;
  const llaveServicio = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const limpiar = (v: string | undefined) =>
    String(v ?? '').trim().replace(/^["']+|["']+$/g, '').trim();
  const telefono = limpiar(Deno.env.get('VENDEDORA_TELEFONO'));
  const apikey = limpiar(Deno.env.get('CALLMEBOT_APIKEY'));
  const correo = limpiar(Deno.env.get('VENDEDORA_CORREO'));
  const resendKey = limpiar(Deno.env.get('RESEND_API_KEY'));
  const remitente =
    limpiar(Deno.env.get('CORREO_REMITENTE')) || 'Tina <onboarding@resend.dev>';

  // Cada canal es una función que manda el aviso por su lado.
  const canales: { nombre: string; enviar: (t: string, a: string) => Promise<void> }[] = [];
  if (correo !== '' && resendKey !== '') {
    canales.push({
      nombre: 'correo',
      enviar: async (texto, asunto) => {
        const r = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${resendKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: remitente,
            to: [correo],
            subject: asunto,
            text: paraCorreo(texto),
          }),
        });
        if (!r.ok) {
          throw new Error(`Resend respondió ${r.status}: ${(await r.text()).slice(0, 200)}`);
        }
      },
    });
  }
  if (telefono !== '' && apikey !== '') {
    canales.push({
      nombre: 'whatsapp',
      enviar: async (texto) => {
        const url =
          'https://api.callmebot.com/whatsapp.php' +
          `?phone=${encodeURIComponent(telefono)}` +
          `&text=${encodeURIComponent(texto)}` +
          `&apikey=${encodeURIComponent(apikey)}`;
        const r = await fetch(url);
        const respuesta = await r.text();
        if (!r.ok) {
          throw new Error(`CallMeBot respondió ${r.status}: ${respuesta.slice(0, 200)}`);
        }
      },
    });
  }

  const deps: Dependencias = {
    llaveServicio,
    configurado: canales.length > 0,
    enviar: async (texto, asunto) => {
      const resultados = await Promise.allSettled(
        canales.map((c) => c.enviar(texto, asunto)),
      );
      resultados.forEach((r, i) => {
        if (r.status === 'rejected') {
          console.error(`El canal ${canales[i].nombre} falló:`, r.reason);
        }
      });
      // Basta con que uno haya llegado.
      if (!resultados.some((r) => r.status === 'fulfilled')) {
        throw new Error('Ningún canal pudo mandar el aviso.');
      }
    },
    rpc: async (nombre, args) => {
      const r = await fetch(`${urlSupabase}/rest/v1/rpc/${nombre}`, {
        method: 'POST',
        headers: {
          apikey: llaveServicio,
          Authorization: `Bearer ${llaveServicio}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(args),
      });
      const datos = await r.json().catch(() => null);
      if (!r.ok) {
        return {
          datos: null,
          error: { message: datos?.message ?? 'Error', code: datos?.code },
        };
      }
      return { datos, error: null };
    },
  };

  Deno.serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
    if (req.method !== 'POST') {
      return responder({ estado: 405, cuerpo: { error: 'Método no permitido.' } });
    }
    try {
      return responder(
        await avisarPedido(await req.json(), req.headers.get('authorization'), deps),
      );
    } catch (e) {
      console.error('Error al avisar del pedido:', e);
      return responder({
        estado: 500,
        cuerpo: { error: 'No pudimos mandar el aviso.' },
      });
    }
  });
}
