import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/main.dart';
import 'package:tina_app/theme/tina_tema.dart';

void main() {
  testWidgets('La app arranca en la portada de Tina', (tester) async {
    TinaTipografia.usarFuenteWeb = false;
    tester.view.physicalSize = const Size(450, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TinaApp());
    await tester.pumpAndSettle();

    expect(find.text('Tan latinas'), findsOneWidget);
  });
}
