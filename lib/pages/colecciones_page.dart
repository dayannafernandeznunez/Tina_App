import 'package:flutter/material.dart';

import '../components/components.dart';
import '../theme/tina_tema.dart';

/// Las colecciones de la tienda, como fotos grandes. No guarda nada.
class ColeccionesPage extends StatelessWidget {
  const ColeccionesPage({
    super.key,
    required this.colecciones,
    required this.unidadesCarrito,
    required this.onColeccion,
    required this.onAtras,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
    this.enlaces = const EnlacesTienda(),
  });

  final List<ItemCategoria> colecciones;
  final int unidadesCarrito;
  final ValueChanged<String> onColeccion;
  final VoidCallback onAtras;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;
  final EnlacesTienda enlaces;

  @override
  Widget build(BuildContext context) {
    return TinaScaffold(
      titulo: 'Colecciones',
      conAtras: true,
      conPromo: true,
      activo: DestinoNav.categorias,
      enlaces: enlaces,
      unidadesCarrito: unidadesCarrito,
      onAtras: onAtras,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      cuerpo: TinaLista(
        arriba: 22,
        children: [
          const TinaTituloSeccion(
            titulo: 'Colecciones',
            subtitulo: 'Piezas que van juntas',
          ),
          const SizedBox(height: 22),
          if (colecciones.isEmpty)
            Padding(
              key: const ValueKey('sin-colecciones'),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'Pronto vas a ver aquí nuestras colecciones.',
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 16,
                  color: TinaColores.marron,
                ),
              ),
            )
          else
            TinaMosaicoCategorias(categorias: colecciones, onTap: onColeccion),
        ],
      ),
    );
  }
}
