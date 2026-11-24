// Función del servidor: recibe los avisos de Wompi ("el pago se aprobó").
//
// Wompi hace un POST a esta función cada vez que cambia el estado de una
// transacción. Aquí se comprueba que el aviso es de verdad de Wompi (con el
// secreto de eventos) y se le pasa a la base de datos, que verifica el monto y
// marca el pedido como pagado, crea el comprobante o lo cancela si se anuló.
//
// Importante: esta función se despliega SIN verificación de JWT, porque Wompi no
// manda una llave de Supabase. Lo que la protege es la firma de cada aviso.
//
// Secreto necesario (Supabase > Edge Functions > Secrets):
//   WOMPI_EVENTS_SECRET     test_events_... (pruebas) o prod_events_... (producción)
// Supabase agrega solos SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY.
//
// La dirección de esta función va en Wompi > Desarrolladores > "URL de Eventos".

declare const Deno: any;

export type Dependencias = {
  rpc: (
    nombre: string,
    args: Record<string, unknown>,
  ) => Promise<{ datos: any; error: { message: string; code?: string } | null }>;
  secretoEventos: string;
  /**
   * Avisa por WhatsApp a la vendedora de un pedido que se acaba de pagar. Es un
   * extra: si falla, el pago igual queda registrado.
   */
  avisar?: (idPedido: number) => Promise<void>;
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

/** Entra por la ruta "transaction.id" dentro de `data`. */
function valorEnRuta(objeto: any, ruta: string): unknown {
  return ruta.split('.').reduce((o, clave) => o?.[clave], objeto);
}

/**
 * El checksum de un aviso: los valores de las propiedades que el propio aviso
 * lista en `signature.properties`, luego el `timestamp`, luego el secreto de
 * eventos, todo en SHA-256.
 */
export async function checksumEvento(
  evento: any,
  secreto: string,
): Promise<string> {
  const propiedades: string[] = evento?.signature?.properties ?? [];
  const valores = propiedades.map((p) =>
    String(valorEnRuta(evento?.data, p) ?? ''),
  );
  return sha256Hex(`${valores.join('')}${evento?.timestamp ?? ''}${secreto}`);
}

/** Quita espacios, saltos de línea y comillas que se cuelan al pegar un secreto. */
export function limpiarSecreto(valor: string): string {
  return String(valor ?? '').trim().replace(/^["']+|["']+$/g, '').trim();
}

/**
 * Qué anotar en los Logs cuando un aviso llega con la firma mala. No incluye
 * nada secreto: del secreto solo su tipo (test_events, prod_events o "otro") y
 * su largo. Sirve para ver si se guardó el secreto equivocado.
 */
export function diagnosticoFirma(evento: any, secreto: string): Record<string, unknown> {
  const tipo = /^(test|prod)_events_/.exec(secreto);
  return {
    tipo_de_secreto: tipo ? `${tipo[1]}_events` : 'no empieza por test_events_ ni prod_events_',
    largo_del_secreto: secreto.length,
    ambiente_del_aviso: evento?.environment ?? null,
    tiene_firma: typeof evento?.signature?.checksum === 'string',
  };
}

function iguales(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diferencia = 0;
  for (let i = 0; i < a.length; i++) {
    diferencia |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diferencia === 0;
}

/** ¿El aviso viene de Wompi? Sin firma, o con una firma distinta, no. */
export async function eventoValido(
  evento: any,
  secreto: string,
): Promise<boolean> {
  const esperado = evento?.signature?.checksum;
  const propiedades = evento?.signature?.properties;
  if (
    typeof esperado !== 'string' ||
    !Array.isArray(propiedades) ||
    propiedades.length === 0 ||
    evento?.timestamp === undefined ||
    !secreto
  ) {
    return false;
  }
  const calculado = await checksumEvento(evento, secreto);
  return iguales(calculado.toLowerCase(), esperado.toLowerCase());
}

export async function recibirEvento(
  evento: any,
  deps: Dependencias,
): Promise<Respuesta> {
  if (!(await eventoValido(evento, deps.secretoEventos))) {
    console.error(
      'Aviso de Wompi con la firma no válida:',
      JSON.stringify(diagnosticoFirma(evento, deps.secretoEventos)),
    );
    return { estado: 401, cuerpo: { error: 'Firma no válida.' } };
  }
  if (evento.event !== 'transaction.updated') {
    return { estado: 200, cuerpo: { ok: true, ignorado: evento.event ?? null } };
  }

  const t = evento.data?.transaction;
  if (!t?.reference || !t?.status || typeof t?.amount_in_cents !== 'number') {
    return { estado: 200, cuerpo: { ok: false, motivo: 'Aviso incompleto.' } };
  }

  const { datos, error } = await deps.rpc('registrar_resultado_pago', {
    p_referencia: t.reference,
    p_estado: t.status,
    p_monto_centavos: t.amount_in_cents,
    p_id_transaccion: t.id ?? null,
  });

  if (error) {
    // Los errores de la base de datos con mensaje propio (monto que no coincide,
    // referencia de otra tienda) no se arreglan reintentando: se registran y se
    // responde 200. Cualquier otro error sí merece que Wompi reintente.
    if (error.code === 'P0001') {
      console.error('Aviso de Wompi rechazado:', error.message, t.reference);
      return { estado: 200, cuerpo: { ok: false, motivo: error.message } };
    }
    console.error('Error al aplicar el aviso de Wompi:', error);
    return { estado: 500, cuerpo: { error: 'Error temporal, reintenta.' } };
  }

  // Pago aprobado: se le avisa a la vendedora. Aunque el aviso falle, se
  // responde 200 para que Wompi no vuelva a mandar el mismo pago.
  if (datos?.resultado === 'aprobado' && deps.avisar) {
    try {
      await deps.avisar(Number(datos.id_pedido));
    } catch (e) {
      console.error('No se pudo avisar del pedido pagado', datos.id_pedido, e);
    }
  }
  return { estado: 200, cuerpo: { ok: true, resultado: datos?.resultado } };
}

// Solo corre dentro de Supabase (donde existe `Deno`), no en las pruebas.
if (typeof Deno !== 'undefined') {
  const urlSupabase = Deno.env.get('SUPABASE_URL')!;
  const llaveServicio = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const deps: Dependencias = {
    secretoEventos: limpiarSecreto(Deno.env.get('WOMPI_EVENTS_SECRET') ?? ''),
    // Llama a la función avisar-pedido identificándose con la llave de servicio.
    avisar: async (idPedido) => {
      const r = await fetch(`${urlSupabase}/functions/v1/avisar-pedido`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${llaveServicio}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ id_pedido: idPedido }),
      });
      if (!r.ok) throw new Error(`avisar-pedido respondió ${r.status}`);
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
    if (req.method !== 'POST') {
      return new Response('Método no permitido', { status: 405 });
    }
    try {
      const r = await recibirEvento(await req.json(), deps);
      return new Response(JSON.stringify(r.cuerpo), {
        status: r.estado,
        headers: { 'Content-Type': 'application/json' },
      });
    } catch (e) {
      console.error('Error al recibir un aviso de Wompi:', e);
      return new Response('Error', { status: 500 });
    }
  });
}
