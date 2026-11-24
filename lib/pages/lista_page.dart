import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/filtros_catalogo.dart';
import '../logic/vistas.dart';
import '../theme/tina_tema.dart';
import '../utils/adaptable.dart';

/// Productos de una categoría, con sus filtros (disponibilidad, color y precio)
/// y el orden. No guarda nada: los filtros y si el panel está abierto (en
/// celular) viven en la Screen.
class ListaPage extends StatelessWidget {
  const ListaPage({
    super.key,
    required this.categoriaActiva,
    required this.categorias,
    required this.productos,
    required this.todosDeLaCategoria,
    required this.filtros,
    required this.filtrosVisibles,
    required this.unidadesCarrito,
    required this.onProducto,
    required this.onCategoria,
    required this.onFiltros,
    required this.onAlternarFiltros,
    required this.onAtras,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
  });

  final String categoriaActiva;
  final List<ItemCategoria> categorias;

  /// Los productos que se ven, ya filtrados y ordenados.
  final List<ProductoVista> productos;

  /// Todos los de la categoría, sin filtrar (para contar colores y precios).
  final List<ProductoVista> todosDeLaCategoria;
  final FiltrosCatalogo filtros;

  /// En celular, si el panel de filtros está abierto.
  final bool filtrosVisibles;
  final int unidadesCarrito;
  final ValueChanged<int> onProducto;

  /// `null` significa "Todos".
  final ValueChanged<String?> onCategoria;
  final ValueChanged<FiltrosCatalogo> onFiltros;
  final VoidCallback onAlternarFiltros;
  final VoidCallback onAtras;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;

  @override
  Widget build(BuildContext context) {
    final grande = esEscritorio(context);
    final conteo =
        '${productos.length} '
        '${productos.length == 1 ? 'accesorio' : 'accesorios'}';

    final panel = TinaPanelFiltros(
      productos: todosDeLaCategoria,
      filtros: filtros,
      onCambio: onFiltros,
    );

    final orden = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in OrdenCatalogo.values)
          TinaChip(
            key: ValueKey('orden-${o.name}'),
            etiqueta: o.etiqueta,
            activo: filtros.orden == o,
            onTap: () => onFiltros(filtros.copyWith(orden: o)),
          ),
      ],
    );

    final grilla = productos.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              spacing: 14,
              children: [
                Text(
                  todosDeLaCategoria.isEmpty
                      ? 'Todavía no hay accesorios en esta categoría.'
                      : 'No hay accesorios con esos filtros.',
                  textAlign: TextAlign.center,
                  style: TinaTipografia.estilo(
                    tamano: 16,
                    color: TinaColores.marron,
                  ),
                ),
                if (filtros.hayFiltros)
                  SizedBox(
                    width: 240,
                    child: TinaBoton(
                      key: const ValueKey('sin-resultados-quitar'),
                      etiqueta: 'Quitar filtros',
                      onPressed: () => onFiltros(filtros.sinFiltros()),
                    ),
                  ),
              ],
            ),
          )
        : TinaGrillaProductos(
            productos: productos,
            onProducto: onProducto,
            columnasEscritorio: 3,
          );

    return TinaScaffold(
      titulo: grande ? null : categoriaActiva,
      conAtras: true,
      conPromo: true,
      activo: DestinoNav.categorias,
      unidadesCarrito: unidadesCarrito,
      onAtras: onAtras,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      cuerpo: TinaLista(
        arriba: 22,
        children: [
          Center(
            child: TinaCirculosCategorias(
              categorias: categorias,
              activa: categoriaActiva,
              onTap: onCategoria,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 14,
            children: [
              Flexible(
                child: Text(
                  categoriaActiva,
                  style: TinaTipografia.estilo(
                    tamano: 30,
                    peso: FontWeight.w800,
                    espaciado: -0.9,
                  ),
                ),
              ),
              Text(
                conteo,
                style: TinaTipografia.estilo(
                  tamano: 14,
                  color: TinaColores.marron,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (grande)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 34,
              children: [
                SizedBox(width: 240, child: panel),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 20,
                    children: [orden, grilla],
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TinaChip(
                    key: const ValueKey('abrir-filtros'),
                    etiqueta: filtrosVisibles ? 'Ocultar filtros' : 'Filtros',
                    conteo: filtros.activos == 0 ? null : filtros.activos,
                    activo: filtrosVisibles,
                    onTap: onAlternarFiltros,
                  ),
                ),
                if (filtrosVisibles)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: TinaColores.blanco.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: panel,
                  ),
                orden,
                grilla,
              ],
            ),
          const SizedBox(height: 44),
          TinaPiePagina(
            categorias: [for (final c in categorias) c.nombre],
            onCategoria: onCategoria,
            onLogo: onLogo,
          ),
        ],
      ),
    );
  }
}
