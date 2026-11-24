import 'package:flutter/widgets.dart';

/// A dónde llevan los enlaces extra de la tienda: el Charm Bar, las colecciones
/// y el buscador. Si un destino es `null`, ese enlace no se muestra.
class EnlacesTienda {
  const EnlacesTienda({this.onCharmBar, this.onColecciones, this.onBuscar});

  final VoidCallback? onCharmBar;
  final VoidCallback? onColecciones;
  final VoidCallback? onBuscar;
}
