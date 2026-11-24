import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';
import 'tina_imagen_red.dart';

/// Tarjeta de un producto en las listas: la foto manda. Debajo van el nombre,
/// el precio y los puntos con los colores disponibles. Con el mouse encima se
/// ve la segunda foto, si el producto la tiene.
///
/// Sin foto se ve el degradado de marca.
class TinaTarjetaProducto extends StatelessWidget {
  const TinaTarjetaProducto({
    super.key,
    required this.nombre,
    required this.precio,
    required this.categoria,
    required this.colores,
    required this.onTap,
    this.foto,
    this.fotoAlterna,
    this.agotado = false,
    this.pocasUnidades = false,
  });

  /// Dirección de la foto principal.
  final String? foto;

  /// La segunda foto, que aparece al pasar el mouse.
  final String? fotoAlterna;

  final String nombre;
  final String precio;
  final String categoria;
  final List<Color> colores;
  final bool agotado;
  final bool pocasUnidades;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final etiqueta = agotado
        ? 'Agotado'
        : pocasUnidades
        ? 'Pocas unidades'
        : null;
    return Semantics(
      button: true,
      label: 'Ver $nombre',
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              AspectRatio(
                aspectRatio: 0.9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
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
                      if (foto != null) TinaImagenRed(url: foto!, radio: 0),
                      if (fotoAlterna != null)
                        AnimatedOpacity(
                          key: const ValueKey('foto-alterna'),
                          opacity: encima ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: TinaImagenRed(url: fotoAlterna!, radio: 0),
                        ),
                      if (agotado)
                        ColoredBox(
                          color: TinaColores.blanco.withValues(alpha: 0.35),
                        ),
                      if (etiqueta != null)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            key: const ValueKey('etiqueta-stock'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: agotado
                                  ? TinaColores.tinta
                                  : TinaColores.rosaFuerte,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              etiqueta,
                              style: TinaTipografia.estilo(
                                tamano: 11,
                                peso: FontWeight.w800,
                                color: TinaColores.blanco,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TinaTipografia.estilo(
                        tamano: 14,
                        peso: FontWeight.w700,
                        altura: 1.2,
                        color: encima ? TinaColores.naranja : TinaColores.tinta,
                      ),
                    ),
                    Text(
                      precio,
                      style: TinaTipografia.estilo(
                        tamano: 15,
                        peso: FontWeight.w800,
                        color: TinaColores.naranja,
                      ),
                    ),
                    if (colores.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (final color in colores)
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black12),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
