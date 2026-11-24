import 'vistas.dart';

const _acentos = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
};

/// Minúsculas y sin tildes, para que "Corazón" y "corazon" sean lo mismo.
String normalizarTexto(String texto) {
  final b = StringBuffer();
  for (final c in texto.toLowerCase().runes) {
    final ch = String.fromCharCode(c);
    b.write(_acentos[ch] ?? ch);
  }
  return b.toString().trim();
}

/// Los productos que coinciden con lo que se escribió: cada palabra tiene que
/// aparecer en el nombre, la categoría, la colección, la descripción, la técnica
/// o los colores. Sin nada escrito no hay resultados.
List<ProductoVista> buscarProductos(
  List<ProductoVista> productos,
  String consulta,
) {
  final palabras = normalizarTexto(consulta)
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (palabras.isEmpty) return const [];

  bool coincide(ProductoVista p) {
    final pajar = normalizarTexto(
      [
        p.producto.nombre,
        p.categoria,
        p.coleccion ?? '',
        p.producto.descripcion,
        p.producto.tecnica,
        ...p.colores,
      ].join(' '),
    );
    return palabras.every(pajar.contains);
  }

  final r = [
    for (final p in productos)
      if (coincide(p)) p,
  ];
  // Primero los que tienen la palabra en el nombre.
  r.sort((a, b) {
    int puntos(ProductoVista p) {
      final n = normalizarTexto(p.producto.nombre);
      return palabras.where(n.contains).length;
    }

    return puntos(b).compareTo(puntos(a));
  });
  return r;
}
