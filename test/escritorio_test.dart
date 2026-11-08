import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/components/components.dart';
import 'package:tina_app/screens/tina_screen.dart';
import 'package:tina_app/theme/tina_tema.dart';

Future<void> _abrirApp(
  WidgetTester tester, {
  Size tamano = const Size(1400, 2400),
}) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: TinaTema.crear(), home: const TinaScreen()),
  );
  await tester.pumpAndSettle();
}

Finder _llave(String llave) => find.byKey(ValueKey(llave));

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: true);
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String clave, String texto) async {
  final campo = find.descendant(
    of: _llave('campo-$clave'),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}

void main() {
  group('Diseño de escritorio', () {
    testWidgets(
      'usa la barra superior con enlaces y no la navegación inferior',
      (tester) async {
        await _abrirApp(tester);

        expect(find.byType(TinaBarraEscritorio), findsOneWidget);
        expect(find.byType(TinaBarraSuperior), findsNothing);
        expect(find.byType(TinaNavInferior), findsNothing);
        for (final destino in ['inicio', 'categorias', 'carrito', 'cuenta']) {
          expect(_llave('nav-$destino'), findsOneWidget, reason: destino);
        }
      },
    );

    testWidgets('la grilla de productos tiene 4 columnas', (tester) async {
      await _abrirApp(tester);

      final y = [
        for (final id in [1, 2, 3, 4, 5])
          tester.getTopLeft(_llave('producto-$id')).dy,
      ];
      expect(y[0], y[1]);
      expect(y[0], y[2]);
      expect(y[0], y[3]);
      expect(
        y[4],
        greaterThan(y[0]),
        reason: 'el quinto baja a la segunda fila',
      );
    });

    testWidgets('los enlaces de la barra recorren las secciones', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('nav-categorias'));
      expect(find.text('2 accesorios'), findsOneWidget);

      await _tocar(tester, _llave('nav-carrito'));
      expect(find.text('Tu carrito está vacío'), findsOneWidget);

      await _tocar(tester, _llave('nav-cuenta'));
      expect(find.text('Inicia sesión'), findsOneWidget);

      await _tocar(tester, _llave('nav-inicio'));
      expect(find.text('Tan latinas'), findsOneWidget);
    });

    testWidgets(
      'el detalle pone la foto a la izquierda y la información a la derecha',
      (tester) async {
        await _abrirApp(tester);
        await _tocar(tester, _llave('producto-1'));

        final foto = tester.getTopLeft(find.byType(TinaFotoProducto));
        final info = tester.getTopLeft(find.byType(TinaSelectorColor));
        expect(info.dx, greaterThan(foto.dx + 300));
        // Los dos bloques arrancan arriba, uno junto al otro.
        expect(
          tester.getTopLeft(find.text('COLLARES')).dy - foto.dy,
          lessThan(40),
        );
      },
    );

    testWidgets(
      'el carrito pone las líneas a la izquierda y el resumen a la derecha',
      (tester) async {
        await _abrirApp(tester);
        await _tocar(tester, _llave('producto-1'));
        await _tocar(tester, find.textContaining('Agregar al carrito'));

        final linea = tester.getTopLeft(_llave('item-1'));
        final resumen = tester.getTopLeft(find.text('Subtotal'));
        expect(resumen.dx, greaterThan(linea.dx + 500));
      },
    );

    testWidgets('compra completa y cambio de estado en el panel', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('producto-3'));
      await _tocar(tester, find.textContaining('Agregar al carrito'));
      await _tocar(tester, find.text('Continuar'));

      // Datos de envío y resumen quedan lado a lado.
      expect(
        tester.getTopLeft(find.text('Resumen del pedido')).dx,
        greaterThan(tester.getTopLeft(find.text('Datos de envío')).dx + 400),
      );

      await _escribir(tester, 'nombre', 'Isabella Vergara');
      await _escribir(tester, 'telefono', '3001234567');
      await _escribir(tester, 'correo', 'isabella@correo.com');
      await _escribir(tester, 'direccion', 'Calle 5 #38-20');
      await _escribir(tester, 'ciudad', 'Cali');
      await _escribir(tester, 'departamento', 'Valle del Cauca');
      await _tocar(tester, find.textContaining('Pagar con Wompi'));

      expect(find.text('confirmado!'), findsOneWidget);
      expect(find.text('TINA-0015'), findsOneWidget);

      await _tocar(tester, find.text('Seguir comprando'));
      await _tocar(tester, _llave('nav-cuenta'));
      await _tocar(tester, _llave('ir-panel'));

      expect(find.text('8 pedidos'), findsOneWidget);
      // Los pedidos van en dos columnas.
      expect(
        tester.getTopLeft(_llave('pedido-TINA-0014')).dy,
        tester.getTopLeft(_llave('pedido-TINA-0015')).dy,
      );

      await _tocar(tester, _llave('estado-TINA-0015'));
      await tester.tap(find.text('Enviado').last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('TINA-0015 ahora está: Enviado'),
        findsOneWidget,
      );
    });
  });

  group('El diseño de celular se conserva', () {
    testWidgets('con 450 px de ancho usa la navegación inferior', (
      tester,
    ) async {
      await _abrirApp(tester, tamano: const Size(450, 2600));

      expect(find.byType(TinaBarraSuperior), findsOneWidget);
      expect(find.byType(TinaNavInferior), findsOneWidget);
      expect(find.byType(TinaBarraEscritorio), findsNothing);

      final y = [
        for (final id in [1, 2, 3])
          tester.getTopLeft(_llave('producto-$id')).dy,
      ];
      expect(y[0], y[1]);
      expect(y[2], greaterThan(y[0]), reason: 'en celular son 2 columnas');
    });
  });
}
