import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';

/// Tarjeta de un producto en las listas: foto, categoría, nombre, precio y
/// puntos con los colores disponibles. El prototipo pinta un degradado de
/// marca donde iría la foto.
class TinaTarjetaProducto extends StatelessWidget {
  const TinaTarjetaProducto({
    super.key,
    required this.nombre,
    required this.precio,
    required this.categoria,
    required this.colores,
    required this.onTap,
  });

  final String nombre;
  final String precio;
  final String categoria;
  final List<Color> colores;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver $nombre',
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => TinaLevante(
          encima: encima,
          dy: -4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const RadialGradient(
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
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: TinaColores.dorado, width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: TinaColores.crema,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: TinaColores.dorado),
                            ),
                            child: Text(
                              categoria,
                              style: TinaTipografia.estilo(
                                tamano: 12,
                                peso: FontWeight.w800,
                                color: TinaColores.rojo,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOut,
                            transform: Matrix4.translationValues(
                              encima ? 5 : 0,
                              0,
                              0,
                            ),
                            constraints: const BoxConstraints.tightFor(
                              width: 44,
                              height: 44,
                            ),
                            decoration: const BoxDecoration(
                              color: TinaColores.naranja,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: TinaColores.blanco,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TinaTipografia.estilo(
                          tamano: 15,
                          peso: FontWeight.w800,
                          altura: 1.15,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            precio,
                            style: TinaTipografia.estilo(
                              tamano: 16,
                              peso: FontWeight.w800,
                              color: TinaColores.naranja,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              for (final color in colores)
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: TinaColores.dorado,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
