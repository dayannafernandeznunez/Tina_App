import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/logic/busqueda.dart';
import 'package:tina_app/logic/vistas.dart';
import 'package:tina_app/models/models.dart';

ProductoVista _p(
  int id,
  String nombre,
  String categoria, {
  String descripcion = '',
  String? coleccion,
  List<String> colores = const ['Naranja'],
}) => ProductoVista(
  producto: Producto(
    idProducto: id,
    idCategoria: 1,
    nombre: nombre,
    descripcion: descripcion,
    tecnica: 'Porcelanicrón',
    precio: 10000,
  ),
  categoria: categoria,
  coleccion: coleccion,
  variantes: [
    for (var i = 0; i < colores.length; i++)
      VarianteProducto(
        idVariante: id * 10 + i,
        idProducto: id,
        color: colores[i],
        talla: 'Única',
        stock: 3,
      ),
  ],
);

final _productos = [
  _p(1, 'Aretes Calabaza', 'Aretes', colores: ['Naranja', 'Negro']),
  _p(2, 'Collar Corazón', 'Collares', coleccion: 'Con amor, para mí'),
  _p(3, 'Pulsera tejida', 'Pulseras', descripcion: 'Con cuentas de colores'),
  _p(4, 'Aretes Corazón', 'Aretes', colores: ['Rosado']),
];

List<int> _ids(List<ProductoVista> r) => [
  for (final p in r) p.producto.idProducto,
];

void main() {
  group('Buscador', () {
    test('sin nada escrito no hay resultados', () {
      expect(buscarProductos(_productos, ''), isEmpty);
      expect(buscarProductos(_productos, '   '), isEmpty);
    });

    test('busca en el nombre sin importar mayúsculas ni tildes', () {
      expect(_ids(buscarProductos(_productos, 'corazon')), [2, 4]);
      expect(_ids(buscarProductos(_productos, 'CORAZÓN')), [2, 4]);
    });

    test('todas las palabras tienen que aparecer', () {
      expect(_ids(buscarProductos(_productos, 'aretes corazon')), [4]);
      expect(buscarProductos(_productos, 'aretes pulsera'), isEmpty);
    });

    test('también busca en categoría, colores, colección y descripción', () {
      expect(_ids(buscarProductos(_productos, 'pulseras')), [3]);
      expect(_ids(buscarProductos(_productos, 'rosado')), [4]);
      expect(_ids(buscarProductos(_productos, 'con amor')), [2]);
      expect(_ids(buscarProductos(_productos, 'cuentas')), [3]);
    });

    test('los que tienen la palabra en el nombre van primero', () {
      // "aretes" está en el nombre de 1 y 4; "naranja" solo en un color de 1.
      expect(_ids(buscarProductos(_productos, 'aretes')), [1, 4]);
      final r = buscarProductos(_productos, 'corazon');
      expect(_ids(r).toSet(), {2, 4});
    });

    test('una palabra que no existe no da resultados', () {
      expect(buscarProductos(_productos, 'zzzz'), isEmpty);
    });

    test('normalizarTexto quita tildes, la eñe y las mayúsculas', () {
      expect(normalizarTexto('  Piña COLADA Ñandú  '), 'pina colada nandu');
    });
  });
}
