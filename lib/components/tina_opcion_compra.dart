import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';

/// Opción que se elige con un punto, como "Comprar con cuenta" o "Comprar como
/// invitada". Puede llevar un [extra] debajo del texto (por ejemplo, una
/// etiqueta de descuento).
class TinaOpcionCompra extends StatelessWidget {
  const TinaOpcionCompra({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.seleccionada,
    required this.onTap,
    this.extra,
  });

  final String titulo;
  final String subtitulo;
  final bool seleccionada;
  final VoidCallback onTap;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final borde = seleccionada ? TinaColores.naranja : TinaColores.dorado;
    return Semantics(
      button: true,
      selected: seleccionada,
      label: titulo,
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => TinaLevante(
          encima: encima,
          dy: -2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: seleccionada
                    ? TinaColores.cremaSuave
                    : TinaColores.cremaCampo,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borde, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borde, width: 2),
                    ),
                    child: seleccionada
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: TinaColores.naranja,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          titulo,
                          style: TinaTipografia.estilo(
                            tamano: 16,
                            peso: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: TinaTipografia.estilo(
                            tamano: 13,
                            color: TinaColores.marron,
                            altura: 1.3,
                          ),
                        ),
                        if (extra != null) ...[
                          const SizedBox(height: 4),
                          extra!,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
