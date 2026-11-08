import '../models/models.dart';

/// Una línea del carrito con la variante y el producto ya resueltos.
class LineaCarrito {
  const LineaCarrito({
    required this.item,
    required this.variante,
    required this.producto,
  });

  final CarritoItem item;
  final VarianteProducto variante;
  final Producto producto;

  int get total => producto.precio * item.cantidad;
}

/// Subtotal, descuento y total de un carrito.
class ResumenCarrito {
  const ResumenCarrito({
    required this.lineas,
    required this.unidades,
    required this.subtotal,
    required this.porcentaje,
    required this.descuento,
    this.promocion,
  });

  final List<LineaCarrito> lineas;
  final int unidades;
  final int subtotal;
  final int porcentaje;
  final int descuento;
  final Promocion? promocion;

  int get total => subtotal - descuento;
  bool get vacio => lineas.isEmpty;
}

/// Reglas de negocio que no dependen de la pantalla: se pueden probar solas.
class Calculos {
  Calculos._();

  /// Arma el resumen de un carrito. Si dos promociones aplican a la vez, se
  /// toma la de mayor porcentaje y no se acumulan (pregunta abierta PA-1).
  static ResumenCarrito resumen({
    required List<CarritoItem> items,
    required List<VarianteProducto> variantes,
    required List<Producto> productos,
    required List<Promocion> promociones,
    required bool primeraCompra,
  }) {
    final variantePorId = {for (final v in variantes) v.idVariante: v};
    final productoPorId = {for (final p in productos) p.idProducto: p};

    final lineas = [
      for (final item in items)
        LineaCarrito(
          item: item,
          variante: variantePorId[item.idVariante]!,
          producto: productoPorId[variantePorId[item.idVariante]!.idProducto]!,
        ),
    ];
    final unidades = lineas.fold<int>(0, (s, l) => s + l.item.cantidad);
    final subtotal = lineas.fold<int>(0, (s, l) => s + l.total);

    Promocion? elegida;
    for (final promo in promociones.where((p) => p.activa)) {
      final aplica = switch (promo.tipo) {
        'volumen' => unidades >= promo.cantidadMinima,
        'primera_compra' => primeraCompra && unidades >= 1,
        _ => false,
      };
      if (aplica &&
          (elegida == null || promo.porcentaje > elegida.porcentaje)) {
        elegida = promo;
      }
    }

    final porcentaje = elegida?.porcentaje ?? 0;
    return ResumenCarrito(
      lineas: lineas,
      unidades: unidades,
      subtotal: subtotal,
      porcentaje: porcentaje,
      descuento: (subtotal * porcentaje / 100).round(),
      promocion: elegida,
    );
  }

  /// Una clienta tiene derecho al descuento de primera compra si no tiene
  /// ningún pedido pagado: los pendientes y cancelados no cuentan.
  static bool esPrimeraCompra(int idCliente, List<Pedido> pedidos) {
    return !pedidos.any(
      (p) =>
          p.idCliente == idCliente &&
          p.estadoActual != EstadoPedido.pendiente &&
          p.estadoActual != EstadoPedido.cancelado,
    );
  }

  /// Costo de envío de prueba: $9.000 en Cali y $12.000 al resto del país.
  /// La regla real está pendiente (PA-2).
  static int costoEnvio(String ciudad) =>
      ciudad.trim().toLowerCase() == 'cali' ? 9000 : 12000;

  /// Texto que explica cuánto falta para el descuento por volumen.
  static String notaDescuento({
    required ResumenCarrito resumen,
    required List<Promocion> promociones,
    required bool conCuenta,
  }) {
    final volumen = promociones.firstWhere((p) => p.tipo == 'volumen');
    final primera = promociones.firstWhere((p) => p.tipo == 'primera_compra');
    if (resumen.unidades >= volumen.cantidadMinima) {
      return 'Ya tienes ${volumen.cantidadMinima} o más unidades: '
          'el ${volumen.porcentaje}% está aplicado.';
    }
    final faltan = volumen.cantidadMinima - resumen.unidades;
    final unidad = faltan == 1 ? 'unidad' : 'unidades';
    final sobreCuenta = conCuenta
        ? ' El ${primera.porcentaje}% ya está aplicado.'
        : ' El ${primera.porcentaje}% se aplica si compras con cuenta.';
    return 'Te faltan $faltan $unidad para el ${volumen.porcentaje}%.$sobreCuenta';
  }
}
