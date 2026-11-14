import '../models/models.dart';

/// Una variante (color y talla con su stock) mientras se edita. [clave] es un
/// identificador solo de la pantalla: sirve para distinguir filas aunque
/// todavía no existan en la base de datos.
class BorradorVariante {
  const BorradorVariante({
    required this.clave,
    this.idVariante = 0,
    this.color = '',
    this.talla = 'Única',
    this.stock = 0,
  });

  final String clave;

  /// 0 mientras la variante es nueva.
  final int idVariante;
  final String color;
  final String talla;
  final int stock;

  BorradorVariante copyWith({String? color, String? talla, int? stock}) =>
      BorradorVariante(
        clave: clave,
        idVariante: idVariante,
        color: color ?? this.color,
        talla: talla ?? this.talla,
        stock: stock ?? this.stock,
      );

  VarianteProducto aVariante(int idProducto) => VarianteProducto(
    idVariante: idVariante,
    idProducto: idProducto,
    color: color.trim(),
    talla: talla.trim().isEmpty ? 'Única' : talla.trim(),
    stock: stock,
  );
}

/// Un producto mientras la administradora lo crea o lo edita: lo que escribió
/// en el formulario, antes de guardarlo.
class BorradorProducto {
  const BorradorProducto({
    this.idProducto = 0,
    this.nombre = '',
    this.descripcion = '',
    this.tecnica = '',
    this.precio = '',
    this.idCategoria = 0,
    this.activo = true,
    this.variantes = const [],
    this.idsVariantesOriginales = const [],
  });

  /// Un producto vacío, con una variante en blanco para empezar.
  factory BorradorProducto.nuevo({
    required int idCategoria,
    required String claveVariante,
  }) => BorradorProducto(
    idCategoria: idCategoria,
    variantes: [BorradorVariante(clave: claveVariante)],
  );

  /// El formulario de un producto que ya existe.
  factory BorradorProducto.desde(
    Producto p,
    List<VarianteProducto> variantes,
  ) => BorradorProducto(
    idProducto: p.idProducto,
    nombre: p.nombre,
    descripcion: p.descripcion,
    tecnica: p.tecnica,
    precio: p.precio.toString(),
    idCategoria: p.idCategoria,
    activo: p.activo,
    variantes: [
      for (final v in variantes)
        BorradorVariante(
          clave: 'v${v.idVariante}',
          idVariante: v.idVariante,
          color: v.color,
          talla: v.talla,
          stock: v.stock,
        ),
    ],
    idsVariantesOriginales: [for (final v in variantes) v.idVariante],
  );

  /// 0 mientras el producto es nuevo.
  final int idProducto;
  final String nombre;
  final String descripcion;
  final String tecnica;

  /// Lo que se escribió en el campo de precio, tal cual.
  final String precio;
  final int idCategoria;
  final bool activo;
  final List<BorradorVariante> variantes;

  /// Variantes que tenía al abrirlo: las que ya no estén se borran al guardar.
  final List<int> idsVariantesOriginales;

  bool get esNuevo => idProducto == 0;

  BorradorProducto copyWith({
    String? nombre,
    String? descripcion,
    String? tecnica,
    String? precio,
    int? idCategoria,
    bool? activo,
    List<BorradorVariante>? variantes,
  }) => BorradorProducto(
    idProducto: idProducto,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    tecnica: tecnica ?? this.tecnica,
    precio: precio ?? this.precio,
    idCategoria: idCategoria ?? this.idCategoria,
    activo: activo ?? this.activo,
    variantes: variantes ?? this.variantes,
    idsVariantesOriginales: idsVariantesOriginales,
  );

  BorradorProducto conVariante(
    String clave,
    BorradorVariante Function(BorradorVariante) cambio,
  ) => copyWith(
    variantes: [for (final v in variantes) v.clave == clave ? cambio(v) : v],
  );

  /// Lo mismo, pero con los ids que la base de datos ya asignó. Sirve cuando un
  /// guardado se corta a la mitad: al reintentar no se duplica lo que ya quedó.
  BorradorProducto conIds({
    int? idProducto,
    Map<String, int> idsVariantes = const {},
  }) => BorradorProducto(
    idProducto: idProducto ?? this.idProducto,
    nombre: nombre,
    descripcion: descripcion,
    tecnica: tecnica,
    precio: precio,
    idCategoria: idCategoria,
    activo: activo,
    variantes: [
      for (final v in variantes)
        idsVariantes.containsKey(v.clave)
            ? BorradorVariante(
                clave: v.clave,
                idVariante: idsVariantes[v.clave]!,
                color: v.color,
                talla: v.talla,
                stock: v.stock,
              )
            : v,
    ],
    idsVariantesOriginales: [
      ...idsVariantesOriginales,
      for (final id in idsVariantes.values)
        if (!idsVariantesOriginales.contains(id)) id,
    ],
  );

  /// El precio en pesos enteros; acepta "55000", "55.000" o "$55.000".
  /// `null` si no hay un número válido.
  int? get precioEnPesos {
    final soloDigitos = precio.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloDigitos.isEmpty) return null;
    return int.tryParse(soloDigitos);
  }

  /// Lo que falta o está mal, por campo. Vacío si se puede guardar.
  ///
  /// Las claves son `nombre`, `precio`, `categoria`, `variantes` y, para cada
  /// variante, `color-<clave>`.
  Map<String, String> errores() {
    final e = <String, String>{};
    if (nombre.trim().isEmpty) e['nombre'] = 'Escribe el nombre.';
    final p = precioEnPesos;
    if (p == null || p <= 0) {
      e['precio'] = 'Escribe el precio en pesos, solo números.';
    }
    if (idCategoria == 0) e['categoria'] = 'Elige una categoría.';
    if (variantes.isEmpty) {
      e['variantes'] = 'Agrega al menos un color o talla.';
    }

    final vistas = <String>{};
    for (final v in variantes) {
      if (v.color.trim().isEmpty) {
        e['color-${v.clave}'] = 'Escribe el color.';
        continue;
      }
      final combinacion =
          '${v.color.trim().toLowerCase()}|${v.talla.trim().toLowerCase()}';
      if (!vistas.add(combinacion)) {
        e['color-${v.clave}'] = 'Ya hay una fila con ese color y esa talla.';
      }
    }
    return e;
  }

  Producto aProducto() => Producto(
    idProducto: idProducto,
    idCategoria: idCategoria,
    nombre: nombre.trim(),
    descripcion: descripcion.trim(),
    tecnica: tecnica.trim(),
    precio: precioEnPesos ?? 0,
    activo: activo,
  );

  int get stockTotal => variantes.fold(0, (s, v) => s + v.stock);
}
