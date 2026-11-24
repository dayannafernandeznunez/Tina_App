import '../models/models.dart';
import 'vistas.dart';

/// Un charm que se puede elegir: una variante de un producto de la categoría
/// "Charms" con unidades.
class CharmElegible {
  const CharmElegible({
    required this.variante,
    required this.producto,
    this.foto,
  });

  final VarianteProducto variante;
  final Producto producto;
  final String? foto;

  int get idVariante => variante.idVariante;
  int get precio => producto.precio;
  int get stock => variante.stock;

  /// "Charm Corazón" o, si el producto tiene varios colores, "Charm Flor · Roja".
  String get nombre {
    final color = variante.color.trim();
    final sinColor = color.isEmpty || color.toLowerCase() == 'único';
    return sinColor ? producto.nombre : '${producto.nombre} · $color';
  }
}

/// Lo que hace falta para armar un collar en el Charm Bar: el collar base (un
/// producto de la categoría "Charm Bar", con sus colores y sus modos) y los
/// charms (productos de la categoría "Charms"). Todo es catálogo normal: lo que
/// la vendedora crea y activa en el panel.
class CharmBar {
  const CharmBar({this.base, this.charms = const []});

  static const String categoriaBase = 'Charm Bar';
  static const String categoriaCharms = 'Charms';

  /// Los charms que se recomiendan por collar.
  static const int recomendados = 7;
  static const int maximoCharms = 20;

  /// El collar base (el primer producto visible de "Charm Bar").
  final ProductoVista? base;
  final List<CharmElegible> charms;

  /// Arma el Charm Bar con los productos que la tienda muestra hoy.
  factory CharmBar.desde(List<ProductoVista> vistas) {
    final bases = vistas.where(
      (v) => v.categoria == categoriaBase && v.producto.activo,
    );
    final charms = <CharmElegible>[];
    for (final v in vistas) {
      if (v.categoria != categoriaCharms || !v.producto.activo) continue;
      for (final variante in v.variantes) {
        if (variante.stock <= 0) continue;
        charms.add(
          CharmElegible(
            variante: variante,
            producto: v.producto,
            foto: v.fotosPara(variante.color).firstOrNull,
          ),
        );
      }
    }
    return CharmBar(base: bases.firstOrNull, charms: charms);
  }

  /// ¿Se puede armar un collar? Hay un collar base con unidades y charms.
  bool get disponible =>
      base != null && base!.stockTotal > 0 && charms.isNotEmpty;

  /// Los colores del collar base que tienen unidades.
  List<String> get colores => [
    ...{
      for (final v in base?.variantes ?? const <VarianteProducto>[])
        if (v.stock > 0) v.color,
    },
  ];

  /// Los modos de poner los charms (por ejemplo "Charms fijos" y "Charms
  /// removibles") que tiene ese color con unidades.
  List<String> modosDe(String color) => [
    for (final v in base?.variantes ?? const <VarianteProducto>[])
      if (v.color == color && v.stock > 0) v.talla,
  ];

  VarianteProducto? varianteBase(String color, String modo) =>
      base?.variante(color, modo);

  CharmElegible? charm(int idVariante) {
    for (final c in charms) {
      if (c.idVariante == idVariante) return c;
    }
    return null;
  }
}

/// Lo que la clienta va eligiendo: el color, el modo, cuántos charms quiere y
/// cuáles. Es solo la elección; el precio y las unidades las calcula
/// [CharmBar].
class ArmadoCollar {
  const ArmadoCollar({
    this.color = '',
    this.modo = '',
    this.cantidad = 1,
    this.seleccion = const {},
  });

  final String color;
  final String modo;

  /// Cuántos charms quiere en total.
  final int cantidad;

  /// Los charms elegidos: id de la variante -> cuántos.
  final Map<int, int> seleccion;

  int get elegidos => seleccion.values.fold(0, (s, n) => s + n);

  /// Ya eligió todos los charms que dijo que quería.
  bool get completo => elegidos == cantidad;

  int get faltan => cantidad - elegidos;

  ArmadoCollar copyWith({
    String? color,
    String? modo,
    int? cantidad,
    Map<int, int>? seleccion,
  }) => ArmadoCollar(
    color: color ?? this.color,
    modo: modo ?? this.modo,
    cantidad: cantidad ?? this.cantidad,
    seleccion: seleccion ?? this.seleccion,
  );

  /// Cambia cuántos charms quiere; si eligió de más, se quitan los últimos.
  ArmadoCollar conCantidad(int nueva) {
    final n = nueva.clamp(1, CharmBar.maximoCharms);
    var sobran = elegidos - n;
    final nuevos = {...seleccion};
    for (final id in nuevos.keys.toList().reversed) {
      if (sobran <= 0) break;
      final quita = sobran < nuevos[id]! ? sobran : nuevos[id]!;
      nuevos[id] = nuevos[id]! - quita;
      if (nuevos[id] == 0) nuevos.remove(id);
      sobran -= quita;
    }
    return copyWith(cantidad: n, seleccion: nuevos);
  }

  /// Agrega un charm si todavía caben y hay unidades ([stock]).
  ArmadoCollar conCharm(int idVariante, int stock) {
    if (elegidos >= cantidad) return this;
    final actual = seleccion[idVariante] ?? 0;
    if (actual >= stock) return this;
    return copyWith(seleccion: {...seleccion, idVariante: actual + 1});
  }

  /// Quita una unidad de ese charm.
  ArmadoCollar sinCharm(int idVariante) {
    final actual = seleccion[idVariante] ?? 0;
    if (actual == 0) return this;
    final nuevos = {...seleccion};
    if (actual == 1) {
      nuevos.remove(idVariante);
    } else {
      nuevos[idVariante] = actual - 1;
    }
    return copyWith(seleccion: nuevos);
  }

  /// Cuánto cuesta el collar con estos charms.
  int precio(CharmBar charmBar) {
    final base = charmBar.base?.producto.precio ?? 0;
    var total = base;
    seleccion.forEach((id, n) {
      total += (charmBar.charm(id)?.precio ?? 0) * n;
    });
    return total;
  }
}
