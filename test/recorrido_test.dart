import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/components/components.dart';
import 'package:tina_app/screens/tina_screen.dart';
import 'package:tina_app/theme/tina_tema.dart';

Future<void> _abrirApp(WidgetTester tester) async {
  TinaTipografia.usarFuenteWeb = false;
  tester.view.physicalSize = const Size(450, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: TinaTema.crear(), home: const TinaScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: true);
  await tester.pumpAndSettle();
}

Future<void> _escribir(
  WidgetTester tester,
  String clave,
  String texto, {
  String prefijo = 'campo',
}) async {
  final campo = find.descendant(
    of: find.byKey(ValueKey('$prefijo-$clave')),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}

Finder _llave(String llave) => find.byKey(ValueKey(llave));

Future<void> _abrirProducto(WidgetTester tester, int id) =>
    _tocar(tester, _llave('producto-$id'));

Future<void> _agregarAlCarrito(WidgetTester tester) =>
    _tocar(tester, find.textContaining('Agregar al carrito'));

Future<void> _llenarEnvio(WidgetTester tester) async {
  await _escribir(tester, 'nombre', 'Isabella Vergara');
  await _escribir(tester, 'telefono', '3001234567');
  await _escribir(tester, 'correo', 'isabella@correo.com');
  await _escribir(tester, 'direccion', 'Calle 5 #38-20');
  await _escribir(tester, 'ciudad', 'Cali');
  await _escribir(tester, 'departamento', 'Valle del Cauca');
}

void main() {
  group('Catálogo y detalle', () {
    testWidgets('la portada muestra los productos y las categorías', (
      tester,
    ) async {
      await _abrirApp(tester);

      expect(find.text('Tan latinas'), findsOneWidget);
      expect(find.text('Maxi collar 3D con mostacilla'), findsOneWidget);
      expect(find.text('Imán de porcelanicrón sol'), findsOneWidget);
      expect(_llave('chip-Pulseras'), findsOneWidget);
    });

    testWidgets('una categoría filtra la lista y "Todos" vuelve a la portada', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('chip-Pulseras'));
      expect(find.text('2 accesorios'), findsOneWidget);
      expect(find.text('Pulsera tejida'), findsOneWidget);
      expect(find.text('Aretes mini flor'), findsNothing);

      await _tocar(tester, _llave('chip-Todos'));
      expect(find.text('Tan latinas'), findsOneWidget);
    });

    testWidgets('el detalle muestra el stock y respeta el límite de cantidad', (
      tester,
    ) async {
      await _abrirApp(tester);
      await _abrirProducto(tester, 1);

      expect(find.text('Quedan 5'), findsNothing);
      expect(find.text('Naranja'), findsOneWidget);

      // Cambia a Blanco (stock 4) e intenta pasar del stock.
      await _tocar(tester, _llave('color-Blanco'));
      expect(find.text('Quedan 4'), findsOneWidget);
      for (var i = 0; i < 8; i++) {
        await _tocar(tester, _llave('cantidad-mas'));
      }
      expect(find.text('4'), findsOneWidget);
      expect(find.text(r'Agregar al carrito · $220.000'), findsOneWidget);
    });

    testWidgets('al cambiar de color la talla se ajusta a las que existen', (
      tester,
    ) async {
      await _abrirApp(tester);
      await _abrirProducto(tester, 5);

      await _tocar(tester, _llave('talla-L'));
      await _tocar(tester, _llave('color-Beige'));

      expect(_llave('talla-L'), findsOneWidget);
      expect(find.text('Beige'), findsOneWidget);
    });

    testWidgets('la flecha de las fotos cambia la foto y atrás vuelve', (
      tester,
    ) async {
      await _abrirApp(tester);
      await _abrirProducto(tester, 3);

      expect(find.text('Foto 1 de 3'), findsOneWidget);
      await _tocar(tester, _llave('foto-siguiente'));
      expect(find.text('Foto 2 de 3'), findsOneWidget);
      await _tocar(tester, _llave('foto-anterior'));
      await _tocar(tester, _llave('foto-anterior'));
      expect(find.text('Foto 3 de 3'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Volver'), warnIfMissed: false);
      await tester.pumpAndSettle();
    });
  });

  group('Carrito', () {
    testWidgets('crear, editar y eliminar se reflejan en pantalla', (
      tester,
    ) async {
      await _abrirApp(tester);

      // Crear: agrega 2 collares.
      await _abrirProducto(tester, 1);
      await _tocar(tester, _llave('cantidad-mas'));
      await _agregarAlCarrito(tester);

      expect(find.text('Tu carrito'), findsOneWidget);
      expect(find.text('Maxi collar 3D con mostacilla'), findsOneWidget);
      expect(find.text(r'$110.000'), findsWidgets);
      expect(find.text('2'), findsWidgets);

      // Editar: sube la cantidad a 3.
      await _tocar(tester, _llave('cantidad-mas'));
      expect(find.text(r'$165.000'), findsWidgets);

      // Eliminar: quita la línea y el carrito queda vacío.
      await _tocar(tester, _llave('quitar'));
      expect(find.text('Tu carrito está vacío'), findsOneWidget);
    });

    testWidgets('agregar dos veces la misma variante suma la cantidad', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _abrirProducto(tester, 3);
      await _agregarAlCarrito(tester);
      await tester.tap(find.bySemanticsLabel('Volver'));
      await tester.pumpAndSettle();
      await _abrirProducto(tester, 3);
      await _agregarAlCarrito(tester);

      expect(find.byKey(const ValueKey('item-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('item-2')), findsNothing);
      expect(find.text(r'$36.000'), findsWidgets);
    });

    testWidgets('14 unidades reciben el 30% de descuento', (tester) async {
      await _abrirApp(tester);

      // 10 aretes (Nude, stock 10).
      await _abrirProducto(tester, 3);
      for (var i = 0; i < 9; i++) {
        await _tocar(tester, _llave('cantidad-mas'));
      }
      await _agregarAlCarrito(tester);
      expect(
        find.textContaining('Te faltan 4 unidades para el 30%'),
        findsOneWidget,
      );
      expect(find.textContaining('Descuento'), findsNothing);

      // Vuelve a la portada y suma 4 imanes.
      await tester.tap(find.bySemanticsLabel('Volver'));
      await tester.pumpAndSettle();
      await _abrirProducto(tester, 7);
      for (var i = 0; i < 3; i++) {
        await _tocar(tester, _llave('cantidad-mas'));
      }
      await _agregarAlCarrito(tester);

      expect(
        find.textContaining('Ya tienes 14 o más unidades'),
        findsOneWidget,
      );
      expect(find.text('Descuento 30% (14+ unidades)'), findsOneWidget);
      // 10 × 18.000 + 4 × 12.000 = 228.000; 30% = 68.400; total 159.600
      expect(find.text(r'−$68.400'), findsOneWidget);
      expect(find.text(r'$159.600'), findsOneWidget);
    });
  });

  group('Compra', () {
    testWidgets('invitada: valida los datos, paga y se descuenta el stock', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _abrirProducto(tester, 1);
      await _tocar(tester, _llave('cantidad-mas'));
      await _agregarAlCarrito(tester);
      await _tocar(tester, find.text('Continuar'));
      expect(find.text('Finalizar compra'), findsOneWidget);

      // Sin datos no deja pagar y marca los campos.
      await _tocar(tester, find.textContaining('Pagar con Wompi'));
      expect(find.text('Obligatorio'), findsWidgets);
      expect(find.text('Finalizar compra'), findsOneWidget);

      await _llenarEnvio(tester);
      await _tocar(tester, find.textContaining('Pagar con Wompi'));

      expect(find.text('confirmado!'), findsOneWidget);
      expect(find.text('TINA-0015'), findsOneWidget);
      expect(find.text('C-0015'), findsOneWidget);
      expect(find.text(r'$110.000'), findsOneWidget);

      // El stock del collar naranja bajó de 6 a 4.
      await _tocar(tester, find.text('Seguir comprando'));
      await _abrirProducto(tester, 1);
      expect(find.text('Quedan 4'), findsOneWidget);
    });

    testWidgets('con cuenta: inicia sesión desde el checkout y recibe el 20%', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _abrirProducto(tester, 5);
      await _agregarAlCarrito(tester);
      await _tocar(tester, find.text('Continuar'));

      // Elegir "con cuenta" sin sesión lleva a iniciar sesión.
      await _tocar(tester, _llave('opcion-cuenta'));
      expect(find.text('Inicia sesión'), findsOneWidget);

      await _escribir(
        tester,
        'correo',
        'valentina.rios@correo.com',
        prefijo: 'login',
      );
      await _escribir(tester, 'clave', 'contrasena1', prefijo: 'login');
      await _tocar(tester, find.text('Iniciar sesión'));

      // Vuelve al checkout, con los datos conocidos y el descuento aplicado.
      expect(find.text('Finalizar compra'), findsOneWidget);
      expect(
        find.text('Descuento 20% (primera compra con cuenta)'),
        findsOneWidget,
      );
      expect(find.text('Comprar con mi cuenta'), findsOneWidget);

      // Los datos conocidos aparecen en los campos, sin avisos de error.
      String textoDe(String clave) => tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(ValueKey('campo-$clave')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text;
      expect(textoDe('nombre'), 'Valentina Ríos');
      expect(textoDe('correo'), 'valentina.rios@correo.com');
      expect(textoDe('telefono'), '3056667788');
      expect(find.text('Obligatorio'), findsNothing);
    });

    testWidgets('invitada no recibe el 20%', (tester) async {
      await _abrirApp(tester);

      await _abrirProducto(tester, 5);
      await _agregarAlCarrito(tester);

      expect(find.textContaining('Descuento'), findsNothing);
      expect(
        find.textContaining('El 20% se aplica si compras con cuenta'),
        findsOneWidget,
      );
    });
  });

  group('Cuenta', () {
    testWidgets('inicio de sesión incorrecto muestra el error', (tester) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('nav-cuenta'));
      await _escribir(tester, 'correo', 'nadie@correo.com', prefijo: 'login');
      await _escribir(tester, 'clave', 'contrasena1', prefijo: 'login');
      await _tocar(tester, find.text('Iniciar sesión'));

      expect(
        find.text('No encontramos una cuenta con ese correo.'),
        findsOneWidget,
      );
    });

    testWidgets('iniciar sesión con campos vacíos pide cada dato', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('nav-cuenta'));
      await _tocar(tester, find.text('Iniciar sesión'));
      expect(find.text('Escribe tu correo.'), findsOneWidget);

      await _escribir(
        tester,
        'correo',
        'valentina.rios@correo.com',
        prefijo: 'login',
      );
      await _tocar(tester, find.text('Iniciar sesión'));
      expect(find.text('Mínimo 8 caracteres'), findsWidgets);

      await _tocar(tester, _llave('login-toggle'));
      await _tocar(tester, find.text('Crear cuenta'));
      expect(find.text('Escribe tu nombre.'), findsOneWidget);
    });

    testWidgets('registrarse con un correo que ya tiene cuenta se rechaza', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('nav-cuenta'));
      await _tocar(tester, _llave('login-toggle'));
      await _escribir(tester, 'nombre', 'Otra Persona', prefijo: 'login');
      await _escribir(
        tester,
        'correo',
        'sara.valencia@correo.com',
        prefijo: 'login',
      );
      await _escribir(tester, 'clave', 'contrasena1', prefijo: 'login');
      await _tocar(tester, find.text('Crear cuenta'));

      expect(find.text('Ya existe una cuenta con ese correo.'), findsOneWidget);
    });

    testWidgets('crear una cuenta nueva, ver la cuenta y cerrar sesión', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('nav-cuenta'));
      await _tocar(tester, _llave('login-toggle'));
      await _escribir(tester, 'nombre', 'Isabella Vergara', prefijo: 'login');
      await _escribir(
        tester,
        'correo',
        'isabella@correo.com',
        prefijo: 'login',
      );
      await _escribir(tester, 'clave', 'contrasena1', prefijo: 'login');
      await _tocar(tester, find.text('Crear cuenta'));

      // Llega a la portada (la intro termina sola) y abre su cuenta.
      await _tocar(tester, _llave('nav-cuenta'));

      expect(find.text('Isabella Vergara'), findsOneWidget);
      expect(find.textContaining('Todavía no tienes pedidos'), findsOneWidget);

      await _tocar(tester, find.text('Cerrar sesión'));
      expect(find.text('Tan latinas'), findsOneWidget);
    });

    testWidgets('una clienta ve sus pedidos y abre el detalle con historial', (
      tester,
    ) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('nav-cuenta'));
      await _escribir(
        tester,
        'correo',
        'laura.caicedo@correo.com',
        prefijo: 'login',
      );
      await _escribir(tester, 'clave', 'contrasena1', prefijo: 'login');
      await _tocar(tester, find.text('Iniciar sesión'));
      await _tocar(tester, _llave('nav-cuenta'));

      expect(find.text('Laura Caicedo'), findsOneWidget);
      expect(_llave('mi-pedido-TINA-0012'), findsOneWidget);
      expect(_llave('mi-pedido-TINA-0008'), findsOneWidget);
      expect(_llave('mi-pedido-TINA-0010'), findsNothing);

      await _tocar(tester, _llave('mi-pedido-TINA-0012'));
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('GUIA-4821937'), findsOneWidget);
    });
  });

  group('Panel de la vendedora', () {
    Future<void> irAlPanel(WidgetTester tester) async {
      await _tocar(tester, _llave('nav-cuenta'));
      await _tocar(tester, _llave('ir-panel'));
    }

    testWidgets('lista los pedidos y filtra por estado', (tester) async {
      await _abrirApp(tester);
      await irAlPanel(tester);

      expect(find.text('7 pedidos'), findsOneWidget);
      expect(_llave('pedido-TINA-0014'), findsOneWidget);

      await _tocar(tester, _llave('filtro-entregado'));
      expect(_llave('pedido-TINA-0013'), findsOneWidget);
      expect(_llave('pedido-TINA-0008'), findsOneWidget);
      expect(_llave('pedido-TINA-0014'), findsNothing);
    });

    testWidgets('cambiar el estado se refleja y queda en el historial', (
      tester,
    ) async {
      await _abrirApp(tester);
      await irAlPanel(tester);

      // TINA-0010 está pagado: pasa a "Enviado".
      await _tocar(tester, _llave('estado-TINA-0010'));
      await tester.tap(find.text('Enviado').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('TINA-0010 ahora está: Enviado'),
        findsOneWidget,
      );

      // El filtro de enviados ahora tiene dos pedidos.
      await _tocar(tester, _llave('filtro-enviado'));
      expect(_llave('pedido-TINA-0010'), findsOneWidget);
      expect(_llave('pedido-TINA-0012'), findsOneWidget);

      // El detalle muestra la guía nueva y el cambio con quién lo hizo.
      await _tocar(tester, _llave('pedido-TINA-0010'));
      expect(find.text('GUIA-4800010'), findsOneWidget);
      expect(find.textContaining('Antes: Pagado'), findsOneWidget);
      expect(find.textContaining('Administradora Tina'), findsWidgets);
    });

    testWidgets('cancelar un pedido devuelve el stock al catálogo', (
      tester,
    ) async {
      await _abrirApp(tester);
      await irAlPanel(tester);

      // TINA-0012 llevó 1 collar naranja (stock 6): al cancelar queda en 7.
      await _tocar(tester, _llave('estado-TINA-0012'));
      await tester.tap(find.text('Cancelado').last);
      await tester.pumpAndSettle();

      await _tocar(tester, find.text('Ver tienda'));
      await _abrirProducto(tester, 1);
      expect(find.text('7 disponibles'), findsOneWidget);
    });

    testWidgets('una compra nueva aparece en el panel', (tester) async {
      await _abrirApp(tester);

      await _abrirProducto(tester, 3);
      await _agregarAlCarrito(tester);
      await _tocar(tester, find.text('Continuar'));
      await _llenarEnvio(tester);
      await _tocar(tester, find.textContaining('Pagar con Wompi'));
      await _tocar(tester, find.text('Seguir comprando'));

      await irAlPanel(tester);
      expect(find.text('8 pedidos'), findsOneWidget);
      expect(_llave('pedido-TINA-0015'), findsOneWidget);
      expect(find.textContaining('Isabella Vergara'), findsOneWidget);
    });
  });

  group('Navegación', () {
    testWidgets('la barra inferior recorre las secciones', (tester) async {
      await _abrirApp(tester);

      await _tocar(tester, _llave('nav-categorias'));
      expect(find.text('Collares'), findsWidgets);
      expect(find.text('2 accesorios'), findsOneWidget);

      await _tocar(tester, _llave('nav-carrito'));
      expect(find.text('Tu carrito está vacío'), findsOneWidget);

      await _tocar(tester, find.text('Ver accesorios'));
      expect(find.text('Tan latinas'), findsOneWidget);

      await _tocar(tester, _llave('nav-cuenta'));
      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.byType(TinaNavInferior), findsOneWidget);
    });
  });
}
