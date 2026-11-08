import 'package:flutter/widgets.dart';

/// A partir de este ancho (en píxeles) la app usa el diseño de escritorio:
/// barra superior con enlaces, grillas más anchas y dos columnas.
const double anchoEscritorio = 900;

/// Ancho máximo del contenido en escritorio, para que no se estire en
/// pantallas muy grandes.
const double anchoContenido = 1200;

bool esEscritorio(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= anchoEscritorio;
