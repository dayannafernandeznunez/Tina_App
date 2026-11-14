import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/administradora.dart';
import 'package:tina_app/data/catalogo.dart';
import 'package:tina_app/data/sesion.dart';
import 'package:tina_app/main.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/theme/tina_tema.dart';

/// La parte de fotos de la administradora, de mentira: todo en memoria.
class _AdminFalsa implements AdministradoraRepositorio {
  int _siguiente = 100;

  final List<String> llamadas = [];
  List<ImagenProducto> ordenRecibido = [];

  @override
  Future<ImagenProducto> subirFotoProducto({
    required int idProducto,
    required FotoElegida foto,
    required int orden,
  }) async {
    llamadas.add('subir:$idProducto:$orden');
    final id = _siguiente++;
    return ImagenProducto(
      idImagen: id,
      idProducto: idProducto,
      url: 'https://ejemplo.invalid/$id.jpg',
      ruta: 'producto-$idProducto/$id.jpg',
      orden: orden,
    );
  }

  @override
  Future<void> borrarFotoProducto(ImagenProducto foto) async {
    llamadas.add('borrar:${foto.idImagen}');
  }

  @override
  Future<void> ordenarFotosProducto(List<ImagenProducto> enOrden) async {
    llamadas.add('ordenar');
    ordenRecibido = enOrden;
  }

  @override
  Future<AjusteSitio> subirFotoSitio({
    required AjusteSitio ajuste,
    required FotoElegida foto,
  }) async {
    llamadas.add('sitio:${ajuste.clave}');
    return AjusteSitio(
      clave: ajuste.clave,
      descripcion: ajuste.descripcion,
      url: 'https://ejemplo.invalid/${ajuste.clave}.jpg',
      ruta: '${ajuste.clave}/a.jpg',
    );
  }

  @override
  Future<AjusteSitio> quitarFotoSitio(AjusteSitio ajuste) async {
    llamadas.add('quitar:${ajuste.clave}');
    return AjusteSitio(clave: ajuste.clave, descripcion: ajuste.descripcion);
  }
}

/// El inicio de sesión de mentira, con una administradora y una clienta.
class _SesionFalsa implements SesionRepositorio {
  _SesionFalsa({this.restaurada, this.pideConfirmar = false});

  SesionActiva? restaurada;
  final bool pideConfirmar;
  final List<String> llamadas = [];

  static const _cuentas = {
    'tina@correo.com': ('Tina', true),
    'sara@correo.com': ('Sara', false),
  };

  SesionActiva _sesion(String correo, String nombre, bool admin, int id) =>
      SesionActiva(
        cliente: Cliente(
          idCliente: id,
          nombre: nombre,
          correo: correo,
          telefono: '',
          cuentaRegistrada: true,
          fechaRegistro: DateTime(2026, 11, 14),
        ),
        esAdministradora: admin,
      );

  @override
  Future<SesionActiva?> restaurar() async => restaurada;

  @override
  Future<SesionActiva> iniciarSesion(String correo, String clave) async {
    llamadas.add('entrar:$correo');
    final cuenta = _cuentas[correo];
    if (cuenta == null || clave != 'clave-buena') {
      throw const ErrorSesion('Correo o contraseña incorrectos.');
    }
    return _sesion(correo, cuenta.$1, cuenta.$2, cuenta.$2 ? 900 : 901);
  }

  @override
  Future<ResultadoRegistro> registrar({
    required String nombre,
    required String correo,
    required String clave,
  }) async {
    llamadas.add('registrar:$correo');
    if (_cuentas.containsKey(correo)) {
      throw const ErrorSesion('Ya existe una cuenta con ese correo.');
    }
    if (pideConfirmar) return const ResultadoRegistro();
    return ResultadoRegistro(sesion: _sesion(correo, nombre, false, 902));
  }

  @override
  Future<void> cerrarSesion() async {
    llamadas.add('salir');
  }
}

class _SelectorFalso implements SelectorFotos {
  _SelectorFalso([this.nombre = 'collar.jpg']);

  String? nombre;
  int veces = 0;

  @override
  Future<FotoElegida?> elegir() async {
    veces++;
    if (nombre == null) return null;
    return FotoElegida(bytes: Uint8List(16), nombre: nombre!);
  }
}

/// Catálogo con un solo artículo (id 1), una foto ya subida y los lugares del
/// sitio sin foto.
class _CatalogoUno implements CatalogoRepositorio {
  @override
  Future<Catalogo> cargar() async => const Catalogo(
    categorias: [
      Categoria(idCategoria: 1, nombre: 'Collares', descripcion: ''),
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
    imagenes: [
      ImagenProducto(
        idImagen: 1,
        idProducto: 1,
        url: 'https://ejemplo.invalid/1.jpg',
        ruta: 'producto-1/1.jpg',
        orden: 1,
      ),
    ],
    ajustesSitio: [
      AjusteSitio(clave: 'portada_inicio', descripcion: 'Portada del inicio'),
      AjusteSitio(clave: 'logo', descripcion: 'Logo de Tina'),
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

SesionActiva _adminGuardada() => SesionActiva(
  cliente: Cliente(
    idCliente: 900,
    nombre: 'Tina',
    correo: 'tina@correo.com',
    telefono: '',
    cuentaRegistrada: true,
    fechaRegistro: DateTime(2026, 11, 14),
  ),
  esAdministradora: true,
);

Future<void> _abrir(
  WidgetTester tester, {
  required _SesionFalsa sesiones,
  _AdminFalsa? admin,
  _SelectorFalso? selector,
}) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = const Size(450, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    TinaApp(
      catalogo: _CatalogoUno(),
      sesiones: sesiones,
      admin: admin ?? _AdminFalsa(),
      selectorFotos: selector ?? _SelectorFalso(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Abre el ingreso de la tienda y entra con el formulario de siempre.
Future<void> _entrar(
  WidgetTester tester, {
  String correo = 'tina@correo.com',
  String clave = 'clave-buena',
}) async {
  await _tocar(tester, _llave('nav-cuenta'));
  await _escribir(tester, 'login-correo', correo);
  await _escribir(tester, 'login-clave', clave);
  await _tocar(tester, find.text('Iniciar sesión'));
}

void main() {
  group('Un solo inicio de sesión', () {
    testWidgets('el ingreso no tiene acceso aparte para vendedora', (
      tester,
    ) async {
      await _abrir(tester, sesiones: _SesionFalsa());
      await _tocar(tester, _llave('nav-cuenta'));

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(_llave('ir-panel'), findsNothing);
      expect(find.textContaining('vendedora'), findsNothing);
      expect(find.textContaining('Para probar'), findsNothing);
    });

    testWidgets(
      'la administradora entra por el mismo formulario y llega al panel',
      (tester) async {
        final sesiones = _SesionFalsa();
        await _abrir(tester, sesiones: sesiones);
        await _entrar(tester);

        expect(find.text('Panel de vendedora'), findsOneWidget);
        expect(_llave('seccion-fotosArticulos'), findsOneWidget);
        expect(sesiones.llamadas, contains('entrar:tina@correo.com'));
      },
    );

    testWidgets('una clienta entra y va a la tienda, sin panel', (
      tester,
    ) async {
      await _abrir(tester, sesiones: _SesionFalsa());
      await _entrar(tester, correo: 'sara@correo.com');

      expect(find.text('Panel de vendedora'), findsNothing);
      expect(_llave('seccion-fotosArticulos'), findsNothing);

      await _tocar(tester, _llave('nav-cuenta'));
      expect(find.text('Sara'), findsOneWidget);
      expect(_llave('ir-panel-cuenta'), findsNothing);
    });

    testWidgets('con contraseña incorrecta muestra el error y no entra', (
      tester,
    ) async {
      await _abrir(tester, sesiones: _SesionFalsa());
      await _entrar(tester, clave: 'mala-clave');

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(_llave('seccion-fotosArticulos'), findsNothing);
    });

    testWidgets('al registrarse con una cuenta nueva entra directo', (
      tester,
    ) async {
      await _abrir(tester, sesiones: _SesionFalsa());
      await _tocar(tester, _llave('nav-cuenta'));
      await _tocar(tester, _llave('login-toggle'));
      await _escribir(tester, 'login-nombre', 'Isabella');
      await _escribir(tester, 'login-correo', 'isabella@correo.com');
      await _escribir(tester, 'login-clave', 'clave-buena');
      await _tocar(tester, find.text('Crear cuenta'));

      await _tocar(tester, _llave('nav-cuenta'));
      expect(find.text('Isabella'), findsOneWidget);
      expect(_llave('ir-panel-cuenta'), findsNothing);
    });

    testWidgets(
      'si hay que confirmar el correo, lo avisa y vuelve al ingreso',
      (tester) async {
        await _abrir(tester, sesiones: _SesionFalsa(pideConfirmar: true));
        await _tocar(tester, _llave('nav-cuenta'));
        await _tocar(tester, _llave('login-toggle'));
        await _escribir(tester, 'login-nombre', 'Isabella');
        await _escribir(tester, 'login-correo', 'isabella@correo.com');
        await _escribir(tester, 'login-clave', 'clave-buena');
        await _tocar(tester, find.text('Crear cuenta'));

        expect(
          find.text(
            'Te enviamos un correo para confirmar tu cuenta. Después inicia sesión.',
          ),
          findsOneWidget,
        );
        expect(find.text('Inicia sesión'), findsOneWidget);
      },
    );

    testWidgets('un correo que ya existe no se puede registrar de nuevo', (
      tester,
    ) async {
      await _abrir(tester, sesiones: _SesionFalsa());
      await _tocar(tester, _llave('nav-cuenta'));
      await _tocar(tester, _llave('login-toggle'));
      await _escribir(tester, 'login-nombre', 'Sara');
      await _escribir(tester, 'login-correo', 'sara@correo.com');
      await _escribir(tester, 'login-clave', 'clave-buena');
      await _tocar(tester, find.text('Crear cuenta'));

      expect(find.text('Ya existe una cuenta con ese correo.'), findsOneWidget);
    });

    testWidgets('pide cada dato que falta', (tester) async {
      await _abrir(tester, sesiones: _SesionFalsa());
      await _tocar(tester, _llave('nav-cuenta'));

      await _tocar(tester, find.text('Iniciar sesión'));
      expect(find.text('Escribe tu correo.'), findsOneWidget);
    });

    testWidgets(
      'si la administradora ya tenía sesión, su cuenta ofrece el panel',
      (tester) async {
        await _abrir(
          tester,
          sesiones: _SesionFalsa(restaurada: _adminGuardada()),
        );
        await _tocar(tester, _llave('nav-cuenta'));

        expect(find.text('Tina'), findsWidgets);
        await _tocar(tester, _llave('ir-panel-cuenta'));
        expect(_llave('seccion-fotosArticulos'), findsOneWidget);
      },
    );

    testWidgets('con cuentas reales no hay pedidos de ejemplo', (tester) async {
      await _abrir(tester, sesiones: _SesionFalsa());
      await _entrar(tester);

      expect(find.text('0 pedidos'), findsOneWidget);
    });

    testWidgets('cerrar sesión cierra la cuenta y vuelve a la tienda', (
      tester,
    ) async {
      final sesiones = _SesionFalsa();
      await _abrir(tester, sesiones: sesiones);
      await _entrar(tester);
      await _tocar(tester, find.text('Cerrar sesión'));

      expect(sesiones.llamadas, contains('salir'));
      expect(find.text('Tan latinas'), findsOneWidget);

      // Ya sin sesión, la cuenta vuelve a pedir ingreso.
      await _tocar(tester, _llave('nav-cuenta'));
      expect(find.text('Inicia sesión'), findsOneWidget);
    });
  });

  group('Fotos de artículos', () {
    Future<_AdminFalsa> abrirFotos(
      WidgetTester tester, {
      _SelectorFalso? selector,
    }) async {
      final admin = _AdminFalsa();
      await _abrir(
        tester,
        sesiones: _SesionFalsa(),
        admin: admin,
        selector: selector,
      );
      await _entrar(tester);
      await _tocar(tester, _llave('seccion-fotosArticulos'));
      return admin;
    }

    testWidgets('muestra las fotos que ya tiene el artículo', (tester) async {
      await abrirFotos(tester);

      expect(find.text('Fotos de artículos'), findsWidgets);
      expect(_llave('foto-admin-1'), findsOneWidget);
      expect(find.text('Principal'), findsOneWidget);
    });

    testWidgets('sube una foto y aparece al final', (tester) async {
      final admin = await abrirFotos(tester);

      await _tocar(tester, find.text('Subir foto'));

      expect(admin.llamadas, contains('subir:1:2'));
      expect(_llave('foto-admin-100'), findsOneWidget);
      expect(_llave('foto-admin-1'), findsOneWidget);
      expect(find.text('Foto subida.'), findsOneWidget);
    });

    testWidgets('si cierra el selector sin elegir, no sube nada', (
      tester,
    ) async {
      final selector = _SelectorFalso(null);
      final admin = await abrirFotos(tester, selector: selector);

      await _tocar(tester, find.text('Subir foto'));

      expect(selector.veces, 1);
      expect(admin.llamadas.where((l) => l.startsWith('subir')), isEmpty);
    });

    testWidgets('rechaza un archivo que no es una foto permitida', (
      tester,
    ) async {
      final admin = await abrirFotos(
        tester,
        selector: _SelectorFalso('lista.pdf'),
      );

      await _tocar(tester, find.text('Subir foto'));

      expect(find.text('Usa una foto JPG, PNG o WEBP.'), findsOneWidget);
      expect(admin.llamadas.where((l) => l.startsWith('subir')), isEmpty);
    });

    testWidgets('hace principal la segunda foto', (tester) async {
      final admin = await abrirFotos(tester);
      await _tocar(tester, find.text('Subir foto'));

      await _tocar(
        tester,
        find.descendant(
          of: _llave('foto-admin-100'),
          matching: find.text('Hacer principal'),
        ),
      );

      expect(admin.llamadas, contains('ordenar'));
      expect(admin.ordenRecibido.map((f) => f.idImagen), [100, 1]);
      // Ahora la 100 es la principal: solo la 1 ofrece "Hacer principal".
      expect(
        find.descendant(
          of: _llave('foto-admin-100'),
          matching: find.text('Hacer principal'),
        ),
        findsNothing,
      );
    });

    testWidgets('borra una foto después de confirmar', (tester) async {
      final admin = await abrirFotos(tester);

      await _tocar(tester, find.text('Borrar'));
      // Cancelar no borra.
      await _tocar(tester, _llave('borrar-no'));
      expect(admin.llamadas.where((l) => l.startsWith('borrar')), isEmpty);
      expect(_llave('foto-admin-1'), findsOneWidget);

      await _tocar(tester, find.text('Borrar'));
      await _tocar(tester, _llave('borrar-si'));

      expect(admin.llamadas, contains('borrar:1'));
      expect(_llave('foto-admin-1'), findsNothing);
      expect(_llave('sin-fotos'), findsOneWidget);
    });
  });

  group('Fotos del sitio', () {
    Future<_AdminFalsa> abrirSitio(WidgetTester tester) async {
      final admin = _AdminFalsa();
      await _abrir(tester, sesiones: _SesionFalsa(), admin: admin);
      await _entrar(tester);
      await _tocar(tester, _llave('seccion-fotosSitio'));
      return admin;
    }

    testWidgets('lista los lugares y avisa los que aún no se usan', (
      tester,
    ) async {
      await abrirSitio(tester);

      expect(_llave('ajuste-portada_inicio'), findsOneWidget);
      expect(_llave('ajuste-logo'), findsOneWidget);
      expect(_llave('sin-uso-logo'), findsOneWidget);
      expect(_llave('sin-uso-portada_inicio'), findsNothing);
    });

    testWidgets('sube la foto de la portada y se ve en la tienda', (
      tester,
    ) async {
      final admin = await abrirSitio(tester);

      await _tocar(tester, _llave('subir-portada_inicio'));

      expect(admin.llamadas, contains('sitio:portada_inicio'));
      expect(find.text('Cambiar foto'), findsOneWidget);
      expect(_llave('quitar-portada_inicio'), findsOneWidget);
      expect(
        find.text('Foto guardada. Ya se ve en la tienda.'),
        findsOneWidget,
      );
    });

    testWidgets('quita la foto y vuelve el diseño por defecto', (tester) async {
      final admin = await abrirSitio(tester);
      await _tocar(tester, _llave('subir-portada_inicio'));

      await _tocar(tester, _llave('quitar-portada_inicio'));

      expect(admin.llamadas, contains('quitar:portada_inicio'));
      expect(_llave('quitar-portada_inicio'), findsNothing);
    });
  });
}
