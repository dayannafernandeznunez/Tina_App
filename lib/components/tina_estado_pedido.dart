import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/tina_tema.dart';
import 'estrella_tina.dart';

enum ModoEstado { etiqueta, mensaje }

class _Paleta {
  const _Paleta(this.fondo, this.texto, this.punto, this.mensaje);

  final Color fondo;
  final Color texto;
  final Color punto;
  final String mensaje;
}

const Map<EstadoPedido, _Paleta> _paletas = {
  EstadoPedido.pendiente: _Paleta(
    Color(0xFFFFF3DC),
    Color(0xFF8A5A00),
    Color(0xFFF2A93B),
    'Estamos esperando la confirmación de tu pago en Wompi.',
  ),
  EstadoPedido.pagado: _Paleta(
    Color(0xFFFFE6D4),
    Color(0xFFB84A00),
    Color(0xFFFF6A00),
    'Recibimos tu pago. Ya empezamos a alistar tu pedido.',
  ),
  EstadoPedido.preparacion: _Paleta(
    Color(0xFFFDE3E8),
    Color(0xFFA3153A),
    Color(0xFFE8566C),
    'Tu pedido se está armando a mano.',
  ),
  EstadoPedido.enviado: _Paleta(
    Color(0xFFE3F2F0),
    Color(0xFF2E6E68),
    Color(0xFF4AA49C),
    'Tu pedido va en camino.',
  ),
  EstadoPedido.entregado: _Paleta(
    Color(0xFFE9F1DD),
    Color(0xFF3E6B1F),
    Color(0xFF7DA62A),
    'Tu pedido llegó. ¡Que lo disfrutes!',
  ),
  EstadoPedido.cancelado: _Paleta(
    Color(0xFFEFE8E1),
    Color(0xFF6B5A4C),
    Color(0xFF9C8B7C),
    'Este pedido fue cancelado.',
  ),
};

/// Estado de un pedido. En modo etiqueta es una pastilla con un punto de
/// color (para listas y tablas); en modo mensaje es un recuadro con estrella
/// que explica el estado a la clienta.
class TinaEstadoPedido extends StatelessWidget {
  const TinaEstadoPedido({
    super.key,
    required this.estado,
    this.modo = ModoEstado.etiqueta,
  });

  final EstadoPedido estado;
  final ModoEstado modo;

  @override
  Widget build(BuildContext context) {
    final paleta = _paletas[estado]!;
    final borde = paleta.punto.withValues(alpha: 0.4);

    if (modo == ModoEstado.etiqueta) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(
          color: paleta.fondo,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borde),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 7,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: paleta.punto,
                shape: BoxShape.circle,
              ),
            ),
            Flexible(
              child: Text(
                estado.etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TinaTipografia.estilo(
                  tamano: 13,
                  peso: FontWeight.w800,
                  color: paleta.texto,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: paleta.fondo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borde, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          EstrellaTina(tamano: 34, color: paleta.punto),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  estado.etiqueta,
                  style: TinaTipografia.estilo(
                    tamano: 16,
                    peso: FontWeight.w800,
                    color: paleta.texto,
                  ),
                ),
                Text(
                  paleta.mensaje,
                  style: TinaTipografia.estilo(tamano: 14, altura: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
