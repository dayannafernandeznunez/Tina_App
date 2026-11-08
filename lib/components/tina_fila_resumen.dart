import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';

enum TipoFila { normal, descuento, total }

/// Fila del resumen de un pedido: subtotal, descuento o total. Con [detalle]
/// agrega una segunda línea pequeña bajo la etiqueta.
class TinaFilaResumen extends StatelessWidget {
  const TinaFilaResumen({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.detalle,
    this.tipo = TipoFila.normal,
  });

  final String etiqueta;
  final String valor;
  final String? detalle;
  final TipoFila tipo;

  @override
  Widget build(BuildContext context) {
    if (tipo == TipoFila.total) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: TinaTipografia.estilo(
                  tamano: 20,
                  peso: FontWeight.w800,
                  espaciado: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              valor,
              style: TinaTipografia.estilo(
                tamano: 24,
                peso: FontWeight.w800,
                color: TinaColores.naranja,
                espaciado: -0.48,
              ),
            ),
          ],
        ),
      );
    }

    return TinaHover(
      cursor: MouseCursor.defer,
      builder: (context, encima) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: encima ? TinaColores.cremaSuave : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(etiqueta, style: TinaTipografia.estilo(tamano: 15)),
                      if (detalle != null && detalle!.isNotEmpty)
                        Text(
                          detalle!,
                          style: TinaTipografia.estilo(
                            tamano: 13,
                            color: TinaColores.marron,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  valor,
                  style: TinaTipografia.estilo(
                    tamano: 15,
                    peso: FontWeight.w800,
                    color: tipo == TipoFila.descuento
                        ? TinaColores.rojo
                        : TinaColores.tinta,
                  ),
                ),
              ],
            ),
          ),
          const _LineaPunteada(),
        ],
      ),
    );
  }
}

class _LineaPunteada extends StatelessWidget {
  const _LineaPunteada();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1.5,
      width: double.infinity,
      child: CustomPaint(painter: _PintorPunteado()),
    );
  }
}

class _PintorPunteado extends CustomPainter {
  const _PintorPunteado();

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = TinaColores.dorado.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 5).clamp(0, size.width), y),
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorPunteado viejo) => false;
}
