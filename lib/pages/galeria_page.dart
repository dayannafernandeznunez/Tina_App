import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../theme/colores_producto.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

/// Galería de componentes de Tina. No guarda nada: muestra lo que le pasa la
/// Screen y avisa con callbacks.
class GaleriaPage extends StatelessWidget {
  const GaleriaPage({
    super.key,
    required this.productos,
    required this.categorias,
    required this.variantes,
    required this.color,
    required this.talla,
    required this.cantidad,
    required this.destino,
    required this.unidadesCarrito,
    required this.onColor,
    required this.onTalla,
    required this.onCantidad,
    required this.onDestino,
    required this.onAgregar,
  });

  final List<Producto> productos;
  final List<Categoria> categorias;
  final List<VarianteProducto> variantes;
  final String color;
  final String talla;
  final int cantidad;
  final DestinoNav destino;
  final int unidadesCarrito;
  final ValueChanged<String> onColor;
  final ValueChanged<String> onTalla;
  final ValueChanged<int> onCantidad;
  final ValueChanged<DestinoNav> onDestino;
  final VoidCallback onAgregar;

  List<Color> _coloresDe(Producto p) => {
    for (final v in variantes.where((v) => v.idProducto == p.idProducto))
      v.color,
  }.map(colorDeProducto).toList();

  String _categoriaDe(Producto p) =>
      categorias.firstWhere((c) => c.idCategoria == p.idCategoria).nombre;

  @override
  Widget build(BuildContext context) {
    final muestra = productos.take(2).toList();
    return Scaffold(
      appBar: TinaBarraSuperior(
        carrito: unidadesCarrito,
        onCarrito: onAgregar,
        onLogo: () {},
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Galería de componentes',
            style: TinaTipografia.serif(tamano: 34, color: TinaColores.rojo),
          ),
          _Seccion(
            titulo: 'Botones',
            hijos: [
              TinaBoton(etiqueta: 'Agregar al carrito', onPressed: onAgregar),
              TinaBoton(
                etiqueta: 'Ver accesorios',
                variante: VarianteBoton.secundario,
                onPressed: () {},
              ),
            ],
          ),
          const _Seccion(
            titulo: 'Campos',
            hijos: [
              TinaCampo(etiqueta: 'Correo', placeholder: 'tu@correo.com'),
              TinaCampo(
                etiqueta: 'Contraseña',
                tipo: TipoCampo.contrasena,
                placeholder: 'Mínimo 8 caracteres',
              ),
            ],
          ),
          _Seccion(
            titulo: 'Tarjetas de producto',
            hijos: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  for (final p in muestra)
                    Expanded(
                      child: TinaTarjetaProducto(
                        nombre: p.nombre,
                        precio: formatoPesos(p.precio),
                        categoria: _categoriaDe(p),
                        colores: _coloresDe(p),
                        onTap: () {},
                      ),
                    ),
                ],
              ),
            ],
          ),
          _Seccion(
            titulo: 'Selectores',
            hijos: [
              TinaSelectorColor(
                opciones: const [
                  OpcionColor(nombre: 'Naranja', color: Color(0xFFFF6A00)),
                  OpcionColor(nombre: 'Blanco', color: Color(0xFFFFFFFF)),
                  OpcionColor(nombre: 'Beige', color: Color(0xFFD8C09A)),
                ],
                valor: color,
                onChanged: onColor,
              ),
              TinaSelectorTalla(
                opciones: const ['S', 'M', 'L'],
                valor: talla,
                onChanged: onTalla,
              ),
              Row(
                spacing: 12,
                children: [
                  Text(
                    'Cantidad',
                    style: TinaTipografia.estilo(
                      tamano: 15,
                      peso: FontWeight.w800,
                    ),
                  ),
                  TinaSelectorCantidad(valor: cantidad, onChanged: onCantidad),
                ],
              ),
            ],
          ),
          const _Seccion(
            titulo: 'Etiquetas de descuento',
            hijos: [
              Align(
                alignment: Alignment.centerLeft,
                child: TinaEtiquetaDescuento(
                  texto: '20% en tu primera compra con cuenta',
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TinaEtiquetaDescuento(
                  texto: '30% si compras 14 o más unidades',
                  tono: TonoEtiqueta.suave,
                ),
              ),
            ],
          ),
          const _Seccion(
            titulo: 'Filas de resumen',
            hijos: [
              TinaFilaResumen(
                etiqueta: 'Pulsera tejida ×3',
                detalle: 'Beige · Talla M',
                valor: r'$51.000',
              ),
              TinaFilaResumen(etiqueta: 'Subtotal', valor: r'$51.000'),
              TinaFilaResumen(
                etiqueta: 'Descuento 20% (primera compra con cuenta)',
                valor: r'−$10.200',
                tipo: TipoFila.descuento,
              ),
              TinaFilaResumen(
                etiqueta: 'Total',
                valor: r'$40.800',
                tipo: TipoFila.total,
              ),
            ],
          ),
          _Seccion(
            titulo: 'Estado del pedido',
            hijos: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in EstadoPedido.values)
                    TinaEstadoPedido(estado: e),
                ],
              ),
              const TinaEstadoPedido(
                estado: EstadoPedido.pagado,
                modo: ModoEstado.mensaje,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: TinaNavInferior(
        activo: destino,
        carrito: unidadesCarrito,
        onNav: onDestino,
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Text(
            titulo.toUpperCase(),
            style: TinaTipografia.estilo(
              tamano: 12,
              peso: FontWeight.w800,
              color: TinaColores.marron,
              espaciado: 1.2,
            ),
          ),
          ...hijos,
        ],
      ),
    );
  }
}
