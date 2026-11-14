import '../models/models.dart';

/// Un producto con su categoría y sus variantes, listo para mostrar.
class ProductoVista {
  const ProductoVista({
    required this.producto,
    required this.categoria,
    required this.variantes,
    this.fotos = const [],
  });

  final Producto producto;
  final String categoria;
  final List<VarianteProducto> variantes;

  /// Direcciones de las fotos, en el orden que eligió la administradora.
  final List<String> fotos;

  /// Colores distintos, en el orden en que aparecen las variantes.
  List<String> get colores => [
    ...{for (final v in variantes) v.color},
  ];

  List<String> tallasDe(String color) => [
    for (final v in variantes)
      if (v.color == color) v.talla,
  ];

  VarianteProducto? variante(String color, String talla) {
    for (final v in variantes) {
      if (v.color == color && v.talla == talla) return v;
    }
    return null;
  }

  int stockDe(String color, String talla) => variante(color, talla)?.stock ?? 0;
}

class LineaPedido {
  const LineaPedido({
    required this.nombre,
    required this.color,
    required this.talla,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  final String nombre;
  final String color;
  final String talla;
  final int cantidad;
  final int precioUnitario;
  final int subtotal;

  String get variante => talla == 'Única' ? color : '$color · Talla $talla';
}

class EntradaHistorial {
  const EntradaHistorial({
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.fecha,
    required this.quien,
    required this.notificado,
  });

  final String? estadoAnterior;
  final String estadoNuevo;
  final DateTime fecha;
  final String quien;
  final bool notificado;
}

/// Un pedido con todo lo que lo rodea: clienta, líneas, envío, pago,
/// comprobante e historial.
class PedidoCompleto {
  const PedidoCompleto({
    required this.pedido,
    required this.cliente,
    required this.lineas,
    required this.envio,
    required this.pago,
    required this.comprobante,
    required this.historial,
  });

  final Pedido pedido;
  final Cliente cliente;
  final List<LineaPedido> lineas;
  final Envio envio;
  final Pago? pago;
  final Comprobante? comprobante;
  final List<EntradaHistorial> historial;

  String get resumenProductos => lineas
      .map(
        (l) =>
            '${l.nombre}${l.talla == 'Única' ? '' : ' (${l.talla})'} ×${l.cantidad}',
      )
      .join(', ');
}

/// Junta las tablas sueltas en pedidos completos, del más reciente al más
/// antiguo.
List<PedidoCompleto> armarPedidos({
  required List<Pedido> pedidos,
  required List<DetallePedido> detalles,
  required List<VarianteProducto> variantes,
  required List<Producto> productos,
  required List<Cliente> clientes,
  required List<Envio> envios,
  required List<Pago> pagos,
  required List<Comprobante> comprobantes,
  required List<HistorialEstado> historial,
  required List<Usuario> usuarios,
}) {
  final variantePorId = {for (final v in variantes) v.idVariante: v};
  final productoPorId = {for (final p in productos) p.idProducto: p};
  final clientePorId = {for (final c in clientes) c.idCliente: c};
  final usuarioPorId = {for (final u in usuarios) u.idUsuario: u};

  // Si la administradora borra un artículo, los pedidos que lo incluían siguen
  // mostrándose: el precio y la cantidad quedaron guardados en el pedido.
  LineaPedido lineaDe(DetallePedido d) {
    final variante = variantePorId[d.idVariante];
    final producto = variante == null
        ? null
        : productoPorId[variante.idProducto];
    return LineaPedido(
      nombre: producto?.nombre ?? 'Artículo que ya no está en la tienda',
      color: variante?.color ?? '',
      talla: variante?.talla ?? 'Única',
      cantidad: d.cantidad,
      precioUnitario: d.precioUnitario,
      subtotal: d.subtotal,
    );
  }

  final ordenados = [...pedidos]
    ..sort((a, b) {
      final porFecha = b.fecha.compareTo(a.fecha);
      return porFecha != 0 ? porFecha : b.idPedido.compareTo(a.idPedido);
    });

  return [
    for (final pedido in ordenados)
      () {
        final pago = pagos
            .where((p) => p.idPedido == pedido.idPedido)
            .firstOrNull;
        final entradas =
            historial.where((h) => h.idPedido == pedido.idPedido).toList()
              ..sort((a, b) => a.fecha.compareTo(b.fecha));
        return PedidoCompleto(
          pedido: pedido,
          cliente: clientePorId[pedido.idCliente]!,
          lineas: [
            for (final d in detalles.where(
              (d) => d.idPedido == pedido.idPedido,
            ))
              lineaDe(d),
          ],
          envio: envios.firstWhere((e) => e.idPedido == pedido.idPedido),
          pago: pago,
          comprobante: pago == null
              ? null
              : comprobantes.where((c) => c.idPago == pago.idPago).firstOrNull,
          historial: [
            for (final h in entradas)
              EntradaHistorial(
                estadoAnterior: h.estadoAnterior,
                estadoNuevo: h.estadoNuevo,
                fecha: h.fecha,
                quien: usuarioPorId[h.idUsuario]?.nombre ?? 'Sistema',
                notificado: h.notificado,
              ),
          ],
        );
      }(),
  ];
}
