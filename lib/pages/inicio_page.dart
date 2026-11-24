import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/vistas.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';

/// Portada de la tienda: la portada de marca, lo que da confianza, las
/// categorías, una sección de productos por categoría y el pie de página.
class InicioPage extends StatelessWidget {
  const InicioPage({
    super.key,
    required this.productos,
    required this.categorias,
    required this.promociones,
    required this.unidadesCarrito,
    required this.onProducto,
    required this.onCategoria,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
    this.fotoPortada,
  });

  /// Foto de la portada que sube la administradora (puede no haber ninguna).
  final String? fotoPortada;

  final List<ProductoVista> productos;
  final List<String> categorias;
  final List<Promocion> promociones;
  final int unidadesCarrito;
  final ValueChanged<int> onProducto;

  /// `null` significa "Todos".
  final ValueChanged<String?> onCategoria;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;

  /// Cuántos productos se ven de cada categoría antes de "Ver más opciones".
  static const int porSeccion = 4;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final c in categorias)
        ItemCategoria(
          nombre: c,
          foto: productos
              .where((p) => p.categoria == c && p.fotos.isNotEmpty)
              .map((p) => p.fotos.first)
              .firstOrNull,
        ),
    ];
    final secciones = [
      for (final c in categorias)
        (c, productos.where((p) => p.categoria == c && p.producto.activo)),
    ].where((s) => s.$2.isNotEmpty).toList();

    return TinaScaffold(
      activo: DestinoNav.inicio,
      conPromo: true,
      unidadesCarrito: unidadesCarrito,
      onNav: onNav,
      onCarrito: onCarrito,
      onLogo: onLogo,
      cuerpo: TinaLista(
        children: [
          TinaHero(
            foto: fotoPortada,
            linea1: 'Tan latinas',
            linea2: 'como tú',
            subtitulo: 'Accesorios hechos a mano, uno por uno.',
            onComprar: secciones.isEmpty
                ? null
                : () => onCategoria(secciones.first.$1),
          ),
          const SizedBox(height: 16),
          const TinaCintaConfianza(),
          const SizedBox(height: 34),
          Center(
            child: Text(
              'Encuentra el accesorio perfecto para cada ocasión.',
              textAlign: TextAlign.center,
              style: TinaTipografia.estilo(
                tamano: 15,
                color: TinaColores.marron,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TinaCirculosCategorias(
              categorias: items,
              onTap: onCategoria,
              mostrarTodos: false,
            ),
          ),
          for (var i = 0; i < secciones.length; i++) ...[
            const SizedBox(height: 42),
            TinaTituloSeccion(
              titulo: secciones[i].$1,
              subtitulo: 'Hechas a mano, una por una',
            ),
            const SizedBox(height: 18),
            TinaGrillaProductos(
              productos: secciones[i].$2.take(porSeccion).toList(),
              onProducto: onProducto,
            ),
            if (secciones[i].$2.length > porSeccion) ...[
              const SizedBox(height: 22),
              Center(
                child: _VerMas(
                  key: ValueKey('ver-mas-${secciones[i].$1}'),
                  onTap: () => onCategoria(secciones[i].$1),
                ),
              ),
            ],
            if (i == 0 && secciones.length > 1) ...[
              const SizedBox(height: 46),
              const TinaTituloSeccion(titulo: 'Explora por categoría'),
              const SizedBox(height: 18),
              TinaMosaicoCategorias(
                categorias: items,
                onTap: (c) => onCategoria(c),
              ),
            ],
          ],
          if (promociones.any((p) => p.activa)) ...[
            const SizedBox(height: 46),
            const TinaTituloSeccion(titulo: 'Beneficios Tina'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final promo in promociones.where((p) => p.activa))
                  TinaEtiquetaDescuento(
                    texto: promo.nombre,
                    tono: promo.tipo == 'primera_compra'
                        ? TonoEtiqueta.fuerte
                        : TonoEtiqueta.suave,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 46),
          const TinaGarantias(),
          const SizedBox(height: 40),
          TinaPiePagina(
            categorias: categorias,
            onCategoria: onCategoria,
            onLogo: onLogo,
          ),
        ],
      ),
    );
  }
}

/// Botón "Ver más opciones →" con borde, como el de las colecciones.
class _VerMas extends StatelessWidget {
  const _VerMas({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver más opciones',
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            decoration: BoxDecoration(
              color: encima ? TinaColores.naranja : TinaColores.blanco,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Ver más opciones →',
              style: TinaTipografia.estilo(
                tamano: 15,
                peso: FontWeight.w800,
                color: encima ? TinaColores.blanco : TinaColores.naranja,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
