import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'estrella_tina.dart';

/// Fondo con el estilo de Tina (el de las piezas de la feria): naranja plano,
/// manchas rosadas con degradado que se salen por los bordes, estrellas
/// blancas de cuatro puntas y un grano fino como de papel.
///
/// Se dibuja detrás de [child]. No usa bordes ni sombras.
class TinaFondoMarca extends StatelessWidget {
  const TinaFondoMarca({
    super.key,
    required this.child,
    this.radio = 32,
    this.variante = VarianteFondo.portada,
  });

  final Widget child;
  final double radio;
  final VarianteFondo variante;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: TinaColores.naranja)),
          ..._manchas(),
          ..._estrellas(),
          // El grano va sobre los colores y bajo el contenido.
          const Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _PintorGrano()),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  List<Widget> _manchas() {
    switch (variante) {
      case VarianteFondo.portada:
        return const [
          Positioned(right: -90, top: -110, child: _Mancha(tamano: 320)),
          Positioned(
            left: -80,
            bottom: -130,
            child: _Mancha(tamano: 260, fuerte: true),
          ),
        ];
      case VarianteFondo.completo:
        return const [
          Positioned(right: -120, top: -140, child: _Mancha(tamano: 420)),
          Positioned(
            left: -110,
            bottom: -150,
            child: _Mancha(tamano: 360, fuerte: true),
          ),
          Positioned(right: -60, bottom: 40, child: _Mancha(tamano: 180)),
        ];
      case VarianteFondo.banda:
        return const [
          Positioned(right: -60, top: -80, child: _Mancha(tamano: 200)),
          Positioned(
            left: -50,
            bottom: -90,
            child: _Mancha(tamano: 170, fuerte: true),
          ),
        ];
    }
  }

  List<Widget> _estrellas() {
    switch (variante) {
      case VarianteFondo.portada:
        return const [
          Positioned(
            right: 36,
            top: 34,
            child: EstrellaTina(tamano: 34, color: TinaColores.blanco),
          ),
          Positioned(
            right: 96,
            top: 92,
            child: EstrellaTina(tamano: 14, color: TinaColores.durazno),
          ),
          Positioned(
            right: 70,
            bottom: 26,
            child: EstrellaTina(tamano: 18, color: TinaColores.blanco),
          ),
        ];
      case VarianteFondo.completo:
        return const [
          Positioned(
            right: 48,
            top: 80,
            child: EstrellaTina(tamano: 46, color: TinaColores.blanco),
          ),
          Positioned(
            right: 120,
            top: 150,
            child: EstrellaTina(tamano: 18, color: TinaColores.durazno),
          ),
          Positioned(
            left: 40,
            bottom: 120,
            child: EstrellaTina(tamano: 34, color: TinaColores.blanco),
          ),
          Positioned(
            left: 92,
            bottom: 80,
            child: EstrellaTina(tamano: 14, color: TinaColores.blanco),
          ),
        ];
      case VarianteFondo.banda:
        return const [
          Positioned(
            right: 24,
            top: 18,
            child: EstrellaTina(tamano: 22, color: TinaColores.blanco),
          ),
        ];
    }
  }
}

enum VarianteFondo { portada, completo, banda }

/// Mancha rosada con degradado, como las del carrusel.
class _Mancha extends StatelessWidget {
  const _Mancha({required this.tamano, this.fuerte = false});

  final double tamano;
  final bool fuerte;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0.3, 0.2),
          radius: 0.85,
          colors: fuerte
              ? const [TinaColores.rosa, TinaColores.rosaFuerte]
              : const [TinaColores.rosaClaro, TinaColores.rosa],
        ),
      ),
    );
  }
}

/// Grano fino: puntitos claros y oscuros muy suaves, siempre iguales.
class _PintorGrano extends CustomPainter {
  const _PintorGrano();

  @override
  void paint(Canvas canvas, Size size) {
    final azar = math.Random(7);
    final cantidad = (size.width * size.height / 90).clamp(300, 4200).toInt();
    final claros = <Offset>[];
    final oscuros = <Offset>[];
    for (var i = 0; i < cantidad; i++) {
      final punto = Offset(
        azar.nextDouble() * size.width,
        azar.nextDouble() * size.height,
      );
      (azar.nextBool() ? claros : oscuros).add(punto);
    }
    canvas.drawPoints(
      PointMode.points,
      claros,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPoints(
      PointMode.points,
      oscuros,
      Paint()
        ..color = const Color(0xFF7A2A00).withValues(alpha: 0.10)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PintorGrano viejo) => false;
}
