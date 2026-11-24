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
    this.onInicio,
    this.onCategoria,
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

  /// Para las migas de pan: ir al inicio y a la categoría del producto.
  final VoidCallback? onInicio;
  final ValueChanged<String>? onCategoria;

  @override
  Widget build(BuildContext context) {
    final producto = vista.producto;
    final stock = vista.stockDe(color, talla);
    // Al elegir un color se ven las fotos de ese color (o las generales).
    final fotos = vista.fotosPara(color);
    final volumen = promociones.where((p) => p.tipo == 'volumen').firstOrNull;

    return TinaScaffold(
      conAtras: true,
      conPromo: true,
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
            izquierda: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                TinaFotoProducto(
                  total: fotos.isEmpty ? 3 : fotos.length,
                  fotos: fotos,
                  actual: foto,
                  onCambiar: onFoto,
                ),
                if (fotos.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 10,
                      children: [
                        for (var i = 0; i < fotos.length; i++)
                          _Miniatura(
                            key: ValueKey('miniatura-$i'),
                            url: fotos[i],
                            activa: i == foto % fotos.length,
                            onTap: () => onFoto(i),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            derecha: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Migas(
                  categoria: vista.categoria,
                  nombre: producto.nombre,
                  onInicio: onInicio,
                  onCategoria: onCategoria,
                ),
                const SizedBox(height: 16),
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
                const _Puntos(),
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
                const SizedBox(height: 14),
                Text(
                  'Envío de \$5.000 a todo el país  ·  Pagos seguros con Wompi',
                  key: const ValueKey('detalle-envio-pagos'),
                  style: TinaTipografia.estilo(
                    tamano: 13,
                    peso: FontWeight.w700,
                    color: TinaColores.marron,
                  ),
                ),
                const SizedBox(height: 26),
                TinaPestanas(
                  pestanas: [
                    (
                      'Descripción',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text(
                            producto.descripcion,
                            style: TinaTipografia.estilo(
                              tamano: 15,
                              altura: 1.4,
                            ),
                          ),
                          if (producto.tecnica.trim().isNotEmpty)
                            Text(
                              'Técnica: ${producto.tecnica}',
                              style: TinaTipografia.estilo(
                                tamano: 13,
                                color: TinaColores.marron,
                              ),
                            ),
                        ],
                      ),
                    ),
                    (
                      'Envíos',
                      const _Texto(
                        'El envío cuesta \$5.000 a cualquier lugar del país. Si '
                        'estás en Cali puedes pedir contraentrega: te escribimos '
                        'por WhatsApp para coordinar la entrega, el pago es por '
                        'transferencia y no se cobra envío.',
                      ),
                    ),
                    (
                      'Cuidados',
                      const _Texto(
                        'Cada pieza está hecha a mano. Guárdala en un lugar seco, '
                        'sepárala de otras para que no se rayen y evita el '
                        'contacto con perfume, cremas y agua.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Inicio › Categoría › Producto, con los dos primeros tocables.
class _Migas extends StatelessWidget {
  const _Migas({
    required this.categoria,
    required this.nombre,
    this.onInicio,
    this.onCategoria,
  });

  final String categoria;
  final String nombre;
  final VoidCallback? onInicio;
  final ValueChanged<String>? onCategoria;

  @override
  Widget build(BuildContext context) {
    Widget enlace(String texto, VoidCallback? onTap, Key llave) =>
        GestureDetector(
          key: llave,
          onTap: onTap,
          child: Text(
            texto,
            style: TinaTipografia.estilo(
              tamano: 13,
              peso: FontWeight.w700,
              color: TinaColores.marron,
            ),
          ),
        );
    final separador = Text(
      '›',
      style: TinaTipografia.estilo(tamano: 13, color: TinaColores.marron),
    );
    return Wrap(
      key: const ValueKey('migas'),
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        enlace('Inicio', onInicio, const ValueKey('miga-inicio')),
        separador,
        enlace(
          categoria,
          onCategoria == null ? null : () => onCategoria!(categoria),
          const ValueKey('miga-categoria'),
        ),
        separador,
        Text(
          nombre,
          style: TinaTipografia.estilo(
            tamano: 13,
            peso: FontWeight.w700,
            color: TinaColores.naranja,
          ),
        ),
      ],
    );
  }
}

/// Tres ideas de la marca, cada una con su ícono.
class _Puntos extends StatelessWidget {
  const _Puntos();

  static const List<(IconData, String)> _items = [
    (Icons.back_hand_outlined, 'Hecho a mano, pieza por pieza'),
    (Icons.local_shipping_outlined, 'Envío a todo el país'),
    (Icons.chat_bubble_outline_rounded, 'Contraentrega en Cali'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('detalle-puntos'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (final (icono, texto) in _items)
          Row(
            spacing: 10,
            children: [
              Icon(icono, size: 20, color: TinaColores.naranja),
              Flexible(
                child: Text(texto, style: TinaTipografia.estilo(tamano: 14)),
              ),
            ],
          ),
      ],
    );
  }
}

class _Texto extends StatelessWidget {
  const _Texto(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) =>
      Text(texto, style: TinaTipografia.estilo(tamano: 15, altura: 1.4));
}

/// Foto pequeña debajo de la principal; la elegida lleva un borde naranja.
class _Miniatura extends StatelessWidget {
  const _Miniatura({
    super.key,
    required this.url,
    required this.activa,
    required this.onTap,
  });

  final String url;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: activa ? TinaColores.naranja : Colors.transparent,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: TinaImagenRed(url: url, radio: 13),
        ),
      ),
    );
  }
}
