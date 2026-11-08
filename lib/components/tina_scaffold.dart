import 'package:flutter/material.dart';

import '../utils/adaptable.dart';
import 'tina_barra_accion.dart';
import 'tina_barra_escritorio.dart';
import 'tina_barra_superior.dart';
import 'tina_nav_inferior.dart';

/// Marco común de las pantallas. Elige solo entre el diseño de celular (barra
/// superior de 64 px y navegación inferior) y el de escritorio (barra superior
/// con enlaces), según el ancho disponible.
///
/// - [activo] marca el destino de la navegación; si es `null`, la pantalla no
///   muestra navegación inferior en celular.
/// - [accion] es la acción principal (un botón) y queda fija al pie.
class TinaScaffold extends StatelessWidget {
  const TinaScaffold({
    super.key,
    required this.cuerpo,
    this.titulo,
    this.conAtras = false,
    this.conCarrito = true,
    this.unidadesCarrito = 0,
    this.activo,
    this.onNav,
    this.onAtras,
    this.onCarrito,
    this.onLogo,
    this.accion,
  });

  final Widget cuerpo;
  final String? titulo;
  final bool conAtras;
  final bool conCarrito;
  final int unidadesCarrito;
  final DestinoNav? activo;
  final ValueChanged<DestinoNav>? onNav;
  final VoidCallback? onAtras;
  final VoidCallback? onCarrito;
  final VoidCallback? onLogo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final escritorio = esEscritorio(context);

    Widget? inferior;
    if (accion != null) {
      inferior = TinaBarraAccion(hijo: accion!);
    } else if (!escritorio && activo != null && onNav != null) {
      inferior = TinaNavInferior(
        activo: activo!,
        carrito: unidadesCarrito,
        onNav: onNav!,
      );
    }

    return Scaffold(
      appBar: escritorio
          ? TinaBarraEscritorio(
              titulo: titulo,
              conAtras: conAtras,
              conCarrito: conCarrito,
              carrito: unidadesCarrito,
              activo: activo,
              onNav: onNav,
              onAtras: onAtras,
              onLogo: onLogo,
              onCarrito: onCarrito,
            )
          : TinaBarraSuperior(
              titulo: titulo,
              conAtras: conAtras,
              conCarrito: conCarrito,
              carrito: unidadesCarrito,
              onAtras: onAtras,
              onCarrito: onCarrito,
              onLogo: onLogo,
            ),
      body: cuerpo,
      bottomNavigationBar: inferior,
    );
  }
}
