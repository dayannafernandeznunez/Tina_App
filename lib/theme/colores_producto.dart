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
};

Color colorDeProducto(String nombre) =>
    _coloresPorNombre[nombre] ?? const Color(0xFFCCCCCC);
