import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';
import 'estrella_tina.dart';

/// Galería de fotos de un producto con flechas y puntos. El prototipo pinta un
/// degradado de marca distinto por foto en lugar de la imagen real.
class TinaFotoProducto extends StatelessWidget {
  const TinaFotoProducto({
    super.key,
    required this.total,
    required this.actual,
    required this.onCambiar,
  });

  final int total;
  final int actual;
  final ValueChanged<int> onCambiar;

  static const List<Gradient> _fondos = [
    RadialGradient(
      center: Alignment(-0.4, -0.5),
      radius: 1.2,
      colors: [Color(0xFFFFB347), TinaColores.naranja, TinaColores.rosa],
      stops: [0, 0.55, 1],
    ),
    LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [TinaColores.rosa, TinaColores.naranja, Color(0xFFFFB347)],
    ),
    RadialGradient(
      center: Alignment(0.5, -0.3),
      radius: 1.2,
      colors: [Color(0xFFFFD2A0), TinaColores.rosa, TinaColores.rojo],
      stops: [0, 0.5, 1],
    ),
  ];

  void _mover(int paso) => onCambiar((actual + paso + total) % total);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: _fondos[actual % _fondos.length],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: TinaColores.dorado, width: 1.5),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      const EstrellaTina(
                        tamano: 34,
                        color: TinaColores.durazno,
                      ),
                      Text(
                        'Foto ${actual + 1} de $total',
                        style: TinaTipografia.serif(
                          tamano: 22,
                          color: TinaColores.crema,
                        ),
                      ),
                    ],
                  ),
                ),
                if (total > 1) ...[
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _Flecha(
                        llave: const ValueKey('foto-anterior'),
                        etiqueta: 'Foto anterior',
                        icono: Icons.chevron_left_rounded,
                        onTap: () => _mover(-1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _Flecha(
                        llave: const ValueKey('foto-siguiente'),
                        etiqueta: 'Foto siguiente',
                        icono: Icons.chevron_right_rounded,
                        onTap: () => _mover(1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6,
          children: [
            for (var i = 0; i < total; i++)
              TinaHover(
                builder: (context, encima) => TinaGiro(
                  encima: encima,
                  escala: 1.1,
                  vueltas: 0,
                  child: GestureDetector(
                    key: ValueKey('foto-punto-$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onCambiar(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: i == actual ? 26 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: i == actual
                              ? TinaColores.naranja
                              : const Color(0xFFE0CDB5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Flecha extends StatelessWidget {
  const _Flecha({
    required this.llave,
    required this.etiqueta,
    required this.icono,
    required this.onTap,
  });

  final Key llave;
  final String etiqueta;
  final IconData icono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: etiqueta,
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => TinaGiro(
          encima: encima,
          escala: 1.1,
          vueltas: 0,
          child: GestureDetector(
            key: llave,
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TinaColores.crema,
                shape: BoxShape.circle,
                border: Border.all(color: TinaColores.dorado, width: 1.5),
              ),
              child: Icon(icono, size: 24, color: TinaColores.tinta),
            ),
          ),
        ),
      ),
    );
  }
}
