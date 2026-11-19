import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/administradora.dart';
import 'package:tina_app/logic/borrador_producto.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/theme/colores_producto.dart';

FotoNueva _foto(String clave, [String? color]) => FotoNueva(
  clave: clave,
  foto: FotoElegida(bytes: Uint8List.fromList([1, 2, 3]), nombre: '$clave.jpg'),
  color: color,
);

/// Un producto nuevo completo: con su portada, que es lo mínimo para crearlo.
BorradorProducto _valido() => BorradorProducto(
  nombre: 'Collar nuevo',
  precio: '55.000',
  idCategoria: 1,
  variantes: const [
    BorradorVariante(clave: 'a', color: 'Naranja', stock: 4),
    BorradorVariante(clave: 'b', color: 'Blanco', talla: 'M', stock: 2),
  ],
  fotosNuevas: [_foto('portada')],
);

void main() {
  group('Formulario de producto', () {
    test('un producto completo no tiene errores', () {
      expect(_valido().errores(), isEmpty);
    });

    test('un producto nuevo necesita su foto de portada', () {
      final sinFoto = _valido().copyWith(fotosNuevas: []);

      expect(sinFoto.errores(), contains('foto'));
      // Una foto de un color no reemplaza la portada.
      expect(
        sinFoto.copyWith(fotosNuevas: [_foto('f', 'Naranja')]).errores(),
        contains('foto'),
      );
    });

    test('un producto que ya existe no necesita portada para guardarse', () {
      const producto = Producto(
        idProducto: 3,
        idCategoria: 2,
        nombre: 'Aretes',
        descripcion: '',
        tecnica: '',
        precio: 18000,
      );
      final borrador = BorradorProducto.desde(producto, const [
        VarianteProducto(
          idVariante: 5,
          idProducto: 3,
          color: 'Nude',
          talla: 'Única',
          stock: 10,
        ),
      ]);

      expect(borrador.errores(), isEmpty);
    });

    test('separa las fotos por color sin distinguir mayúsculas', () {
      final b = _valido().copyWith(
        fotosNuevas: [
          _foto('p'),
          _foto('n1', 'Naranja'),
          _foto('n2', ' naranja '),
          _foto('b1', 'Blanco'),
        ],
      );

      expect(b.nuevasDe(null).map((f) => f.clave), ['p']);
      expect(b.nuevasDe('NARANJA').map((f) => f.clave), ['n1', 'n2']);
      expect(b.nuevasDe('Blanco').map((f) => f.clave), ['b1']);
      expect(b.colores, ['Naranja', 'Blanco']);
    });

    test('muestra cuánto stock tiene cada color', () {
      final b = _valido().conVariante(
        'b',
        (v) => v.copyWith(color: 'naranja', talla: 'L', stock: 3),
      );

      // Las dos filas son el mismo color con otra talla: se suman.
      expect(b.stockPorColor, {'Naranja': 7});
      expect(b.stockTotal, 7);
    });

    test('quitar una foto que ya tenía la marca para borrarla al guardar', () {
      const producto = Producto(
        idProducto: 3,
        idCategoria: 2,
        nombre: 'Aretes',
        descripcion: '',
        tecnica: '',
        precio: 18000,
      );
      const fotos = [
        ImagenProducto(idImagen: 1, idProducto: 3, url: 'a', orden: 1),
        ImagenProducto(
          idImagen: 2,
          idProducto: 3,
          url: 'b',
          orden: 2,
          color: 'Nude',
        ),
      ];
      final b = BorradorProducto.desde(producto, const [
        VarianteProducto(
          idVariante: 5,
          idProducto: 3,
          color: 'Nude',
          talla: 'Única',
          stock: 1,
        ),
      ], fotos: fotos);

      expect(b.fotosDe(null).map((f) => f.idImagen), [1]);
      expect(b.fotosDe('nude').map((f) => f.idImagen), [2]);

      final sinNude = b.copyWith(idsFotosABorrar: [2]);
      expect(sinNude.fotosDe('Nude'), isEmpty);
      expect(sinNude.fotosActuales.map((f) => f.idImagen), [1]);
    });

    test('las fotos de un color que ya no está se muestran aparte', () {
      const producto = Producto(
        idProducto: 3,
        idCategoria: 2,
        nombre: 'Aretes',
        descripcion: '',
        tecnica: '',
        precio: 18000,
      );
      final b = BorradorProducto.desde(
        producto,
        const [
          VarianteProducto(
            idVariante: 5,
            idProducto: 3,
            color: 'Nude',
            talla: 'Única',
            stock: 1,
          ),
        ],
        fotos: const [
          ImagenProducto(
            idImagen: 2,
            idProducto: 3,
            url: 'b',
            orden: 2,
            color: 'Verde',
          ),
        ],
      );

      expect(b.fotosHuerfanas.map((f) => f.idImagen), [2]);
    });

    test(
      'al reintentar un guardado cortado no se repiten las fotos hechas',
      () {
        final b = _valido()
            .copyWith(fotosNuevas: [_foto('p'), _foto('n', 'Naranja')])
            .sinFotosHechas(clavesSubidas: {'p'});

        expect(b.fotosNuevas.map((f) => f.clave), ['n']);
      },
    );

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
