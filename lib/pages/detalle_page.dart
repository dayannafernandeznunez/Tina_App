import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/vistas.dart';
import '../models/models.dart';
import '../theme/colores_producto.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

/// Detalle de un producto: fotos, descripción y selección de color, talla y
/// cantidad. La selección la guarda la Screen; esta Page solo la muestra.
class DetallePage extends StatelessWidget {
  const DetallePage({
    super.key,
    required this.vista,
    required this.promociones,
    required this.color,
    required this.talla,
    required this.cantidad,
    required this.foto,
    required this.unidadesCarrito,
    required this.onAtras,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
    required this.onColor,
    required this.onTalla,
    required this.onCantidad,
    required this.onFoto,
    required this.onAgregar,
  });

  final ProductoVista vista;
  final List<Promocion> promociones;
  final String color;
  final String talla;
  final int cantidad;
  final int foto;
  final int unidadesCarrito;
  final VoidCallback onAtras;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;
  final ValueChanged<String> onColor;
  final ValueChanged<String> onTalla;
  final ValueChanged<int> onCantidad;
  final ValueChanged<int> onFoto;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final producto = vista.producto;
    final stock = vista.stockDe(color, talla);
    final volumen = promociones.where((p) => p.tipo == 'volumen').firstOrNull;

    return TinaScaffold(
      conAtras: true,
      unidadesCarrito: unidadesCarrito,
      onAtras: onAtras,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      accion: stock == 0
          ? TinaBoton(
              etiqueta: 'Agotado',
              variante: VarianteBoton.secundario,
              onPressed: () {},
            )
          : TinaBoton(
              etiqueta:
                  'Agregar al carrito · ${formatoPesos(producto.precio * cantidad)}',
              onPressed: onAgregar,
            ),
      cuerpo: TinaLista(
        arriba: 18,
        children: [
          TinaDosColumnas(
            flexIzquierda: 5,
            flexDerecha: 6,
            izquierda: TinaFotoProducto(
              total: vista.fotos.isEmpty ? 3 : vista.fotos.length,
              fotos: vista.fotos,
              actual: foto,
              onCambiar: onFoto,
            ),
            derecha: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vista.categoria.toUpperCase(),
                  style: TinaTipografia.estilo(
                    tamano: 12,
                    peso: FontWeight.w800,
                    color: TinaColores.rojo,
                    espaciado: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  producto.nombre,
                  style: TinaTipografia.estilo(
                    tamano: 26,
                    peso: FontWeight.w800,
                    espaciado: -0.52,
                    altura: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatoPesos(producto.precio),
                  style: TinaTipografia.estilo(
                    tamano: 24,
                    peso: FontWeight.w800,
                    color: TinaColores.naranja,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  producto.descripcion,
                  style: TinaTipografia.estilo(tamano: 15, altura: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Técnica: ${producto.tecnica}',
                  style: TinaTipografia.estilo(
                    tamano: 13,
                    color: TinaColores.marron,
                  ),
                ),
                const SizedBox(height: 22),
                TinaSelectorColor(
                  opciones: [
                    for (final c in vista.colores)
                      OpcionColor(nombre: c, color: colorDeProducto(c)),
                  ],
                  valor: color,
                  onChanged: onColor,
                ),
                const SizedBox(height: 18),
                TinaSelectorTalla(
                  opciones: vista.tallasDe(color),
                  valor: talla,
                  onChanged: onTalla,
                ),
                const SizedBox(height: 18),
                Row(
                  spacing: 14,
                  children: [
                    Text(
                      'Cantidad',
                      style: TinaTipografia.estilo(
                        tamano: 15,
                        peso: FontWeight.w800,
                      ),
                    ),
                    TinaSelectorCantidad(
                      valor: cantidad,
                      maximo: stock < 1 ? 1 : stock,
                      onChanged: onCantidad,
                    ),
                    Expanded(
                      child: Text(
                        stock == 0
                            ? 'Agotado'
                            : stock <= 5
                            ? 'Quedan $stock'
                            : '$stock disponibles',
                        textAlign: TextAlign.end,
                        style: TinaTipografia.estilo(
                          tamano: 13,
                          peso: FontWeight.w800,
                          color: stock == 0
                              ? TinaColores.rojo
                              : TinaColores.marron,
                        ),
                      ),
                    ),
                  ],
                ),
                if (volumen != null) ...[
                  const SizedBox(height: 18),
                  TinaEtiquetaDescuento(
                    texto: volumen.nombre,
                    tono: TonoEtiqueta.suave,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
