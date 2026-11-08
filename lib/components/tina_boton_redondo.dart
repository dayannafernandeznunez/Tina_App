import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';

/// Botón circular con un ícono (volver, carrito). Lo usan las barras
/// superiores.
class TinaBotonRedondo extends StatelessWidget {
  const TinaBotonRedondo({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.onPressed,
    this.tamanoIcono = 22,
  });

  final String etiqueta;
  final IconData icono;
  final double tamanoIcono;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: etiqueta,
      excludeSemantics: true,
      onTap: onPressed,
      child: TinaHover(
        builder: (context, encima) => TinaLevante(
          encima: encima,
          dy: -2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: TinaColores.cremaCampo,
                shape: BoxShape.circle,
                border: Border.all(
                  color: encima ? TinaColores.naranja : TinaColores.dorado,
                  width: 1.5,
                ),
              ),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                offset: Offset(encima && etiqueta == 'Volver' ? -0.12 : 0, 0),
                child: Icon(icono, size: tamanoIcono, color: TinaColores.tinta),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
