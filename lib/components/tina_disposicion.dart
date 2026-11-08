import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import '../utils/adaptable.dart';

/// Lista desplazable que centra su contenido con un ancho máximo. La barra de
/// desplazamiento queda en el borde de la ventana, no en el del contenido.
class TinaLista extends StatelessWidget {
  const TinaLista({
    super.key,
    required this.children,
    this.anchoMaximo = anchoContenido,
    this.arriba = 20,
    this.abajo = 28,
  });

  final List<Widget> children;
  final double anchoMaximo;
  final double arriba;
  final double abajo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final margen = restricciones.maxWidth >= anchoEscritorio ? 24.0 : 20.0;
        final contenido = math.min(
          anchoMaximo,
          restricciones.maxWidth - margen * 2,
        );
        final lateral = (restricciones.maxWidth - contenido) / 2;
        return ListView(
          padding: EdgeInsets.fromLTRB(lateral, arriba, lateral, abajo),
          children: children,
        );
      },
    );
  }
}

/// Dos bloques lado a lado en pantallas anchas y uno sobre otro en las
/// angostas. Con [tarjetaDerecha] el bloque derecho va dentro de una tarjeta
/// (solo cuando está al lado).
class TinaDosColumnas extends StatelessWidget {
  const TinaDosColumnas({
    super.key,
    required this.izquierda,
    required this.derecha,
    this.flexIzquierda = 11,
    this.flexDerecha = 9,
    this.tarjetaDerecha = false,
  });

  final Widget izquierda;
  final Widget derecha;
  final int flexIzquierda;
  final int flexDerecha;
  final bool tarjetaDerecha;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        if (restricciones.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [izquierda, derecha],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 40,
          children: [
            Expanded(flex: flexIzquierda, child: izquierda),
            Expanded(
              flex: flexDerecha,
              child: tarjetaDerecha
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: TinaColores.cremaCampo,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: TinaColores.dorado,
                          width: 1.5,
                        ),
                      ),
                      child: derecha,
                    )
                  : derecha,
            ),
          ],
        );
      },
    );
  }
}

/// Reparte widgets en tantas columnas como quepan con [anchoMinimo] cada una.
class TinaRejilla extends StatelessWidget {
  const TinaRejilla({
    super.key,
    required this.children,
    required this.anchoMinimo,
    this.espacio = 16,
  });

  final List<Widget> children;
  final double anchoMinimo;
  final double espacio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final columnas = math.max(
          1,
          ((ancho + espacio) / (anchoMinimo + espacio)).floor(),
        );
        final anchoColumna = (ancho - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final hijo in children)
              SizedBox(width: anchoColumna, child: hijo),
          ],
        );
      },
    );
  }
}
