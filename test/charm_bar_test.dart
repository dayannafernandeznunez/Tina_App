import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/logic/charm_bar.dart';
import 'package:tina_app/logic/vistas.dart';
import 'package:tina_app/models/models.dart';

ProductoVista _vista(
  int id,
  String categoria,
  String nombre,
  int precio,
  List<(String, String, int)> variantes, {
  bool activo = true,
}) => ProductoVista(
  producto: Producto(
    idProducto: id,
    idCategoria: 1,
    nombre: nombre,
    descripcion: '',
    tecnica: '',
    precio: precio,
    activo: activo,
  ),
  categoria: categoria,
  variantes: [
    for (var i = 0; i < variantes.length; i++)
      VarianteProducto(
        idVariante: id * 100 + i,
        idProducto: id,
        color: variantes[i].$1,
        talla: variantes[i].$2,
        stock: variantes[i].$3,
      ),
  ],
);

final _vistas = [
  _vista(1, 'Charm Bar', 'Collar Charm Bar', 60000, [
    ('Palo rosa', 'Charms fijos', 3),
    ('Palo rosa', 'Charms removibles', 2),
    ('Naranja', 'Charms fijos', 0),
    ('Blanco', 'Charms fijos', 1),
  ]),
  _vista(2, 'Charms', 'Charm Corazón', 12000, [('Único', 'Única', 5)]),
  _vista(3, 'Charms', 'Charm Flor', 15000, [
    ('Roja', 'Única', 2),
    ('Azul', 'Única', 0),
  ]),
  _vista(4, 'Charms', 'Charm Oculto', 9000, [
    ('Único', 'Única', 5),
  ], activo: false),
  _vista(5, 'Aretes', 'Aretes de prueba', 18000, [('Nude', 'Única', 4)]),
];

void main() {
  group('Charm Bar', () {
    final bar = CharmBar.desde(_vistas);

    test('toma el collar base y los charms con unidades', () {
      expect(bar.base?.producto.nombre, 'Collar Charm Bar');
      expect(bar.charms.map((c) => c.nombre), [
        'Charm Corazón',
        'Charm Flor · Roja',
      ]);
      expect(bar.disponible, isTrue);
    });

    test('no muestra charms ocultos ni agotados', () {
      expect(
        bar.charms.any((c) => c.producto.nombre == 'Charm Oculto'),
        isFalse,
      );
      expect(bar.charms.any((c) => c.nombre.contains('Azul')), isFalse);
    });

    test('los colores y los modos salen de las variantes con unidades', () {
      expect(bar.colores, ['Palo rosa', 'Blanco']);
      expect(bar.modosDe('Palo rosa'), ['Charms fijos', 'Charms removibles']);
      expect(bar.modosDe('Naranja'), isEmpty);
    });

    test(
      'no está disponible si el collar base está oculto o no hay charms',
      () {
        final oculto = CharmBar.desde([
          _vista(1, 'Charm Bar', 'Collar', 60000, [
            ('Rosa', 'Fijos', 3),
          ], activo: false),
          _vistas[1],
        ]);
        expect(oculto.disponible, isFalse);

        final sinCharms = CharmBar.desde([_vistas[0]]);
        expect(sinCharms.disponible, isFalse);

        expect(const CharmBar().disponible, isFalse);
      },
    );
  });

  group('Armado del collar', () {
    final bar = CharmBar.desde(_vistas);
    final corazon = bar.charms.first.idVariante;
    final flor = bar.charms.last.idVariante;

    test('solo deja elegir tantos charms como se pidieron', () {
      var a = const ArmadoCollar(cantidad: 2);
      a = a.conCharm(corazon, 5).conCharm(corazon, 5).conCharm(flor, 2);

      expect(a.elegidos, 2);
      expect(a.completo, isTrue);
      expect(a.seleccion, {corazon: 2});
    });

    test('no deja pasar de las unidades que hay de un charm', () {
      var a = const ArmadoCollar(cantidad: 5);
      a = a.conCharm(flor, 2).conCharm(flor, 2).conCharm(flor, 2);

      expect(a.seleccion[flor], 2);
      expect(a.faltan, 3);
    });

    test('quitar un charm resta una unidad y borra el que llega a cero', () {
      var a = const ArmadoCollar(cantidad: 3)
          .conCharm(corazon, 5)
          .conCharm(corazon, 5);

      a = a.sinCharm(corazon);
      expect(a.seleccion, {corazon: 1});
      a = a.sinCharm(corazon);
      expect(a.seleccion, isEmpty);
      expect(a.sinCharm(corazon).seleccion, isEmpty);
    });

    test('al bajar la cantidad se quitan los últimos charms elegidos', () {
      var a = const ArmadoCollar(cantidad: 4)
          .conCharm(corazon, 5)
          .conCharm(corazon, 5)
          .conCharm(flor, 2)
          .conCharm(flor, 2);

      a = a.conCantidad(3);

      expect(a.cantidad, 3);
      expect(a.elegidos, 3);
      expect(a.seleccion, {corazon: 2, flor: 1});
    });

    test('la cantidad nunca baja de 1 ni pasa del máximo', () {
      expect(const ArmadoCollar().conCantidad(0).cantidad, 1);
      expect(
        const ArmadoCollar().conCantidad(99).cantidad,
        CharmBar.maximoCharms,
      );
    });

    test('el precio es el del collar más el de cada charm', () {
      var a = const ArmadoCollar(cantidad: 3)
          .conCharm(corazon, 5)
          .conCharm(corazon, 5)
          .conCharm(flor, 2);

      // 60.000 + 2 × 12.000 + 15.000
      expect(a.precio(bar), 99000);
      expect(const ArmadoCollar().precio(bar), 60000);
      expect(const ArmadoCollar().precio(const CharmBar()), 0);
    });
  });
}
