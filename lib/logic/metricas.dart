import '../models/models.dart';

/// Una fila de un ranking: un producto, un color o una ciudad con sus números.
class FilaRanking {
  const FilaRanking({
    required this.nombre,
    required this.valor,
    this.extra = 0,
  });

  final String nombre;

  /// Lo que ordena el ranking (unidades, recompras...).
  final int valor;

  /// Un segundo número, según el ranking (ventas en pesos, pedidos...).
  final int extra;
}

/// Los datos de los pedidos para tomar decisiones: qué se vende, qué se vuelve
/// a comprar, cada cuánto y dónde. Se calcula con los pedidos que ya están en
/// la app; no guarda nada.
///
/// Cómo se cuenta:
/// - Un pedido **válido** es cualquiera que no esté cancelado. Todo lo de
///   productos, colores, clientas y ciudades usa solo pedidos válidos.
/// - Un pedido está **cobrado** si ya pasó de "Pendiente de pago". Los pedidos
///   pendientes (por ejemplo una contraentrega por transferir) cuentan como
///   "por cobrar".
/// - Un pedido es una **recompra** si esa misma clienta ya tenía un pedido
///   válido antes.
class Metricas {
  const Metricas({
    required this.totalPedidos,
    required this.pedidosValidos,
    required this.pedidosPorEstado,
    required this.ventasProductos,
    required this.totalDescuentos,
    required this.pedidosConDescuento,
    required this.totalEnvios,
    required this.totalVendido,
    required this.cobrado,
    required this.porCobrar,
    required this.cancelado,
    required this.ticketPromedio,
    required this.productosMasVendidos,
    required this.productosMasRecomprados,
    required this.coloresMasVendidos,
    required this.clientas,
    required this.clientasRecurrentes,
    required this.diasPromedioRecompra,
    required this.diasMedianaRecompra,
    required this.ciudades,
    required this.pedidosPorMetodo,
  });

  /// Todos los pedidos, también los cancelados.
  final int totalPedidos;

  /// Los que no están cancelados.
  final int pedidosValidos;
  final Map<EstadoPedido, int> pedidosPorEstado;

  // ---- Balance general (en pesos), solo pedidos válidos.
  /// Lo que valen los artículos, antes de descuentos y envío.
  final int ventasProductos;
  final int totalDescuentos;
  final int pedidosConDescuento;
  final int totalEnvios;

  /// Productos − descuentos + envíos: lo que pagan las clientas.
  final int totalVendido;

  /// De eso, lo que ya se pagó.
  final int cobrado;

  /// De eso, lo que falta por pagar (pedidos pendientes).
  final int porCobrar;

  /// Lo que valían los pedidos cancelados (no suma al total vendido).
  final int cancelado;
  final int ticketPromedio;

  // ---- Productos.
  final List<FilaRanking> productosMasVendidos;

  /// `valor` son las recompras; `extra`, cuántas clientas lo recompraron.
  final List<FilaRanking> productosMasRecomprados;
  final List<FilaRanking> coloresMasVendidos;

  // ---- Clientas y recompra.
  final int clientas;
  final int clientasRecurrentes;

  /// Días entre un pedido y el siguiente de la misma clienta; `null` si nadie
  /// ha vuelto a comprar.
  final double? diasPromedioRecompra;
  final double? diasMedianaRecompra;

  /// Por ciudad, de más a menos recompras. `valor` son las recompras; `extra`,
  /// los pedidos de esa ciudad.
  final List<FilaRanking> ciudades;

  final Map<MetodoPago, int> pedidosPorMetodo;

  /// Qué parte de las clientas volvió a comprar (0 a 1).
  double get tasaRecompra => clientas == 0 ? 0 : clientasRecurrentes / clientas;

  int get recompras => ciudades.fold(0, (s, c) => s + c.valor);

  static const _cobrados = {
    EstadoPedido.pagado,
    EstadoPedido.preparacion,
    EstadoPedido.enviado,
    EstadoPedido.entregado,
  };

  static Metricas calcular({
    required List<Pedido> pedidos,
    required List<DetallePedido> detalles,
    required List<VarianteProducto> variantes,
    required List<Producto> productos,
    required List<Envio> envios,
    int tope = 5,
  }) {
    final variantePorId = {for (final v in variantes) v.idVariante: v};
    final productoPorId = {for (final p in productos) p.idProducto: p};
    final envioPorPedido = {for (final e in envios) e.idPedido: e};

    final porEstado = {for (final e in EstadoPedido.values) e: 0};
    final porMetodo = <MetodoPago, int>{};
    var ventasProductos = 0;
    var descuentos = 0;
    var conDescuento = 0;
    var costosEnvio = 0;
    var vendido = 0;
    var cobrado = 0;
    var porCobrar = 0;
    var cancelado = 0;

    final validos = <Pedido>[];
    for (final p in pedidos) {
      porEstado[p.estadoActual] = (porEstado[p.estadoActual] ?? 0) + 1;
      if (p.estadoActual == EstadoPedido.cancelado) {
        cancelado += p.total;
        continue;
      }
      validos.add(p);
      ventasProductos += p.subtotal;
      descuentos += p.descuento;
      if (p.descuento > 0) conDescuento++;
      costosEnvio += envioPorPedido[p.idPedido]?.costo ?? 0;
      vendido += p.total;
      if (_cobrados.contains(p.estadoActual)) {
        cobrado += p.total;
      } else {
        porCobrar += p.total;
      }
      porMetodo[p.metodoPago] = (porMetodo[p.metodoPago] ?? 0) + 1;
    }

    // Del más antiguo al más reciente: así se sabe qué es una recompra.
    validos.sort((a, b) {
      final f = a.fecha.compareTo(b.fecha);
      return f != 0 ? f : a.idPedido.compareTo(b.idPedido);
    });
    final idsValidos = {for (final p in validos) p.idPedido};
    final detallesValidos = [
      for (final d in detalles)
        if (idsValidos.contains(d.idPedido)) d,
    ];

    // ---- Productos y colores más vendidos.
    final unidadesProducto = <String, int>{};
    final ventasPorProducto = <String, int>{};
    final unidadesColor = <String, int>{};
    final nombreColor = <String, String>{};
    String nombreDe(DetallePedido d) {
      final v = variantePorId[d.idVariante];
      final p = v == null ? null : productoPorId[v.idProducto];
      return p?.nombre ?? 'Artículo que ya no está en la tienda';
    }

    for (final d in detallesValidos) {
      final nombre = nombreDe(d);
      unidadesProducto[nombre] = (unidadesProducto[nombre] ?? 0) + d.cantidad;
      ventasPorProducto[nombre] = (ventasPorProducto[nombre] ?? 0) + d.subtotal;
      final color = variantePorId[d.idVariante]?.color;
      if (color != null && color.trim().isNotEmpty) {
        final clave = claveColor(color);
        nombreColor.putIfAbsent(clave, () => color.trim());
        unidadesColor[clave] = (unidadesColor[clave] ?? 0) + d.cantidad;
      }
    }

    // ---- Recompra de productos: por clienta, en cuántos pedidos distintos
    // compró cada producto; todos los pedidos después del primero son recompras.
    final pedidosPorClienta = <int, List<Pedido>>{};
    for (final p in validos) {
      (pedidosPorClienta[p.idCliente] ??= []).add(p);
    }
    final idClientaDePedido = {
      for (final p in validos) p.idPedido: p.idCliente,
    };
    final pedidosDeProductoPorClienta = <String, Map<int, Set<int>>>{};
    for (final d in detallesValidos) {
      final nombre = nombreDe(d);
      final clienta = idClientaDePedido[d.idPedido]!;
      ((pedidosDeProductoPorClienta[nombre] ??= {})[clienta] ??= {}).add(
        d.idPedido,
      );
    }
    final recomprasProducto = <String, int>{};
    final clientasQueRecompraron = <String, int>{};
    pedidosDeProductoPorClienta.forEach((nombre, porClienta) {
      var recompras = 0;
      var quienes = 0;
      for (final pedidosDeLaClienta in porClienta.values) {
        if (pedidosDeLaClienta.length > 1) {
          recompras += pedidosDeLaClienta.length - 1;
          quienes++;
        }
      }
      if (recompras > 0) {
        recomprasProducto[nombre] = recompras;
        clientasQueRecompraron[nombre] = quienes;
      }
    });

    // ---- Tiempo entre compras y recompras por ciudad.
    final intervalos = <double>[];
    var recurrentes = 0;
    final pedidosPorCiudad = <String, int>{};
    final recomprasPorCiudad = <String, int>{};
    final nombreCiudad = <String, String>{};
    pedidosPorClienta.forEach((_, lista) {
      if (lista.length > 1) recurrentes++;
      for (var i = 0; i < lista.length; i++) {
        final ciudad = envioPorPedido[lista[i].idPedido]?.ciudad.trim() ?? '';
        if (ciudad.isNotEmpty) {
          final clave = ciudad.toLowerCase();
          nombreCiudad.putIfAbsent(clave, () => ciudad);
          pedidosPorCiudad[clave] = (pedidosPorCiudad[clave] ?? 0) + 1;
          if (i > 0) {
            recomprasPorCiudad[clave] = (recomprasPorCiudad[clave] ?? 0) + 1;
          }
        }
        if (i > 0) {
          intervalos.add(
            lista[i].fecha.difference(lista[i - 1].fecha).inMinutes / 1440,
          );
        }
      }
    });
    intervalos.sort();
    double? mediana;
    if (intervalos.isNotEmpty) {
      final m = intervalos.length ~/ 2;
      mediana = intervalos.length.isOdd
          ? intervalos[m]
          : (intervalos[m - 1] + intervalos[m]) / 2;
    }

    List<FilaRanking> top(
      Map<String, int> valores,
      FilaRanking Function(String clave, int valor) fila,
    ) {
      final claves = valores.keys.toList()
        ..sort((a, b) {
          final porValor = valores[b]!.compareTo(valores[a]!);
          return porValor != 0 ? porValor : a.compareTo(b);
        });
      return [for (final c in claves.take(tope)) fila(c, valores[c]!)];
    }

    return Metricas(
      totalPedidos: pedidos.length,
      pedidosValidos: validos.length,
      pedidosPorEstado: porEstado,
      ventasProductos: ventasProductos,
      totalDescuentos: descuentos,
      pedidosConDescuento: conDescuento,
      totalEnvios: costosEnvio,
      totalVendido: vendido,
      cobrado: cobrado,
      porCobrar: porCobrar,
      cancelado: cancelado,
      ticketPromedio: validos.isEmpty ? 0 : (vendido / validos.length).round(),
      productosMasVendidos: top(
        unidadesProducto,
        (n, u) =>
            FilaRanking(nombre: n, valor: u, extra: ventasPorProducto[n]!),
      ),
      productosMasRecomprados: top(
        recomprasProducto,
        (n, r) =>
            FilaRanking(nombre: n, valor: r, extra: clientasQueRecompraron[n]!),
      ),
      coloresMasVendidos: top(
        unidadesColor,
        (c, u) => FilaRanking(nombre: nombreColor[c]!, valor: u),
      ),
      clientas: pedidosPorClienta.length,
      clientasRecurrentes: recurrentes,
      diasPromedioRecompra: intervalos.isEmpty
          ? null
          : intervalos.reduce((a, b) => a + b) / intervalos.length,
      diasMedianaRecompra: mediana,
      ciudades: [
        for (final f
            in (recomprasPorCiudad.keys.toList()..sort((a, b) {
                  final r = recomprasPorCiudad[b]!.compareTo(
                    recomprasPorCiudad[a]!,
                  );
                  return r != 0
                      ? r
                      : pedidosPorCiudad[b]!.compareTo(pedidosPorCiudad[a]!);
                }))
                .take(tope))
          FilaRanking(
            nombre: nombreCiudad[f]!,
            valor: recomprasPorCiudad[f]!,
            extra: pedidosPorCiudad[f]!,
          ),
      ],
      pedidosPorMetodo: porMetodo,
    );
  }
}
