import 'package:flutter/material.dart';

/// La estrella de cuatro puntas de la marca. Se usa en el botón principal, en
/// las etiquetas, en los mensajes de estado y en el logo.
class EstrellaTina extends StatelessWidget {
  const EstrellaTina({super.key, this.tamano = 16, required this.color});

  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: CustomPaint(painter: _PintorEstrella(color)),
      ),
    );
  }
}

class _PintorEstrella extends CustomPainter {
  const _PintorEstrella(this.color);

  final Color color;

  static const List<Offset> _puntos = [
    Offset(0.50, 0.00),
    Offset(0.58, 0.42),
    Offset(1.00, 0.50),
    Offset(0.58, 0.58),
    Offset(0.50, 1.00),
    Offset(0.42, 0.58),
    Offset(0.00, 0.50),
    Offset(0.42, 0.42),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final camino = Path()
      ..moveTo(_puntos.first.dx * size.width, _puntos.first.dy * size.height);
    for (final p in _puntos.skip(1)) {
      camino.lineTo(p.dx * size.width, p.dy * size.height);
    }
    camino.close();
    canvas.drawPath(camino, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PintorEstrella viejo) => viejo.color != color;
}
