import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';

enum DestinoNav { inicio, categorias, carrito, cuenta }

/// Barra de navegación inferior con cuatro destinos. Marca el activo que le
/// diga quien la usa y avisa con [onNav] cuando se toca otro.
class TinaNavInferior extends StatelessWidget {
  const TinaNavInferior({
    super.key,
    required this.activo,
    required this.onNav,
    this.carrito = 0,
  });

  final DestinoNav activo;
  final ValueChanged<DestinoNav> onNav;
  final int carrito;

  static const Map<DestinoNav, (String, IconData)> _destinos = {
    DestinoNav.inicio: ('Inicio', Icons.home_outlined),
    DestinoNav.categorias: ('Categorías', Icons.grid_view_rounded),
    DestinoNav.carrito: ('Carrito', Icons.shopping_bag_outlined),
    DestinoNav.cuenta: ('Cuenta', Icons.person_outline_rounded),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
      decoration: const BoxDecoration(
        color: TinaColores.cremaBarra,
        border: Border(top: BorderSide(color: TinaColores.dorado, width: 1.5)),
      ),
      child: Row(
        children: [
          for (final entrada in _destinos.entries)
            Expanded(
              child: _ItemNav(
                key: ValueKey('nav-${entrada.key.name}'),
                etiqueta: entrada.value.$1,
                icono: entrada.value.$2,
                activo: entrada.key == activo,
                insignia: entrada.key == DestinoNav.carrito ? carrito : 0,
                onTap: () => onNav(entrada.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  const _ItemNav({
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
    final color = activo ? TinaColores.naranja : TinaColores.marron;
    return Semantics(
      button: true,
      selected: activo,
      label: etiqueta,
      excludeSemantics: true,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 3,
            children: [
              Container(
                width: 52,
                height: 32,
                decoration: BoxDecoration(
                  color: activo ? TinaColores.melocoton : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(icono, size: 22, color: color),
                    if (insignia > 0)
                      Positioned(
                        top: -3,
                        right: 4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: TinaColores.rojo,
                            borderRadius: BorderRadius.circular(999),
                          ),
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
                  ],
                ),
              ),
              Text(
                etiqueta,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TinaTipografia.estilo(
                  tamano: 12,
                  peso: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
