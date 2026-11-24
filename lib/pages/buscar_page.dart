import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/vistas.dart';
import '../theme/tina_tema.dart';

/// Buscador de la tienda: se escribe y salen los accesorios que coinciden.
/// No guarda nada: lo escrito y los resultados los da la Screen.
class BuscarPage extends StatelessWidget {
  const BuscarPage({
    super.key,
    required this.consulta,
    required this.resultados,
    required this.sugerencias,
    required this.unidadesCarrito,
    required this.onConsulta,
    required this.onProducto,
    required this.onAtras,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
    this.enlaces = const EnlacesTienda(),
  });

  final String consulta;
  final List<ProductoVista> resultados;

  /// Palabras para probar cuando todavía no se escribió nada (las categorías).
  final List<String> sugerencias;
  final int unidadesCarrito;
  final ValueChanged<String> onConsulta;
  final ValueChanged<int> onProducto;
  final VoidCallback onAtras;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;
  final EnlacesTienda enlaces;

  @override
  Widget build(BuildContext context) {
    final escribio = consulta.trim().isNotEmpty;
    return TinaScaffold(
      titulo: 'Buscar',
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
          TinaCampo(
            key: const ValueKey('buscar-campo'),
            etiqueta: '¿Qué estás buscando?',
            placeholder: 'Aretes, collar, naranja...',
            valor: consulta,
            onChanged: onConsulta,
          ),
          const SizedBox(height: 22),
          if (!escribio) ...[
            Text(
              'Prueba con:',
              style: TinaTipografia.estilo(
                tamano: 14,
                color: TinaColores.marron,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in sugerencias)
                  TinaChip(
                    key: ValueKey('sugerencia-$s'),
                    etiqueta: s,
                    activo: false,
                    onTap: () => onConsulta(s),
                  ),
              ],
            ),
          ] else if (resultados.isEmpty)
            Padding(
              key: const ValueKey('buscar-sin-resultados'),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No encontramos accesorios con "${consulta.trim()}". '
                'Prueba con otra palabra.',
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 16,
                  color: TinaColores.marron,
                ),
              ),
            )
          else ...[
            Text(
              '${resultados.length} '
              '${resultados.length == 1 ? 'resultado' : 'resultados'}',
              key: const ValueKey('buscar-conteo'),
              style: TinaTipografia.estilo(
                tamano: 14,
                color: TinaColores.marron,
              ),
            ),
            const SizedBox(height: 16),
            TinaGrillaProductos(productos: resultados, onProducto: onProducto),
          ],
        ],
      ),
    );
  }
}
