import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/logic/metricas.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/pages/panel_datos_page.dart';
import 'package:tina_app/theme/tina_tema.dart';

const _productos = [
  Producto(
    idProducto: 1,
    idCategoria: 1,
    nombre: 'Collar',
    descripcion: '',
    tecnica: '',
    precio: 40000,
  ),
  Producto(
    idProducto: 2,
    idCategoria: 2,
    nombre: 'Aretes',
    descripcion: '',
    tecnica: '',
    precio: 18000,
  ),
];

const _variantes = [
  VarianteProducto(
    idVariante: 1,
    idProducto: 1,
    color: 'Naranja',
    talla: 'Única',
    stock: 9,
  ),
  VarianteProducto(
    idVariante: 2,
    idProducto: 1,
    color: 'Blanco',
    talla: 'Única',
    stock: 9,
  ),
  VarianteProducto(
    idVariante: 3,
    idProducto: 2,
    color: 'Blanco',
    talla: 'Única',
    stock: 9,
  ),
  VarianteProducto(
    idVariante: 4,
    idProducto: 2,
    color: 'Rosado',
    talla: 'Única',
    stock: 9,
  ),
];

Pedido _pedido(
  int id,
  int cliente,
  DateTime fecha,
  EstadoPedido estado, {
  required int subtotal,
  int descuento = 0,
  int envio = 5000,
  MetodoPago metodo = MetodoPago.wompi,
}) => Pedido(
  idPedido: id,
  idCliente: cliente,
  fecha: fecha,
  estadoActual: estado,
  subtotal: subtotal,
  descuento: descuento,
  total: subtotal - descuento + envio,
  metodoPago: metodo,
);

DetallePedido _detalle(int pedido, int variante, int cantidad, int precio) =>
    DetallePedido(
      idDetalle: pedido * 10 + variante,
      idPedido: pedido,
      idVariante: variante,
      cantidad: cantidad,
      precioUnitario: precio,
      subtotal: cantidad * precio,
    );

Envio _envio(int pedido, String ciudad, {int costo = 5000}) => Envio(
  idEnvio: pedido,
  idPedido: pedido,
  nombreDestinatario: 'X',
  telefono: '3000000000',
  departamento: 'Valle del Cauca',
  ciudad: ciudad,
  direccion: 'Calle 1',
  costo: costo,
);

/// Tres clientas y seis pedidos:
/// - Ana (1): #1 collar x2 + aretes blanco x1; #2 collar x1 (11 días después,
///   contraentrega con 20%); #3 cancelado.
/// - Bea (2): #4 aretes blanco x3, pendiente, en Bogotá.
/// - Cata (3): #5 collar blanco x1; #6 aretes rosado x2, dos días después.
Metricas _escenario() => Metricas.calcular(
  pedidos: [
    _pedido(1, 1, DateTime(2026, 11, 1), EstadoPedido.pagado, subtotal: 98000),
    _pedido(
      2,
      1,
      DateTime(2026, 11, 12),
      EstadoPedido.entregado,
      subtotal: 40000,
      descuento: 8000,
      envio: 0,
      metodo: MetodoPago.contraentrega,
    ),
    _pedido(
      3,
      1,
      DateTime(2026, 11, 21),
      EstadoPedido.cancelado,
      subtotal: 90000,
    ),
    _pedido(
      4,
      2,
      DateTime(2026, 11, 5),
      EstadoPedido.pendiente,
      subtotal: 54000,
    ),
    _pedido(5, 3, DateTime(2026, 11, 2), EstadoPedido.enviado, subtotal: 40000),
    _pedido(6, 3, DateTime(2026, 11, 4), EstadoPedido.pagado, subtotal: 36000),
  ],
  detalles: [
    _detalle(1, 1, 2, 40000),
    _detalle(1, 3, 1, 18000),
    _detalle(2, 1, 1, 40000),
    _detalle(3, 3, 5, 18000),
    _detalle(4, 3, 3, 18000),
    _detalle(5, 2, 1, 40000),
    _detalle(6, 4, 2, 18000),
  ],
  variantes: _variantes,
  productos: _productos,
  envios: [
    _envio(1, 'Cali'),
    _envio(2, 'cali ', costo: 0),
    _envio(3, 'Cali'),
    _envio(4, 'Bogotá'),
    _envio(5, 'Cali'),
    _envio(6, 'Cali'),
  ],
);

void main() {
  group('Métricas de los pedidos', () {
    test('cuenta los pedidos y su estado actual', () {
      final m = _escenario();

      expect(m.totalPedidos, 6);
      expect(m.pedidosValidos, 5);
      expect(m.pedidosPorEstado[EstadoPedido.pagado], 2);
      expect(m.pedidosPorEstado[EstadoPedido.pendiente], 1);
      expect(m.pedidosPorEstado[EstadoPedido.enviado], 1);
      expect(m.pedidosPorEstado[EstadoPedido.entregado], 1);
      expect(m.pedidosPorEstado[EstadoPedido.cancelado], 1);
      expect(m.pedidosPorEstado[EstadoPedido.preparacion], 0);
    });

    test('el balance separa lo cobrado, lo que falta y lo cancelado', () {
      final m = _escenario();

      expect(m.ventasProductos, 268000);
      expect(m.totalDescuentos, 8000);
      expect(m.pedidosConDescuento, 1);
      expect(m.totalEnvios, 20000);
      // Productos - descuentos + envíos.
      expect(m.totalVendido, 280000);
      expect(
        m.totalVendido,
        m.ventasProductos - m.totalDescuentos + m.totalEnvios,
      );
      expect(m.cobrado, 221000);
      expect(m.porCobrar, 59000);
      expect(m.cobrado + m.porCobrar, m.totalVendido);
      expect(m.cancelado, 95000);
      expect(m.ticketPromedio, 56000);
    });

    test('el producto más vendido sale de las unidades, sin cancelados', () {
      final m = _escenario();

      expect(m.productosMasVendidos.map((f) => f.nombre), ['Aretes', 'Collar']);
      // Aretes: 1 + 3 + 2 (las 5 del pedido cancelado no cuentan).
      expect(m.productosMasVendidos.first.valor, 6);
      expect(m.productosMasVendidos.first.extra, 108000);
      expect(m.productosMasVendidos.last.valor, 4);
    });

    test(
      'los colores más vendidos juntan el mismo color de varios productos',
      () {
        final m = _escenario();

        expect(m.coloresMasVendidos.map((f) => '${f.nombre}:${f.valor}'), [
          'Blanco:5',
          'Naranja:3',
          'Rosado:2',
        ]);
      },
    );

    test(
      'el producto más recomprado cuenta pedidos repetidos de la misma clienta',
      () {
        final m = _escenario();

        // Solo Ana repitió un producto (el collar, en #1 y #2).
        expect(m.productosMasRecomprados, hasLength(1));
        expect(m.productosMasRecomprados.single.nombre, 'Collar');
        expect(m.productosMasRecomprados.single.valor, 1);
        expect(m.productosMasRecomprados.single.extra, 1);
      },
    );

    test('mide cada cuánto vuelven a comprar', () {
      final m = _escenario();

      // Ana: 11 días; Cata: 2 días.
      expect(m.diasPromedioRecompra, closeTo(6.5, 0.01));
      expect(m.diasMedianaRecompra, closeTo(6.5, 0.01));
      expect(m.clientas, 3);
      expect(m.clientasRecurrentes, 2);
      expect(m.tasaRecompra, closeTo(2 / 3, 0.001));
    });

    test('la mediana no se deja llevar por una recompra muy tardía', () {
      final m = Metricas.calcular(
        pedidos: [
          _pedido(1, 1, DateTime(2026, 1, 1), EstadoPedido.pagado, subtotal: 1),
          _pedido(2, 1, DateTime(2026, 1, 3), EstadoPedido.pagado, subtotal: 1),
          _pedido(3, 1, DateTime(2026, 1, 5), EstadoPedido.pagado, subtotal: 1),
          _pedido(4, 1, DateTime(2026, 3, 5), EstadoPedido.pagado, subtotal: 1),
        ],
        detalles: const [],
        variantes: _variantes,
        productos: _productos,
        envios: [for (var i = 1; i <= 4; i++) _envio(i, 'Cali')],
      );

      // Intervalos: 2, 2 y 59 días.
      expect(m.diasMedianaRecompra, 2);
      expect(m.diasPromedioRecompra, closeTo(21, 0.01));
    });

    test('las ciudades con más recompras, sin distinguir mayúsculas', () {
      final m = _escenario();

      // "Cali" y "cali " son la misma ciudad. Bogotá no tuvo recompras.
      expect(m.ciudades, hasLength(1));
      expect(m.ciudades.single.nombre, 'Cali');
      expect(m.ciudades.single.valor, 2);
      expect(m.ciudades.single.extra, 4);
    });

    test('cuenta cómo pagan', () {
      final m = _escenario();

      expect(m.pedidosPorMetodo[MetodoPago.wompi], 4);
      expect(m.pedidosPorMetodo[MetodoPago.contraentrega], 1);
    });

    test('sin pedidos todo queda en cero y no falla', () {
      final m = Metricas.calcular(
        pedidos: const [],
        detalles: const [],
        variantes: _variantes,
        productos: _productos,
        envios: const [],
      );

      expect(m.totalPedidos, 0);
      expect(m.totalVendido, 0);
      expect(m.ticketPromedio, 0);
      expect(m.tasaRecompra, 0);
      expect(m.diasPromedioRecompra, isNull);
      expect(m.productosMasVendidos, isEmpty);
      expect(m.ciudades, isEmpty);
    });
  });

  group('Página de datos', () {
    Future<void> abrir(WidgetTester tester, Metricas m) async {
      TinaTipografia.usarFuenteWeb = false;
      tester.view.physicalSize = const Size(450, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: TinaTema.crear(),
          home: PanelDatosPage(
            metricas: m,
            onSeccion: (_) {},
            onVerTienda: () {},
          ),
        ),
      );
    }

    testWidgets('muestra las cifras, los rankings y la recompra', (
      tester,
    ) async {
      await abrir(tester, _escenario());

      expect(find.text('Datos cliente'), findsWidgets);
      expect(find.text('5 pedidos válidos de 6'), findsOneWidget);
      expect(find.text(r'$280.000'), findsWidgets);
      expect(find.text(r'$221.000'), findsWidgets);
      expect(find.text('Producto más vendido'), findsOneWidget);
      expect(find.text('6 uds · \$108.000'), findsOneWidget);
      expect(find.text('Producto más recomprado'), findsOneWidget);
      expect(find.text('1 recompra · 1 clienta'), findsOneWidget);
      expect(find.text('Ciudades con mayor recompra'), findsOneWidget);
      expect(find.text('2 recompras de 4 pedidos'), findsOneWidget);
      expect(find.text('Tiempo promedio de recompra'), findsOneWidget);
      expect(find.text('7 días'), findsWidgets); // 6,5 se redondea a 7
    });

    testWidgets('sin pedidos explica que todavía no hay datos', (tester) async {
      await abrir(
        tester,
        Metricas.calcular(
          pedidos: const [],
          detalles: const [],
          variantes: _variantes,
          productos: _productos,
          envios: const [],
        ),
      );

      expect(find.byKey(const ValueKey('datos-vacio')), findsOneWidget);
      expect(find.text('Producto más vendido'), findsNothing);
    });

    testWidgets('sin recompras lo dice en vez de dejar el espacio vacío', (
      tester,
    ) async {
      await abrir(
        tester,
        Metricas.calcular(
          pedidos: [
            _pedido(
              1,
              1,
              DateTime(2026, 1, 1),
              EstadoPedido.pagado,
              subtotal: 18000,
            ),
          ],
          detalles: [_detalle(1, 3, 1, 18000)],
          variantes: _variantes,
          productos: _productos,
          envios: [_envio(1, 'Cali')],
        ),
      );

      expect(
        find.text('Todavía nadie ha recomprado un producto.'),
        findsOneWidget,
      );
      expect(find.text('Todavía no hay recompras.'), findsOneWidget);
      expect(find.text('Sin datos todavía'), findsWidgets);
    });
  });
}
