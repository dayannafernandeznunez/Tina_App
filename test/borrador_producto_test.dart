import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/logic/borrador_producto.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/theme/colores_producto.dart';

BorradorProducto _valido() => const BorradorProducto(
  nombre: 'Collar nuevo',
  precio: '55.000',
  idCategoria: 1,
  variantes: [
    BorradorVariante(clave: 'a', color: 'Naranja', stock: 4),
    BorradorVariante(clave: 'b', color: 'Blanco', talla: 'M', stock: 2),
  ],
);

void main() {
  group('Formulario de producto', () {
    test('un producto completo no tiene errores', () {
      expect(_valido().errores(), isEmpty);
    });

    test('el precio acepta puntos, signo de pesos y espacios', () {
      for (final texto in ['55000', '55.000', r'$55.000', ' 55 000 ']) {
        expect(_valido().copyWith(precio: texto).precioEnPesos, 55000);
      }
    });

    test('pide nombre, precio y categoría', () {
      final e = const BorradorProducto(
        variantes: [BorradorVariante(clave: 'a', color: 'Rojo')],
      ).errores();

      expect(e.keys, containsAll(['nombre', 'precio', 'categoria']));
    });

    test('un precio en cero o sin números es inválido', () {
      expect(_valido().copyWith(precio: '0').errores(), contains('precio'));
      expect(
        _valido().copyWith(precio: 'gratis').errores(),
        contains('precio'),
      );
    });

    test('pide al menos una variante y un color en cada una', () {
      expect(
        _valido().copyWith(variantes: []).errores(),
        contains('variantes'),
      );
      final sinColor = _valido().conVariante(
        'a',
        (v) => v.copyWith(color: ' '),
      );
      expect(sinColor.errores(), contains('color-a'));
    });

    test('no deja repetir la misma combinación de color y talla', () {
      final repetido = _valido().conVariante(
        'b',
        (v) => v.copyWith(color: 'naranja', talla: 'única'),
      );

      expect(repetido.errores(), contains('color-b'));
    });

    test('el mismo color con otra talla sí se puede', () {
      final distinto = _valido().conVariante(
        'b',
        (v) => v.copyWith(color: 'Naranja', talla: 'L'),
      );

      expect(distinto.errores(), isEmpty);
    });

    test('al armar el producto limpia los espacios', () {
      final p = _valido()
          .copyWith(nombre: '  Collar  ', tecnica: ' Tejido ')
          .aProducto();

      expect(p.nombre, 'Collar');
      expect(p.tecnica, 'Tejido');
      expect(p.precio, 55000);
    });

    test('una talla vacía se guarda como "Única"', () {
      final v = const BorradorVariante(
        clave: 'a',
        color: 'Rojo',
        talla: ' ',
      ).aVariante(7);

      expect(v.talla, 'Única');
      expect(v.idProducto, 7);
    });

    test(
      'al abrir un producto existente recuerda sus variantes originales',
      () {
        const producto = Producto(
          idProducto: 3,
          idCategoria: 2,
          nombre: 'Aretes',
          descripcion: 'Livianos',
          tecnica: 'Porcelanicrón',
          precio: 18000,
        );
        final variantes = [
          const VarianteProducto(
            idVariante: 5,
            idProducto: 3,
            color: 'Nude',
            talla: 'Única',
            stock: 10,
          ),
          const VarianteProducto(
            idVariante: 6,
            idProducto: 3,
            color: 'Blanco',
            talla: 'Única',
            stock: 8,
          ),
        ];

        final borrador = BorradorProducto.desde(producto, variantes);

        expect(borrador.esNuevo, isFalse);
        expect(borrador.precio, '18000');
        expect(borrador.idsVariantesOriginales, [5, 6]);
        expect(borrador.stockTotal, 18);
        expect(borrador.errores(), isEmpty);
      },
    );

    test('un producto nuevo empieza con una variante en blanco', () {
      final borrador = BorradorProducto.nuevo(
        idCategoria: 1,
        claveVariante: 'n0',
      );

      expect(borrador.esNuevo, isTrue);
      expect(borrador.variantes.length, 1);
      expect(borrador.errores(), contains('color-n0'));
    });
  });

  group('Colores', () {
    test('reconoce el color sin importar mayúsculas ni tildes', () {
      expect(colorDeProducto('cafe'), colorDeProducto('Café'));
      expect(colorDeProducto('  NARANJA '), colorDeProducto('Naranja'));
    });

    test('un color desconocido sale gris', () {
      expect(
        colorDeProducto('Arcoíris cuántico'),
        colorDeProducto('otro raro'),
      );
    });
  });
}
