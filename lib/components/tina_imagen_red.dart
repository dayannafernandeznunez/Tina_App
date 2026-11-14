import 'package:flutter/material.dart';

/// Foto que viene de internet (Supabase Storage). Aparece suavemente cuando
/// termina de cargar; mientras carga, o si falla, deja ver lo que haya debajo
/// (por ejemplo el degradado de marca).
class TinaImagenRed extends StatelessWidget {
  const TinaImagenRed({super.key, required this.url, required this.radio});

  final String url;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (context, hijo, cuadro, sincrona) {
          if (sincrona) return hijo;
          return AnimatedOpacity(
            opacity: cuadro == null ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: hijo,
          );
        },
        errorBuilder: (context, error, pila) => const SizedBox.shrink(),
      ),
    );
  }
}
