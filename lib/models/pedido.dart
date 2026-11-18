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

/// Cómo paga la clienta. En la base de datos se guarda `valorBd`.
enum MetodoPago {
  wompi('Wompi', 'wompi'),
  applePay('Apple Pay', 'apple_pay'),
  contraentrega('Contraentrega', 'contraentrega');

  const MetodoPago(this.etiqueta, this.valorBd);

  final String etiqueta;
  final String valorBd;

  static MetodoPago desdeBd(String? valor) => values.firstWhere(
    (m) => m.valorBd == valor,
    orElse: () => MetodoPago.wompi,
  );
}

DateTime _fecha(dynamic valor) => DateTime.parse(valor as String).toLocal();

/// Tabla PEDIDO. `total` = `subtotal` - `descuento` + el costo de envío: es lo
/// que paga la clienta.
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
    this.metodoPago = MetodoPago.wompi,
  });

  /// Arma el pedido a partir de una fila de Supabase.
  factory Pedido.desdeMapa(Map<String, dynamic> fila) => Pedido(
    idPedido: fila['id_pedido'] as int,
    idCliente: fila['id_cliente'] as int,
    idPromocion: fila['id_promocion'] as int?,
    fecha: _fecha(fila['fecha']),
    estadoActual: EstadoPedido.desdeNombre(fila['estado_actual'] as String),
    subtotal: fila['subtotal'] as int,
    descuento: fila['descuento'] as int,
    total: fila['total'] as int,
    metodoPago: MetodoPago.desdeBd(fila['metodo_pago'] as String?),
  );

  final int idPedido;
  final int idCliente;
  final int? idPromocion;
  final DateTime fecha;
  final EstadoPedido estadoActual;
  final int subtotal;
  final int descuento;
  final int total;
  final MetodoPago metodoPago;

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
    metodoPago: metodoPago,
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

  /// Arma la línea del pedido a partir de una fila de Supabase.
  factory DetallePedido.desdeMapa(Map<String, dynamic> fila) => DetallePedido(
    idDetalle: fila['id_detalle'] as int,
    idPedido: fila['id_pedido'] as int,
    idVariante: fila['id_variante'] as int,
    cantidad: fila['cantidad'] as int,
    precioUnitario: fila['precio_unitario'] as int,
    subtotal: fila['subtotal'] as int,
  );

  final int idDetalle;
  final int idPedido;
  final int idVariante;
  final int cantidad;
  final int precioUnitario;
  final int subtotal;
}

/// Tabla PAGO. `estado` es `pendiente`, `aprobado` o `rechazado`; `proveedor`
/// es `wompi`, `apple_pay` o `contraentrega`. La `referencia` es la del
/// proveedor y no existe en la contraentrega.
class Pago {
  const Pago({
    required this.idPago,
    required this.idPedido,
    this.referencia,
    required this.monto,
    required this.estado,
    required this.fecha,
    this.proveedor = 'wompi',
  });

  /// Arma el pago a partir de una fila de Supabase.
  factory Pago.desdeMapa(Map<String, dynamic> fila) => Pago(
    idPago: fila['id_pago'] as int,
    idPedido: fila['id_pedido'] as int,
    referencia: fila['referencia'] as String?,
    monto: fila['monto'] as int,
    estado: fila['estado'] as String,
    fecha: _fecha(fila['fecha']),
    proveedor: (fila['proveedor'] as String?) ?? 'wompi',
  );

  final int idPago;
  final int idPedido;
  final String? referencia;
  final int monto;
  final String estado;
  final DateTime fecha;
  final String proveedor;
}

/// Tabla COMPROBANTE: existe solo para pagos aprobados.
class Comprobante {
  const Comprobante({
    required this.idComprobante,
    required this.idPago,
    required this.numero,
    required this.fechaEmision,
  });

  /// Arma el comprobante a partir de una fila de Supabase.
  factory Comprobante.desdeMapa(Map<String, dynamic> fila) => Comprobante(
    idComprobante: fila['id_comprobante'] as int,
    idPago: fila['id_pago'] as int,
    numero: fila['numero'] as String,
    fechaEmision: _fecha(fila['fecha_emision']),
  );

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

  /// Arma el envío a partir de una fila de Supabase.
  factory Envio.desdeMapa(Map<String, dynamic> fila) => Envio(
    idEnvio: fila['id_envio'] as int,
    idPedido: fila['id_pedido'] as int,
    nombreDestinatario: fila['nombre_destinatario'] as String,
    telefono: fila['telefono'] as String,
    departamento: fila['departamento'] as String,
    ciudad: fila['ciudad'] as String,
    direccion: fila['direccion'] as String,
    costo: fila['costo'] as int,
    guia: fila['guia'] as String?,
  );

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

  /// Arma el registro del historial a partir de una fila de Supabase.
  factory HistorialEstado.desdeMapa(Map<String, dynamic> fila) =>
      HistorialEstado(
        idHistorial: fila['id_historial'] as int,
        idPedido: fila['id_pedido'] as int,
        idUsuario: fila['id_usuario'] as int,
        estadoAnterior: fila['estado_anterior'] as String?,
        estadoNuevo: fila['estado_nuevo'] as String,
        notificado: (fila['notificado'] as bool?) ?? false,
        fecha: _fecha(fila['fecha']),
      );

  final int idHistorial;
  final int idPedido;
  final int idUsuario;
  final String? estadoAnterior;
  final String estadoNuevo;
  final bool notificado;
  final DateTime fecha;
}
