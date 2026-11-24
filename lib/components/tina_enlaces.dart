import 'package:flutter/widgets.dart';

/// Lo que la tienda muestra en el formulario de suscripción del pie de página.
/// No guarda nada: avisa con callbacks.
class DatosSuscripcion {
  const DatosSuscripcion({
    required this.correo,
    required this.onCorreo,
    required this.onEnviar,
    this.ocupado = false,
    this.hecho = false,
    this.error,
  });

  final String correo;
  final ValueChanged<String> onCorreo;
  final VoidCallback onEnviar;
  final bool ocupado;

  /// Ya se suscribió: se muestra el agradecimiento en vez del formulario.
  final bool hecho;
  final String? error;
}

/// A dónde llevan los enlaces extra de la tienda (el Charm Bar, las colecciones
/// y el buscador) y el formulario de suscripción. Si un destino es `null`, ese
/// enlace no se muestra.
class EnlacesTienda {
  const EnlacesTienda({
    this.onCharmBar,
    this.onColecciones,
    this.onBuscar,
    this.suscripcion,
  });

  final VoidCallback? onCharmBar;
  final VoidCallback? onColecciones;
  final VoidCallback? onBuscar;
  final DatosSuscripcion? suscripcion;
}
