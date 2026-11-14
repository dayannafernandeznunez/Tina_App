import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/vistas.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';

/// Portada: eslogan, categorías y todos los productos.
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

  @override
  Widget build(BuildContext context) {
    return TinaScaffold(
      activo: DestinoNav.inicio,
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
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                TinaChip(
                  key: const ValueKey('chip-Todos'),
                  etiqueta: 'Todos',
                  activo: true,
                  onTap: () => onCategoria(null),
                ),
                for (final c in categorias)
                  TinaChip(
                    key: ValueKey('chip-$c'),
                    etiqueta: c,
                    activo: false,
                    onTap: () => onCategoria(c),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Todos los accesorios',
            style: TinaTipografia.estilo(
              tamano: 22,
              peso: FontWeight.w800,
              espaciado: -0.44,
            ),
          ),
          const SizedBox(height: 14),
          TinaGrillaProductos(productos: productos, onProducto: onProducto),
          const SizedBox(height: 28),
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
      ),
    );
  }
}
