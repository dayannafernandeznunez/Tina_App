import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';
import 'tina_selector_cantidad.dart';

/// Una línea del carrito: muestra del color, nombre, variante, cantidad
/// editable, total de la línea y botón para quitarla.
class TinaItemCarrito extends StatelessWidget {
  const TinaItemCarrito({
    super.key,
    required this.nombre,
    required this.variante,
    required this.color,
    required this.cantidad,
    required this.maximo,
    required this.total,
    required this.onCantidad,
    required this.onQuitar,
  });

  final String nombre;
  final String variante;
  final Color color;
  final int cantidad;
  final int maximo;
  final String total;
  final ValueChanged<int> onCantidad;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TinaColores.cremaCampo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TinaColores.dorado, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            width: 72,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const RadialGradient(
                center: Alignment(-0.4, -0.5),
                radius: 1.2,
                colors: [
                  Color(0xFFFFB347),
                  TinaColores.naranja,
                  TinaColores.rosa,
                ],
                stops: [0, 0.55, 1],
              ),
            ),
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: TinaColores.crema, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TinaTipografia.estilo(
                    tamano: 15,
                    peso: FontWeight.w800,
                    altura: 1.15,
                  ),
                ),
                Text(
                  variante,
                  style: TinaTipografia.estilo(
                    tamano: 13,
                    color: TinaColores.marron,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TinaSelectorCantidad(
                      valor: cantidad,
                      maximo: maximo,
                      onChanged: onCantidad,
                    ),
                    Text(
                      total,
                      style: TinaTipografia.estilo(
                        tamano: 16,
                        peso: FontWeight.w800,
                        color: TinaColores.naranja,
                      ),
                    ),
                  ],
                ),
                Semantics(
                  button: true,
                  label: 'Quitar $nombre',
                  excludeSemantics: true,
                  onTap: onQuitar,
                  child: TinaHover(
                    builder: (context, encima) => GestureDetector(
                      key: const ValueKey('quitar'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onQuitar,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Quitar',
                          style: TinaTipografia.estilo(
                            tamano: 14,
                            peso: FontWeight.w800,
                            color: encima
                                ? const Color(0xFF9E1030)
                                : TinaColores.rojo,
                          ).copyWith(decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
