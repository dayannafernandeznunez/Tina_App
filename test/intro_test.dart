import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/components/components.dart';
import 'package:tina_app/screens/tina_screen.dart';
import 'package:tina_app/theme/tina_tema.dart';

Future<void> _abrirApp(WidgetTester tester) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = const Size(450, 2600);
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
    of: _llave('login-$clave'),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}

/// Inicia sesión con una cuenta de prueba desde la pestaña Cuenta.
Future<void> _iniciarSesion(WidgetTester tester) async {
  await _tocar(tester, _llave('nav-cuenta'));
  await _escribir(tester, 'correo', 'valentina.rios@correo.com');
  await _escribir(tester, 'clave', 'contrasena1');
  await tester.tap(find.text('Iniciar sesión'));
  // Sin pumpAndSettle: la intro sigue animándose.
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('Intro animada de la app', () {
    testWidgets('no sale al abrir la app', (tester) async {
      await _abrirApp(tester);

      expect(find.byType(TinaIntro), findsNothing);
      expect(find.text('Tan latinas'), findsOneWidget);
    });

    testWidgets('sale al iniciar sesión y se salta con un clic', (
      tester,
    ) async {
      await _abrirApp(tester);
      await _iniciarSesion(tester);

      expect(find.byType(TinaIntro), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        expect(_llave('intro-letra-$i'), findsOneWidget, reason: 'letra $i');
      }

      await tester.tap(find.byType(TinaIntro));
      await tester.pumpAndSettle();

      expect(find.byType(TinaIntro), findsNothing);
      expect(find.text('Tan latinas'), findsOneWidget);
    });

    testWidgets('termina sola y se va', (tester) async {
      await _abrirApp(tester);
      await _iniciarSesion(tester);
      expect(find.byType(TinaIntro), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 4300));
      await tester.pump();

      expect(find.byType(TinaIntro), findsNothing);
    });

    testWidgets('sale una sola vez por inicio de sesión', (tester) async {
      await _abrirApp(tester);
      await _iniciarSesion(tester);
      await tester.tap(find.byType(TinaIntro));
      await tester.pumpAndSettle();

      // Volver a la portada varias veces no la repite.
      await _tocar(tester, _llave('nav-categorias'));
      await _tocar(tester, _llave('nav-inicio'));
      expect(find.byType(TinaIntro), findsNothing);
      await _tocar(tester, _llave('nav-cuenta'));
      await _tocar(tester, _llave('nav-inicio'));
      expect(find.byType(TinaIntro), findsNothing);

      // Al cerrar sesión y entrar otra vez, vuelve a salir.
      await _tocar(tester, _llave('nav-cuenta'));
      await _tocar(tester, find.text('Cerrar sesión'));
      expect(find.byType(TinaIntro), findsNothing);

      await _iniciarSesion(tester);
      expect(find.byType(TinaIntro), findsOneWidget);
    });

    testWidgets('si se entra desde el checkout, sale al llegar a la portada', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('producto-1'));
      await _tocar(tester, find.textContaining('Agregar al carrito'));
      await _tocar(tester, find.text('Continuar'));
      await _tocar(tester, _llave('opcion-cuenta'));
      await _escribir(tester, 'correo', 'valentina.rios@correo.com');
      await _escribir(tester, 'clave', 'contrasena1');
      await _tocar(tester, find.text('Iniciar sesión'));

      // Vuelve al checkout sin intro.
      expect(find.text('Finalizar compra'), findsOneWidget);
      expect(find.byType(TinaIntro), findsNothing);

      // Al llegar a la portada (atrás hasta el inicio), la intro sale.
      await tester.tap(find.bySemanticsLabel('Volver'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Volver'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TinaIntro), findsOneWidget);
    });
  });

  group('TinaIntro', () {
    testWidgets('avisa una sola vez al saltarla', (tester) async {
      TinaTipografia.usarFuenteWeb = false;
      var avisos = 0;
      await tester.pumpWidget(
        MaterialApp(home: TinaIntro(onTerminar: () => avisos++)),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byType(TinaIntro));
      await tester.tap(find.byType(TinaIntro));
      await tester.pumpAndSettle();

      expect(avisos, 1);
    });

    testWidgets('avisa al terminar la animación', (tester) async {
      TinaTipografia.usarFuenteWeb = false;
      var avisos = 0;
      await tester.pumpWidget(
        MaterialApp(home: TinaIntro(onTerminar: () => avisos++)),
      );

      await tester.pump(const Duration(milliseconds: 4300));
      await tester.pump();

      expect(avisos, 1);
    });

    testWidgets('las letras se descubren de a una', (tester) async {
      TinaTipografia.usarFuenteWeb = false;
      await tester.pumpWidget(MaterialApp(home: TinaIntro(onTerminar: () {})));

      double ancho(int i) => tester
          .getSize(
            find.descendant(
              of: _llave('intro-letra-$i'),
              matching: find.byType(ClipRect),
            ),
          )
          .width;

      // A los 1,0 s la primera letra ya está completa y la última no.
      await tester.pump(const Duration(milliseconds: 1000));
      final primera = ancho(0);
      final ultima = ancho(3);
      expect(primera, greaterThan(0));
      expect(ultima, lessThan(primera + 0.001));

      // Al final todas tienen su ancho completo.
      await tester.pump(const Duration(milliseconds: 1800));
      expect(ancho(3), greaterThan(0));
    });

    testWidgets('con "reducir animaciones" no se muestra', (tester) async {
      TinaTipografia.usarFuenteWeb = false;
      var avisos = 0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: TinaIntro(onTerminar: () => avisos++)),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(avisos, 1);
    });
  });
}
