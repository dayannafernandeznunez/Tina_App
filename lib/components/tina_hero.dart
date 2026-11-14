import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import '../utils/adaptable.dart';
import 'estrella_tina.dart';
import 'tina_imagen_red.dart';

/// Encabezado de la portada: el eslogan sobre fondo naranja con círculos y
/// estrellas.
class TinaHero extends StatelessWidget {
  const TinaHero({
    super.key,
    required this.linea1,
    required this.linea2,
    required this.subtitulo,
    this.foto,
  });

  /// Foto de la portada que sube la administradora. Sin ella se ve el diseño
  /// de círculos y estrellas.
  final String? foto;

  final String linea1;
  final String linea2;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final grande = esEscritorio(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: grande
            ? const EdgeInsets.fromLTRB(56, 64, 56, 56)
            : const EdgeInsets.fromLTRB(24, 36, 24, 28),
        decoration: BoxDecoration(
          color: TinaColores.naranja,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: TinaColores.dorado, width: 1.5),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (foto != null) ...[
              Positioned.fill(child: TinaImagenRed(url: foto!, radio: 30)),
              // Velo naranja para que el texto se lea sobre cualquier foto.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TinaColores.naranja.withValues(alpha: 0.85),
                        TinaColores.naranja.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Positioned(
              right: -70,
              top: -80,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                  color: TinaColores.rosa,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -60,
              bottom: -90,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: TinaColores.rojo.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Positioned(
              right: 22,
              top: 26,
              child: EstrellaTina(tamano: 30, color: TinaColores.durazno),
            ),
            const Positioned(
              right: 70,
              bottom: 8,
              child: EstrellaTina(tamano: 14, color: TinaColores.blanco),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linea1,
                  style: TinaTipografia.estilo(
                    tamano: grande ? 72 : 40,
                    peso: FontWeight.w800,
                    color: TinaColores.blanco,
                    espaciado: -1.2,
                    altura: 0.95,
                  ),
                ),
                Text(
                  linea2,
                  style: TinaTipografia.serif(
                    tamano: grande ? 80 : 44,
                    color: TinaColores.crema,
                    altura: 1,
                  ),
                ),
                SizedBox(height: grande ? 20 : 12),
                Text(
                  subtitulo,
                  style: TinaTipografia.estilo(
                    tamano: grande ? 20 : 15,
                    color: TinaColores.crema,
                    altura: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
