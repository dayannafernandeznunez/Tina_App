import 'package:flutter_test/flutter_test.dart';
import 'package:tina_app/data/datos_simulados.dart';
import 'package:tina_app/models/models.dart';
import 'package:tina_app/utils/formato.dart';

void main() {
  group('Los datos simulados siguen el modelo entidad-relación', () {
    test('cada producto, imagen y variante apunta a algo que existe', () {
      final categorias = DatosSimulados.categorias
          .map((c) => c.idCategoria)
          .toSet();
      final productos = DatosSimulados.productos
          .map((p) => p.idProducto)
          .toSet();

      for (final p in DatosSimulados.productos) {
        expect(categorias, contains(p.idCategoria), reason: p.nombre);
      }
      for (final i in DatosSimulados.imagenes) {
        expect(productos, contains(i.idProducto));
      }
      for (final v in DatosSimulados.variantes) {
        expect(productos, contains(v.idProducto));
        expect(v.stock, greaterThanOrEqualTo(0));
      }
    });

    test('los ids de cada tabla son únicos', () {
      expect(
        DatosSimulados.productos.map((p) => p.idProducto).toSet().length,
        DatosSimulados.productos.length,
      );
      expect(
        DatosSimulados.variantes.map((v) => v.idVariante).toSet().length,
        DatosSimulados.variantes.length,
      );
      expect(
        DatosSimulados.pedidos.map((p) => p.idPedido).toSet().length,
        DatosSimulados.pedidos.length,
      );
    });

    test('cada producto tiene al menos una variante y tres fotos', () {
      for (final p in DatosSimulados.productos) {
        expect(
          DatosSimulados.variantes.where((v) => v.idProducto == p.idProducto),
          isNotEmpty,
        );
        expect(
          DatosSimulados.imagenes
              .where((i) => i.idProducto == p.idProducto)
              .length,
          3,
        );
      }
    });

    test('los totales de cada pedido cuadran con sus detalles', () {
      final variantes = {
        for (final v in DatosSimulados.variantes) v.idVariante: v,
      };
      final productos = {
        for (final p in DatosSimulados.productos) p.idProducto: p,
      };
      final promociones = {
        for (final p in DatosSimulados.promociones) p.idPromocion: p,
      };

      for (final pedido in DatosSimulados.pedidos) {
        final detalles = DatosSimulados.detalles
            .where((d) => d.idPedido == pedido.idPedido)
            .toList();
        expect(detalles, isNotEmpty, reason: pedido.codigo);

        for (final d in detalles) {
          final precio = productos[variantes[d.idVariante]!.idProducto]!.precio;
          expect(d.precioUnitario, precio);
          expect(d.subtotal, d.precioUnitario * d.cantidad);
        }

        final subtotal = detalles.fold<int>(0, (s, d) => s + d.subtotal);
        expect(pedido.subtotal, subtotal, reason: pedido.codigo);
        expect(pedido.total, pedido.subtotal - pedido.descuento);

        final porcentaje = pedido.idPromocion == null
            ? 0
            : promociones[pedido.idPromocion]!.porcentaje;
        expect(pedido.descuento, (subtotal * porcentaje / 100).round());
      }
    });

    test('el descuento por volumen solo aparece con 14 o más unidades', () {
      for (final pedido in DatosSimulados.pedidos) {
        final unidades = DatosSimulados.detalles
            .where((d) => d.idPedido == pedido.idPedido)
            .fold<int>(0, (s, d) => s + d.cantidad);
        if (pedido.idPromocion == 2) {
          expect(unidades, greaterThanOrEqualTo(14), reason: pedido.codigo);
        }
      }
    });

    test('el comprobante existe solo si el pago fue aprobado', () {
      final aprobados = DatosSimulados.pagos
          .where((p) => p.estado == 'aprobado')
          .map((p) => p.idPago)
          .toSet();
      final conComprobante = DatosSimulados.comprobantes
          .map((c) => c.idPago)
          .toSet();
      expect(conComprobante, aprobados);
    });

    test('el historial termina en el estado actual de cada pedido', () {
      for (final pedido in DatosSimulados.pedidos) {
        final suyos =
            DatosSimulados.historial
                .where((h) => h.idPedido == pedido.idPedido)
                .toList()
              ..sort((a, b) => a.fecha.compareTo(b.fecha));
        expect(
          suyos.last.estadoNuevo,
          pedido.estadoActual.name,
          reason: pedido.codigo,
        );
        expect(suyos.first.estadoAnterior, isNull);
      }
    });

    test(
      'toda clienta de un pedido existe y los pedidos enviados tienen guía',
      () {
        final clientes = DatosSimulados.clientes
            .map((c) => c.idCliente)
            .toSet();
        for (final pedido in DatosSimulados.pedidos) {
          expect(clientes, contains(pedido.idCliente));
          final envio = DatosSimulados.envios.firstWhere(
            (e) => e.idPedido == pedido.idPedido,
          );
          final despachado =
              pedido.estadoActual == EstadoPedido.enviado ||
              pedido.estadoActual == EstadoPedido.entregado;
          expect(envio.guia != null, despachado, reason: pedido.codigo);
        }
      },
    );
  });

  group('Formato', () {
    test('pesos con punto de miles', () {
      expect(formatoPesos(55000), '\$55.000');
      expect(formatoPesos(1250000), '\$1.250.000');
      expect(formatoPesos(0), '\$0');
    });

    test('fecha corta', () {
      expect(formatoFecha(DateTime(2026, 10, 24)), '24 oct 2026');
    });
  });
}
