import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';

/// Pestañas de texto (Descripción, Envíos, Cuidados...). Guarda por sí sola cuál
/// está abierta: es solo de presentación, no un dato de la tienda.
class TinaPestanas extends StatefulWidget {
  const TinaPestanas({super.key, required this.pestanas});

  /// Título de cada pestaña y su contenido.
  final List<(String, Widget)> pestanas;

  @override
  State<TinaPestanas> createState() => _TinaPestanasState();
}

class _TinaPestanasState extends State<TinaPestanas> {
  int _actual = 0;

  @override
  Widget build(BuildContext context) {
    final indice = _actual.clamp(0, widget.pestanas.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        Wrap(
          spacing: 22,
          runSpacing: 6,
          children: [
            for (var i = 0; i < widget.pestanas.length; i++)
              Semantics(
                button: true,
                selected: i == indice,
                label: widget.pestanas[i].$1,
                excludeSemantics: true,
                onTap: () => setState(() => _actual = i),
                child: GestureDetector(
                  key: ValueKey('pestana-${widget.pestanas[i].$1}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _actual = i),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: i == indice
                              ? TinaColores.naranja
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      widget.pestanas[i].$1,
                      style: TinaTipografia.estilo(
                        tamano: 15,
                        peso: FontWeight.w800,
                        color: i == indice
                            ? TinaColores.naranja
                            : TinaColores.marron,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        widget.pestanas[indice].$2,
      ],
    );
  }
}
