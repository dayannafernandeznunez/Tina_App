import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Un problema que se le puede mostrar tal cual a la clienta o a la
/// administradora ("No hay stock suficiente de Pulsera tejida.").
class ErrorPedido implements Exception {
  const ErrorPedido(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Un artículo del pedido: qué variante y cuántas unidades.
class LineaPedidoNueva {
  const LineaPedidoNueva({required this.idVariante, required this.cantidad});

  final int idVariante;
  final int cantidad;
}

/// A dónde se envía el pedido.
class DatosEnvio {
  const DatosEnvio({
    required this.nombreDestinatario,
    required this.telefono,
    required this.departamento,
    required this.ciudad,
    required this.direccion,
  });

  final String nombreDestinatario;
  final String telefono;
  final String departamento;
  final String ciudad;
  final String direccion;
}

/// Quién compra. Solo se usa cuando no hay una sesión iniciada.
class DatosCompradora {
  const DatosCompradora({
    required this.nombre,
    required this.correo,
    required this.telefono,
  });

  final String nombre;
  final String correo;
  final String telefono;
}

/// Lo que responde la base de datos al crear un pedido: los montos ya
/// calculados con los precios y descuentos reales.
class PedidoCreado {
  const PedidoCreado({
    required this.idPedido,
    required this.idCliente,
    required this.subtotal,
    required this.descuento,
    required this.costoEnvio,
    required this.total,
  });

  factory PedidoCreado.desdeMapa(Map<String, dynamic> fila) => PedidoCreado(
    idPedido: fila['id_pedido'] as int,
    idCliente: fila['id_cliente'] as int,
    subtotal: fila['subtotal'] as int,
    descuento: fila['descuento'] as int,
    costoEnvio: fila['costo_envio'] as int,
    total: fila['total'] as int,
  );

  final int idPedido;
  final int idCliente;
  final int subtotal;
  final int descuento;
  final int costoEnvio;
  final int total;
}

/// Los pedidos y todo lo que cuelga de ellos, listos para armar la pantalla.
class DatosPedidos {
  const DatosPedidos({
    this.clientes = const [],
    this.pedidos = const [],
    this.detalles = const [],
    this.envios = const [],
    this.pagos = const [],
    this.comprobantes = const [],
    this.historial = const [],
    this.usuarios = const [],
  });

  final List<Cliente> clientes;
  final List<Pedido> pedidos;
  final List<DetallePedido> detalles;
  final List<Envio> envios;
  final List<Pago> pagos;
  final List<Comprobante> comprobantes;
  final List<HistorialEstado> historial;
  final List<Usuario> usuarios;
}

/// Crear pedidos, leerlos y cambiar su estado. La app solo conoce esta
/// interfaz; los cálculos (precios, descuentos, stock) los hace la base de datos.
abstract class PedidosRepositorio {
  /// Los pedidos que la persona puede ver: todos si es administradora; si no,
  /// solo los suyos.
  Future<DatosPedidos> cargar({required bool esAdministradora});

  /// Crea el pedido. Lanza [ErrorPedido] si no hay stock, si falta algún dato
  /// o si la contraentrega no aplica al destino.
  Future<PedidoCreado> crear({
    required List<LineaPedidoNueva> lineas,
    required DatosEnvio envio,
    required DatosCompradora compradora,
    required MetodoPago metodo,
  });

  /// Solo la administradora. Al cancelar, el stock vuelve a las variantes.
  Future<void> cambiarEstado(int idPedido, EstadoPedido estado);
}

/// Hace todo lo anterior con Supabase.
class PedidosSupabase implements PedidosRepositorio {
  PedidosSupabase([SupabaseClient? cliente])
    : _c = cliente ?? Supabase.instance.client;

  final SupabaseClient _c;

  /// PostgREST devuelve un objeto cuando la relación es uno a uno y una lista
  /// cuando es uno a muchos; esto lo deja siempre como lista de filas.
  static List<Map<String, dynamic>> _filas(dynamic valor) {
    if (valor == null) return const [];
    if (valor is List) return valor.cast<Map<String, dynamic>>();
    return [valor as Map<String, dynamic>];
  }

  @override
  Future<DatosPedidos> cargar({required bool esAdministradora}) async {
    final filas = await _c
        .from('pedido')
        .select(
          '*, cliente(*), detalle_pedido(*), envio(*), '
          'pago(*, comprobante(*)), historial_estado(*)',
        )
        .order('fecha', ascending: false);

    final clientes = <int, Cliente>{};
    final pedidos = <Pedido>[];
    final detalles = <DetallePedido>[];
    final envios = <Envio>[];
    final pagos = <Pago>[];
    final comprobantes = <Comprobante>[];
    final historial = <HistorialEstado>[];

    for (final fila in filas) {
      pedidos.add(Pedido.desdeMapa(fila));
      for (final c in _filas(fila['cliente'])) {
        final cliente = Cliente.desdeMapa(c);
        clientes[cliente.idCliente] = cliente;
      }
      detalles.addAll(
        _filas(fila['detalle_pedido']).map(DetallePedido.desdeMapa),
      );
      envios.addAll(_filas(fila['envio']).map(Envio.desdeMapa));
      historial.addAll(
        _filas(fila['historial_estado']).map(HistorialEstado.desdeMapa),
      );
      for (final p in _filas(fila['pago'])) {
        pagos.add(Pago.desdeMapa(p));
        comprobantes.addAll(
          _filas(p['comprobante']).map(Comprobante.desdeMapa),
        );
      }
    }

    // Para mostrar quién hizo cada cambio, la administradora lee los usuarios.
    var usuarios = <Usuario>[];
    if (esAdministradora) {
      final filasUsuario = await _c
          .from('usuario')
          .select('id_usuario, nombre, correo, rol');
      usuarios = [
        for (final u in filasUsuario)
          Usuario(
            idUsuario: u['id_usuario'] as int,
            nombre: u['nombre'] as String,
            correo: u['correo'] as String,
            rol: u['rol'] as String,
          ),
      ];
    }

    return DatosPedidos(
      clientes: clientes.values.toList(),
      pedidos: pedidos,
      detalles: detalles,
      envios: envios,
      pagos: pagos,
      comprobantes: comprobantes,
      historial: historial,
      usuarios: usuarios,
    );
  }

  @override
  Future<PedidoCreado> crear({
    required List<LineaPedidoNueva> lineas,
    required DatosEnvio envio,
    required DatosCompradora compradora,
    required MetodoPago metodo,
  }) async {
    try {
      final respuesta = await _c.rpc(
        'crear_pedido',
        params: {
          'p_items': [
            for (final l in lineas)
              {'id_variante': l.idVariante, 'cantidad': l.cantidad},
          ],
          'p_envio': {
            'nombre_destinatario': envio.nombreDestinatario,
            'telefono': envio.telefono,
            'departamento': envio.departamento,
            'ciudad': envio.ciudad,
            'direccion': envio.direccion,
          },
          'p_cliente': {
            'nombre': compradora.nombre,
            'correo': compradora.correo,
            'telefono': compradora.telefono,
          },
          'p_metodo': metodo.valorBd,
        },
      );
      return PedidoCreado.desdeMapa(respuesta as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // Los mensajes de la base de datos ya están en español y se pueden mostrar.
      throw ErrorPedido(e.message);
    } catch (_) {
      throw const ErrorPedido(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }

  @override
  Future<void> cambiarEstado(int idPedido, EstadoPedido estado) async {
    try {
      await _c.rpc(
        'cambiar_estado_pedido',
        params: {'p_id': idPedido, 'p_estado': estado.name},
      );
    } on PostgrestException catch (e) {
      throw ErrorPedido(e.message);
    } catch (_) {
      throw const ErrorPedido(
        'No pudimos guardar el cambio. Inténtalo de nuevo.',
      );
    }
  }
}
