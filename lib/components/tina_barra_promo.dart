import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'estrella_tina.dart';

/// Franja delgada sobre la cabecera con lo más importante de la tienda: el
/// envío y el descuento de la primera compra.
class TinaBarraPromo extends StatelessWidget {
  const TinaBarraPromo({super.key});

  static const double alto = 34;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('barra-promo'),
      height: alto,
      width: double.infinity,
      color: TinaColores.rosaFuerte,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            const EstrellaTina(tamano: 11, color: TinaColores.blanco),
            Text(
              'Envío de \$5.000 a todo el país',
              style: TinaTipografia.estilo(
                tamano: 13,
                peso: FontWeight.w800,
                color: TinaColores.blanco,
              ),
            ),
            const EstrellaTina(tamano: 11, color: TinaColores.blanco),
            Text(
              '20% en tu primera compra con cuenta',
              style: TinaTipografia.estilo(
                tamano: 13,
                peso: FontWeight.w800,
                color: TinaColores.blanco,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
