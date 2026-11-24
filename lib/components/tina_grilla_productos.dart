import 'package:flutter/material.dart';

import '../logic/vistas.dart';
import '../theme/colores_producto.dart';
import '../utils/formato.dart';
import 'tina_tarjeta_producto.dart';

/// Productos en columnas: 2 en celular, 3 en tablet y [columnasEscritorio] en
/// pantallas anchas (4 por defecto).
class TinaGrillaProductos extends StatelessWidget {
  const TinaGrillaProductos({
    super.key,
    required this.productos,
    required this.onProducto,
    this.columnasEscritorio = 4,
  });

  final List<ProductoVista> productos;
  final ValueChanged<int> onProducto;
  final int columnasEscritorio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final columnas = restricciones.maxWidth < 520
            ? 2
            : restricciones.maxWidth < 800
            ? 3
            : columnasEscritorio;
        final ancho = (restricciones.maxWidth - 18 * (columnas - 1)) / columnas;
        return Wrap(
          spacing: 18,
          runSpacing: 26,
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
                  fotoAlterna: p.fotos.length > 1 ? p.fotos[1] : null,
                  agotado: p.agotado,
                  pocasUnidades: p.pocasUnidades,
                  onTap: () => onProducto(p.producto.idProducto),
                ),
              ),
          ],
        );
      },
    );
  }
}
