import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';

/// Pantalla final de la compra: número de pedido, comprobante y estado.
class ConfirmacionPage extends StatelessWidget {
  const ConfirmacionPage({
    super.key,
    required this.codigoPedido,
    required this.numeroComprobante,
    required this.referenciaPago,
    required this.totalPagado,
    required this.unidadesCarrito,
    required this.onSeguir,
    required this.onLogo,
    required this.onCarrito,
    required this.onNav,
    this.onVerPedido,
    this.contraentrega = false,
  });

  /// El pedido es contraentrega: se coordina por WhatsApp y se paga por
  /// transferencia, así que no hay pago en línea ni comprobante todavía.
  final bool contraentrega;

  final String codigoPedido;
  final String numeroComprobante;
  final String referenciaPago;
  final String totalPagado;
  final int unidadesCarrito;
  final VoidCallback onSeguir;

  /// Sin sesión no hay dónde ver el pedido; entonces el botón no se muestra.
  final VoidCallback? onVerPedido;
  final VoidCallback onLogo;
  final VoidCallback onCarrito;
  final ValueChanged<DestinoNav> onNav;

  @override
  Widget build(BuildContext context) {
    return TinaScaffold(
      unidadesCarrito: unidadesCarrito,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      accion: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          TinaBoton(etiqueta: 'Seguir comprando', onPressed: onSeguir),
          if (onVerPedido != null)
            TinaBoton(
              etiqueta: 'Ver mi pedido',
              variante: VarianteBoton.secundario,
              onPressed: onVerPedido!,
            ),
        ],
      ),
      cuerpo: TinaLista(
        anchoMaximo: 640,
        arriba: 28,
        children: [
          TinaEncabezadoMarca(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Pedido',
                  style: TinaTipografia.estilo(
                    tamano: 44,
                    peso: FontWeight.w800,
                    color: TinaColores.blanco,
                    espaciado: -1.8,
                    altura: 0.95,
                  ),
                ),
                Text(
                  contraentrega ? 'recibido!' : 'confirmado!',
                  style: TinaTipografia.serif(
                    tamano: 50,
                    color: TinaColores.blanco,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gracias por regalarte algo hecho a mano.',
                  style: TinaTipografia.estilo(
                    tamano: 15,
                    color: TinaColores.blanco,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TinaFilaResumen(etiqueta: 'Número de pedido', valor: codigoPedido),
          if (contraentrega)
            const TinaFilaResumen(
              etiqueta: 'Forma de pago',
              detalle: 'Contraentrega en Cali',
              valor: 'Transferencia',
            )
          else
            TinaFilaResumen(
              etiqueta: 'Número de comprobante',
              detalle: 'Wompi · $referenciaPago',
              valor: numeroComprobante,
            ),
          TinaFilaResumen(
            etiqueta: contraentrega ? 'Total a pagar' : 'Total pagado',
            valor: totalPagado,
            tipo: TipoFila.total,
          ),
          const SizedBox(height: 16),
          if (contraentrega)
            const TinaEstadoPedido(
              estado: EstadoPedido.pendiente,
              modo: ModoEstado.mensaje,
              mensaje:
                  'Te escribiremos por WhatsApp para coordinar la entrega. '
                  'El pago es por transferencia y no se cobra envío.',
            )
          else
            const TinaEstadoPedido(
              estado: EstadoPedido.pagado,
              modo: ModoEstado.mensaje,
            ),
          const SizedBox(height: 14),
          Row(
            spacing: 10,
            children: [
              const _Icono(Icons.mail_outline_rounded),
              const _Icono(Icons.chat_bubble_outline_rounded),
              Expanded(
                child: Text(
                  'Te llegará un correo y un WhatsApp con los detalles de tu pedido.',
                  style: TinaTipografia.estilo(
                    tamano: 13,
                    color: TinaColores.marron,
                    altura: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Icono extends StatelessWidget {
  const _Icono(this.icono);

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: TinaColores.naranja,
        shape: BoxShape.circle,
      ),
      child: Icon(icono, size: 18, color: TinaColores.blanco),
    );
  }
}
