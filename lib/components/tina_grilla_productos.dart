import 'package:flutter/material.dart';

import '../logic/vistas.dart';
import '../theme/colores_producto.dart';
import '../utils/formato.dart';
import 'tina_tarjeta_producto.dart';

/// Productos en dos columnas.
class TinaGrillaProductos extends StatelessWidget {
  const TinaGrillaProductos({
    super.key,
    required this.productos,
    required this.onProducto,
  });

  final List<ProductoVista> productos;
  final ValueChanged<int> onProducto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        // 2 columnas en celular, 3 en tablet y 4 en escritorio.
        final columnas = restricciones.maxWidth < 520
            ? 2
            : restricciones.maxWidth < 800
            ? 3
            : 4;
        final ancho = (restricciones.maxWidth - 16 * (columnas - 1)) / columnas;
        return Wrap(
          spacing: 16,
          runSpacing: 22,
          children: [
            for (final p in productos)
              SizedBox(
                width: ancho,
                child: TinaTarjetaProducto(
                  key: ValueKey('producto-${p.producto.idProducto}'),
                  nombre: p.producto.nombre,
                  precio: formatoPesos(p.producto.precio),
                  categoria: p.categoria,
                  colores: [for (final c in p.colores) colorDeProducto(c)],
                  foto: p.fotos.isEmpty ? null : p.fotos.first,
                  onTap: () => onProducto(p.producto.idProducto),
                ),
              ),
          ],
        );
      },
    );
  }
}
