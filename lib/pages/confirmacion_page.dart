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
    required this.onVerPedido,
    required this.onLogo,
    required this.onCarrito,
    required this.onNav,
  });

  final String codigoPedido;
  final String numeroComprobante;
  final String referenciaPago;
  final String totalPagado;
  final int unidadesCarrito;
  final VoidCallback onSeguir;
  final VoidCallback onVerPedido;
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
          TinaBoton(
            etiqueta: 'Ver mi pedido',
            variante: VarianteBoton.secundario,
            onPressed: onVerPedido,
          ),
        ],
      ),
      cuerpo: TinaLista(
        anchoMaximo: 640,
        arriba: 28,
        children: [
          Center(
            child: Column(
              spacing: 6,
              children: [
                const EstrellaTina(tamano: 52, color: TinaColores.naranja),
                const SizedBox(height: 6),
                Text(
                  '¡Pedido',
                  style: TinaTipografia.estilo(
                    tamano: 40,
                    peso: FontWeight.w800,
                    espaciado: -1.2,
                    altura: 0.95,
                  ),
                ),
                Text(
                  'confirmado!',
                  style: TinaTipografia.serif(
                    tamano: 44,
                    color: TinaColores.rojo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gracias por regalarte algo hecho a mano.',
                  textAlign: TextAlign.center,
                  style: TinaTipografia.estilo(
                    tamano: 15,
                    color: TinaColores.marron,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TinaFilaResumen(etiqueta: 'Número de pedido', valor: codigoPedido),
          TinaFilaResumen(
            etiqueta: 'Número de comprobante',
            detalle: 'Wompi · $referenciaPago',
            valor: numeroComprobante,
          ),
          TinaFilaResumen(
            etiqueta: 'Total pagado',
            valor: totalPagado,
            tipo: TipoFila.total,
          ),
          const SizedBox(height: 16),
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
