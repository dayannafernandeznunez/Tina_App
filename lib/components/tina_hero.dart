import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import '../utils/adaptable.dart';
import 'estrella_tina.dart';
import 'tina_fondo_marca.dart';
import 'tina_imagen_red.dart';

/// Encabezado de la portada con el estilo de las piezas de Tina: naranja
/// plano, manchas rosadas, estrellas blancas y grano, con el eslogan en blanco.
class TinaHero extends StatelessWidget {
  const TinaHero({
    super.key,
    required this.linea1,
    required this.linea2,
    required this.subtitulo,
    this.foto,
    this.onComprar,
  });

  /// Si se da, la portada muestra el botón "Comprar ahora".
  final VoidCallback? onComprar;

  /// Foto de la portada que sube la administradora. Sin ella se ve el diseño
  /// de manchas y estrellas.
  final String? foto;

  final String linea1;
  final String linea2;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final grande = esEscritorio(context);
    return TinaFondoMarca(
      radio: grande ? 40 : 30,
      child: Stack(
        children: [
          if (foto != null) ...[
            Positioned.fill(child: TinaImagenRed(url: foto!, radio: 0)),
            // Velo naranja para que el texto se lea sobre cualquier foto.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      TinaColores.naranja.withValues(alpha: 0.88),
                      TinaColores.naranja.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ],
          // La estrella grande color crema de las piezas de la feria.
          Positioned(
            right: grande ? 56 : 14,
            bottom: grande ? 56 : 22,
            child: EstrellaTina(
              tamano: grande ? 140 : 84,
              color: const Color(0xFFF4DCC4),
            ),
          ),
          Padding(
            padding: grande
                ? const EdgeInsets.fromLTRB(64, 72, 64, 64)
                : const EdgeInsets.fromLTRB(26, 40, 26, 34),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: grande ? 0.58 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    linea2,
                    style: TinaTipografia.serif(
                      tamano: grande ? 52 : 34,
                      color: TinaColores.blanco,
                      altura: 1,
                    ),
                  ),
                  SizedBox(height: grande ? 6 : 2),
                  Text(
                    linea1,
                    style: TinaTipografia.estilo(
                      tamano: grande ? 84 : 50,
                      peso: FontWeight.w800,
                      color: TinaColores.blanco,
                      espaciado: grande ? -3.6 : -2,
                      altura: 0.92,
                    ),
                  ),
                  SizedBox(height: grande ? 22 : 14),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: grande ? 420 : 260),
                    child: Text(
                      subtitulo,
                      style: TinaTipografia.estilo(
                        tamano: grande ? 20 : 15,
                        color: TinaColores.blanco,
                        altura: 1.3,
                      ),
                    ),
                  ),
                  if (onComprar != null) ...[
                    SizedBox(height: grande ? 28 : 20),
                    GestureDetector(
                      key: const ValueKey('hero-comprar'),
                      onTap: onComprar,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: grande ? 30 : 24,
                          vertical: grande ? 15 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: TinaColores.blanco,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            Text(
                              'Comprar ahora',
                              style: TinaTipografia.estilo(
                                tamano: grande ? 16 : 14,
                                peso: FontWeight.w800,
                                color: TinaColores.naranja,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: TinaColores.naranja,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: grande ? 30 : 22),
                  Text(
                    'Tina',
                    style: TinaTipografia.estilo(
                      tamano: 22,
                      peso: FontWeight.w800,
                      color: TinaColores.blanco,
                      espaciado: -0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
