// Función del servidor: prepara el pago de un pedido con Wompi.
//
// La app le dice "quiero pagar el pedido 12" (con el token de ese pedido) y esta
// función responde con la dirección de la página de pago de Wompi, ya firmada.
// La firma de integridad usa un secreto que nunca sale del servidor, y el monto
// se toma del pedido en la base de datos, no de lo que mande el navegador.
//
// Secretos necesarios (Supabase > Edge Functions > Secrets):
//   WOMPI_PUBLIC_KEY        pub_test_... (pruebas) o pub_prod_... (producción)
//   WOMPI_INTEGRITY_SECRET  test_integrity_... o prod_integrity_...
//   SITIO_URL               la dirección de la tienda, sin "/" al final. Wompi
//                           devuelve a la clienta ahí después de pagar.
// Supabase agrega solos SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY.

declare const Deno: any;

export type Dependencias = {
  /** Llama a una función de la base de datos con la llave de servicio. */
  rpc: (
    nombre: string,
    args: Record<string, unknown>,
  ) => Promise<{ datos: any; error: { message: string; code?: string } | null }>;
  llavePublica: string;
  secretoIntegridad: string;
  sitioUrl: string;
};

export type Respuesta = { estado: number; cuerpo: Record<string, unknown> };

export async function sha256Hex(texto: string): Promise<string> {
  const hash = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(texto),
  );
  return [...new Uint8Array(hash)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/** Referencia + monto en centavos + moneda (+ vencimiento) + secreto, en SHA-256. */
export async function firmaIntegridad(datos: {
  referencia: string;
  montoEnCentavos: number;
  moneda: string;
  secreto: string;
  vencimiento?: string;
}): Promise<string> {
  return sha256Hex(
    `${datos.referencia}${datos.montoEnCentavos}${datos.moneda}` +
      `${datos.vencimiento ?? ''}${datos.secreto}`,
  );
}

/** La dirección de la página de pago de Wompi (Web Checkout). */
export function urlCheckout(datos: {
  llavePublica: string;
  referencia: string;
  montoEnCentavos: number;
  moneda: string;
  firma: string;
  redirigirA: string;
  correo?: string;
  nombre?: string;
  telefono?: string;
}): string {
  const p = new URLSearchParams();
  p.set('public-key', datos.llavePublica);
  p.set('currency', datos.moneda);
  p.set('amount-in-cents', String(datos.montoEnCentavos));
  p.set('reference', datos.referencia);
  p.set('signature:integrity', datos.firma);
  p.set('redirect-url', datos.redirigirA);
  if (datos.correo) p.set('customer-data:email', datos.correo);
  if (datos.nombre) p.set('customer-data:full-name', datos.nombre);
  if (datos.telefono) {
    p.set('customer-data:phone-number', datos.telefono.replace(/\D/g, ''));
    p.set('customer-data:phone-number-prefix', '+57');
  }
  return `https://checkout.wompi.co/p/?${p.toString()}`;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function iniciarPago(
  cuerpo: any,
  deps: Dependencias,
): Promise<Respuesta> {
  const idPedido = Number(cuerpo?.id_pedido);
  const token = String(cuerpo?.token ?? '');
  if (!Number.isInteger(idPedido) || idPedido < 1 || !UUID.test(token)) {
    return { estado: 400, cuerpo: { error: 'Faltan los datos del pedido.' } };
  }
  if (!deps.llavePublica || !deps.secretoIntegridad || !deps.sitioUrl) {
    console.error('Faltan secretos de Wompi o SITIO_URL en la función.');
    return {
      estado: 500,
      cuerpo: { error: 'El pago en línea todavía no está configurado.' },
    };
  }

  const { datos, error } = await deps.rpc('iniciar_pago', {
    p_id: idPedido,
    p_token: token,
  });
  if (error) {
    return { estado: 400, cuerpo: { error: error.message } };
  }

  const firma = await firmaIntegridad({
    referencia: datos.referencia,
    montoEnCentavos: datos.monto_en_centavos,
    moneda: datos.moneda,
    secreto: deps.secretoIntegridad,
  });
  const sitio = deps.sitioUrl.replace(/\/+$/, '');
  const url = urlCheckout({
    llavePublica: deps.llavePublica,
    referencia: datos.referencia,
    montoEnCentavos: datos.monto_en_centavos,
    moneda: datos.moneda,
    firma,
    // Wompi agrega "id" (el de la transacción) al volver.
    redirigirA: `${sitio}/?pedido=${idPedido}&t=${token}`,
    correo: datos.correo,
    nombre: datos.nombre,
    telefono: datos.telefono,
  });
  return { estado: 200, cuerpo: { url, referencia: datos.referencia } };
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
  const llaveServicio = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const deps: Dependencias = {
    llavePublica: Deno.env.get('WOMPI_PUBLIC_KEY') ?? '',
    secretoIntegridad: Deno.env.get('WOMPI_INTEGRITY_SECRET') ?? '',
    sitioUrl: Deno.env.get('SITIO_URL') ?? '',
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
      return responder(await iniciarPago(await req.json(), deps));
    } catch (e) {
      console.error('Error al iniciar el pago:', e);
      return responder({
        estado: 500,
        cuerpo: { error: 'No pudimos iniciar el pago. Inténtalo de nuevo.' },
      });
    }
  });
}
