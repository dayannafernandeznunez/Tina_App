import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_circulos_categorias.dart';
import 'tina_hover.dart';
import 'tina_imagen_red.dart';

/// Las categorías como fotos grandes, con su nombre encima y "Ver aquí →".
/// Se deslizan de lado cuando no caben.
class TinaMosaicoCategorias extends StatelessWidget {
  const TinaMosaicoCategorias({
    super.key,
    required this.categorias,
    required this.onTap,
  });

  final List<ItemCategoria> categorias;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final porFila = restricciones.maxWidth < 520
            ? 2
            : restricciones.maxWidth < 800
            ? 3
            : 4;
        final ancho = (restricciones.maxWidth - 14 * (porFila - 1)) / porFila;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final c in categorias)
              SizedBox(
                width: ancho,
                child: _Baldosa(
                  key: ValueKey('mosaico-${c.nombre}'),
                  item: c,
                  onTap: () => onTap(c.nombre),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Baldosa extends StatelessWidget {
  const _Baldosa({super.key, required this.item, required this.onTap});

  final ItemCategoria item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver ${item.nombre}',
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 0.78,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.4, -0.5),
                        radius: 1.2,
                        colors: [
                          Color(0xFFFFB347),
                          TinaColores.naranja,
                          TinaColores.rosa,
                        ],
                        stops: [0, 0.55, 1],
                      ),
                    ),
                  ),
                  if (item.foto != null)
                    AnimatedScale(
                      scale: encima ? 1.05 : 1,
                      duration: const Duration(milliseconds: 260),
                      child: TinaImagenRed(url: item.foto!, radio: 0),
                    ),
                  // Velo oscuro abajo para que el texto se lea sobre la foto.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xAA2A1608)],
                        stops: [0.5, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          item.nombre,
                          style: TinaTipografia.estilo(
                            tamano: 20,
                            peso: FontWeight.w800,
                            color: TinaColores.blanco,
                            espaciado: -0.4,
                          ),
                        ),
                        Text(
                          'Ver aquí →',
                          style: TinaTipografia.estilo(
                            tamano: 13,
                            peso: FontWeight.w700,
                            color: TinaColores.blanco,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
