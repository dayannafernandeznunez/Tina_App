import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/catalogo.dart';
import 'package:tina_app/main.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/theme/tina_tema.dart';

/// Un Charm Bar completo: collar base en dos colores y dos modos, y tres
/// charms (uno con poco stock).
class _CatalogoCharmBar implements CatalogoRepositorio {
  _CatalogoCharmBar({this.conCharms = true});

  final bool conCharms;

  @override
  Future<Catalogo> cargar() async => Catalogo(
    categorias: const [
      Categoria(idCategoria: 1, nombre: 'Aretes', descripcion: ''),
      Categoria(idCategoria: 2, nombre: 'Charm Bar', descripcion: ''),
      Categoria(idCategoria: 3, nombre: 'Charms', descripcion: ''),
    ],
    productos: [
      const Producto(
        idProducto: 1,
        idCategoria: 1,
        nombre: 'Aretes de prueba',
        descripcion: '',
        tecnica: '',
        precio: 18000,
      ),
      Producto(
        idProducto: 2,
        idCategoria: 2,
        nombre: 'Collar Charm Bar',
        descripcion: '',
        tecnica: '',
        precio: 60000,
      ),
      if (conCharms) ...const [
        Producto(
          idProducto: 3,
          idCategoria: 3,
          nombre: 'Charm Corazón',
          descripcion: '',
          tecnica: '',
          precio: 12000,
        ),
        Producto(
          idProducto: 4,
          idCategoria: 3,
          nombre: 'Charm Flor',
          descripcion: '',
          tecnica: '',
          precio: 15000,
        ),
      ],
    ],
    variantes: [
      const VarianteProducto(
        idVariante: 1,
        idProducto: 1,
        color: 'Nude',
        talla: 'Única',
        stock: 4,
      ),
      const VarianteProducto(
        idVariante: 21,
        idProducto: 2,
        color: 'Palo rosa',
        talla: 'Charms fijos',
        stock: 3,
      ),
      const VarianteProducto(
        idVariante: 22,
        idProducto: 2,
        color: 'Palo rosa',
        talla: 'Charms removibles',
        stock: 3,
      ),
      const VarianteProducto(
        idVariante: 23,
        idProducto: 2,
        color: 'Naranja',
        talla: 'Charms fijos',
        stock: 1,
      ),
      if (conCharms) ...const [
        VarianteProducto(
          idVariante: 31,
          idProducto: 3,
          color: 'Único',
          talla: 'Única',
          stock: 5,
        ),
        VarianteProducto(
          idVariante: 41,
          idProducto: 4,
          color: 'Único',
          talla: 'Única',
          stock: 1,
        ),
      ],
    ],
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
  Size tamano = const Size(1400, 3200),
}) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(TinaApp(catalogo: catalogo ?? _CatalogoCharmBar()));
  await tester.pumpAndSettle();
}

Future<void> _alCharmBar(WidgetTester tester) async {
  await _tocar(tester, _llave('chip-Charm Bar'));
}

void main() {
  group('Charm Bar', () {
    testWidgets('la categoría Charm Bar abre el armador, no una lista', (
      tester,
    ) async {
      await _abrir(tester);

      await _alCharmBar(tester);

      expect(find.text('Crea un collar único'), findsOneWidget);
      expect(find.text('Desde \$60.000'), findsOneWidget);
      expect(_llave('armar-precio'), findsOneWidget);
      expect(_llave('orden-destacados'), findsNothing);
    });

    testWidgets('muestra los cuatro pasos con colores, modos y charms', (
      tester,
    ) async {
      await _abrir(tester);
      await _alCharmBar(tester);

      expect(find.text('Elige el color del collar'), findsOneWidget);
      expect(_llave('armar-color-Palo rosa'), findsOneWidget);
      expect(_llave('armar-color-Naranja'), findsOneWidget);
      expect(find.text('¿Cuántos charms quieres?'), findsOneWidget);
      expect(find.text('Recomendado: 7 charms'), findsOneWidget);
      expect(_llave('armar-modo-Charms fijos'), findsOneWidget);
      expect(_llave('armar-modo-Charms removibles'), findsOneWidget);
      expect(find.text('Personaliza tus charms'), findsOneWidget);
      expect(_llave('charm-31'), findsOneWidget);
      expect(_llave('charm-41'), findsOneWidget);
    });

    testWidgets('los modos dependen del color elegido', (tester) async {
      await _abrir(tester);
      await _alCharmBar(tester);

      await _tocar(tester, _llave('armar-color-Naranja'));

      // El naranja solo existe con charms fijos.
      expect(_llave('armar-modo-Charms fijos'), findsOneWidget);
      expect(_llave('armar-modo-Charms removibles'), findsNothing);
    });

    testWidgets('el precio suma el collar y cada charm', (tester) async {
      await _abrir(tester);
      await _alCharmBar(tester);
      expect(find.text('\$60.000'), findsWidgets);

      await _tocar(tester, _llave('cantidad-mas'));
      await _tocar(tester, _llave('charm-31'));
      await _tocar(tester, _llave('charm-41'));

      // 60.000 + 12.000 + 15.000
      expect(find.text('\$87.000'), findsOneWidget);
      expect(find.text('Tus charms (2/2)'), findsOneWidget);
    });

    testWidgets('no deja elegir más charms de los que se pidieron', (
      tester,
    ) async {
      await _abrir(tester);
      await _alCharmBar(tester);

      await _tocar(tester, _llave('charm-31'));
      await _tocar(tester, _llave('charm-41'));

      expect(find.text('Tus charms (1/1)'), findsOneWidget);
      expect(find.textContaining('Ya elegiste tu 1'), findsNothing);
      expect(find.textContaining('Ya elegiste tus 1 charm'), findsOneWidget);
    });

    testWidgets('no deja repetir un charm más veces que su stock', (
      tester,
    ) async {
      await _abrir(tester);
      await _alCharmBar(tester);
      await _tocar(tester, _llave('cantidad-mas'));
      await _tocar(tester, _llave('cantidad-mas'));

      // El Charm Flor tiene una sola unidad.
      await _tocar(tester, _llave('charm-41'));
      await _tocar(tester, _llave('charm-41'));

      expect(find.text('Tus charms (1/3)'), findsOneWidget);
      expect(
        find.textContaining('Solo quedan 1 de Charm Flor'),
        findsOneWidget,
      );
    });

    testWidgets('quitar un charm elegido lo saca de la lista', (tester) async {
      await _abrir(tester);
      await _alCharmBar(tester);
      await _tocar(tester, _llave('charm-31'));
      expect(_llave('charm-elegido-31'), findsOneWidget);

      await _tocar(tester, _llave('quitar-charm-Charm Corazón'));

      expect(_llave('charm-elegido-31'), findsNothing);
      expect(find.text('Tus charms (0/1)'), findsOneWidget);
    });

    testWidgets('sin terminar de elegir avisa cuántos faltan', (tester) async {
      await _abrir(tester);
      await _alCharmBar(tester);
      await _tocar(tester, _llave('cantidad-mas'));
      await _tocar(tester, _llave('cantidad-mas'));
      await _tocar(tester, _llave('charm-31'));

      expect(find.text('Elige 2 charms más'), findsOneWidget);
      await _tocar(tester, _llave('armar-agregar'));

      expect(find.text('Te faltan 2 charms por elegir.'), findsOneWidget);
      expect(find.text('Tu carrito'), findsNothing);
    });

    testWidgets('al terminar, el collar y los charms quedan en el carrito', (
      tester,
    ) async {
      await _abrir(tester);
      await _alCharmBar(tester);
      await _tocar(tester, _llave('cantidad-mas'));
      await _tocar(tester, _llave('charm-31'));
      await _tocar(tester, _llave('charm-41'));
      expect(find.text('Añadir al carrito · \$87.000'), findsOneWidget);

      await _tocar(tester, _llave('armar-agregar'));

      // Tres artículos: el collar y los dos charms.
      expect(find.text('Collar Charm Bar'), findsOneWidget);
      expect(find.text('Charm Corazón'), findsOneWidget);
      expect(find.text('Charm Flor'), findsOneWidget);
    });

    testWidgets('si no hay charms a la venta muestra "abre muy pronto"', (
      tester,
    ) async {
      await _abrir(tester, catalogo: _CatalogoCharmBar(conCharms: false));
      await _alCharmBar(tester);

      expect(_llave('charm-pronto'), findsOneWidget);
      expect(find.text('El Charm Bar abre muy pronto'), findsOneWidget);
      expect(_llave('armar-agregar'), findsNothing);
    });

    testWidgets('la portada usa el título de marca si no hay foto', (
      tester,
    ) async {
      await _abrir(tester);
      await _alCharmBar(tester);

      expect(_llave('charm-portada-marca'), findsOneWidget);
      expect(find.text('Charm Bar'), findsWidgets);
    });
  });
}
