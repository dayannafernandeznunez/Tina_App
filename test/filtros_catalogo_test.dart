import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/logic/filtros_catalogo.dart';
import 'package:tina_app/logic/vistas.dart';
import 'package:tina_app/models/models.dart';

ProductoVista _p(
  int id,
  String nombre,
  int precio,
  Map<String, int> stockPorColor,
) => ProductoVista(
  producto: Producto(
    idProducto: id,
    idCategoria: 1,
    nombre: nombre,
    descripcion: '',
    tecnica: '',
    precio: precio,
  ),
  categoria: 'Aretes',
  variantes: [
    for (final e in stockPorColor.entries)
      VarianteProducto(
        idVariante: id * 10 + e.key.length,
        idProducto: id,
        color: e.key,
        talla: 'Única',
        stock: e.value,
      ),
  ],
);

final _productos = [
  _p(1, 'Bruja', 70000, {'Negro': 3}),
  _p(2, 'Calabaza', 49000, {'Naranja': 5, 'Negro': 0}),
  _p(3, 'Fantasmita', 49000, {'Blanco': 0}),
  _p(4, 'Esférica', 90000, {'Rosado': 2, 'naranja': 1}),
];

List<int> _ids(List<ProductoVista> ps) => [
  for (final p in ps) p.producto.idProducto,
];

void main() {
  group('Filtros del catálogo', () {
    test('sin filtros se ven todos, en el mismo orden', () {
      expect(_ids(const FiltrosCatalogo().aplicar(_productos)), [1, 2, 3, 4]);
      expect(const FiltrosCatalogo().hayFiltros, isFalse);
      expect(const FiltrosCatalogo().activos, 0);
    });

    test('por color deja los que lo tienen, sin importar mayúsculas', () {
      final f = FiltrosCatalogo(colores: {claveColor('NARANJA')});

      expect(_ids(f.aplicar(_productos)), [2, 4]);
    });

    test('varios colores suman: sale el que tenga cualquiera', () {
      final f = FiltrosCatalogo(colores: {'blanco', 'rosado'});

      expect(_ids(f.aplicar(_productos)), [3, 4]);
    });

    test('solo disponibles quita los agotados', () {
      const f = FiltrosCatalogo(soloDisponibles: true);

      expect(_ids(f.aplicar(_productos)), [1, 2, 4]);
    });

    test('disponible y color: el color debe tener unidades', () {
      // "Calabaza" tiene Negro, pero con stock 0.
      final f = FiltrosCatalogo(colores: {'negro'}, soloDisponibles: true);

      expect(_ids(f.aplicar(_productos)), [1]);
    });

    test('el precio máximo es un tope, no un valor exacto', () {
      const f = FiltrosCatalogo(precioMaximo: 70000);

      expect(_ids(f.aplicar(_productos)), [1, 2, 3]);
    });

    test('se cuentan los filtros puestos, no el orden', () {
      final f = FiltrosCatalogo(
        colores: {'negro'},
        soloDisponibles: true,
        precioMaximo: 80000,
        orden: OrdenCatalogo.nombre,
      );

      expect(f.activos, 3);
      expect(f.sinFiltros().activos, 0);
      expect(f.sinFiltros().orden, OrdenCatalogo.nombre);
    });

    test('ordena por precio y por nombre', () {
      expect(
        _ids(
          const FiltrosCatalogo(orden: OrdenCatalogo.precioMenor)
              .aplicar(_productos),
        ),
        [2, 3, 1, 4],
      );
      expect(
        _ids(
          const FiltrosCatalogo(orden: OrdenCatalogo.precioMayor)
              .aplicar(_productos),
        ),
        [4, 1, 2, 3],
      );
      expect(
        _ids(
          const FiltrosCatalogo(orden: OrdenCatalogo.nombre)
              .aplicar(_productos),
        ),
        [1, 2, 4, 3],
      );
    });

    test('los colores se cuentan por producto, juntando mayúsculas', () {
      final colores = FiltrosCatalogo.coloresDe(_productos);

      expect(
        {for (final c in colores) c.nombre: c.productos},
        {'Blanco': 1, 'Naranja': 2, 'Negro': 2, 'Rosado': 1},
      );
    });

    test('el rango de precios va del más bajo al más alto', () {
      expect(FiltrosCatalogo.rangoDePrecios(_productos), (49000, 90000));
      expect(FiltrosCatalogo.rangoDePrecios(const []), isNull);
    });
  });
}
