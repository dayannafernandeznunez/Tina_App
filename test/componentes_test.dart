import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/components/components.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/screens/galeria_screen.dart';
import 'package:tina_app/theme/tina_tema.dart';

Widget _envolver(Widget hijo) => MaterialApp(
  theme: TinaTema.crear(),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 390, child: hijo),
    ),
  ),
);

void main() {
  setUpAll(() => TinaTipografia.usarFuenteWeb = false);

  group('TinaBoton', () {
    testWidgets('muestra la etiqueta y avisa al tocarlo', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        _envolver(
          TinaBoton(etiqueta: 'Agregar al carrito', onPressed: () => toques++),
        ),
      );

      await tester.tap(find.text('Agregar al carrito'));

      expect(toques, 1);
    });

    testWidgets('la variante secundaria también responde', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        _envolver(
          TinaBoton(
            etiqueta: 'Ver accesorios',
            variante: VarianteBoton.secundario,
            onPressed: () => toques++,
          ),
        ),
      );

      await tester.tap(find.text('Ver accesorios'));

      expect(toques, 1);
    });
  });

  group('TinaCampo', () {
    testWidgets('muestra la etiqueta y reporta lo que se escribe', (
      tester,
    ) async {
      String? ultimo;
      await tester.pumpWidget(
        _envolver(
          TinaCampo(
            etiqueta: 'Correo',
            placeholder: 'tu@correo.com',
            onChanged: (v) => ultimo = v,
          ),
        ),
      );

      expect(find.text('Correo'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'sara@correo.com');

      expect(ultimo, 'sara@correo.com');
    });

    testWidgets('el campo de contraseña oculta el texto', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const TinaCampo(etiqueta: 'Contraseña', tipo: TipoCampo.contrasena),
        ),
      );

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.obscureText, isTrue);
    });
  });

  group('TinaTarjetaProducto', () {
    testWidgets('muestra los datos y avisa al tocarla', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        _envolver(
          SizedBox(
            width: 180,
            child: TinaTarjetaProducto(
              nombre: 'Maxi collar 3D con mostacilla',
              precio: r'$55.000',
              categoria: 'Collares',
              colores: const [Color(0xFFFF6A00), Colors.white],
              onTap: () => toques++,
            ),
          ),
        ),
      );

      expect(find.text('Maxi collar 3D con mostacilla'), findsOneWidget);
      expect(find.text(r'$55.000'), findsOneWidget);
      expect(find.text('Collares'), findsOneWidget);

      await tester.tap(find.text('Maxi collar 3D con mostacilla'));
      expect(toques, 1);
    });
  });

  group('TinaBarraSuperior', () {
    testWidgets('con título y atrás: avisa atrás y carrito', (tester) async {
      final semantica = tester.ensureSemantics();
      var atras = 0;
      var carrito = 0;
      await tester.pumpWidget(
        _envolver(
          TinaBarraSuperior(
            titulo: 'Tu carrito',
            conAtras: true,
            carrito: 3,
            onAtras: () => atras++,
            onCarrito: () => carrito++,
          ),
        ),
      );

      expect(find.text('Tu carrito'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Volver'));
      await tester.tap(find.bySemanticsLabel('Carrito'));

      expect(atras, 1);
      expect(carrito, 1);
      semantica.dispose();
    });

    testWidgets('sin título muestra el logo y sin unidades no hay número', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      var logo = 0;
      await tester.pumpWidget(
        _envolver(TinaBarraSuperior(onLogo: () => logo++)),
      );

      expect(find.bySemanticsLabel('Volver'), findsNothing);
      expect(find.text('0'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Tina, inicio'));
      expect(logo, 1);
      semantica.dispose();
    });
  });

  group('TinaNavInferior', () {
    testWidgets('avisa el destino tocado y muestra las unidades', (
      tester,
    ) async {
      DestinoNav? destino;
      await tester.pumpWidget(
        _envolver(
          TinaNavInferior(
            activo: DestinoNav.inicio,
            carrito: 2,
            onNav: (d) => destino = d,
          ),
        ),
      );

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Cuenta'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-categorias')));
      expect(destino, DestinoNav.categorias);

      await tester.tap(find.byKey(const ValueKey('nav-cuenta')));
      expect(destino, DestinoNav.cuenta);
    });
  });

  group('TinaEtiquetaDescuento', () {
    testWidgets('muestra el texto en los dos tonos', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const Column(
            children: [
              TinaEtiquetaDescuento(
                texto: '20% en tu primera compra con cuenta',
              ),
              TinaEtiquetaDescuento(
                texto: '30% si compras 14 o más unidades',
                tono: TonoEtiqueta.suave,
              ),
            ],
          ),
        ),
      );

      expect(find.text('20% en tu primera compra con cuenta'), findsOneWidget);
      expect(find.text('30% si compras 14 o más unidades'), findsOneWidget);
    });
  });

  group('TinaFilaResumen', () {
    testWidgets('muestra etiqueta, detalle y valor', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const TinaFilaResumen(
            etiqueta: 'Pulsera tejida ×3',
            detalle: 'Beige · Talla M',
            valor: r'$51.000',
          ),
        ),
      );

      expect(find.text('Pulsera tejida ×3'), findsOneWidget);
      expect(find.text('Beige · Talla M'), findsOneWidget);
      expect(find.text(r'$51.000'), findsOneWidget);
    });

    testWidgets('el total muestra su etiqueta y su valor', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const TinaFilaResumen(
            etiqueta: 'Total',
            valor: r'$40.800',
            tipo: TipoFila.total,
          ),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
      expect(find.text(r'$40.800'), findsOneWidget);
    });
  });

  group('TinaEstadoPedido', () {
    testWidgets('etiqueta de cada estado', (tester) async {
      await tester.pumpWidget(
        _envolver(
          Column(
            children: [
              for (final e in EstadoPedido.values) TinaEstadoPedido(estado: e),
            ],
          ),
        ),
      );

      for (final e in EstadoPedido.values) {
        expect(find.text(e.etiqueta), findsOneWidget, reason: e.name);
      }
    });

    testWidgets('modo mensaje explica el estado', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const TinaEstadoPedido(
            estado: EstadoPedido.preparacion,
            modo: ModoEstado.mensaje,
          ),
        ),
      );

      expect(find.text('En preparación'), findsOneWidget);
      expect(find.text('Tu pedido se está armando a mano.'), findsOneWidget);
    });
  });

  group('Selectores', () {
    testWidgets('color: avisa el nombre elegido y marca el actual', (
      tester,
    ) async {
      String? elegido;
      await tester.pumpWidget(
        _envolver(
          TinaSelectorColor(
            opciones: const [
              OpcionColor(nombre: 'Naranja', color: Color(0xFFFF6A00)),
              OpcionColor(nombre: 'Blanco', color: Colors.white),
            ],
            valor: 'Naranja',
            onChanged: (v) => elegido = v,
          ),
        ),
      );

      expect(find.text('Naranja'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('color-Blanco')));
      expect(elegido, 'Blanco');
    });

    testWidgets('talla: avisa la talla elegida', (tester) async {
      String? elegida;
      await tester.pumpWidget(
        _envolver(
          TinaSelectorTalla(
            opciones: const ['S', 'M', 'L'],
            valor: 'M',
            onChanged: (v) => elegida = v,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('talla-L')));
      expect(elegida, 'L');
    });

    testWidgets('cantidad: suma, resta y respeta los límites', (tester) async {
      final cambios = <int>[];
      Widget construir(int valor, {int maximo = 99}) => _envolver(
        TinaSelectorCantidad(
          valor: valor,
          maximo: maximo,
          onChanged: cambios.add,
        ),
      );

      await tester.pumpWidget(construir(3));
      await tester.tap(find.byKey(const ValueKey('cantidad-mas')));
      await tester.tap(find.byKey(const ValueKey('cantidad-menos')));
      expect(cambios, [4, 2]);

      cambios.clear();
      await tester.pumpWidget(construir(1));
      await tester.tap(find.byKey(const ValueKey('cantidad-menos')));
      expect(cambios, isEmpty, reason: 'no baja de 1');

      await tester.pumpWidget(construir(5, maximo: 5));
      await tester.tap(find.byKey(const ValueKey('cantidad-mas')));
      expect(cambios, isEmpty, reason: 'no pasa del stock');
    });
  });

  group('GaleriaScreen', () {
    testWidgets(
      'el estado vive en la Screen: cantidad y carrito se actualizan',
      (tester) async {
        tester.view.physicalSize = const Size(900, 6000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(theme: TinaTema.crear(), home: const GaleriaScreen()),
        );

        // Sube la cantidad a 3 y la agrega al carrito.
        await tester.tap(find.byKey(const ValueKey('cantidad-mas')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('cantidad-mas')));
        await tester.pump();
        expect(find.text('3'), findsOneWidget);

        await tester.tap(find.text('Agregar al carrito'));
        await tester.pump();

        // El número aparece en la barra superior y en la navegación inferior.
        expect(find.text('3'), findsNWidgets(3));
      },
    );
  });
}
