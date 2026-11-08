import '../models/models.dart';

/// Datos en memoria con la misma forma que las tablas del modelo
/// entidad-relación de Tina. Son el punto de partida de la app: después, el
/// estado vive en la Screen anfitriona y estas listas solo se copian.
class DatosSimulados {
  DatosSimulados._();

  static const List<Categoria> categorias = [
    Categoria(
      idCategoria: 1,
      nombre: 'Collares',
      descripcion: 'Maxi collares 3D tejidos a mano con mostacilla.',
    ),
    Categoria(
      idCategoria: 2,
      nombre: 'Aretes',
      descripcion: 'Aretes de porcelanicrón moldeados a mano.',
    ),
    Categoria(
      idCategoria: 3,
      nombre: 'Pulseras',
      descripcion: 'Pulseras tejidas en varias tallas.',
    ),
    Categoria(
      idCategoria: 4,
      nombre: 'Imanes',
      descripcion: 'Imanes de porcelanicrón para la nevera.',
    ),
  ];

  static const List<Producto> productos = [
    Producto(
      idProducto: 1,
      idCategoria: 1,
      nombre: 'Maxi collar 3D con mostacilla',
      descripcion: 'Pieza grande y llamativa, tejida a mano con mostacilla en volumen. Cada collar sale un poquito distinto.',
      tecnica: 'Mostacilla tejida en volumen',
      precio: 55000,
    ),
    Producto(
      idProducto: 2,
      idCategoria: 1,
      nombre: 'Maxi collar 3D tropical',
      descripcion: 'Un collar de colores vivos para los días de calor, armado cuenta por cuenta.',
      tecnica: 'Mostacilla tejida en volumen',
      precio: 58000,
    ),
    Producto(
      idProducto: 3,
      idCategoria: 2,
      nombre: 'Aretes de porcelanicrón',
      descripcion: 'Aretes moldeados a mano en porcelanicrón, livianos para usarlos todo el día.',
      tecnica: 'Porcelanicrón moldeado a mano',
      precio: 18000,
    ),
    Producto(
      idProducto: 4,
      idCategoria: 2,
      nombre: 'Aretes mini flor',
      descripcion:
          'Florecitas pequeñas pintadas a mano, para combinar con todo.',
      tecnica: 'Porcelanicrón moldeado a mano',
      precio: 16000,
    ),
    Producto(
      idProducto: 5,
      idCategoria: 3,
      nombre: 'Pulsera tejida',
      descripcion: 'Pulsera tejida a mano, en tres tallas para que te quede justo como es.',
      tecnica: 'Tejido a mano',
      precio: 17000,
    ),
    Producto(
      idProducto: 6,
      idCategoria: 3,
      nombre: 'Pulsera tejida con dije',
      descripcion: 'Nuestra pulsera tejida con un dije de porcelanicrón.',
      tecnica: 'Tejido a mano y porcelanicrón',
      precio: 19000,
    ),
    Producto(
      idProducto: 7,
      idCategoria: 4,
      nombre: 'Imán de porcelanicrón corazón',
      descripcion: 'Un corazón pequeño hecho a mano para tu nevera.',
      tecnica: 'Porcelanicrón moldeado a mano',
      precio: 12000,
    ),
    Producto(
      idProducto: 8,
      idCategoria: 4,
      nombre: 'Imán de porcelanicrón sol',
      descripcion: 'Un solcito pintado a mano que alegra cualquier superficie.',
      tecnica: 'Porcelanicrón moldeado a mano',
      precio: 12000,
    ),
  ];

  static const List<VarianteProducto> variantes = [
    VarianteProducto(
      idVariante: 1,
      idProducto: 1,
      color: 'Naranja',
      talla: 'Única',
      stock: 6,
    ),
    VarianteProducto(
      idVariante: 2,
      idProducto: 1,
      color: 'Blanco',
      talla: 'Única',
      stock: 4,
    ),
    VarianteProducto(
      idVariante: 3,
      idProducto: 2,
      color: 'Rosado',
      talla: 'Única',
      stock: 5,
    ),
    VarianteProducto(
      idVariante: 4,
      idProducto: 2,
      color: 'Naranja',
      talla: 'Única',
      stock: 3,
    ),
    VarianteProducto(
      idVariante: 5,
      idProducto: 3,
      color: 'Nude',
      talla: 'Única',
      stock: 10,
    ),
    VarianteProducto(
      idVariante: 6,
      idProducto: 3,
      color: 'Blanco',
      talla: 'Única',
      stock: 8,
    ),
    VarianteProducto(
      idVariante: 7,
      idProducto: 4,
      color: 'Naranja',
      talla: 'Única',
      stock: 12,
    ),
    VarianteProducto(
      idVariante: 8,
      idProducto: 4,
      color: 'Rosado',
      talla: 'Única',
      stock: 9,
    ),
    VarianteProducto(
      idVariante: 9,
      idProducto: 5,
      color: 'Naranja',
      talla: 'S',
      stock: 5,
    ),
    VarianteProducto(
      idVariante: 10,
      idProducto: 5,
      color: 'Naranja',
      talla: 'M',
      stock: 7,
    ),
    VarianteProducto(
      idVariante: 11,
      idProducto: 5,
      color: 'Naranja',
      talla: 'L',
      stock: 4,
    ),
    VarianteProducto(
      idVariante: 12,
      idProducto: 5,
      color: 'Beige',
      talla: 'S',
      stock: 6,
    ),
    VarianteProducto(
      idVariante: 13,
      idProducto: 5,
      color: 'Beige',
      talla: 'M',
      stock: 8,
    ),
    VarianteProducto(
      idVariante: 14,
      idProducto: 5,
      color: 'Beige',
      talla: 'L',
      stock: 3,
    ),
    VarianteProducto(
      idVariante: 15,
      idProducto: 6,
      color: 'Naranja',
      talla: 'S',
      stock: 4,
    ),
    VarianteProducto(
      idVariante: 16,
      idProducto: 6,
      color: 'Naranja',
      talla: 'M',
      stock: 6,
    ),
    VarianteProducto(
      idVariante: 17,
      idProducto: 6,
      color: 'Naranja',
      talla: 'L',
      stock: 3,
    ),
    VarianteProducto(
      idVariante: 18,
      idProducto: 6,
      color: 'Rosado',
      talla: 'S',
      stock: 5,
    ),
    VarianteProducto(
      idVariante: 19,
      idProducto: 6,
      color: 'Rosado',
      talla: 'M',
      stock: 5,
    ),
    VarianteProducto(
      idVariante: 20,
      idProducto: 6,
      color: 'Rosado',
      talla: 'L',
      stock: 2,
    ),
    VarianteProducto(
      idVariante: 21,
      idProducto: 7,
      color: 'Rojo',
      talla: 'Única',
      stock: 15,
    ),
    VarianteProducto(
      idVariante: 22,
      idProducto: 7,
      color: 'Rosado',
      talla: 'Única',
      stock: 12,
    ),
    VarianteProducto(
      idVariante: 23,
      idProducto: 8,
      color: 'Naranja',
      talla: 'Única',
      stock: 14,
    ),
    VarianteProducto(
      idVariante: 24,
      idProducto: 8,
      color: 'Blanco',
      talla: 'Única',
      stock: 10,
    ),
  ];

  /// Tres fotos por producto. Las rutas son simbólicas: el prototipo pinta un
  /// degradado de marca en lugar de la foto.
  static final List<ImagenProducto> imagenes = [
    for (final p in productos)
      for (var i = 1; i <= 3; i++)
        ImagenProducto(
          idImagen: (p.idProducto - 1) * 3 + i,
          idProducto: p.idProducto,
          url: 'productos/producto-${p.idProducto}-$i.jpg',
          orden: i,
        ),
  ];

  static final List<Cliente> clientes = [
    Cliente(
      idCliente: 1,
      nombre: 'Sara Valencia',
      correo: 'sara.valencia@correo.com',
      telefono: '3001112233',
      cuentaRegistrada: true,
      fechaRegistro: DateTime(2026, 9, 2),
      fechaUltimoInicioSesion: DateTime(2026, 10, 24),
    ),
    Cliente(
      idCliente: 2,
      nombre: 'Mariana López',
      correo: 'mariana.lopez@correo.com',
      telefono: '3012223344',
      cuentaRegistrada: true,
      fechaRegistro: DateTime(2026, 9, 10),
      fechaUltimoInicioSesion: DateTime(2026, 10, 23),
    ),
    Cliente(
      idCliente: 3,
      nombre: 'Laura Caicedo',
      correo: 'laura.caicedo@correo.com',
      telefono: '3023334455',
      cuentaRegistrada: true,
      fechaRegistro: DateTime(2026, 8, 20),
      fechaUltimoInicioSesion: DateTime(2026, 10, 22),
    ),
    Cliente(
      idCliente: 4,
      nombre: 'Camila Ortiz',
      correo: 'camila.ortiz@correo.com',
      telefono: '3034445566',
      cuentaRegistrada: true,
      fechaRegistro: DateTime(2026, 10, 22),
      fechaUltimoInicioSesion: DateTime(2026, 10, 22),
    ),
    // Compró sin crear cuenta: tiene fila, con cuenta_registrada en falso.
    Cliente(
      idCliente: 5,
      nombre: 'Daniela Mosquera',
      correo: 'daniela.mosquera@correo.com',
      telefono: '3045556677',
      cuentaRegistrada: false,
      fechaRegistro: DateTime(2026, 10, 21),
    ),
    Cliente(
      idCliente: 6,
      nombre: 'Valentina Ríos',
      correo: 'valentina.rios@correo.com',
      telefono: '3056667788',
      cuentaRegistrada: true,
      fechaRegistro: DateTime(2026, 10, 20),
      fechaUltimoInicioSesion: DateTime(2026, 10, 20),
    ),
  ];

  static const List<Usuario> usuarios = [
    Usuario(
      idUsuario: 1,
      nombre: 'Administradora Tina',
      correo: 'pedidos@tina.co',
      rol: 'administradora',
    ),
    Usuario(
      idUsuario: 2,
      nombre: 'Sistema',
      correo: 'sistema@tina.co',
      rol: 'sistema',
    ),
  ];

  static const List<Promocion> promociones = [
    Promocion(
      idPromocion: 1,
      nombre: '20% en tu primera compra con cuenta',
      tipo: 'primera_compra',
      porcentaje: 20,
      cantidadMinima: 1,
      activa: true,
    ),
    Promocion(
      idPromocion: 2,
      nombre: '30% si compras 14 o más unidades',
      tipo: 'volumen',
      porcentaje: 30,
      cantidadMinima: 14,
      activa: true,
    ),
  ];

  // Los pedidos, sus detalles, envíos, pagos, comprobantes e historial se
  // calculan juntos para que los totales y los estados siempre cuadren.
  static final _PedidosSemilla _pedidos = _PedidosSemilla.construir();

  static List<Pedido> get pedidos => _pedidos.pedidos;
  static List<DetallePedido> get detalles => _pedidos.detalles;
  static List<Envio> get envios => _pedidos.envios;
  static List<Pago> get pagos => _pedidos.pagos;
  static List<Comprobante> get comprobantes => _pedidos.comprobantes;
  static List<HistorialEstado> get historial => _pedidos.historial;
}

class _SemillaPedido {
  const _SemillaPedido({
    required this.id,
    required this.idCliente,
    this.idPromocion,
    required this.fecha,
    required this.estado,
    required this.items,
    required this.ciudad,
    required this.departamento,
    required this.direccion,
    required this.costoEnvio,
    this.guia,
  });

  final int id;
  final int idCliente;
  final int? idPromocion;
  final DateTime fecha;
  final EstadoPedido estado;
  final List<(int idVariante, int cantidad)> items;
  final String ciudad;
  final String departamento;
  final String direccion;
  final int costoEnvio;
  final String? guia;
}

class _PedidosSemilla {
  _PedidosSemilla({
    required this.pedidos,
    required this.detalles,
    required this.envios,
    required this.pagos,
    required this.comprobantes,
    required this.historial,
  });

  final List<Pedido> pedidos;
  final List<DetallePedido> detalles;
  final List<Envio> envios;
  final List<Pago> pagos;
  final List<Comprobante> comprobantes;
  final List<HistorialEstado> historial;

  static final List<_SemillaPedido> _semillas = [
    _SemillaPedido(
      id: 8,
      idCliente: 3,
      idPromocion: 2,
      fecha: DateTime(2026, 10, 15, 10, 30),
      estado: EstadoPedido.entregado,
      items: const [(10, 14)],
      ciudad: 'Medellín',
      departamento: 'Antioquia',
      direccion: 'Carrera 43A #1-50, Poblado',
      costoEnvio: 18000,
      guia: 'GUIA-4810021',
    ),
    _SemillaPedido(
      id: 9,
      idCliente: 6,
      fecha: DateTime(2026, 10, 20, 9, 15),
      estado: EstadoPedido.pendiente,
      items: const [(2, 1)],
      ciudad: 'Cali',
      departamento: 'Valle del Cauca',
      direccion: 'Calle 5 #38-20, San Fernando',
      costoEnvio: 9000,
    ),
    _SemillaPedido(
      id: 10,
      idCliente: 5,
      fecha: DateTime(2026, 10, 21, 16, 40),
      estado: EstadoPedido.pagado,
      items: const [(5, 2)],
      ciudad: 'Bogotá',
      departamento: 'Cundinamarca',
      direccion: 'Carrera 15 #85-10, Chicó',
      costoEnvio: 12000,
    ),
    _SemillaPedido(
      id: 11,
      idCliente: 4,
      idPromocion: 1,
      fecha: DateTime(2026, 10, 22, 11, 5),
      estado: EstadoPedido.preparacion,
      items: const [(13, 3)],
      ciudad: 'Cali',
      departamento: 'Valle del Cauca',
      direccion: 'Avenida 6N #25-40, Granada',
      costoEnvio: 9000,
    ),
    _SemillaPedido(
      id: 12,
      idCliente: 3,
      fecha: DateTime(2026, 10, 22, 14, 20),
      estado: EstadoPedido.enviado,
      items: const [(1, 1), (6, 1)],
      ciudad: 'Medellín',
      departamento: 'Antioquia',
      direccion: 'Carrera 43A #1-50, Poblado',
      costoEnvio: 12000,
      guia: 'GUIA-4821937',
    ),
    _SemillaPedido(
      id: 13,
      idCliente: 2,
      fecha: DateTime(2026, 10, 23, 8, 50),
      estado: EstadoPedido.entregado,
      items: const [(9, 1)],
      ciudad: 'Barranquilla',
      departamento: 'Atlántico',
      direccion: 'Calle 84 #50-12, Alto Prado',
      costoEnvio: 12000,
      guia: 'GUIA-4822110',
    ),
    _SemillaPedido(
      id: 14,
      idCliente: 1,
      fecha: DateTime(2026, 10, 24, 19, 10),
      estado: EstadoPedido.cancelado,
      items: const [(5, 1)],
      ciudad: 'Cali',
      departamento: 'Valle del Cauca',
      direccion: 'Carrera 100 #14-20, Ciudad Jardín',
      costoEnvio: 9000,
    ),
  ];

  static List<EstadoPedido> _ruta(EstadoPedido estado) => switch (estado) {
    EstadoPedido.pendiente => [EstadoPedido.pendiente],
    EstadoPedido.pagado => [EstadoPedido.pendiente, EstadoPedido.pagado],
    EstadoPedido.preparacion => [
      EstadoPedido.pendiente,
      EstadoPedido.pagado,
      EstadoPedido.preparacion,
    ],
    EstadoPedido.enviado => [
      EstadoPedido.pendiente,
      EstadoPedido.pagado,
      EstadoPedido.preparacion,
      EstadoPedido.enviado,
    ],
    EstadoPedido.entregado => [
      EstadoPedido.pendiente,
      EstadoPedido.pagado,
      EstadoPedido.preparacion,
      EstadoPedido.enviado,
      EstadoPedido.entregado,
    ],
    EstadoPedido.cancelado => [EstadoPedido.pendiente, EstadoPedido.cancelado],
  };

  factory _PedidosSemilla.construir() {
    final variantes = {
      for (final v in DatosSimulados.variantes) v.idVariante: v,
    };
    final productos = {
      for (final p in DatosSimulados.productos) p.idProducto: p,
    };
    final promociones = {
      for (final p in DatosSimulados.promociones) p.idPromocion: p,
    };
    final clientes = {for (final c in DatosSimulados.clientes) c.idCliente: c};

    final pedidos = <Pedido>[];
    final detalles = <DetallePedido>[];
    final envios = <Envio>[];
    final pagos = <Pago>[];
    final comprobantes = <Comprobante>[];
    final historial = <HistorialEstado>[];

    var idDetalle = 1;
    var idHistorial = 1;

    for (final s in _semillas) {
      final suyos = <DetallePedido>[];
      for (final (idVariante, cantidad) in s.items) {
        final precio = productos[variantes[idVariante]!.idProducto]!.precio;
        suyos.add(
          DetallePedido(
            idDetalle: idDetalle++,
            idPedido: s.id,
            idVariante: idVariante,
            cantidad: cantidad,
            precioUnitario: precio,
            subtotal: precio * cantidad,
          ),
        );
      }
      detalles.addAll(suyos);

      final subtotal = suyos.fold<int>(0, (suma, d) => suma + d.subtotal);
      final porcentaje = s.idPromocion == null
          ? 0
          : promociones[s.idPromocion]!.porcentaje;
      final descuento = (subtotal * porcentaje / 100).round();
      final total = subtotal - descuento;

      pedidos.add(
        Pedido(
          idPedido: s.id,
          idCliente: s.idCliente,
          idPromocion: s.idPromocion,
          fecha: s.fecha,
          estadoActual: s.estado,
          subtotal: subtotal,
          descuento: descuento,
          total: total,
        ),
      );

      final cliente = clientes[s.idCliente]!;
      envios.add(
        Envio(
          idEnvio: s.id,
          idPedido: s.id,
          nombreDestinatario: cliente.nombre,
          telefono: cliente.telefono,
          departamento: s.departamento,
          ciudad: s.ciudad,
          direccion: s.direccion,
          costo: s.costoEnvio,
          guia: s.guia,
        ),
      );

      final numero = s.id.toString().padLeft(4, '0');
      final estadoPago = switch (s.estado) {
        EstadoPedido.pendiente => 'pendiente',
        EstadoPedido.cancelado => 'rechazado',
        _ => 'aprobado',
      };
      pagos.add(
        Pago(
          idPago: s.id,
          idPedido: s.id,
          referenciaWompi: 'WMP-${48213 + s.id}-$numero',
          monto: total,
          estado: estadoPago,
          fecha: s.fecha.add(const Duration(minutes: 5)),
        ),
      );
      if (estadoPago == 'aprobado') {
        comprobantes.add(
          Comprobante(
            idComprobante: s.id,
            idPago: s.id,
            numero: 'C-$numero',
            fechaEmision: s.fecha.add(const Duration(minutes: 6)),
          ),
        );
      }

      final ruta = _ruta(s.estado);
      for (var i = 0; i < ruta.length; i++) {
        final automatico =
            ruta[i] == EstadoPedido.pendiente || ruta[i] == EstadoPedido.pagado;
        historial.add(
          HistorialEstado(
            idHistorial: idHistorial++,
            idPedido: s.id,
            idUsuario: automatico ? 2 : 1,
            estadoAnterior: i == 0 ? null : ruta[i - 1].name,
            estadoNuevo: ruta[i].name,
            notificado: true,
            fecha: s.fecha.add(Duration(hours: i * 3)),
          ),
        );
      }
    }

    return _PedidosSemilla(
      pedidos: pedidos,
      detalles: detalles,
      envios: envios,
      pagos: pagos,
      comprobantes: comprobantes,
      historial: historial,
    );
  }
}
