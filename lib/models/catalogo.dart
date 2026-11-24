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

/// Tabla COLECCION: un grupo de productos con nombre, subtítulo y foto (por
/// ejemplo "Con amor, para mí"). Una colección oculta no se ve en la tienda.
class Coleccion {
  const Coleccion({
    required this.idColeccion,
    required this.nombre,
    this.subtitulo = '',
    this.orden = 1,
    this.activa = true,
    this.url,
    this.ruta,
  });

  /// Arma la colección a partir de una fila de Supabase.
  factory Coleccion.desdeMapa(Map<String, dynamic> fila) => Coleccion(
    idColeccion: fila['id_coleccion'] as int,
    nombre: fila['nombre'] as String,
    subtitulo: (fila['subtitulo'] as String?) ?? '',
    orden: (fila['orden'] as int?) ?? 1,
    activa: (fila['activa'] as bool?) ?? true,
    url: fila['url'] as String?,
    ruta: fila['ruta'] as String?,
  );

  final int idColeccion;
  final String nombre;
  final String subtitulo;
  final int orden;
  final bool activa;

  /// La foto de la colección y su archivo en la carpeta de fotos del sitio.
  final String? url;
  final String? ruta;

  bool get tieneFoto => url != null && url!.isNotEmpty;

  Coleccion copyWith({
    String? nombre,
    String? subtitulo,
    bool? activa,
    String? url,
    String? ruta,
    bool sinFoto = false,
  }) => Coleccion(
    idColeccion: idColeccion,
    nombre: nombre ?? this.nombre,
    subtitulo: subtitulo ?? this.subtitulo,
    orden: orden,
    activa: activa ?? this.activa,
    url: sinFoto ? null : (url ?? this.url),
    ruta: sinFoto ? null : (ruta ?? this.ruta),
  );
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
    this.idColeccion,
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
    idColeccion: fila['id_coleccion'] as int?,
  );

  final int idProducto;
  final int idCategoria;
  final String nombre;
  final String descripcion;
  final String tecnica;
  final int precio;
  final bool activo;

  /// La colección a la que pertenece; `null` si no está en ninguna.
  final int? idColeccion;

  /// El mismo producto, sin colección.
  Producto sinColeccion() => Producto(
    idProducto: idProducto,
    idCategoria: idCategoria,
    nombre: nombre,
    descripcion: descripcion,
    tecnica: tecnica,
    precio: precio,
    activo: activo,
  );

  Producto copyWith({bool? activo}) => Producto(
    idProducto: idProducto,
    idCategoria: idCategoria,
    nombre: nombre,
    descripcion: descripcion,
    tecnica: tecnica,
    precio: precio,
    activo: activo ?? this.activo,
    idColeccion: idColeccion,
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
    this.color,
  });

  /// Arma la foto a partir de una fila de Supabase.
  factory ImagenProducto.desdeMapa(Map<String, dynamic> fila) => ImagenProducto(
    idImagen: fila['id_imagen'] as int,
    idProducto: fila['id_producto'] as int,
    url: fila['url'] as String,
    orden: fila['orden'] as int,
    ruta: (fila['ruta'] as String?) ?? '',
    color: fila['color'] as String?,
  );

  final int idImagen;
  final int idProducto;
  final String url;
  final int orden;
  final String ruta;

  /// El color al que pertenece la foto; `null` si es una foto general del
  /// producto (su portada).
  final String? color;

  ImagenProducto copyWith({int? orden}) => ImagenProducto(
    idImagen: idImagen,
    idProducto: idProducto,
    url: url,
    orden: orden ?? this.orden,
    ruta: ruta,
    color: color,
  );
}

/// La clave con la que se comparan los colores: sin mayúsculas ni espacios de
/// más, para que "Blanco" y " blanco " sean el mismo color.
String claveColor(String color) => color.trim().toLowerCase();

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
