import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';

/// Selector de talla con botones rectangulares. No guarda la selección:
/// recibe [valor] y avisa con [onChanged].
class TinaSelectorTalla extends StatelessWidget {
  const TinaSelectorTalla({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onChanged,
  });

  final List<String> opciones;
  final String valor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Row(
          spacing: 8,
          children: [
            Text(
              'Talla',
              style: TinaTipografia.estilo(tamano: 15, peso: FontWeight.w800),
            ),
            Text(
              valor,
              style: TinaTipografia.estilo(
                tamano: 15,
                color: TinaColores.marron,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final talla in opciones)
              Semantics(
                button: true,
                selected: talla == valor,
                label: 'Talla $talla',
                excludeSemantics: true,
                onTap: () => onChanged(talla),
                child: TinaHover(
                  builder: (context, encima) => TinaGiro(
                    encima: encima,
                    escala: 1.06,
                    vueltas: 0,
                    child: GestureDetector(
                      key: ValueKey('talla-$talla'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(talla),
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 56,
                          minHeight: 46,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: talla == valor
                              ? TinaColores.tinta
                              : TinaColores.cremaCampo,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: talla == valor
                                ? TinaColores.tinta
                                : TinaColores.dorado,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: Text(
                            talla,
                            style: TinaTipografia.estilo(
                              tamano: 16,
                              peso: FontWeight.w800,
                              color: talla == valor
                                  ? TinaColores.blanco
                                  : TinaColores.tinta,
                            ),
                          ),
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
