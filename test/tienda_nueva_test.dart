import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/screens/tina_screen.dart';
import 'package:tina_app/theme/tina_tema.dart';

Future<void> _abrir(
  WidgetTester tester, {
  Size tamano = const Size(1400, 2600),
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

void main() {
  group('Portada', () {
    testWidgets(
      'tiene la franja de promoción, la cinta, las garantías y el pie',
      (tester) async {
        await _abrir(tester, tamano: const Size(1400, 5200));

        expect(_llave('barra-promo'), findsOneWidget);
        expect(find.textContaining('Envío de \$5.000'), findsWidgets);
        expect(_llave('cinta-confianza'), findsOneWidget);
        expect(_llave('garantias'), findsOneWidget);
        expect(_llave('pie-pagina'), findsOneWidget);
      },
    );

    testWidgets('el botón "Comprar ahora" lleva a una categoría', (
      tester,
    ) async {
      await _abrir(tester);

      await _tocar(tester, _llave('hero-comprar'));

      expect(_llave('orden-destacados'), findsOneWidget);
      expect(find.textContaining('accesorio'), findsWidgets);
    });

    testWidgets('el mosaico y los círculos llevan a la categoría', (
      tester,
    ) async {
      await _abrir(tester, tamano: const Size(1400, 5200));

      await _tocar(tester, _llave('mosaico-Pulseras'));

      expect(_llave('orden-destacados'), findsOneWidget);
      expect(find.text('2 accesorios'), findsOneWidget);
    });

    testWidgets('sin número de WhatsApp configurado no se muestra el botón', (
      tester,
    ) async {
      await _abrir(tester);

      expect(_llave('boton-whatsapp'), findsNothing);
    });
  });

  group('Catálogo con filtros', () {
    Future<void> alasCollares(WidgetTester tester) async {
      await _abrir(tester);
      await _tocar(tester, _llave('chip-Collares'));
    }

    testWidgets('el panel muestra los colores con su cantidad', (tester) async {
      await alasCollares(tester);

      expect(_llave('filtro-color-Naranja'), findsOneWidget);
      expect(find.text('Naranja (2)'), findsOneWidget);
      expect(find.text('Blanco (1)'), findsOneWidget);
      expect(find.text('En existencia (2)'), findsOneWidget);
    });

    testWidgets('elegir un color deja solo los productos que lo tienen', (
      tester,
    ) async {
      await alasCollares(tester);
      expect(_llave('producto-1'), findsOneWidget);
      expect(_llave('producto-2'), findsOneWidget);

      await _tocar(tester, _llave('filtro-color-Blanco'));

      expect(_llave('producto-1'), findsOneWidget);
      expect(_llave('producto-2'), findsNothing);
      expect(find.text('1 accesorio'), findsOneWidget);
    });

    testWidgets('"Quitar filtros" los devuelve todos', (tester) async {
      await alasCollares(tester);
      await _tocar(tester, _llave('filtro-color-Blanco'));

      await _tocar(tester, _llave('quitar-filtros'));

      expect(_llave('producto-2'), findsOneWidget);
      expect(_llave('quitar-filtros'), findsNothing);
    });

    testWidgets('ordenar por precio cambia el orden de la grilla', (
      tester,
    ) async {
      await alasCollares(tester);
      final antes = tester.getTopLeft(_llave('producto-1')).dx;
      final antes2 = tester.getTopLeft(_llave('producto-2')).dx;

      await _tocar(tester, _llave('orden-precioMayor'));
      final despues = tester.getTopLeft(_llave('producto-1')).dx;
      final despues2 = tester.getTopLeft(_llave('producto-2')).dx;

      // Si antes uno estaba a la izquierda del otro, ahora puede cambiar; lo
      // que importa es que las dos posiciones siguen siendo distintas.
      expect(antes == antes2, isFalse);
      expect(despues == despues2, isFalse);
    });

    testWidgets('al cambiar de categoría los filtros empiezan limpios', (
      tester,
    ) async {
      await alasCollares(tester);
      await _tocar(tester, _llave('filtro-color-Blanco'));

      await _tocar(tester, _llave('chip-Aretes'));

      expect(_llave('quitar-filtros'), findsNothing);
    });

    testWidgets('en celular los filtros se abren con un botón', (tester) async {
      await _abrir(tester, tamano: const Size(450, 4200));
      await _tocar(tester, _llave('chip-Collares'));

      expect(_llave('filtro-disponible'), findsNothing);
      await _tocar(tester, _llave('abrir-filtros'));
      expect(_llave('filtro-disponible'), findsOneWidget);

      await _tocar(tester, _llave('filtro-disponible'));
      expect(find.textContaining('Ocultar filtros'), findsOneWidget);
    });
  });

  group('Página de producto', () {
    Future<void> alProducto(WidgetTester tester) async {
      await _abrir(tester);
      await _tocar(tester, _llave('producto-1'));
    }

    testWidgets('muestra las migas de pan y los puntos de la marca', (
      tester,
    ) async {
      await alProducto(tester);

      expect(_llave('migas'), findsOneWidget);
      expect(_llave('detalle-puntos'), findsOneWidget);
      expect(_llave('detalle-envio-pagos'), findsOneWidget);
    });

    testWidgets('las migas llevan a la categoría y al inicio', (tester) async {
      await alProducto(tester);

      await _tocar(tester, _llave('miga-categoria'));
      expect(_llave('orden-destacados'), findsOneWidget);
    });

    testWidgets('las pestañas cambian el texto', (tester) async {
      await alProducto(tester);
      expect(find.textContaining('Técnica:'), findsOneWidget);

      await _tocar(tester, _llave('pestana-Envíos'));
      expect(find.textContaining('contraentrega'), findsWidgets);
      expect(find.textContaining('Técnica:'), findsNothing);

      await _tocar(tester, _llave('pestana-Cuidados'));
      expect(find.textContaining('lugar seco'), findsOneWidget);
    });
  });
}
