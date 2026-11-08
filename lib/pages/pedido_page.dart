import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/vistas.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

/// Detalle de un pedido: estado, productos, totales, pago, envío e historial.
class PedidoPage extends StatelessWidget {
  const PedidoPage({super.key, required this.pedido, required this.onAtras});

  final PedidoCompleto pedido;
  final VoidCallback onAtras;

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 4),
    child: Text(
      texto,
      style: TinaTipografia.estilo(
        tamano: 20,
        peso: FontWeight.w800,
        espaciado: -0.4,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = pedido.pedido;
    final envio = pedido.envio;
    return TinaScaffold(
      titulo: p.codigo,
      conAtras: true,
      conCarrito: false,
      onAtras: onAtras,
      cuerpo: TinaLista(
        anchoMaximo: 760,
        children: [
          TinaEstadoPedido(estado: p.estadoActual, modo: ModoEstado.mensaje),
          _titulo('Pedido'),
          TinaFilaResumen(etiqueta: 'Fecha', valor: formatoFecha(p.fecha)),
          TinaFilaResumen(etiqueta: 'Clienta', valor: pedido.cliente.nombre),
          _titulo('Productos'),
          for (final l in pedido.lineas)
            TinaFilaResumen(
              etiqueta: '${l.nombre} ×${l.cantidad}',
              detalle: '${l.variante} · ${formatoPesos(l.precioUnitario)} c/u',
              valor: formatoPesos(l.subtotal),
            ),
          TinaFilaResumen(
            etiqueta: 'Subtotal',
            valor: formatoPesos(p.subtotal),
          ),
          if (p.descuento > 0)
            TinaFilaResumen(
              etiqueta: 'Descuento',
              valor: '−${formatoPesos(p.descuento)}',
              tipo: TipoFila.descuento,
            ),
          TinaFilaResumen(
            etiqueta: 'Total',
            valor: formatoPesos(p.total),
            tipo: TipoFila.total,
          ),
          _titulo('Pago'),
          TinaFilaResumen(
            etiqueta: 'Referencia Wompi',
            valor: pedido.pago?.referenciaWompi ?? '—',
          ),
          TinaFilaResumen(
            etiqueta: 'Estado del pago',
            valor: pedido.pago?.estado ?? '—',
          ),
          TinaFilaResumen(
            etiqueta: 'Comprobante',
            valor: pedido.comprobante?.numero ?? 'Sin comprobante',
          ),
          _titulo('Envío'),
          TinaFilaResumen(
            etiqueta: envio.nombreDestinatario,
            detalle:
                '${envio.direccion}, ${envio.ciudad}, ${envio.departamento}',
            valor: formatoPesos(envio.costo),
          ),
          TinaFilaResumen(
            etiqueta: 'Guía',
            valor: envio.guia ?? 'Aún no asignada',
          ),
          _titulo('Historial'),
          for (final h in pedido.historial.reversed)
            TinaFilaResumen(
              etiqueta: EstadoPedido.desdeNombre(h.estadoNuevo).etiqueta,
              detalle:
                  '${h.estadoAnterior == null ? 'Pedido creado' : 'Antes: ${EstadoPedido.desdeNombre(h.estadoAnterior!).etiqueta}'}'
                  ' · ${h.quien} · ${h.notificado ? 'Clienta avisada' : 'Sin avisar'}',
              valor: formatoFecha(h.fecha),
            ),
        ],
      ),
    );
  }
}
