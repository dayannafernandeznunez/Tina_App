/// Estados de un pedido. En la base de datos se guarda el `name` del estado
/// en `PEDIDO.estado_actual` y en `HISTORIAL_ESTADO`.
enum EstadoPedido {
  pendiente('Pendiente de pago'),
  pagado('Pagado'),
  preparacion('En preparación'),
  enviado('Enviado'),
  entregado('Entregado'),
  cancelado('Cancelado');

  const EstadoPedido(this.etiqueta);

  final String etiqueta;

  /// Convierte el nombre guardado en la base de datos (`pagado`) en el estado.
  static EstadoPedido desdeNombre(String nombre) =>
      values.firstWhere((e) => e.name == nombre);
}

/// Tabla PEDIDO. `total` = `subtotal` - `descuento` (el envío va aparte).
class Pedido {
  const Pedido({
    required this.idPedido,
    required this.idCliente,
    this.idPromocion,
    required this.fecha,
    required this.estadoActual,
    required this.subtotal,
    required this.descuento,
    required this.total,
  });

  final int idPedido;
  final int idCliente;
  final int? idPromocion;
  final DateTime fecha;
  final EstadoPedido estadoActual;
  final int subtotal;
  final int descuento;
  final int total;

  /// Código que ve la clienta: TINA-0012.
  String get codigo => 'TINA-${idPedido.toString().padLeft(4, '0')}';

  Pedido copyWith({EstadoPedido? estadoActual}) => Pedido(
    idPedido: idPedido,
    idCliente: idCliente,
    idPromocion: idPromocion,
    fecha: fecha,
    estadoActual: estadoActual ?? this.estadoActual,
    subtotal: subtotal,
    descuento: descuento,
    total: total,
  );
}

/// Tabla DETALLE_PEDIDO. El precio unitario se copia al comprar, para que un
/// cambio de precio posterior no altere pedidos anteriores.
class DetallePedido {
  const DetallePedido({
    required this.idDetalle,
    required this.idPedido,
    required this.idVariante,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  final int idDetalle;
  final int idPedido;
  final int idVariante;
  final int cantidad;
  final int precioUnitario;
  final int subtotal;
}

/// Tabla PAGO. `estado` es `pendiente`, `aprobado` o `rechazado`.
class Pago {
  const Pago({
    required this.idPago,
    required this.idPedido,
    required this.referenciaWompi,
    required this.monto,
    required this.estado,
    required this.fecha,
  });

  final int idPago;
  final int idPedido;
  final String referenciaWompi;
  final int monto;
  final String estado;
  final DateTime fecha;
}

/// Tabla COMPROBANTE: existe solo para pagos aprobados.
class Comprobante {
  const Comprobante({
    required this.idComprobante,
    required this.idPago,
    required this.numero,
    required this.fechaEmision,
  });

  final int idComprobante;
  final int idPago;
  final String numero;
  final DateTime fechaEmision;
}

/// Tabla ENVIO. La guía queda vacía hasta que se despacha el pedido.
class Envio {
  const Envio({
    required this.idEnvio,
    required this.idPedido,
    required this.nombreDestinatario,
    required this.telefono,
    required this.departamento,
    required this.ciudad,
    required this.direccion,
    required this.costo,
    this.guia,
  });

  final int idEnvio;
  final int idPedido;
  final String nombreDestinatario;
  final String telefono;
  final String departamento;
  final String ciudad;
  final String direccion;
  final int costo;
  final String? guia;
}

/// Tabla HISTORIAL_ESTADO: un registro por cada cambio de estado.
class HistorialEstado {
  const HistorialEstado({
    required this.idHistorial,
    required this.idPedido,
    required this.idUsuario,
    this.estadoAnterior,
    required this.estadoNuevo,
    required this.notificado,
    required this.fecha,
  });

  final int idHistorial;
  final int idPedido;
  final int idUsuario;
  final String? estadoAnterior;
  final String estadoNuevo;
  final bool notificado;
  final DateTime fecha;
}
