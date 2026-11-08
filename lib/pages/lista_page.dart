import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/vistas.dart';
import '../theme/tina_tema.dart';

/// Productos de una categoría.
class ListaPage extends StatelessWidget {
  const ListaPage({
    super.key,
    required this.categoriaActiva,
    required this.categorias,
    required this.productos,
    required this.unidadesCarrito,
    required this.onProducto,
    required this.onCategoria,
    required this.onAtras,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
  });

  final String categoriaActiva;
  final List<String> categorias;
  final List<ProductoVista> productos;
  final int unidadesCarrito;
  final ValueChanged<int> onProducto;

  /// `null` significa "Todos".
  final ValueChanged<String?> onCategoria;
  final VoidCallback onAtras;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;

  @override
  Widget build(BuildContext context) {
    final conteo =
        '${productos.length} '
        '${productos.length == 1 ? 'accesorio' : 'accesorios'}';
    return TinaScaffold(
      titulo: categoriaActiva,
      conAtras: true,
      activo: DestinoNav.categorias,
      unidadesCarrito: unidadesCarrito,
      onAtras: onAtras,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      cuerpo: TinaLista(
        arriba: 18,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                TinaChip(
                  key: const ValueKey('chip-Todos'),
                  etiqueta: 'Todos',
                  activo: false,
                  onTap: () => onCategoria(null),
                ),
                for (final c in categorias)
                  TinaChip(
                    key: ValueKey('chip-$c'),
                    etiqueta: c,
                    activo: c == categoriaActiva,
                    onTap: () => onCategoria(c),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            conteo,
            style: TinaTipografia.estilo(tamano: 14, color: TinaColores.marron),
          ),
          const SizedBox(height: 14),
          if (productos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'Todavía no hay accesorios en esta categoría.',
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 16,
                  color: TinaColores.marron,
                ),
              ),
            )
          else
            TinaGrillaProductos(productos: productos, onProducto: onProducto),
        ],
      ),
    );
  }
}
