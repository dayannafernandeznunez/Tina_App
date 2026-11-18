import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/administradora.dart';
import 'package:tina_app/data/catalogo.dart';
import 'package:tina_app/data/pedidos.dart';
import 'package:tina_app/data/sesion.dart';
import 'package:tina_app/main.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/theme/tina_tema.dart';

/// Los pedidos de mentira: guarda en memoria lo que recibe, igual que la base
/// de datos real pero sin red. Devuelve los montos que él mismo "calcula", para
/// comprobar que la app muestra lo que responde el servidor.
class _PedidosFalsos implements PedidosRepositorio {
  _PedidosFalsos({this.error, this.pedidosGuardados = const []});

  /// Si no es nulo, crear un pedido falla con este mensaje.
  String? error;
  List<Pedido> pedidosGuardados;

  final List<
    ({
      List<LineaPedidoNueva> lineas,
      DatosEnvio envio,
      DatosCompradora compradora,
      MetodoPago metodo,
    })
  >
  creados = [];
  final List<(int, EstadoPedido)> cambios = [];
  int cargas = 0;

  @override
  Future<PedidoCreado> crear({
    required List<LineaPedidoNueva> lineas,
    required DatosEnvio envio,
    required DatosCompradora compradora,
    required MetodoPago metodo,
  }) async {
    if (error != null) throw ErrorPedido(error!);
    creados.add((
      lineas: lineas,
      envio: envio,
      compradora: compradora,
      metodo: metodo,
    ));
    // Un precio y un descuento que NO son los de la app, para comprobar que
    // manda el servidor.
    return const PedidoCreado(
      idPedido: 31,
      idCliente: 77,
      subtotal: 40000,
      descuento: 4000,
      costoEnvio: 0,
      total: 36000,
    );
  }

  @override
  Future<DatosPedidos> cargar({required bool esAdministradora}) async {
    cargas++;
    return DatosPedidos(
      clientes: [
        Cliente(
          idCliente: 77,
          nombre: 'Laura Caicedo',
          correo: 'laura@correo.com',
          telefono: '3001112233',
          cuentaRegistrada: true,
          fechaRegistro: DateTime(2026, 11, 1),
        ),
      ],
      pedidos: pedidosGuardados,
      detalles: [
        for (final p in pedidosGuardados)
          DetallePedido(
            idDetalle: p.idPedido,
            idPedido: p.idPedido,
            idVariante: 1,
            cantidad: 1,
            precioUnitario: 40000,
            subtotal: 40000,
          ),
      ],
      envios: [
        for (final p in pedidosGuardados)
          Envio(
            idEnvio: p.idPedido,
            idPedido: p.idPedido,
            nombreDestinatario: 'Laura Caicedo',
            telefono: '3001112233',
            departamento: 'Valle del Cauca',
            ciudad: 'Cali',
            direccion: 'Calle 5 #38-20',
            costo: 0,
          ),
      ],
      pagos: [
        for (final p in pedidosGuardados)
          Pago(
            idPago: p.idPedido,
            idPedido: p.idPedido,
            monto: p.total,
            estado: 'pendiente',
            fecha: DateTime(2026, 11, 2),
            proveedor: 'contraentrega',
          ),
      ],
      historial: [
        for (final p in pedidosGuardados)
          HistorialEstado(
            idHistorial: p.idPedido,
            idPedido: p.idPedido,
            idUsuario: 2,
            estadoNuevo: 'pendiente',
            notificado: false,
            fecha: DateTime(2026, 11, 2),
          ),
      ],
      usuarios: const [
        Usuario(
          idUsuario: 2,
          nombre: 'Sistema',
          correo: 'sistema@tina.co',
          rol: 'sistema',
        ),
      ],
    );
  }

  @override
  Future<void> cambiarEstado(int idPedido, EstadoPedido estado) async {
    if (error != null) throw ErrorPedido(error!);
    cambios.add((idPedido, estado));
    pedidosGuardados = [
      for (final p in pedidosGuardados)
        p.idPedido == idPedido ? p.copyWith(estadoActual: estado) : p,
    ];
  }
}

class _CatalogoContado implements CatalogoRepositorio {
  int cargas = 0;

  @override
  Future<Catalogo> cargar() async {
    cargas++;
    return const Catalogo(
      categorias: [
        Categoria(idCategoria: 1, nombre: 'Aretes', descripcion: ''),
      ],
      productos: [
        Producto(
          idProducto: 1,
          idCategoria: 1,
          nombre: 'Aretes de prueba',
          descripcion: 'Livianos',
          tecnica: 'Porcelanicrón',
          precio: 20000,
        ),
      ],
      variantes: [
        VarianteProducto(
          idVariante: 1,
          idProducto: 1,
          color: 'Nude',
          talla: 'Única',
          stock: 10,
        ),
      ],
      promociones: [
        Promocion(
          idPromocion: 1,
          nombre: '20% en tu primera compra con cuenta',
          tipo: 'primera_compra',
          porcentaje: 20,
          cantidadMinima: 1,
          activa: true,
        ),
        Promocion(
          idPromocion: 2,
          nombre: '30% si compras 14 o más unidades',
          tipo: 'volumen',
          porcentaje: 30,
          cantidadMinima: 14,
          activa: true,
        ),
      ],
    );
  }
}

class _SesionAdmin implements SesionRepositorio {
  @override
  Future<SesionActiva?> restaurar() async => null;

  @override
  Future<SesionActiva> iniciarSesion(String correo, String clave) async =>
      SesionActiva(
        cliente: Cliente(
          idCliente: 900,
          nombre: 'Tina',
          correo: correo,
          telefono: '',
          cuentaRegistrada: true,
          fechaRegistro: DateTime(2026, 11, 14),
        ),
        esAdministradora: true,
      );

  @override
  Future<ResultadoRegistro> registrar({
    required String nombre,
    required String correo,
    required String clave,
  }) => throw UnimplementedError();

  @override
  Future<void> cerrarSesion() async {}
}

/// Para las pruebas de compra sin cuenta: nadie ha iniciado sesión.
class _SesionVacia implements SesionRepositorio {
  @override
  Future<SesionActiva?> restaurar() async => null;

  @override
  Future<SesionActiva> iniciarSesion(String correo, String clave) =>
      throw const ErrorSesion('Sin cuentas en esta prueba.');

  @override
  Future<ResultadoRegistro> registrar({
    required String nombre,
    required String correo,
    required String clave,
  }) => throw UnimplementedError();

  @override
  Future<void> cerrarSesion() async {}
}

class _AdminSinFotos implements AdministradoraRepositorio {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Finder _llave(String llave) => find.byKey(ValueKey(llave));

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: true);
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String llave, String texto) async {
  final campo = find.descendant(
    of: _llave(llave),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}

Future<void> _abrir(
  WidgetTester tester, {
  required _PedidosFalsos pedidos,
  required _CatalogoContado catalogo,
  SesionRepositorio? sesiones,
}) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = const Size(450, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    TinaApp(
      catalogo: catalogo,
      sesiones: sesiones ?? _SesionVacia(),
      pedidos: pedidos,
      admin: _AdminSinFotos(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lleva un par de aretes al checkout y llena los datos de envío.
Future<void> _alCheckout(
  WidgetTester tester, {
  String ciudad = 'Cali',
  String departamento = 'Valle del Cauca',
}) async {
  await _tocar(tester, _llave('producto-1'));
  await _tocar(tester, find.textContaining('Agregar al carrito'));
  await _tocar(tester, find.text('Continuar'));
  await _escribir(tester, 'campo-nombre', 'Isabella Vergara');
  await _escribir(tester, 'campo-telefono', '3001234567');
  await _escribir(tester, 'campo-correo', 'isabella@correo.com');
  await _escribir(tester, 'campo-direccion', 'Calle 5 #38-20');
  await _escribir(tester, 'campo-ciudad', ciudad);
  await _escribir(tester, 'campo-departamento', departamento);
  await tester.pumpAndSettle();
}

Pedido _pedido(int id, EstadoPedido estado) => Pedido(
  idPedido: id,
  idCliente: 77,
  fecha: DateTime(2026, 11, 2),
  estadoActual: estado,
  subtotal: 40000,
  descuento: 0,
  total: 40000,
  metodoPago: MetodoPago.contraentrega,
);

void main() {
  group('Comprar con pedidos reales', () {
    testWidgets(
      'contraentrega en Cali: crea el pedido y muestra lo que calculó el servidor',
      (tester) async {
        final pedidos = _PedidosFalsos();
        final catalogo = _CatalogoContado();
        await _abrir(tester, pedidos: pedidos, catalogo: catalogo);
        await _alCheckout(tester);

        await _tocar(tester, _llave('opcion-contraentrega'));
        await _tocar(tester, _llave('boton-pagar'));

        // Se mandó el carrito, el envío, quién compra y el método.
        final creado = pedidos.creados.single;
        expect(creado.metodo, MetodoPago.contraentrega);
        expect(creado.lineas.single.idVariante, 1);
        expect(creado.lineas.single.cantidad, 1);
        expect(creado.envio.ciudad, 'Cali');
        expect(creado.envio.direccion, 'Calle 5 #38-20');
        expect(creado.compradora.correo, 'isabella@correo.com');

        // La confirmación muestra el total del servidor, no uno calculado aquí.
        expect(find.text('recibido!'), findsOneWidget);
        expect(find.text('TINA-0031'), findsOneWidget);
        expect(find.text(r'$36.000'), findsOneWidget);

        // El stock cambió en la base de datos: se vuelve a leer el catálogo.
        expect(catalogo.cargas, greaterThanOrEqualTo(2));
      },
    );

    testWidgets('sin pago en línea, fuera de Cali avisa y no crea nada', (
      tester,
    ) async {
      final pedidos = _PedidosFalsos();
      await _abrir(tester, pedidos: pedidos, catalogo: _CatalogoContado());
      await _alCheckout(tester, ciudad: 'Bogotá', departamento: 'Cundinamarca');

      await _tocar(tester, _llave('boton-pagar'));

      expect(
        find.textContaining('El pago en línea estará disponible muy pronto'),
        findsOneWidget,
      );
      expect(pedidos.creados, isEmpty);
      expect(find.text('Finalizar compra'), findsOneWidget);
    });

    testWidgets('si falta stock, muestra el mensaje y actualiza el catálogo', (
      tester,
    ) async {
      final pedidos = _PedidosFalsos(
        error: 'No hay stock suficiente de Aretes de prueba.',
      );
      final catalogo = _CatalogoContado();
      await _abrir(tester, pedidos: pedidos, catalogo: catalogo);
      await _alCheckout(tester);
      final cargasAntes = catalogo.cargas;

      await _tocar(tester, _llave('opcion-contraentrega'));
      await _tocar(tester, _llave('boton-pagar'));

      expect(
        find.text('No hay stock suficiente de Aretes de prueba.'),
        findsOneWidget,
      );
      expect(find.text('Finalizar compra'), findsOneWidget);
      expect(catalogo.cargas, greaterThan(cargasAntes));
    });
  });

  group('Pedidos reales en el panel', () {
    Future<_PedidosFalsos> alPanel(WidgetTester tester) async {
      final pedidos = _PedidosFalsos(
        pedidosGuardados: [
          _pedido(5, EstadoPedido.pendiente),
          _pedido(4, EstadoPedido.entregado),
        ],
      );
      await _abrir(
        tester,
        pedidos: pedidos,
        catalogo: _CatalogoContado(),
        sesiones: _SesionAdmin(),
      );
      await _tocar(tester, _llave('nav-cuenta'));
      await _escribir(tester, 'login-correo', 'tina@correo.com');
      await _escribir(tester, 'login-clave', 'clave-buena');
      await _tocar(tester, find.text('Iniciar sesión'));
      return pedidos;
    }

    testWidgets(
      'la administradora ve los pedidos que vienen de la base de datos',
      (tester) async {
        final pedidos = await alPanel(tester);

        expect(pedidos.cargas, greaterThanOrEqualTo(1));
        expect(find.text('2 pedidos'), findsOneWidget);
        expect(_llave('pedido-TINA-0005'), findsOneWidget);
        expect(_llave('pedido-TINA-0004'), findsOneWidget);
        expect(find.textContaining('Laura Caicedo'), findsWidgets);
      },
    );

    testWidgets('cambiar el estado se guarda en la base de datos', (
      tester,
    ) async {
      final pedidos = await alPanel(tester);

      await _tocar(tester, _llave('estado-TINA-0005'));
      await tester.tap(find.text('Pagado').last);
      await tester.pumpAndSettle();

      expect(pedidos.cambios, [(5, EstadoPedido.pagado)]);
      expect(
        find.textContaining('TINA-0005 ahora está: Pagado'),
        findsOneWidget,
      );
    });

    testWidgets('si la base de datos rechaza el cambio, lo avisa', (
      tester,
    ) async {
      final pedidos = await alPanel(tester);
      pedidos.error = 'Un pedido cancelado no se puede reactivar.';

      await _tocar(tester, _llave('estado-TINA-0005'));
      await tester.tap(find.text('Pagado').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Un pedido cancelado no se puede reactivar.'),
        findsOneWidget,
      );
      expect(pedidos.cambios, isEmpty);
    });
  });

  group('Filas de Supabase a pedidos', () {
    test('pedido, detalle, pago, envío, comprobante e historial', () {
      final pedido = Pedido.desdeMapa({
        'id_pedido': 12,
        'id_cliente': 3,
        'id_promocion': 2,
        'fecha': '2026-11-18T15:30:00+00:00',
        'estado_actual': 'pagado',
        'subtotal': 224000,
        'descuento': 67200,
        'total': 161800,
        'metodo_pago': 'contraentrega',
      });
      expect(pedido.codigo, 'TINA-0012');
      expect(pedido.estadoActual, EstadoPedido.pagado);
      expect(pedido.metodoPago, MetodoPago.contraentrega);
      expect(pedido.total, 161800);

      final pago = Pago.desdeMapa({
        'id_pago': 1,
        'id_pedido': 12,
        'referencia': null,
        'monto': 161800,
        'estado': 'aprobado',
        'fecha': '2026-11-18T15:31:00+00:00',
        'proveedor': 'contraentrega',
      });
      expect(pago.referencia, isNull);
      expect(pago.proveedor, 'contraentrega');

      final envio = Envio.desdeMapa({
        'id_envio': 1,
        'id_pedido': 12,
        'nombre_destinatario': 'Laura',
        'telefono': '300',
        'departamento': 'Valle del Cauca',
        'ciudad': 'Cali',
        'direccion': 'Calle 5',
        'costo': 0,
        'guia': null,
      });
      expect(envio.costo, 0);
      expect(envio.guia, isNull);

      final historial = HistorialEstado.desdeMapa({
        'id_historial': 1,
        'id_pedido': 12,
        'id_usuario': 2,
        'estado_anterior': null,
        'estado_nuevo': 'pendiente',
        'notificado': false,
        'fecha': '2026-11-18T15:30:00+00:00',
      });
      expect(historial.estadoAnterior, isNull);
      expect(historial.notificado, isFalse);

      final comprobante = Comprobante.desdeMapa({
        'id_comprobante': 1,
        'id_pago': 1,
        'numero': 'C-0012',
        'fecha_emision': '2026-11-18T15:32:00+00:00',
      });
      expect(comprobante.numero, 'C-0012');

      final detalle = DetallePedido.desdeMapa({
        'id_detalle': 1,
        'id_pedido': 12,
        'id_variante': 7,
        'cantidad': 14,
        'precio_unitario': 16000,
        'subtotal': 224000,
      });
      expect(detalle.subtotal, 224000);
    });

    test('un método de pago desconocido se toma como Wompi', () {
      expect(MetodoPago.desdeBd('otro'), MetodoPago.wompi);
      expect(MetodoPago.desdeBd(null), MetodoPago.wompi);
      expect(MetodoPago.desdeBd('apple_pay'), MetodoPago.applePay);
    });

    test('lo que responde crear_pedido', () {
      final creado = PedidoCreado.desdeMapa({
        'id_pedido': 5,
        'id_cliente': 9,
        'subtotal': 110000,
        'descuento': 0,
        'costo_envio': 5000,
        'total': 115000,
      });
      expect(creado.total, 115000);
      expect(creado.costoEnvio, 5000);
    });
  });
}
