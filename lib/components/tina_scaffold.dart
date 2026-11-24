import 'package:flutter/material.dart';

import '../utils/adaptable.dart';
import 'tina_barra_accion.dart';
import 'tina_barra_escritorio.dart';
import 'tina_barra_promo.dart';
import 'tina_barra_superior.dart';
import 'tina_boton_whatsapp.dart';
import 'tina_fondo_marca.dart';
import 'tina_nav_inferior.dart';

/// Marco común de las pantallas. Elige solo entre el diseño de celular (barra
/// superior de 64 px y navegación inferior) y el de escritorio (barra superior
/// con enlaces), según el ancho disponible.
///
/// - [activo] marca el destino de la navegación; si es `null`, la pantalla no
///   muestra navegación inferior en celular.
/// - [accion] es la acción principal (un botón) y queda fija al pie.
/// - [conPromo] agrega la franja de promoción sobre la cabecera y el botón de
///   WhatsApp: es para las pantallas de la tienda, no las del panel.
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
    this.conFondo = true,
    this.conPromo = false,
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

  /// Pone detrás de la pantalla el fondo de la marca (naranja con manchas
  /// rosadas, estrellas y grano), muy suave para que no estorbe al contenido.
  final bool conFondo;

  /// Muestra la franja de promoción y el botón de WhatsApp.
  final bool conPromo;

  /// Qué tan fuerte se ve el fondo de la marca detrás del contenido (0 a 1).
  static const double opacidadFondo = 0.28;

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

    final PreferredSizeWidget cabecera = escritorio
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
          );

    final contenido = conFondo
        ? Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: Opacity(
                      opacity: opacidadFondo,
                      child: TinaFondoMarca(
                        radio: 0,
                        variante: VarianteFondo.completo,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              cuerpo,
            ],
          )
        : cuerpo;

    return Scaffold(
      appBar: conPromo
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                TinaBarraPromo.alto + cabecera.preferredSize.height,
              ),
              child: Column(children: [const TinaBarraPromo(), cabecera]),
            )
          : cabecera,
      body: conPromo
          ? Stack(
              fit: StackFit.expand,
              children: [
                contenido,
                const Positioned(
                  right: 18,
                  bottom: 18,
                  child: TinaBotonWhatsapp(),
                ),
              ],
            )
          : contenido,
      bottomNavigationBar: inferior,
    );
  }
}
