import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/catalogo.dart';
import 'package:tina_app/main.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/theme/tina_tema.dart';

/// Catálogo de mentira que se comporta como la nube: sin red.
class _CatalogoFalso implements CatalogoRepositorio {
  _CatalogoFalso({this.falla = false});

  final bool falla;

  @override
  Future<Catalogo> cargar() async {
    if (falla) throw Exception('sin conexión');
    return const Catalogo(
      categorias: [
        Categoria(idCategoria: 1, nombre: 'Collares', descripcion: ''),
      ],
      productos: [
        Producto(
          idProducto: 1,
          idCategoria: 1,
          nombre: 'Collar de la nube',
          descripcion: 'Viene de Supabase.',
          tecnica: 'Tejido',
          precio: 40000,
        ),
      ],
      variantes: [
        VarianteProducto(
          idVariante: 1,
          idProducto: 1,
          color: 'Naranja',
          talla: 'Única',
          stock: 5,
        ),
      ],
      promociones: [],
      imagenes: [
        ImagenProducto(
          idImagen: 1,
          idProducto: 1,
          url: 'https://ejemplo.invalid/foto.jpg',
          orden: 1,
        ),
      ],
      ajustesSitio: [
        AjusteSitio(
          clave: 'portada_inicio',
          descripcion: 'Portada',
          url: 'https://ejemplo.invalid/portada.jpg',
        ),
      ],
    );
  }
}

void main() {
  setUpAll(() => TinaTipografia.usarFuenteWeb = false);

  group('Filas de Supabase a modelos', () {
    test('categoría, producto, variante, foto y promoción', () {
      final categoria = Categoria.desdeMapa({
        'id_categoria': 2,
        'nombre': 'Aretes',
        'descripcion': null,
      });
      expect(categoria.nombre, 'Aretes');
      expect(categoria.descripcion, '');

      final producto = Producto.desdeMapa({
        'id_producto': 3,
        'id_categoria': 2,
        'nombre': 'Aretes de porcelanicrón',
        'descripcion': 'Livianos',
        'tecnica': 'Porcelanicrón',
        'precio': 18000,
        'activo': false,
      });
      expect(producto.precio, 18000);
      expect(producto.activo, isFalse);

      final variante = VarianteProducto.desdeMapa({
        'id_variante': 5,
        'id_producto': 3,
        'color': 'Nude',
        'talla': 'Única',
        'stock': 10,
      });
      expect(variante.stock, 10);

      final foto = ImagenProducto.desdeMapa({
        'id_imagen': 1,
        'id_producto': 3,
        'url': 'https://x.supabase.co/storage/v1/object/public/productos/a.jpg',
        'ruta': 'a.jpg',
        'orden': 1,
      });
      expect(foto.ruta, 'a.jpg');

      final promocion = Promocion.desdeMapa({
        'id_promocion': 2,
        'nombre': '30% por volumen',
        'tipo': 'volumen',
        'porcentaje': 30,
        'cantidad_minima': 14,
        'activa': true,
      });
      expect(promocion.cantidadMinima, 14);
    });
  });

  group('La tienda lee el catálogo de la nube', () {
    Future<void> abrir(WidgetTester tester, CatalogoRepositorio repo) async {
      tester.view.physicalSize = const Size(450, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(TinaApp(catalogo: repo));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra los productos que llegan de la nube', (tester) async {
      await abrir(tester, _CatalogoFalso());

      expect(find.text('Collar de la nube'), findsOneWidget);
      // Los productos de ejemplo ya no aparecen.
      expect(find.text('Maxi collar 3D con mostacilla'), findsNothing);
      // Una foto que no se puede cargar no rompe la pantalla.
      expect(tester.takeException(), isNull);
    });

    testWidgets('si la nube falla, avisa y muestra los datos de ejemplo', (
      tester,
    ) async {
      await abrir(tester, _CatalogoFalso(falla: true));

      expect(find.text('Maxi collar 3D con mostacilla'), findsOneWidget);
      expect(
        find.text(
          'No pudimos conectar con la tienda. Mostramos datos de ejemplo.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin repositorio usa solo los datos simulados', (tester) async {
      tester.view.physicalSize = const Size(450, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const TinaApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cargando-catalogo')), findsNothing);
      expect(find.text('Maxi collar 3D con mostacilla'), findsOneWidget);
    });
  });
}
