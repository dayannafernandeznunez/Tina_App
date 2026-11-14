/// Tabla CATEGORIA.
class Categoria {
  const Categoria({
    required this.idCategoria,
    required this.nombre,
    required this.descripcion,
  });

  /// Arma la categoría a partir de una fila de Supabase.
  factory Categoria.desdeMapa(Map<String, dynamic> fila) => Categoria(
    idCategoria: fila['id_categoria'] as int,
    nombre: fila['nombre'] as String,
    descripcion: (fila['descripcion'] as String?) ?? '',
  );

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

  /// Arma el producto a partir de una fila de Supabase.
  factory Producto.desdeMapa(Map<String, dynamic> fila) => Producto(
    idProducto: fila['id_producto'] as int,
    idCategoria: fila['id_categoria'] as int,
    nombre: fila['nombre'] as String,
    descripcion: (fila['descripcion'] as String?) ?? '',
    tecnica: (fila['tecnica'] as String?) ?? '',
    precio: fila['precio'] as int,
    activo: (fila['activo'] as bool?) ?? true,
  );

  final int idProducto;
  final int idCategoria;
  final String nombre;
  final String descripcion;
  final String tecnica;
  final int precio;
  final bool activo;

  Producto copyWith({bool? activo}) => Producto(
    idProducto: idProducto,
    idCategoria: idCategoria,
    nombre: nombre,
    descripcion: descripcion,
    tecnica: tecnica,
    precio: precio,
    activo: activo ?? this.activo,
  );
}

/// Tabla IMAGEN_PRODUCTO. `orden` 1 es la foto principal. `ruta` es el archivo
/// dentro de la carpeta de fotos; `url` es su dirección pública en internet.
class ImagenProducto {
  const ImagenProducto({
    required this.idImagen,
    required this.idProducto,
    required this.url,
    required this.orden,
    this.ruta = '',
  });

  /// Arma la foto a partir de una fila de Supabase.
  factory ImagenProducto.desdeMapa(Map<String, dynamic> fila) => ImagenProducto(
    idImagen: fila['id_imagen'] as int,
    idProducto: fila['id_producto'] as int,
    url: fila['url'] as String,
    orden: fila['orden'] as int,
    ruta: (fila['ruta'] as String?) ?? '',
  );

  final int idImagen;
  final int idProducto;
  final String url;
  final int orden;
  final String ruta;

  ImagenProducto copyWith({int? orden}) => ImagenProducto(
    idImagen: idImagen,
    idProducto: idProducto,
    url: url,
    orden: orden ?? this.orden,
    ruta: ruta,
  );
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

  /// Arma la variante a partir de una fila de Supabase.
  factory VarianteProducto.desdeMapa(Map<String, dynamic> fila) =>
      VarianteProducto(
        idVariante: fila['id_variante'] as int,
        idProducto: fila['id_producto'] as int,
        color: fila['color'] as String,
        talla: (fila['talla'] as String?) ?? 'Única',
        stock: fila['stock'] as int,
      );

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

/// Tabla AJUSTE_SITIO: un lugar de la página con nombre (la portada, el logo...)
/// y la foto que tiene ahora. Sin foto, `url` y `ruta` están vacías y la app
/// muestra su diseño por defecto.
class AjusteSitio {
  const AjusteSitio({
    required this.clave,
    required this.descripcion,
    this.url,
    this.ruta,
  });

  /// Arma el ajuste a partir de una fila de Supabase.
  factory AjusteSitio.desdeMapa(Map<String, dynamic> fila) => AjusteSitio(
    clave: fila['clave'] as String,
    descripcion: (fila['descripcion'] as String?) ?? '',
    url: fila['url'] as String?,
    ruta: fila['ruta'] as String?,
  );

  final String clave;
  final String descripcion;
  final String? url;
  final String? ruta;

  bool get tieneFoto => url != null && url!.isNotEmpty;
}
