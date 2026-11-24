import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';

/// Título de una sección con una línea fina que sigue hasta el borde, y un
/// subtítulo pequeño en cursiva debajo (opcional).
class TinaTituloSeccion extends StatelessWidget {
  const TinaTituloSeccion({super.key, required this.titulo, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Row(
          spacing: 16,
          children: [
            Flexible(
              child: Text(
                titulo,
                style: TinaTipografia.estilo(
                  tamano: 24,
                  peso: FontWeight.w800,
                  espaciado: -0.6,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1.5,
                color: TinaColores.durazno.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        if (subtitulo != null && subtitulo!.isNotEmpty)
          Text(
            subtitulo!,
            style: TinaTipografia.serif(tamano: 17, color: TinaColores.marron),
          ),
      ],
    );
  }
}
