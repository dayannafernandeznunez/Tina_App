import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';
import 'estrella_tina.dart';

/// "Tina" con la ı sin punto y una estrella roja encima.
class TinaLogo extends StatelessWidget {
  const TinaLogo({super.key, required this.onTap, this.tamano = 32});

  final VoidCallback? onTap;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final estilo = TinaTipografia.estilo(
      tamano: tamano,
      peso: FontWeight.w800,
      color: TinaColores.naranja,
      espaciado: -tamano * 0.015,
      altura: 1,
    );
    return Semantics(
      button: true,
      label: 'Tina, inicio',
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => TinaGiro(
          encima: encima,
          escala: 1.05,
          vueltas: 0.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('T', style: estilo),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Text('ı', style: estilo),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -1,
                        child: Center(
                          child: EstrellaTina(
                            tamano: tamano * 0.4,
                            color: TinaColores.rojo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text('na', style: estilo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
