import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/administradora.dart';
import 'package:tina_app/data/catalogo.dart';
import 'package:tina_app/data/sesion.dart';
import 'package:tina_app/main.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/theme/tina_tema.dart';

/// La parte de la administradora, de mentira. Solo importa lo de productos y
/// stock; lo de fotos no se usa aquí.
class _AdminFalsa implements AdministradoraRepositorio {
  int _siguienteProducto = 100;
  int _siguienteVariante = 1000;

  final List<Producto> productosGuardados = [];
  final List<VarianteProducto> variantesGuardadas = [];
  final List<int> variantesBorradas = [];

  /// Si no es nulo, borrar una variante falla con este mensaje.
  String? falloAlBorrar;

  @override
  Future<Producto> guardarProducto(Producto producto) async {
    final guardado = Producto(
      idProducto: producto.idProducto == 0
          ? _siguienteProducto++
          : producto.idProducto,
      idCategoria: producto.idCategoria,
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      tecnica: producto.tecnica,
      precio: producto.precio,
      activo: producto.activo,
    );
    productosGuardados.add(guardado);
    return guardado;
  }

  @override
  Future<VarianteProducto> guardarVariante(VarianteProducto variante) async {
    final guardada = VarianteProducto(
      idVariante: variante.idVariante == 0
          ? _siguienteVariante++
          : variante.idVariante,
      idProducto: variante.idProducto,
      color: variante.color,
      talla: variante.talla,
      stock: variante.stock,
    );
    variantesGuardadas.add(guardada);
    return guardada;
  }

  @override
  Future<void> borrarVariante(int idVariante) async {
    if (falloAlBorrar != null) throw ErrorAdministradora(falloAlBorrar!);
    variantesBorradas.add(idVariante);
  }

  @override
  Future<ImagenProducto> subirFotoProducto({
    required int idProducto,
    required FotoElegida foto,
    required int orden,
  }) => throw UnimplementedError();

  @override
  Future<void> borrarFotoProducto(ImagenProducto foto) =>
      throw UnimplementedError();

  @override
  Future<void> ordenarFotosProducto(List<ImagenProducto> enOrden) =>
      throw UnimplementedError();

  @override
  Future<AjusteSitio> subirFotoSitio({
    required AjusteSitio ajuste,
    required FotoElegida foto,
  }) => throw UnimplementedError();

  @override
  Future<AjusteSitio> quitarFotoSitio(AjusteSitio ajuste) =>
      throw UnimplementedError();
}

class _SesionAdmin implements SesionRepositorio {
  @override
  Future<SesionActiva?> restaurar() async => null;

  @override
  Future<SesionActiva> iniciarSesion(String correo, String clave) async =>
      SesionActiva(
        cliente: Cliente(
          idCliente: 900,
          nombre: 'Tina',
          correo: correo,
          telefono: '',
          cuentaRegistrada: true,
          fechaRegistro: DateTime(2026, 11, 14),
        ),
        esAdministradora: true,
      );

  @override
  Future<ResultadoRegistro> registrar({
    required String nombre,
    required String correo,
    required String clave,
  }) => throw UnimplementedError();

  @override
  Future<void> cerrarSesion() async {}
}

class _SelectorNulo implements SelectorFotos {
  @override
  Future<FotoElegida?> elegir() async => null;
}

/// Tres productos: uno con stock normal (7), uno oculto con poco stock (2) y
/// uno agotado (0).
class _Catalogo implements CatalogoRepositorio {
  @override
  Future<Catalogo> cargar() async => const Catalogo(
    categorias: [
      Categoria(idCategoria: 1, nombre: 'Collares', descripcion: ''),
      Categoria(idCategoria: 2, nombre: 'Aretes', descripcion: ''),
    ],
    productos: [
      Producto(
        idProducto: 1,
        idCategoria: 1,
        nombre: 'Collar de prueba',
        descripcion: 'Uno',
        tecnica: 'Tejido',
        precio: 40000,
      ),
      Producto(
        idProducto: 2,
        idCategoria: 2,
        nombre: 'Aretes ocultos',
        descripcion: 'Dos',
        tecnica: 'Porcelanicrón',
        precio: 18000,
        activo: false,
      ),
      Producto(
        idProducto: 3,
        idCategoria: 2,
        nombre: 'Aretes agotados',
        descripcion: 'Tres',
        tecnica: 'Porcelanicrón',
        precio: 16000,
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
      VarianteProducto(
        idVariante: 2,
        idProducto: 1,
        color: 'Blanco',
        talla: 'Única',
        stock: 2,
      ),
      VarianteProducto(
        idVariante: 3,
        idProducto: 2,
        color: 'Nude',
        talla: 'Única',
        stock: 2,
      ),
      VarianteProducto(
        idVariante: 4,
        idProducto: 3,
        color: 'Rosado',
        talla: 'Única',
        stock: 0,
      ),
    ],
    promociones: [
      Promocion(
        idPromocion: 1,
        nombre: '20% en tu primera compra con cuenta',
        tipo: 'primera_compra',
        porcentaje: 20,
        cantidadMinima: 1,
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

Future<void> _escribir(WidgetTester tester, String llave, String texto) async {
  final campo = find.descendant(
    of: _llave(llave),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}

Finder _en(String llave, String interna) =>
    find.descendant(of: _llave(llave), matching: _llave(interna));

/// Abre la app, entra como administradora y va a la sección de productos.
Future<_AdminFalsa> _abrirProductos(WidgetTester tester) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = const Size(450, 4500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final admin = _AdminFalsa();
  await tester.pumpWidget(
    TinaApp(
      catalogo: _Catalogo(),
      sesiones: _SesionAdmin(),
      admin: admin,
      selectorFotos: _SelectorNulo(),
    ),
  );
  await tester.pumpAndSettle();

  await _tocar(tester, _llave('nav-cuenta'));
  await _escribir(tester, 'login-correo', 'tina@correo.com');
  await _escribir(tester, 'login-clave', 'clave-buena');
  await _tocar(tester, find.text('Iniciar sesión'));
  await _tocar(tester, _llave('seccion-productos'));
  return admin;
}

void main() {
  group('Lista de productos', () {
    testWidgets(
      'muestra todos los productos con su stock, también los ocultos',
      (tester) async {
        await _abrirProductos(tester);

        expect(find.text('3 productos · 2 visibles'), findsOneWidget);
        expect(_en('prod-admin-1', 'stock-producto'), findsOneWidget);
        expect(
          find.descendant(
            of: _llave('prod-admin-1'),
            matching: find.text('Stock: 7'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _llave('prod-admin-2'),
            matching: find.text('Poco stock: 2'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _llave('prod-admin-2'),
            matching: find.text('Oculto'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _llave('prod-admin-3'),
            matching: find.text('Agotado'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('ocultar un producto desde la lista', (tester) async {
      final admin = await _abrirProductos(tester);

      await _tocar(tester, _en('prod-admin-1', 'alternar-visible'));

      expect(admin.productosGuardados.single.activo, isFalse);
      expect(admin.productosGuardados.single.idProducto, 1);
      expect(find.text('Ahora está oculto.'), findsOneWidget);
      expect(find.text('3 productos · 1 visibles'), findsOneWidget);
    });

    testWidgets('volver a mostrar un producto oculto', (tester) async {
      final admin = await _abrirProductos(tester);

      await _tocar(tester, _en('prod-admin-2', 'alternar-visible'));

      expect(admin.productosGuardados.single.activo, isTrue);
      expect(find.text('Ahora se ve en la tienda.'), findsOneWidget);
      expect(find.text('3 productos · 3 visibles'), findsOneWidget);
    });
  });

  group('Crear un producto', () {
    testWidgets('no deja guardar vacío y marca lo que falta', (tester) async {
      final admin = await _abrirProductos(tester);
      await _tocar(tester, _llave('nuevo-producto'));

      expect(find.text('Nuevo producto'), findsWidgets);
      await _tocar(tester, _llave('guardar-producto'));

      expect(find.text('Escribe el nombre.'), findsOneWidget);
      expect(
        find.text('Escribe el precio en pesos, solo números.'),
        findsOneWidget,
      );
      expect(find.text('Escribe el color.'), findsOneWidget);
      expect(admin.productosGuardados, isEmpty);
    });

    testWidgets('crea el producto con su stock y lo muestra en la tienda', (
      tester,
    ) async {
      final admin = await _abrirProductos(tester);
      await _tocar(tester, _llave('nuevo-producto'));

      await _escribir(tester, 'prod-nombre', 'Pulsera de prueba');
      await _escribir(tester, 'prod-descripcion', 'Tejida a mano');
      await _escribir(tester, 'prod-tecnica', 'Tejido');
      await _escribir(tester, 'prod-precio', r'$17.500');
      await _escribir(tester, 'var-n0-color', 'Naranja');
      await _tocar(tester, _en('var-n0-stock', 'cantidad-mas'));
      await _tocar(tester, _en('var-n0-stock', 'cantidad-mas'));
      await _tocar(tester, _en('var-n0-stock', 'cantidad-mas'));
      await _tocar(tester, _llave('guardar-producto'));

      final producto = admin.productosGuardados.single;
      expect(producto.nombre, 'Pulsera de prueba');
      expect(producto.precio, 17500);
      expect(producto.idCategoria, 1);
      expect(producto.activo, isTrue);
      final variante = admin.variantesGuardadas.single;
      expect(variante.idProducto, producto.idProducto);
      expect(variante.color, 'Naranja');
      expect(variante.stock, 3);

      // Vuelve a la lista con el producto nuevo.
      expect(find.text('Producto creado.'), findsOneWidget);
      expect(find.text('4 productos · 3 visibles'), findsOneWidget);
      expect(_llave('prod-admin-${producto.idProducto}'), findsOneWidget);

      // Y ya se ve en la tienda.
      await _tocar(tester, find.text('Ver tienda'));
      expect(find.text('Pulsera de prueba'), findsOneWidget);
    });

    testWidgets('cancelar vuelve a la lista sin guardar nada', (tester) async {
      final admin = await _abrirProductos(tester);
      await _tocar(tester, _llave('nuevo-producto'));
      await _escribir(tester, 'prod-nombre', 'Algo a medias');

      await _tocar(tester, _llave('cancelar-producto'));

      expect(admin.productosGuardados, isEmpty);
      expect(find.text('3 productos · 2 visibles'), findsOneWidget);
      expect(find.text('Algo a medias'), findsNothing);
    });

    testWidgets('un producto nuevo puede quedar oculto', (tester) async {
      final admin = await _abrirProductos(tester);
      await _tocar(tester, _llave('nuevo-producto'));
      await _escribir(tester, 'prod-nombre', 'Borrador');
      await _escribir(tester, 'prod-precio', '9000');
      await _escribir(tester, 'var-n0-color', 'Rojo');
      await _tocar(tester, _llave('prod-oculto'));
      await _tocar(tester, _llave('guardar-producto'));

      expect(admin.productosGuardados.single.activo, isFalse);
    });
  });

  group('Editar y ajustar el inventario', () {
    testWidgets('abre el producto con sus datos y variantes', (tester) async {
      await _abrirProductos(tester);
      await _tocar(tester, _en('prod-admin-1', 'editar-producto'));

      expect(find.text('Editar producto'), findsWidgets);
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: _llave('prod-nombre'),
                matching: find.byType(TextFormField),
              ),
            )
            .controller!
            .text,
        'Collar de prueba',
      );
      expect(_llave('var-v1'), findsOneWidget);
      expect(_llave('var-v2'), findsOneWidget);
    });

    testWidgets('cambia el stock y se ve en la lista', (tester) async {
      final admin = await _abrirProductos(tester);
      await _tocar(tester, _en('prod-admin-1', 'editar-producto'));

      await _tocar(tester, _en('var-v1-stock', 'cantidad-mas'));
      await _tocar(tester, _en('var-v1-stock', 'cantidad-mas'));
      await _tocar(tester, _en('var-v2-stock', 'cantidad-menos'));
      await _tocar(tester, _llave('guardar-producto'));

      final guardadas = {
        for (final v in admin.variantesGuardadas) v.idVariante: v.stock,
      };
      expect(guardadas[1], 7);
      expect(guardadas[2], 1);
      expect(find.text('Cambios guardados.'), findsOneWidget);
      expect(
        find.descendant(
          of: _llave('prod-admin-1'),
          matching: find.text('Poco stock: 3'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: _llave('prod-admin-1'),
          matching: find.text('Stock: 8'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('el stock no baja de cero', (tester) async {
      await _abrirProductos(tester);
      await _tocar(tester, _en('prod-admin-3', 'editar-producto'));

      await _tocar(tester, _en('var-v4-stock', 'cantidad-menos'));

      expect(
        find.descendant(of: _llave('var-v4-stock'), matching: find.text('0')),
        findsOneWidget,
      );
    });

    testWidgets('agrega una variante nueva y quita otra', (tester) async {
      final admin = await _abrirProductos(tester);
      await _tocar(tester, _en('prod-admin-1', 'editar-producto'));

      await _tocar(tester, _llave('agregar-variante'));
      await _escribir(tester, 'var-n0-color', 'Rosado');
      await _escribir(tester, 'var-n0-talla', 'M');
      await _tocar(tester, _en('var-v2', 'var-v2-quitar'));
      await _tocar(tester, _llave('guardar-producto'));

      final nueva = admin.variantesGuardadas.firstWhere(
        (v) => v.color == 'Rosado',
      );
      expect(nueva.talla, 'M');
      expect(nueva.idVariante, greaterThanOrEqualTo(1000));
      expect(admin.variantesBorradas, [2]);
    });

    testWidgets('no deja repetir color y talla', (tester) async {
      final admin = await _abrirProductos(tester);
      await _tocar(tester, _en('prod-admin-1', 'editar-producto'));
      await _tocar(tester, _llave('agregar-variante'));
      await _escribir(tester, 'var-n0-color', 'naranja');

      await _tocar(tester, _llave('guardar-producto'));

      expect(
        find.text('Ya hay una fila con ese color y esa talla.'),
        findsOneWidget,
      );
      expect(admin.productosGuardados, isEmpty);
    });

    testWidgets('si una variante no se puede borrar, avisa y deja abierto', (
      tester,
    ) async {
      final admin = await _abrirProductos(tester);
      admin.falloAlBorrar = 'Esa fila ya tiene pedidos. Déjala con stock 0.';
      await _tocar(tester, _en('prod-admin-1', 'editar-producto'));
      await _tocar(tester, _en('var-v2', 'var-v2-quitar'));

      await _tocar(tester, _llave('guardar-producto'));

      expect(
        find.text('Esa fila ya tiene pedidos. Déjala con stock 0.'),
        findsOneWidget,
      );
      expect(find.text('Editar producto'), findsWidgets);
      expect(_llave('guardar-producto'), findsOneWidget);
    });
  });
}
