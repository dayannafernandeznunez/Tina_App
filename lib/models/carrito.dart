/// Tabla CARRITO. `idCliente` queda vacío hasta que la persona se identifica.
class Carrito {
  const Carrito({
    required this.idCarrito,
    this.idCliente,
    required this.tokenSesion,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.fechaRecordatorio,
  });

  final int idCarrito;
  final int? idCliente;
  final String tokenSesion;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final DateTime? fechaRecordatorio;
}

/// Tabla CARRITO_ITEM: una variante (color y talla) con su cantidad.
class CarritoItem {
  const CarritoItem({
    required this.idItem,
    required this.idCarrito,
    required this.idVariante,
    required this.cantidad,
  });

  final int idItem;
  final int idCarrito;
  final int idVariante;
  final int cantidad;

  CarritoItem copyWith({int? cantidad}) => CarritoItem(
    idItem: idItem,
    idCarrito: idCarrito,
    idVariante: idVariante,
    cantidad: cantidad ?? this.cantidad,
  );
}
