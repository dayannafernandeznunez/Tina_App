import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';

/// Un color que se puede elegir: nombre (el que guarda la variante) y el color
/// con el que se pinta la muestra.
class OpcionColor {
  const OpcionColor({required this.nombre, required this.color});

  final String nombre;
  final Color color;
}

/// Selector de color con muestras circulares. No guarda la selección: recibe
/// [valor] y avisa con [onChanged].
class TinaSelectorColor extends StatelessWidget {
  const TinaSelectorColor({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onChanged,
  });

  final List<OpcionColor> opciones;
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
              'Color',
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
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final opcion in opciones)
              Semantics(
                button: true,
                selected: opcion.nombre == valor,
                label: opcion.nombre,
                excludeSemantics: true,
                onTap: () => onChanged(opcion.nombre),
                child: TinaHover(
                  builder: (context, encima) => TinaGiro(
                    encima: encima,
                    escala: 1.1,
                    vueltas: 0,
                    child: GestureDetector(
                      key: ValueKey('color-${opcion.nombre}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(opcion.nombre),
                      child: Container(
                        width: 46,
                        height: 46,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: opcion.nombre == valor
                                ? TinaColores.tinta
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: opcion.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: TinaColores.dorado,
                              width: 1.5,
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
