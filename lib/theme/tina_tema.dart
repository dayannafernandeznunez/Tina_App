import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores tomados de la galería de componentes de Tina.
class TinaColores {
  TinaColores._();

  static const Color naranja = Color(0xFFFF6A00);
  static const Color naranjaHover = Color(0xFFFF7A1A);
  static const Color rojo = Color(0xFFD81E45);
  static const Color rosa = Color(0xFFE8566C);
  static const Color dorado = Color(0xFFAE8C5C);
  static const Color tinta = Color(0xFF2A1608);
  static const Color marron = Color(0xFF7A5A3E);
  static const Color durazno = Color(0xFFFFD2A0);
  static const Color melocoton = Color(0xFFFFE3CC);
  static const Color crema = Color(0xFFFFF8EF);
  static const Color cremaBarra = Color(0xFFFFF6EC);
  static const Color cremaCampo = Color(0xFFFFFAF4);
  static const Color cremaSuave = Color(0xFFFFF1E2);
  static const Color cremaHover = Color(0xFFFFEEDD);
  static const Color blanco = Color(0xFFFFFFFF);
}

/// Tipografía de Tina: Bricolage Grotesque (pesos 500 y 800) y, para los
/// titulares, Instrument Serif en cursiva.
class TinaTipografia {
  TinaTipografia._();

  /// Se pone en `false` en las pruebas para no descargar fuentes.
  static bool usarFuenteWeb = true;

  static TextStyle estilo({
    double tamano = 16,
    FontWeight peso = FontWeight.w500,
    Color color = TinaColores.tinta,
    double? espaciado,
    double? altura,
  }) {
    final base = TextStyle(
      fontSize: tamano,
      fontWeight: peso,
      color: color,
      letterSpacing: espaciado,
      height: altura,
    );
    return usarFuenteWeb
        ? GoogleFonts.bricolageGrotesque(textStyle: base)
        : base;
  }

  static TextStyle serif({
    double tamano = 32,
    Color color = TinaColores.tinta,
    double? altura,
  }) {
    final base = TextStyle(
      fontSize: tamano,
      color: color,
      fontStyle: FontStyle.italic,
      height: altura,
    );
    return usarFuenteWeb ? GoogleFonts.instrumentSerif(textStyle: base) : base;
  }
}

/// Tema general de la app.
class TinaTema {
  TinaTema._();

  static ThemeData crear() {
    final esquema = ColorScheme.fromSeed(
      seedColor: TinaColores.naranja,
      primary: TinaColores.naranja,
      secondary: TinaColores.rojo,
      surface: TinaColores.crema,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: TinaColores.crema,
    );
    // La fuente se aplica en cada componente con TinaTipografia.estilo, así
    // que el tema solo fija el color del texto.
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: TinaColores.tinta,
        displayColor: TinaColores.tinta,
      ),
    );
  }
}
