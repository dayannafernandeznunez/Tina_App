import '../models/models.dart';
import 'vistas.dart';

/// Cómo se ordenan los productos de una categoría.
enum OrdenCatalogo {
  destacados('Destacados'),
  precioMenor('Precio: menor a mayor'),
  precioMayor('Precio: mayor a menor'),
  nombre('Nombre A–Z');

  const OrdenCatalogo(this.etiqueta);

  final String etiqueta;
}

/// Un color con la cantidad de productos que lo tienen.
class ColorConConteo {
  const ColorConConteo({required this.nombre, required this.productos});

  final String nombre;
  final int productos;
}

/// Lo que la clienta eligió para filtrar y ordenar los productos de una
/// categoría. No guarda nada: solo calcula qué productos se ven.
class FiltrosCatalogo {
  const FiltrosCatalogo({
    this.colores = const {},
    this.soloDisponibles = false,
    this.precioMaximo,
    this.orden = OrdenCatalogo.destacados,
  });

  /// Colores elegidos, por su [claveColor].
  final Set<String> colores;

  /// Solo los que tienen unidades.
  final bool soloDisponibles;

  /// El precio más alto que se quiere ver; `null` es sin límite.
  final int? precioMaximo;
  final OrdenCatalogo orden;

  /// Cuántos filtros hay puestos (el orden no cuenta).
  int get activos =>
      (colores.isEmpty ? 0 : 1) +
      (soloDisponibles ? 1 : 0) +
      (precioMaximo == null ? 0 : 1);

  bool get hayFiltros => activos > 0;

  FiltrosCatalogo copyWith({
    Set<String>? colores,
    bool? soloDisponibles,
    int? precioMaximo,
    bool sinPrecioMaximo = false,
    OrdenCatalogo? orden,
  }) => FiltrosCatalogo(
    colores: colores ?? this.colores,
    soloDisponibles: soloDisponibles ?? this.soloDisponibles,
    precioMaximo: sinPrecioMaximo ? null : (precioMaximo ?? this.precioMaximo),
    orden: orden ?? this.orden,
  );

  /// Lo mismo, sin ningún filtro (conserva el orden).
  FiltrosCatalogo sinFiltros() => FiltrosCatalogo(orden: orden);

  /// ¿El producto cumple con los filtros?
  bool cumple(ProductoVista p) {
    if (soloDisponibles && p.stockTotal <= 0) return false;
    if (precioMaximo != null && p.producto.precio > precioMaximo!) return false;
    if (colores.isNotEmpty) {
      final tiene = p.variantes.any(
        (v) =>
            colores.contains(claveColor(v.color)) &&
            (!soloDisponibles || v.stock > 0),
      );
      if (!tiene) return false;
    }
    return true;
  }

  /// Los productos que cumplen, en el orden elegido. "Destacados" respeta el
  /// orden en que llegan.
  List<ProductoVista> aplicar(List<ProductoVista> productos) {
    final r = [
      for (final p in productos)
        if (cumple(p)) p,
    ];
    switch (orden) {
      case OrdenCatalogo.destacados:
        break;
      case OrdenCatalogo.precioMenor:
        r.sort((a, b) => a.producto.precio.compareTo(b.producto.precio));
      case OrdenCatalogo.precioMayor:
        r.sort((a, b) => b.producto.precio.compareTo(a.producto.precio));
      case OrdenCatalogo.nombre:
        r.sort(
          (a, b) => a.producto.nombre.toLowerCase().compareTo(
            b.producto.nombre.toLowerCase(),
          ),
        );
    }
    return r;
  }

  /// Los colores que hay en [productos], con cuántos productos tiene cada uno.
  static List<ColorConConteo> coloresDe(List<ProductoVista> productos) {
    final nombres = <String, String>{};
    final cuenta = <String, int>{};
    for (final p in productos) {
      final vistos = <String>{};
      for (final v in p.variantes) {
        final clave = claveColor(v.color);
        if (clave.isEmpty) continue;
        nombres.putIfAbsent(clave, () => v.color.trim());
        if (vistos.add(clave)) cuenta[clave] = (cuenta[clave] ?? 0) + 1;
      }
    }
    final claves = cuenta.keys.toList()..sort();
    return [
      for (final c in claves)
        ColorConConteo(nombre: nombres[c]!, productos: cuenta[c]!),
    ];
  }

  /// El precio más bajo y el más alto de [productos]; `null` si no hay.
  static (int, int)? rangoDePrecios(List<ProductoVista> productos) {
    if (productos.isEmpty) return null;
    final precios = [for (final p in productos) p.producto.precio]..sort();
    return (precios.first, precios.last);
  }
}
