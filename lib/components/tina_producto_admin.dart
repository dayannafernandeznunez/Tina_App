import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';

/// Un producto en la lista del panel de la vendedora: nombre, categoría, precio,
/// cuánto stock queda y un interruptor para mostrarlo u ocultarlo en la tienda.
/// No guarda nada: avisa con callbacks.
class TinaProductoAdmin extends StatelessWidget {
  const TinaProductoAdmin({
    super.key,
    required this.nombre,
    required this.detalle,
    required this.stock,
    required this.visible,
    required this.ocupado,
    required this.onEditar,
    required this.onAlternar,
  });

  final String nombre;

  /// Por ejemplo "Collares · $55.000".
  final String detalle;

  /// Unidades que quedan, sumando todas sus variantes.
  final int stock;
  final bool visible;
  final bool ocupado;
  final VoidCallback onEditar;
  final VoidCallback onAlternar;

  /// Con este stock o menos se avisa que queda poco.
  static const int pocoStock = 3;

  @override
  Widget build(BuildContext context) {
    final String textoStock;
    final Color colorStock;
    if (stock <= 0) {
      textoStock = 'Agotado';
      colorStock = TinaColores.rojo;
    } else if (stock <= pocoStock) {
      textoStock = 'Poco stock: $stock';
      colorStock = const Color(0xFFB84A00);
    } else {
      textoStock = 'Stock: $stock';
      colorStock = TinaColores.marron;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: TinaColores.cremaCampo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TinaColores.dorado, width: 1.5),
      ),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: GestureDetector(
              key: const ValueKey('editar-producto'),
              behavior: HitTestBehavior.opaque,
              onTap: onEditar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TinaTipografia.estilo(
                      tamano: 16,
                      peso: FontWeight.w800,
                      altura: 1.15,
                    ),
                  ),
                  Text(
                    detalle,
                    style: TinaTipografia.estilo(
                      tamano: 13,
                      color: TinaColores.marron,
                    ),
                  ),
                  Text(
                    textoStock,
                    key: const ValueKey('stock-producto'),
                    style: TinaTipografia.estilo(
                      tamano: 13,
                      peso: FontWeight.w800,
                      color: colorStock,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                key: const ValueKey('alternar-visible'),
                value: visible,
                onChanged: ocupado ? null : (_) => onAlternar(),
                activeTrackColor: TinaColores.naranja,
                activeThumbColor: TinaColores.blanco,
                inactiveTrackColor: TinaColores.cremaSuave,
                inactiveThumbColor: TinaColores.marron,
              ),
              Text(
                visible ? 'Visible' : 'Oculto',
                style: TinaTipografia.estilo(
                  tamano: 12,
                  peso: FontWeight.w800,
                  color: visible ? TinaColores.naranja : TinaColores.marron,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
