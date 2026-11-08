import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';

/// Pastilla para filtrar (categorías, estados de pedido). El activo va en
/// oscuro. Con [conteo] muestra "Etiqueta · n".
class TinaChip extends StatelessWidget {
  const TinaChip({
    super.key,
    required this.etiqueta,
    required this.activo,
    required this.onTap,
    this.conteo,
  });

  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;
  final int? conteo;

  @override
  Widget build(BuildContext context) {
    final texto = conteo == null ? etiqueta : '$etiqueta · $conteo';
    return Semantics(
      button: true,
      selected: activo,
      label: texto,
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => TinaGiro(
          encima: encima,
          escala: 1.06,
          vueltas: 0.004,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: activo ? TinaColores.tinta : TinaColores.cremaCampo,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: activo ? TinaColores.tinta : TinaColores.dorado,
                  width: 1.5,
                ),
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  texto,
                  style: TinaTipografia.estilo(
                    tamano: 14,
                    peso: FontWeight.w800,
                    color: activo ? TinaColores.blanco : TinaColores.tinta,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
