import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_boton_redondo.dart';

/// Botón redondo del carrito con el número de unidades encima.
class TinaCarritoRedondo extends StatelessWidget {
  const TinaCarritoRedondo({
    super.key,
    required this.carrito,
    required this.onCarrito,
  });

  final int carrito;
  final VoidCallback? onCarrito;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TinaBotonRedondo(
            etiqueta: 'Carrito',
            icono: Icons.shopping_bag_outlined,
            onPressed: onCarrito,
          ),
          if (carrito > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TinaColores.naranja,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$carrito',
                  style: TinaTipografia.estilo(
                    tamano: 12,
                    peso: FontWeight.w800,
                    color: TinaColores.blanco,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
