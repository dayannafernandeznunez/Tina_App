import 'package:flutter/material.dart';

import 'screens/tina_screen.dart';
import 'theme/tina_tema.dart';

void main() => runApp(const TinaApp());

/// La app se adapta al ancho: en pantallas anchas (PC) usa barra superior con
/// enlaces, grillas de 4 columnas y dos columnas en detalle, carrito y
/// checkout; en pantallas angostas (celular) usa la navegación inferior.
class TinaApp extends StatelessWidget {
  const TinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tina',
      debugShowCheckedModeBanner: false,
      theme: TinaTema.crear(),
      home: const TinaScreen(),
    );
  }
}
