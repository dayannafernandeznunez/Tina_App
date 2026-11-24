import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/logic/vistas.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/pages/pedido_page.dart';
import 'package:tina_app/theme/tina_tema.dart';

PedidoCompleto _pedido({
  String telefonoEnvio = '300 111 2233',
  String telefonoCuenta = '',
  String correo = 'laura@correo.com',
}) {
  final fecha = DateTime(2026, 11, 20);
  return PedidoCompleto(
    pedido: Pedido(
      idPedido: 20,
      idCliente: 5,
      fecha: fecha,
      estadoActual: EstadoPedido.pendiente,
      subtotal: 40000,
      descuento: 0,
      total: 40000,
      metodoPago: MetodoPago.contraentrega,
    ),
    cliente: Cliente(
      idCliente: 5,
      nombre: 'Laura Caicedo',
      correo: correo,
      telefono: telefonoCuenta,
      cuentaRegistrada: true,
      fechaRegistro: fecha,
    ),
    lineas: const [
      LineaPedido(
        nombre: 'Aretes',
        color: 'Nude',
        talla: 'Única',
        cantidad: 1,
        precioUnitario: 40000,
        subtotal: 40000,
      ),
    ],
    envio: Envio(
      idEnvio: 20,
      idPedido: 20,
      nombreDestinatario: 'Laura C.',
      telefono: telefonoEnvio,
      departamento: 'Valle del Cauca',
      ciudad: 'Cali',
      direccion: 'Calle 5 #38-20',
      costo: 0,
    ),
    pago: null,
    comprobante: null,
    historial: const [],
  );
}

Future<void> _abrir(WidgetTester tester, PedidoCompleto pedido) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = const Size(500, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TinaTema.crear(),
      home: PedidoPage(pedido: pedido, onAtras: () {}),
    ),
  );
}

Finder _valor(String llave, String texto) => find.descendant(
  of: find.byKey(ValueKey(llave)),
  matching: find.text(texto),
);

void main() {
  group('Contacto de la clienta en el pedido', () {
    testWidgets('muestra su teléfono y su correo', (tester) async {
      await _abrir(tester, _pedido());

      expect(find.text('Contacto de la clienta'), findsOneWidget);
      expect(find.text('Laura Caicedo'), findsOneWidget);
      expect(_valor('contacto-telefono', '300 111 2233'), findsOneWidget);
      expect(_valor('contacto-correo', 'laura@correo.com'), findsOneWidget);
    });

    testWidgets('usa el teléfono de la cuenta si no dejó otro al comprar', (
      tester,
    ) async {
      await _abrir(
        tester,
        _pedido(telefonoEnvio: '', telefonoCuenta: '310 555 6677'),
      );

      expect(_valor('contacto-telefono', '310 555 6677'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('contacto-telefono-cuenta')),
        findsNothing,
      );
    });

    testWidgets('si tiene dos teléfonos distintos, muestra los dos', (
      tester,
    ) async {
      await _abrir(tester, _pedido(telefonoCuenta: '310 555 6677'));

      expect(_valor('contacto-telefono', '300 111 2233'), findsOneWidget);
      expect(
        _valor('contacto-telefono-cuenta', '310 555 6677'),
        findsOneWidget,
      );
    });

    testWidgets('el mismo teléfono en la cuenta y el envío no se repite', (
      tester,
    ) async {
      await _abrir(tester, _pedido(telefonoCuenta: '300 111 2233'));

      expect(
        find.byKey(const ValueKey('contacto-telefono-cuenta')),
        findsNothing,
      );
    });

    testWidgets('sin teléfono ni correo muestra un guion, no un hueco', (
      tester,
    ) async {
      await _abrir(tester, _pedido(telefonoEnvio: '', correo: ''));

      expect(_valor('contacto-telefono', '—'), findsOneWidget);
      expect(_valor('contacto-correo', '—'), findsOneWidget);
    });

    testWidgets(
      'un correo muy largo baja de renglón y no se sale de la pantalla',
      (tester) async {
        TinaTipografia.usarFuenteWeb = false;
        tester.view.physicalSize = const Size(360, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: TinaTema.crear(),
            home: PedidoPage(
              pedido: _pedido(
                correo: 'dayannafernandeznunez.compras.tina@correoinstitucional.edu.co',
              ),
              onAtras: () {},
            ),
          ),
        );

        // Si el correo se saliera, Flutter marcaría un error de desborde y la
        // prueba fallaría. Aquí solo hace falta que se vea completo.
        expect(tester.takeException(), isNull);
        expect(
          _valor(
            'contacto-correo',
            'dayannafernandeznunez.compras.tina@correoinstitucional.edu.co',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('el texto se puede seleccionar para copiarlo', (tester) async {
      await _abrir(tester, _pedido());

      expect(find.byType(SelectionArea), findsOneWidget);
    });
  });
}
