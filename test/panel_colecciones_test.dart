import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/administradora.dart';
import 'package:tina_app/data/catalogo.dart';
import 'package:tina_app/data/sesion.dart';
import 'package:tina_app/main.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/theme/tina_tema.dart';

/// La administradora de mentira: guarda en memoria lo que recibe.
class _AdminFalsa implements AdministradoraRepositorio {
  int _siguiente = 50;
  final List<Coleccion> guardadas = [];
  final List<int> borradas = [];
  final List<int> fotosSubidas = [];
  final List<int> fotosQuitadas = [];
  final List<Producto> productosGuardados = [];

  @override
  Future<Coleccion> guardarColeccion(Coleccion c) async {
    final g = c.idColeccion == 0
        ? Coleccion(
            idColeccion: _siguiente++,
            nombre: c.nombre,
            subtitulo: c.subtitulo,
            orden: c.orden,
            activa: c.activa,
          )
        : c;
    guardadas.add(g);
    return g;
  }

  @override
  Future<void> borrarColeccion(Coleccion c) async =>
      borradas.add(c.idColeccion);

  @override
  Future<Coleccion> subirFotoColeccion({
    required Coleccion coleccion,
    required FotoElegida foto,
  }) async {
    fotosSubidas.add(coleccion.idColeccion);
    return coleccion.copyWith(
      url: 'https://ejemplo.invalid/c.jpg',
      ruta: 'coleccion-${coleccion.idColeccion}/c.jpg',
    );
  }

  @override
  Future<Coleccion> quitarFotoColeccion(Coleccion c) async {
    fotosQuitadas.add(c.idColeccion);
    return c.copyWith(sinFoto: true);
  }

  @override
  Future<Producto> guardarProducto(Producto p) async {
    productosGuardados.add(p);
    return p;
  }

  @override
  Future<VarianteProducto> guardarVariante(VarianteProducto v) async => v;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
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

class _SelectorFalso implements SelectorFotos {
  static final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  @override
  Future<FotoElegida?> elegir() async =>
      FotoElegida(bytes: _png, nombre: 'foto.png');
}

class _Catalogo implements CatalogoRepositorio {
  @override
  Future<Catalogo> cargar() async => const Catalogo(
    categorias: [Categoria(idCategoria: 1, nombre: 'Aretes', descripcion: '')],
    productos: [
      Producto(
        idProducto: 1,
        idCategoria: 1,
        nombre: 'Aretes Calabaza',
        descripcion: '',
        tecnica: '',
        precio: 49000,
        idColeccion: 10,
      ),
      Producto(
        idProducto: 2,
        idCategoria: 1,
        nombre: 'Aretes con flor',
        descripcion: '',
        tecnica: '',
        precio: 52000,
      ),
    ],
    variantes: [
      VarianteProducto(
        idVariante: 1,
        idProducto: 1,
        color: 'Naranja',
        talla: 'Única',
        stock: 4,
      ),
      VarianteProducto(
        idVariante: 2,
        idProducto: 2,
        color: 'Rosado',
        talla: 'Única',
        stock: 4,
      ),
    ],
    colecciones: [
      Coleccion(idColeccion: 10, nombre: 'Feria', subtitulo: 'De la feria'),
      Coleccion(idColeccion: 11, nombre: 'Borrador', activa: false),
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

Future<void> _escribir(WidgetTester tester, String llave, String texto) async {
  final campo = find.descendant(
    of: _llave(llave),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}

Future<_AdminFalsa> _alPanel(WidgetTester tester) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = const Size(900, 4500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final admin = _AdminFalsa();
  await tester.pumpWidget(
    TinaApp(
      catalogo: _Catalogo(),
      sesiones: _SesionAdmin(),
      admin: admin,
      selectorFotos: _SelectorFalso(),
    ),
  );
  await tester.pumpAndSettle();
  await _tocar(tester, _llave('nav-cuenta'));
  await _escribir(tester, 'login-correo', 'tina@correo.com');
  await _escribir(tester, 'login-clave', 'clave-buena');
  await _tocar(tester, find.text('Iniciar sesión'));
  await _tocar(tester, _llave('seccion-colecciones'));
  return admin;
}

void main() {
  group('Panel de colecciones', () {
    testWidgets(
      'lista las colecciones con sus productos, también las ocultas',
      (tester) async {
        await _alPanel(tester);

        expect(find.text('2 colecciones'), findsOneWidget);
        expect(_llave('coleccion-10'), findsOneWidget);
        expect(_llave('coleccion-11'), findsOneWidget);
        expect(find.textContaining('1 producto'), findsOneWidget);
        expect(find.textContaining('0 productos · oculta'), findsOneWidget);
      },
    );

    testWidgets('crea una colección nueva y limpia el formulario', (
      tester,
    ) async {
      final admin = await _alPanel(tester);

      await _escribir(tester, 'coleccion-nombre', 'Con amor, para mí');
      await _escribir(tester, 'coleccion-subtitulo', 'Ideales para regalar');
      await _tocar(tester, _llave('guardar-coleccion'));

      final c = admin.guardadas.single;
      expect(c.nombre, 'Con amor, para mí');
      expect(c.subtitulo, 'Ideales para regalar');
      // Las que había tenían orden 1: la nueva va al final.
      expect(c.orden, 2);
      expect(find.text('3 colecciones'), findsOneWidget);
      expect(find.text('Con amor, para mí'), findsOneWidget);
      expect(find.text('Crear colección'), findsOneWidget);
    });

    testWidgets('no crea una colección sin nombre', (tester) async {
      final admin = await _alPanel(tester);

      await _tocar(tester, _llave('guardar-coleccion'));

      expect(admin.guardadas, isEmpty);
      expect(find.text('Escribe el nombre de la colección.'), findsOneWidget);
    });

    testWidgets('editar carga el formulario y guarda los cambios', (
      tester,
    ) async {
      final admin = await _alPanel(tester);

      await _tocar(tester, _llave('editar-coleccion-10'));
      expect(find.text('Editar colección'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      await _escribir(tester, 'coleccion-nombre', 'Feria 2026');
      await _tocar(tester, _llave('guardar-coleccion'));

      expect(admin.guardadas.single.idColeccion, 10);
      expect(admin.guardadas.single.nombre, 'Feria 2026');
      expect(find.text('Feria 2026'), findsOneWidget);
      expect(find.text('Nueva colección'), findsOneWidget);
    });

    testWidgets('ocultar una colección la guarda como no activa', (
      tester,
    ) async {
      final admin = await _alPanel(tester);

      await _tocar(tester, _llave('visible-coleccion-10'));

      expect(admin.guardadas.single.activa, isFalse);
      expect(find.text('Ahora está oculta.'), findsOneWidget);
    });

    testWidgets('sube y quita la foto de una colección', (tester) async {
      final admin = await _alPanel(tester);
      expect(find.text('Subir foto'), findsWidgets);

      await _tocar(tester, _llave('foto-coleccion-10'));
      expect(admin.fotosSubidas, [10]);
      expect(_llave('quitar-foto-coleccion-10'), findsOneWidget);
      expect(find.text('Cambiar foto'), findsOneWidget);

      await _tocar(tester, _llave('quitar-foto-coleccion-10'));
      expect(admin.fotosQuitadas, [10]);
      expect(_llave('quitar-foto-coleccion-10'), findsNothing);
    });

    testWidgets('borrar pide confirmar y deja sus productos sin colección', (
      tester,
    ) async {
      final admin = await _alPanel(tester);

      await _tocar(tester, _llave('borrar-coleccion-10'));
      expect(admin.borradas, isEmpty);
      expect(find.text('Confirmar: borrar'), findsOneWidget);

      await _tocar(tester, _llave('borrar-coleccion-10'));
      expect(admin.borradas, [10]);
      expect(_llave('coleccion-10'), findsNothing);
      expect(find.text('Colección borrada.'), findsOneWidget);
    });

    testWidgets('cancelar la edición vuelve al formulario de colección nueva', (
      tester,
    ) async {
      final admin = await _alPanel(tester);
      await _tocar(tester, _llave('editar-coleccion-10'));

      await _tocar(tester, _llave('cancelar-coleccion'));

      expect(find.text('Nueva colección'), findsOneWidget);
      expect(admin.guardadas, isEmpty);
    });
  });

  group('Colección en el editor de productos', () {
    testWidgets('el producto se guarda con la colección elegida', (
      tester,
    ) async {
      final admin = await _alPanel(tester);
      await _tocar(tester, _llave('seccion-productos'));
      await _tocar(
        tester,
        find.descendant(
          of: _llave('prod-admin-2'),
          matching: _llave('editar-producto'),
        ),
      );

      await _tocar(tester, _llave('prod-coleccion'));
      await _tocar(tester, find.text('Feria').last);
      await _tocar(tester, _llave('guardar-producto'));

      expect(admin.productosGuardados.last.idColeccion, 10);
    });
  });
}
