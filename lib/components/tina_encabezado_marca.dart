import 'package:flutter/material.dart';

import '../utils/adaptable.dart';
import 'tina_fondo_marca.dart';

/// Banda de título con el estilo de las piezas de Tina (naranja plano, manchas
/// rosadas, estrellas y grano). Los textos que lleve dentro deben ser blancos.
class TinaEncabezadoMarca extends StatelessWidget {
  const TinaEncabezadoMarca({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final grande = esEscritorio(context);
    return TinaFondoMarca(
      variante: VarianteFondo.banda,
      radio: grande ? 36 : 28,
      child: Padding(
        padding: grande
            ? const EdgeInsets.fromLTRB(40, 36, 40, 36)
            : const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
