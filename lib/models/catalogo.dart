/// Tabla CATEGORIA.
class Categoria {
  const Categoria({
    required this.idCategoria,
    required this.nombre,
    required this.descripcion,
  });

  final int idCategoria;
  final String nombre;
  final String descripcion;
}

/// Tabla PRODUCTO. El precio se guarda en pesos enteros (COP).
class Producto {
  const Producto({
    required this.idProducto,
    required this.idCategoria,
    required this.nombre,
    required this.descripcion,
    required this.tecnica,
    required this.precio,
    this.activo = true,
  });

  final int idProducto;
  final int idCategoria;
  final String nombre;
  final String descripcion;
  final String tecnica;
  final int precio;
  final bool activo;
}

/// Tabla IMAGEN_PRODUCTO. `orden` 1 es la foto principal.
class ImagenProducto {
  const ImagenProducto({
    required this.idImagen,
    required this.idProducto,
    required this.url,
    required this.orden,
  });

  final int idImagen;
  final int idProducto;
  final String url;
  final int orden;
}

/// Tabla VARIANTE_PRODUCTO. El stock se lleva por combinación de color y talla.
class VarianteProducto {
  const VarianteProducto({
    required this.idVariante,
    required this.idProducto,
    required this.color,
    required this.talla,
    required this.stock,
  });

  final int idVariante;
  final int idProducto;
  final String color;
  final String talla;
  final int stock;

  VarianteProducto copyWith({int? stock}) => VarianteProducto(
    idVariante: idVariante,
    idProducto: idProducto,
    color: color,
    talla: talla,
    stock: stock ?? this.stock,
  );
}
