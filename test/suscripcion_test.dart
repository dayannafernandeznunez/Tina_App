import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/suscripcion.dart';
import 'package:tina_app/main.dart';
import 'package:tina_app/theme/tina_tema.dart';

class _Suscripciones implements SuscripcionRepositorio {
  _Suscripciones({this.error});

  final String? error;
  final List<String> correos = [];

  @override
  Future<void> suscribir(String correo) async {
    if (error != null) throw ErrorSuscripcion(error!);
    correos.add(correo);
  }
}

Finder _llave(String llave) => find.byKey(ValueKey(llave));

Future<void> _abrir(WidgetTester tester, SuscripcionRepositorio? repo) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = const Size(1400, 5600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(TinaApp(suscripciones: repo));
  await tester.pumpAndSettle();
}

Future<void> _escribirYEnviar(WidgetTester tester, String correo) async {
  final campo = find.descendant(
    of: _llave('suscripcion-correo'),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(campo);
  await tester.enterText(campo, correo);
  await tester.pump();
  await tester.ensureVisible(_llave('suscripcion-enviar'));
  await tester.tap(_llave('suscripcion-enviar'));
  await tester.pumpAndSettle();
}

void main() {
  group('Suscripción en el pie de página', () {
    testWidgets('un correo válido se guarda y se agradece', (tester) async {
      final repo = _Suscripciones();
      await _abrir(tester, repo);

      await _escribirYEnviar(tester, '  laura@correo.com ');

      expect(repo.correos, ['laura@correo.com']);
      expect(_llave('suscripcion-hecha'), findsOneWidget);
      expect(_llave('suscripcion-correo'), findsNothing);
    });

    testWidgets('un correo mal escrito se marca y no se envía', (tester) async {
      final repo = _Suscripciones();
      await _abrir(tester, repo);

      await _escribirYEnviar(tester, 'no-es-correo');

      expect(repo.correos, isEmpty);
      expect(_llave('suscripcion-hecha'), findsNothing);
      expect(find.textContaining('correo'), findsWidgets);
    });

    testWidgets('si no se puede guardar, muestra el motivo y deja reintentar', (
      tester,
    ) async {
      final repo = _Suscripciones(error: 'No pudimos conectar.');
      await _abrir(tester, repo);

      await _escribirYEnviar(tester, 'laura@correo.com');

      expect(find.text('No pudimos conectar.'), findsOneWidget);
      expect(_llave('suscripcion-hecha'), findsNothing);
      expect(_llave('suscripcion-enviar'), findsOneWidget);
    });

    testWidgets('sin repositorio (modo de ejemplo) también responde', (
      tester,
    ) async {
      await _abrir(tester, null);

      await _escribirYEnviar(tester, 'laura@correo.com');

      expect(_llave('suscripcion-hecha'), findsOneWidget);
    });
  });
}
