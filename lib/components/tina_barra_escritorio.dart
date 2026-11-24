import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';
import '../utils/adaptable.dart';
import 'tina_boton_redondo.dart';
import 'tina_carrito_redondo.dart';
import 'tina_logo.dart';
import 'tina_nav_inferior.dart';

/// Barra superior para pantallas anchas: logo, título de la pantalla y los
/// enlaces de navegación (los mismos cuatro destinos de la barra inferior del
/// celular). Si no recibe [onNav] no muestra enlaces y deja solo el carrito.
class TinaBarraEscritorio extends StatelessWidget
    implements PreferredSizeWidget {
  const TinaBarraEscritorio({
    super.key,
    this.titulo,
    this.conAtras = false,
    this.conCarrito = true,
    this.carrito = 0,
    this.activo,
    this.onNav,
    this.onAtras,
    this.onLogo,
    this.onCarrito,
  });

  final String? titulo;
  final bool conAtras;
  final bool conCarrito;
  final int carrito;
  final DestinoNav? activo;
  final ValueChanged<DestinoNav>? onNav;
  final VoidCallback? onAtras;
  final VoidCallback? onLogo;
  final VoidCallback? onCarrito;

  static const Map<DestinoNav, String> _etiquetas = {
    DestinoNav.inicio: 'Inicio',
    DestinoNav.categorias: 'Categorías',
    DestinoNav.carrito: 'Carrito',
    DestinoNav.cuenta: 'Cuenta',
  };

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final hayTitulo = titulo != null && titulo!.isNotEmpty;
    return Container(
      height: 76,
      decoration: const BoxDecoration(color: TinaColores.cremaBarra),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: anchoContenido),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (conAtras) ...[
                  TinaBotonRedondo(
                    etiqueta: 'Volver',
                    icono: Icons.chevron_left_rounded,
                    tamanoIcono: 28,
                    onPressed: onAtras,
                  ),
                  const SizedBox(width: 16),
                ],
                TinaLogo(onTap: onLogo, tamano: 38),
                if (hayTitulo) ...[
                  const SizedBox(width: 20),
                  Container(width: 1.5, height: 28, color: TinaColores.dorado),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Text(
                      titulo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TinaTipografia.estilo(
                        tamano: 20,
                        peso: FontWeight.w800,
                        espaciado: -0.4,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (onNav != null) ...[
                  for (final destino in const [
                    DestinoNav.inicio,
                    DestinoNav.categorias,
                  ])
                    _Enlace(
                      key: ValueKey('nav-${destino.name}'),
                      etiqueta: _etiquetas[destino]!,
                      activo: destino == activo,
                      insignia: 0,
                      onTap: () => onNav!(destino),
                    ),
                  const SizedBox(width: 12),
                  _IconoNav(
                    key: const ValueKey('nav-cuenta'),
                    etiqueta: 'Cuenta',
                    icono: Icons.person_outline_rounded,
                    activo: activo == DestinoNav.cuenta,
                    insignia: 0,
                    onTap: () => onNav!(DestinoNav.cuenta),
                  ),
                  _IconoNav(
                    key: const ValueKey('nav-carrito'),
                    etiqueta: 'Carrito',
                    icono: Icons.shopping_bag_outlined,
                    activo: activo == DestinoNav.carrito,
                    insignia: carrito,
                    onTap: () => onNav!(DestinoNav.carrito),
                  ),
                ] else if (conCarrito)
                  TinaCarritoRedondo(carrito: carrito, onCarrito: onCarrito),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Enlace extends StatelessWidget {
  const _Enlace({
    super.key,
    required this.etiqueta,
    required this.activo,
    required this.insignia,
    required this.onTap,
  });

  final String etiqueta;
  final bool activo;
  final int insignia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activo,
      label: etiqueta,
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => TinaLevante(
          encima: encima,
          dy: -2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: activo ? TinaColores.melocoton : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Text(
                    etiqueta,
                    style: TinaTipografia.estilo(
                      tamano: 15,
                      peso: FontWeight.w800,
                      color: (activo || encima)
                          ? TinaColores.naranja
                          : TinaColores.marron,
                    ),
                  ),
                  if (insignia > 0)
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: TinaColores.rojo,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Text(
                          '$insignia',
                          style: TinaTipografia.estilo(
                            tamano: 12,
                            peso: FontWeight.w800,
                            color: TinaColores.blanco,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ícono de la cabecera (cuenta, carrito) con su número si lo hay.
class _IconoNav extends StatelessWidget {
  const _IconoNav({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.activo,
    required this.insignia,
    required this.onTap,
  });

  final String etiqueta;
  final IconData icono;
  final bool activo;
  final int insignia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activo,
      label: insignia > 0 ? '$etiqueta, $insignia' : etiqueta,
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 46,
            height: 46,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activo
                  ? TinaColores.melocoton
                  : encima
                  ? TinaColores.cremaSuave
                  : Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icono,
                  size: 25,
                  color: (activo || encima)
                      ? TinaColores.naranja
                      : TinaColores.tinta,
                ),
                if (insignia > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 19,
                        minHeight: 19,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: TinaColores.rojo,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Text(
                          '$insignia',
                          style: TinaTipografia.estilo(
                            tamano: 11,
                            peso: FontWeight.w800,
                            color: TinaColores.blanco,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
