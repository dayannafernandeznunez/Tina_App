import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/charm_bar.dart';
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
    this.fotoBannerCharmBar,
    this.colecciones = const [],
    this.onColeccion,
    this.enlaces = const EnlacesTienda(),
  });

  /// Las colecciones visibles (con su foto) y a dónde lleva cada una.
  final List<ItemCategoria> colecciones;
  final ValueChanged<String>? onColeccion;

  /// Foto del banner "Arma tu collar" (la sube la administradora).
  final String? fotoBannerCharmBar;

  /// El Charm Bar, las colecciones y el buscador.
  final EnlacesTienda enlaces;

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
    // El collar base del Charm Bar no se vende suelto: tiene su propio armador.
    final secciones = [
      for (final c in categorias)
        if (c != CharmBar.categoriaBase)
          (c, productos.where((p) => p.categoria == c && p.producto.activo)),
    ].where((s) => s.$2.isNotEmpty).toList();

    return TinaScaffold(
      activo: DestinoNav.inicio,
      conPromo: true,
      enlaces: enlaces,
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
          if (colecciones.isNotEmpty && onColeccion != null) ...[
            const SizedBox(height: 46),
            TinaTituloSeccion(
              titulo: 'Colecciones',
              subtitulo: 'Piezas que van juntas',
              key: const ValueKey('titulo-colecciones'),
            ),
            const SizedBox(height: 18),
            TinaMosaicoCategorias(
              key: const ValueKey('mosaico-colecciones'),
              categorias: colecciones,
              onTap: onColeccion!,
            ),
          ],
          if (enlaces.onCharmBar != null) ...[
            const SizedBox(height: 46),
            _BannerCharmBar(
              foto: fotoBannerCharmBar,
              onTap: enlaces.onCharmBar!,
            ),
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
            enlaces: enlaces,
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

/// El banner grande "Arma tu collar": foto de la administradora o, mientras no
/// la haya, el diseño de marca. Lleva al Charm Bar.
class _BannerCharmBar extends StatelessWidget {
  const _BannerCharmBar({required this.onTap, this.foto});

  final String? foto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(
          'ARMA TU COLLAR',
          style: TinaTipografia.estilo(
            tamano: 13,
            peso: FontWeight.w800,
            color: TinaColores.blanco,
            espaciado: 1.4,
          ),
        ),
        Text(
          'Charm Bar',
          style: TinaTipografia.estilo(
            tamano: 36,
            peso: FontWeight.w800,
            color: TinaColores.blanco,
            espaciado: -1.2,
          ),
        ),
        Text(
          'Elige el collar, elige tus charms y hazlo único.',
          style: TinaTipografia.serif(tamano: 20, color: TinaColores.blanco),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          key: const ValueKey('banner-charm-bar'),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
            decoration: BoxDecoration(
              color: TinaColores.blanco,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Quiero ver más',
              style: TinaTipografia.estilo(
                tamano: 15,
                peso: FontWeight.w800,
                color: TinaColores.naranja,
              ),
            ),
          ),
        ),
      ],
    );
    if (foto == null) {
      return TinaEncabezadoMarca(child: contenido);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: AspectRatio(
        aspectRatio: 2.4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TinaImagenRed(url: foto!, radio: 0),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC2A1608), Color(0x002A1608)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Align(alignment: Alignment.bottomLeft, child: contenido),
            ),
          ],
        ),
      ),
    );
  }
}
