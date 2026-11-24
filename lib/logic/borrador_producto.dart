import '../data/administradora.dart';
import '../models/models.dart';

/// Una foto que la administradora eligió y todavía no se sube: se sube cuando
/// guarda el producto. [color] es el color al que pertenece; `null` es una
/// foto general (la portada).
class FotoNueva {
  const FotoNueva({required this.clave, required this.foto, this.color});

  /// Identifica la foto en la pantalla, igual que `BorradorVariante.clave`.
  final String clave;
  final FotoElegida foto;
  final String? color;

  FotoNueva conColor(String? color) =>
      FotoNueva(clave: clave, foto: foto, color: color);
}

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
    this.idColeccion = 0,
    this.activo = true,
    this.variantes = const [],
    this.idsVariantesOriginales = const [],
    this.fotosExistentes = const [],
    this.fotosNuevas = const [],
    this.idsFotosABorrar = const [],
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
    List<VarianteProducto> variantes, {
    List<ImagenProducto> fotos = const [],
  }) => BorradorProducto(
    idProducto: p.idProducto,
    nombre: p.nombre,
    descripcion: p.descripcion,
    tecnica: p.tecnica,
    precio: p.precio.toString(),
    idCategoria: p.idCategoria,
    idColeccion: p.idColeccion ?? 0,
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
    fotosExistentes: [...fotos]..sort((a, b) => a.orden.compareTo(b.orden)),
  );

  /// 0 mientras el producto es nuevo.
  final int idProducto;
  final String nombre;
  final String descripcion;
  final String tecnica;

  /// Lo que se escribió en el campo de precio, tal cual.
  final String precio;
  final int idCategoria;

  /// La colección del producto; 0 si no está en ninguna.
  final int idColeccion;
  final bool activo;
  final List<BorradorVariante> variantes;

  /// Variantes que tenía al abrirlo: las que ya no estén se borran al guardar.
  final List<int> idsVariantesOriginales;

  /// Las fotos que el producto ya tiene, de cualquier color.
  final List<ImagenProducto> fotosExistentes;

  /// Fotos elegidas que se suben al guardar.
  final List<FotoNueva> fotosNuevas;

  /// Fotos que ya tenía y se quitaron: se borran al guardar.
  final List<int> idsFotosABorrar;

  bool get esNuevo => idProducto == 0;

  BorradorProducto copyWith({
    String? nombre,
    String? descripcion,
    String? tecnica,
    String? precio,
    int? idCategoria,
    int? idColeccion,
    bool? activo,
    List<BorradorVariante>? variantes,
    List<FotoNueva>? fotosNuevas,
    List<int>? idsFotosABorrar,
  }) => BorradorProducto(
    idProducto: idProducto,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    tecnica: tecnica ?? this.tecnica,
    precio: precio ?? this.precio,
    idCategoria: idCategoria ?? this.idCategoria,
    idColeccion: idColeccion ?? this.idColeccion,
    activo: activo ?? this.activo,
    variantes: variantes ?? this.variantes,
    idsVariantesOriginales: idsVariantesOriginales,
    fotosExistentes: fotosExistentes,
    fotosNuevas: fotosNuevas ?? this.fotosNuevas,
    idsFotosABorrar: idsFotosABorrar ?? this.idsFotosABorrar,
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
    idColeccion: idColeccion,
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
    fotosExistentes: fotosExistentes,
    fotosNuevas: fotosNuevas,
    idsFotosABorrar: idsFotosABorrar,
  );

  /// Lo mismo, pero sin las fotos que un guardado cortado a la mitad ya subió
  /// ([clavesSubidas]) o borró ([idsBorradas]): al reintentar no se repiten.
  BorradorProducto sinFotosHechas({
    Set<String> clavesSubidas = const {},
    Set<int> idsBorradas = const {},
  }) => BorradorProducto(
    idProducto: idProducto,
    nombre: nombre,
    descripcion: descripcion,
    tecnica: tecnica,
    precio: precio,
    idCategoria: idCategoria,
    idColeccion: idColeccion,
    activo: activo,
    variantes: variantes,
    idsVariantesOriginales: idsVariantesOriginales,
    fotosExistentes: [
      for (final f in fotosExistentes)
        if (!idsBorradas.contains(f.idImagen)) f,
    ],
    fotosNuevas: [
      for (final f in fotosNuevas)
        if (!clavesSubidas.contains(f.clave)) f,
    ],
    idsFotosABorrar: [
      for (final id in idsFotosABorrar)
        if (!idsBorradas.contains(id)) id,
    ],
  );

  /// Los colores distintos de la lista, en el orden en que aparecen. Los
  /// vacíos no cuentan.
  List<String> get colores {
    final vistos = <String>{};
    return [
      for (final v in variantes)
        if (v.color.trim().isNotEmpty && vistos.add(claveColor(v.color)))
          v.color.trim(),
    ];
  }

  /// Fotos que ya tiene y no se van a borrar.
  List<ImagenProducto> get fotosActuales => [
    for (final f in fotosExistentes)
      if (!idsFotosABorrar.contains(f.idImagen)) f,
  ];

  bool _esDeColor(String? colorFoto, String? color) => color == null
      ? colorFoto == null
      : colorFoto != null && claveColor(colorFoto) == claveColor(color);

  /// Las fotos que ya tiene de [color] (`null` = generales).
  List<ImagenProducto> fotosDe(String? color) => [
    for (final f in fotosActuales)
      if (_esDeColor(f.color, color)) f,
  ];

  /// Las fotos elegidas para subir de [color] (`null` = generales).
  List<FotoNueva> nuevasDe(String? color) => [
    for (final f in fotosNuevas)
      if (_esDeColor(f.color, color)) f,
  ];

  /// Fotos de un color que ya no está en la lista de colores (por ejemplo, si
  /// se le cambió el nombre): siguen en el producto y se pueden quitar.
  List<ImagenProducto> get fotosHuerfanas {
    final claves = {for (final c in colores) claveColor(c)};
    return [
      for (final f in fotosActuales)
        if (f.color != null && !claves.contains(claveColor(f.color!))) f,
    ];
  }

  /// Si tiene al menos una foto general (la portada) ya guardada o elegida.
  bool get tienePortada =>
      fotosDe(null).isNotEmpty || nuevasDe(null).isNotEmpty;

  /// El precio en pesos enteros; acepta "55000", "55.000" o "$55.000".
  /// `null` si no hay un número válido.
  int? get precioEnPesos {
    final soloDigitos = precio.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloDigitos.isEmpty) return null;
    return int.tryParse(soloDigitos);
  }

  /// Lo que falta o está mal, por campo. Vacío si se puede guardar.
  ///
  /// Las claves son `nombre`, `precio`, `categoria`, `variantes`, `foto` (un
  /// producto nuevo necesita su portada) y, para cada variante, `color-<clave>`.
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
    if (esNuevo && !tienePortada) {
      e['foto'] = 'Sube la foto de portada del producto.';
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
    idColeccion: idColeccion == 0 ? null : idColeccion,
    nombre: nombre.trim(),
    descripcion: descripcion.trim(),
    tecnica: tecnica.trim(),
    precio: precioEnPesos ?? 0,
    activo: activo,
  );

  int get stockTotal => variantes.fold(0, (s, v) => s + v.stock);

  /// El stock de cada color, sumando sus tallas.
  Map<String, int> get stockPorColor {
    final r = <String, int>{};
    for (final c in colores) {
      r[c] = variantes
          .where((v) => claveColor(v.color) == claveColor(c))
          .fold(0, (s, v) => s + v.stock);
    }
    return r;
  }
}
