import 'package:flutter/material.dart';

/// El modelo guarda el color de cada variante solo como nombre (columna
/// `color` de VARIANTE_PRODUCTO). Aquí se traduce a un color para pintar la
/// muestra en pantalla.
const Map<String, Color> _coloresPorNombre = {
  'Naranja': Color(0xFFFF6A00),
  'Blanco': Color(0xFFFFFFFF),
  'Nude': Color(0xFFE6C3A5),
  'Beige': Color(0xFFD8C09A),
  'Rosado': Color(0xFFE8566C),
  'Rojo': Color(0xFFD81E45),
  'Negro': Color(0xFF2A1608),
  'Gris': Color(0xFF9C9C9C),
  'Café': Color(0xFF7A4A2B),
  'Amarillo': Color(0xFFF2C230),
  'Mostaza': Color(0xFFD9A021),
  'Verde': Color(0xFF4F9D5B),
  'Turquesa': Color(0xFF3BB3AB),
  'Azul': Color(0xFF3F6FD1),
  'Celeste': Color(0xFF8CC8F0),
  'Morado': Color(0xFF7B4DB5),
  'Lila': Color(0xFFC8A6E8),
  'Fucsia': Color(0xFFD6247F),
  'Coral': Color(0xFFF2735A),
  'Vinotinto': Color(0xFF7A1F3D),
  'Dorado': Color(0xFFC9A24B),
  'Plateado': Color(0xFFC4C7CC),
};

/// Compara sin importar mayúsculas ni tildes, para que "cafe" y "Café" sean
/// el mismo color.
String _sinTildes(String texto) => texto
    .trim()
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');

final Map<String, Color> _coloresNormalizados = {
  for (final e in _coloresPorNombre.entries) _sinTildes(e.key): e.value,
};

/// Si el color no está en la lista, se pinta un gris neutro.
Color colorDeProducto(String nombre) =>
    _coloresNormalizados[_sinTildes(nombre)] ?? const Color(0xFFCCCCCC);
