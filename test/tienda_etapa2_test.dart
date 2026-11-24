import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/catalogo.dart';
import 'package:tina_app/main.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/theme/tina_tema.dart';

Producto _prod(
  int id,
  int cat,
  String nombre,
  int precio, {
  int? coleccion,
  bool activo = true,
}) => Producto(
  idProducto: id,
  idCategoria: cat,
  nombre: nombre,
  descripcion: 'Hecho a mano',
  tecnica: 'Porcelanicrón',
  precio: precio,
  idColeccion: coleccion,
  activo: activo,
);

VarianteProducto _var(
  int id,
  int prod,
  String color, [
  String talla = 'Única',
]) => VarianteProducto(
  idVariante: id,
  idProducto: prod,
  color: color,
  talla: talla,
  stock: 4,
);

class _Catalogo implements CatalogoRepositorio {
  _Catalogo({this.colecciones = true, this.baseActivo = true});

  final bool colecciones;
  final bool baseActivo;

  @override
  Future<Catalogo> cargar() async => Catalogo(
    categorias: const [
      Categoria(idCategoria: 1, nombre: 'Aretes', descripcion: ''),
      Categoria(idCategoria: 2, nombre: 'Collares', descripcion: ''),
      Categoria(idCategoria: 3, nombre: 'Charm Bar', descripcion: ''),
      Categoria(idCategoria: 4, nombre: 'Charms', descripcion: ''),
    ],
    productos: [
      _prod(1, 1, 'Aretes Calabaza', 49000, coleccion: colecciones ? 10 : null),
      _prod(2, 1, 'Aretes con flor', 52000, coleccion: colecciones ? 10 : null),
      _prod(3, 2, 'Collar tropical', 58000),
      _prod(4, 2, 'Collar oculto', 30000, coleccion: colecciones ? 11 : null),
      _prod(5, 3, 'Collar Charm Bar', 60000, activo: baseActivo),
      _prod(6, 4, 'Charm Corazón', 12000),
    ],
    variantes: [
      _var(1, 1, 'Naranja'),
      _var(2, 2, 'Rosado'),
      _var(3, 3, 'Naranja'),
      _var(4, 4, 'Blanco'),
      _var(51, 5, 'Palo rosa', 'Charms fijos'),
      _var(61, 6, 'Único'),
    ],
    colecciones: colecciones
        ? const [
            Coleccion(
              idColeccion: 10,
              nombre: 'Feria',
              subtitulo: 'Piezas de la feria',
            ),
            Coleccion(idColeccion: 11, nombre: 'Borrador', activa: false),
          ]
        : const [],
    promociones: const [
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

Finder _llave(String llave) => find.byKey(ValueKey(llave));

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: true);
  await tester.pumpAndSettle();
}

Future<void> _abrir(
  WidgetTester tester, {
  CatalogoRepositorio? catalogo,
  Size tamano = const Size(1400, 5200),
}) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(TinaApp(catalogo: catalogo ?? _Catalogo()));
  await tester.pumpAndSettle();
}

void main() {
  group('Cabecera con enlaces extra', () {
    testWidgets('en escritorio muestra Charm Bar, Colecciones y la lupa', (
      tester,
    ) async {
      await _abrir(tester);

      expect(_llave('nav-charmbar'), findsOneWidget);
      expect(_llave('nav-colecciones'), findsOneWidget);
      expect(_llave('nav-buscar'), findsOneWidget);
    });

    testWidgets('sin colecciones no se ofrece el enlace', (tester) async {
      await _abrir(tester, catalogo: _Catalogo(colecciones: false));

      expect(_llave('nav-colecciones'), findsNothing);
      expect(_llave('titulo-colecciones'), findsNothing);
      expect(_llave('nav-charmbar'), findsOneWidget);
    });

    testWidgets('en celular la lupa está en la esquina de la cabecera', (
      tester,
    ) async {
      await _abrir(tester, tamano: const Size(450, 5200));

      expect(_llave('nav-buscar'), findsOneWidget);
      expect(_llave('nav-charmbar'), findsNothing);
    });

    testWidgets('el enlace Charm Bar abre el armador', (tester) async {
      await _abrir(tester);

      await _tocar(tester, _llave('nav-charmbar'));

      expect(find.text('Crea un collar único'), findsOneWidget);
    });
  });

  group('Portada con colecciones y banner', () {
    testWidgets('muestra el banner del Charm Bar y lleva al armador', (
      tester,
    ) async {
      await _abrir(tester);

      expect(find.text('ARMA TU COLLAR'), findsOneWidget);
      await _tocar(tester, _llave('banner-charm-bar'));

      expect(find.text('Crea un collar único'), findsOneWidget);
    });

    testWidgets('las colecciones activas se ven; las ocultas no', (
      tester,
    ) async {
      await _abrir(tester);

      expect(_llave('titulo-colecciones'), findsOneWidget);
      expect(_llave('mosaico-Feria'), findsOneWidget);
      expect(_llave('mosaico-Borrador'), findsNothing);
    });

    testWidgets('el collar base no sale como una sección más', (tester) async {
      await _abrir(tester);

      expect(find.text('Collar Charm Bar'), findsNothing);
      expect(_llave('producto-5'), findsNothing);
    });
  });

  group('Colecciones', () {
    testWidgets('la página lista las colecciones y abre una', (tester) async {
      await _abrir(tester);

      await _tocar(tester, _llave('nav-colecciones'));
      expect(_llave('mosaico-Feria'), findsOneWidget);

      await _tocar(tester, _llave('mosaico-Feria'));

      // Solo los productos de la colección.
      expect(_llave('producto-1'), findsOneWidget);
      expect(_llave('producto-2'), findsOneWidget);
      expect(_llave('producto-3'), findsNothing);
      expect(find.text('2 accesorios'), findsOneWidget);
    });

    testWidgets('al volver a una categoría ya no se ve solo la colección', (
      tester,
    ) async {
      await _abrir(tester);
      await _tocar(tester, _llave('nav-colecciones'));
      await _tocar(tester, _llave('mosaico-Feria'));

      await _tocar(tester, _llave('chip-Collares'));

      expect(_llave('producto-3'), findsOneWidget);
      expect(_llave('producto-1'), findsNothing);
    });
  });

  group('Buscador', () {
    testWidgets('escribir muestra los productos que coinciden', (tester) async {
      await _abrir(tester);
      await _tocar(tester, _llave('nav-buscar'));

      await tester.enterText(
        find.descendant(
          of: _llave('buscar-campo'),
          matching: find.byType(TextFormField),
        ),
        'aretes',
      );
      await tester.pumpAndSettle();

      expect(find.text('2 resultados'), findsOneWidget);
      expect(_llave('producto-1'), findsOneWidget);
      expect(_llave('producto-2'), findsOneWidget);
      expect(_llave('producto-3'), findsNothing);
    });

    testWidgets('sin coincidencias lo dice', (tester) async {
      await _abrir(tester);
      await _tocar(tester, _llave('nav-buscar'));

      await tester.enterText(
        find.descendant(
          of: _llave('buscar-campo'),
          matching: find.byType(TextFormField),
        ),
        'xyz',
      );
      await tester.pumpAndSettle();

      expect(_llave('buscar-sin-resultados'), findsOneWidget);
    });

    testWidgets('las sugerencias son las categorías, sin el collar base', (
      tester,
    ) async {
      await _abrir(tester);
      await _tocar(tester, _llave('nav-buscar'));

      expect(_llave('sugerencia-Aretes'), findsOneWidget);
      expect(_llave('sugerencia-Charm Bar'), findsNothing);

      await _tocar(tester, _llave('sugerencia-Collares'));

      expect(_llave('producto-3'), findsOneWidget);
    });

    testWidgets('no encuentra productos ocultos', (tester) async {
      await _abrir(tester, catalogo: _Catalogo(baseActivo: false));
      await _tocar(tester, _llave('nav-buscar'));

      await tester.enterText(
        find.descendant(
          of: _llave('buscar-campo'),
          matching: find.byType(TextFormField),
        ),
        'charm bar',
      );
      await tester.pumpAndSettle();

      expect(_llave('producto-5'), findsNothing);
    });
  });

  group('Charm Bar con el collar base oculto', () {
    testWidgets('avisa que abre muy pronto', (tester) async {
      await _abrir(tester, catalogo: _Catalogo(baseActivo: false));

      await _tocar(tester, _llave('nav-charmbar'));

      expect(_llave('charm-pronto'), findsOneWidget);
    });
  });
}
