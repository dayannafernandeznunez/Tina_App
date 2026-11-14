import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/vistas.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

/// Panel de la vendedora, sección "Productos": todos los productos con su
/// stock, para crear uno nuevo, editarlo u ocultarlo de la tienda. No guarda
/// nada.
class PanelProductosPage extends StatelessWidget {
  const PanelProductosPage({
    super.key,
    required this.productos,
    required this.ocupado,
    required this.onSeccion,
    required this.onNuevo,
    required this.onEditar,
    required this.onAlternar,
    required this.onVerTienda,
    this.onSalir,
  });

  /// Todos los productos, también los ocultos.
  final List<ProductoVista> productos;
  final bool ocupado;
  final ValueChanged<SeccionPanel> onSeccion;
  final VoidCallback onNuevo;
  final ValueChanged<int> onEditar;
  final ValueChanged<int> onAlternar;
  final VoidCallback onVerTienda;
  final VoidCallback? onSalir;

  @override
  Widget build(BuildContext context) {
    final visibles = productos.where((p) => p.producto.activo).length;
    return TinaScaffold(
      titulo: 'Panel de vendedora',
      conAtras: true,
      conCarrito: false,
      onAtras: onVerTienda,
      onLogo: onVerTienda,
      cuerpo: TinaLista(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Productos',
                style: TinaTipografia.estilo(
                  tamano: 28,
                  peso: FontWeight.w800,
                  espaciado: -0.84,
                ),
              ),
              Text(
                '${productos.length} productos · $visibles visibles',
                key: const ValueKey('resumen-productos'),
                style: TinaTipografia.estilo(
                  tamano: 14,
                  color: TinaColores.marron,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TinaPanelSecciones(
            activa: SeccionPanel.productos,
            onSeccion: onSeccion,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TinaBoton(
                key: const ValueKey('nuevo-producto'),
                etiqueta: 'Nuevo producto',
                onPressed: onNuevo,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (productos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(
                'Todavía no hay productos. ¡Crea el primero!',
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 15,
                  color: TinaColores.marron,
                ),
              ),
            )
          else
            TinaRejilla(
              anchoMinimo: 420,
              children: [
                for (final p in productos)
                  TinaProductoAdmin(
                    key: ValueKey('prod-admin-${p.producto.idProducto}'),
                    nombre: p.producto.nombre,
                    detalle:
                        '${p.categoria} · ${formatoPesos(p.producto.precio)}',
                    stock: p.variantes.fold(0, (s, v) => s + v.stock),
                    visible: p.producto.activo,
                    ocupado: ocupado,
                    onEditar: () => onEditar(p.producto.idProducto),
                    onAlternar: () => onAlternar(p.producto.idProducto),
                  ),
              ],
            ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                spacing: 12,
                children: [
                  TinaBoton(
                    etiqueta: 'Ver tienda',
                    variante: VarianteBoton.secundario,
                    onPressed: onVerTienda,
                  ),
                  if (onSalir != null)
                    TinaBoton(
                      etiqueta: 'Cerrar sesión',
                      variante: VarianteBoton.secundario,
                      onPressed: onSalir!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
