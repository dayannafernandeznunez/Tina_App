import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/datos_simulados.dart';
import 'package:tina_app/logic/calculos.dart';
import 'package:tina_app/logic/vistas.dart';
import 'package:tina_app/models/models.dart';

ResumenCarrito _resumen(List<(int, int)> lineas, {bool primeraCompra = false}) {
  return Calculos.resumen(
    items: [
      for (var i = 0; i < lineas.length; i++)
        CarritoItem(
          idItem: i + 1,
          idCarrito: 1,
          idVariante: lineas[i].$1,
          cantidad: lineas[i].$2,
        ),
    ],
    variantes: DatosSimulados.variantes,
    productos: DatosSimulados.productos,
    promociones: DatosSimulados.promociones,
    primeraCompra: primeraCompra,
  );
}

void main() {
  group('Descuentos del carrito', () {
    test('sin promoción no hay descuento', () {
      final r = _resumen([(10, 2)]); // Pulsera M naranja, $17.000 c/u
      expect(r.unidades, 2);
      expect(r.subtotal, 34000);
      expect(r.descuento, 0);
      expect(r.total, 34000);
      expect(r.promocion, isNull);
    });

    test('la primera compra con cuenta recibe 20%', () {
      final r = _resumen([(13, 3)], primeraCompra: true); // 3 × $17.000
      expect(r.porcentaje, 20);
      expect(r.descuento, 10200);
      expect(r.total, 40800);
    });

    test('13 unidades no reciben el descuento por volumen, 14 sí', () {
      expect(_resumen([(10, 13)]).porcentaje, 0);

      final r = _resumen([(10, 14)]);
      expect(r.porcentaje, 30);
      expect(r.subtotal, 238000);
      expect(r.descuento, 71400);
      expect(r.total, 166600);
    });

    test('si aplican los dos, se toma el mayor y no se acumulan', () {
      final r = _resumen([(10, 14)], primeraCompra: true);
      expect(r.porcentaje, 30);
      expect(r.promocion?.tipo, 'volumen');
    });

    test('un carrito vacío no tiene descuento ni total', () {
      final r = _resumen([], primeraCompra: true);
      expect(r.vacio, isTrue);
      expect(r.total, 0);
      expect(r.porcentaje, 0);
    });

    test('la nota dice cuánto falta para el descuento por volumen', () {
      final r = _resumen([(10, 12)]);
      final nota = Calculos.notaDescuento(
        resumen: r,
        promociones: DatosSimulados.promociones,
        conCuenta: false,
      );
      expect(nota, contains('Te faltan 2 unidades para el 30%'));
      expect(nota, contains('El 20% se aplica si compras con cuenta'));

      final lleno = Calculos.notaDescuento(
        resumen: _resumen([(10, 14)]),
        promociones: DatosSimulados.promociones,
        conCuenta: true,
      );
      expect(lleno, contains('el 30% está aplicado'));
    });
  });

  group('Primera compra', () {
    test('quien tiene un pedido pagado ya no es primera compra', () {
      // Mariana (2) tiene un pedido entregado.
      expect(Calculos.esPrimeraCompra(2, DatosSimulados.pedidos), isFalse);
    });

    test('los pedidos pendientes o cancelados no cuentan', () {
      // Valentina (6) solo tiene uno pendiente; Sara (1) solo uno cancelado.
      expect(Calculos.esPrimeraCompra(6, DatosSimulados.pedidos), isTrue);
      expect(Calculos.esPrimeraCompra(1, DatosSimulados.pedidos), isTrue);
    });

    test('una clienta sin pedidos es primera compra', () {
      expect(Calculos.esPrimeraCompra(99, DatosSimulados.pedidos), isTrue);
    });
  });

  group('Envío', () {
    test('Cali cuesta menos que el resto del país', () {
      expect(Calculos.costoEnvio('Cali'), 9000);
      expect(Calculos.costoEnvio(' cali '), 9000);
      expect(Calculos.costoEnvio('Bogotá'), 12000);
    });
  });

  group('Vistas', () {
    test('ProductoVista ordena colores y tallas sin repetir', () {
      final pulsera = ProductoVista(
        producto: DatosSimulados.productos.firstWhere((p) => p.idProducto == 5),
        categoria: 'Pulseras',
        variantes: DatosSimulados.variantes
            .where((v) => v.idProducto == 5)
            .toList(),
      );
      expect(pulsera.colores, ['Naranja', 'Beige']);
      expect(pulsera.tallasDe('Beige'), ['S', 'M', 'L']);
      expect(pulsera.stockDe('Beige', 'M'), 8);
      expect(pulsera.stockDe('Beige', 'XL'), 0);
    });

    test(
      'armarPedidos junta todo y ordena del más reciente al más antiguo',
      () {
        final pedidos = armarPedidos(
          pedidos: DatosSimulados.pedidos,
          detalles: DatosSimulados.detalles,
          variantes: DatosSimulados.variantes,
          productos: DatosSimulados.productos,
          clientes: DatosSimulados.clientes,
          envios: DatosSimulados.envios,
          pagos: DatosSimulados.pagos,
          comprobantes: DatosSimulados.comprobantes,
          historial: DatosSimulados.historial,
          usuarios: DatosSimulados.usuarios,
        );

        expect(pedidos.length, DatosSimulados.pedidos.length);
        expect(pedidos.first.pedido.codigo, 'TINA-0014');
        expect(pedidos.last.pedido.codigo, 'TINA-0008');

        final doce = pedidos.firstWhere((p) => p.pedido.idPedido == 12);
        expect(
          doce.resumenProductos,
          'Maxi collar 3D con mostacilla ×1, Aretes de porcelanicrón ×1',
        );
        expect(doce.cliente.nombre, 'Laura Caicedo');
        expect(doce.envio.guia, isNotNull);
        expect(doce.comprobante, isNotNull);
        expect(doce.historial.last.estadoNuevo, 'enviado');
        expect(doce.historial.last.quien, 'Administradora Tina');
        expect(doce.historial.first.quien, 'Sistema');

        final pendiente = pedidos.firstWhere((p) => p.pedido.idPedido == 9);
        expect(pendiente.comprobante, isNull);
      },
    );
  });
}
