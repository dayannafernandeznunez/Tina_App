import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import '../utils/adaptable.dart';
import 'estrella_tina.dart';
import 'tina_hover.dart';
import 'tina_imagen_red.dart';

/// Una categoría para los círculos: su nombre y, si hay, una foto.
class ItemCategoria {
  const ItemCategoria({required this.nombre, this.foto});

  final String nombre;
  final String? foto;
}

/// Fila de categorías en círculos, con la foto de un producto de cada una. Se
/// desliza de lado cuando no caben. [activa] es la categoría elegida (`null` es
/// "Todos"); [onTap] recibe `null` al tocar "Todos".
class TinaCirculosCategorias extends StatelessWidget {
  const TinaCirculosCategorias({
    super.key,
    required this.categorias,
    required this.onTap,
    this.activa,
    this.mostrarTodos = true,
    this.todosActivo = false,
  });

  final List<ItemCategoria> categorias;
  final ValueChanged<String?> onTap;
  final String? activa;
  final bool mostrarTodos;

  /// Marca "Todos" como elegido (cuando se ven todos los productos).
  final bool todosActivo;

  @override
  Widget build(BuildContext context) {
    final grande = esEscritorio(context);
    final tamano = grande ? 104.0 : 82.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: grande ? 24 : 16,
        children: [
          if (mostrarTodos)
            _Circulo(
              key: const ValueKey('chip-Todos'),
              nombre: 'Todos',
              tamano: tamano,
              activo: todosActivo,
              onTap: () => onTap(null),
            ),
          for (final c in categorias)
            _Circulo(
              key: ValueKey('chip-${c.nombre}'),
              nombre: c.nombre,
              foto: c.foto,
              tamano: tamano,
              activo: c.nombre == activa,
              onTap: () => onTap(c.nombre),
            ),
        ],
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo({
    super.key,
    required this.nombre,
    required this.tamano,
    required this.activo,
    required this.onTap,
    this.foto,
  });

  final String nombre;
  final String? foto;
  final double tamano;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activo,
      label: nombre,
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: tamano + 8,
            child: Column(
              spacing: 8,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: tamano,
                  height: tamano,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activo || encima
                        ? TinaColores.naranja
                        : Colors.transparent,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TinaColores.cremaSuave,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: foto != null
                        ? TinaImagenRed(url: foto!, radio: tamano)
                        : Center(
                            child: EstrellaTina(
                              tamano: tamano * 0.34,
                              color: activo
                                  ? TinaColores.naranja
                                  : TinaColores.durazno,
                            ),
                          ),
                  ),
                ),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TinaTipografia.estilo(
                    tamano: 13,
                    peso: FontWeight.w800,
                    color: activo || encima
                        ? TinaColores.naranja
                        : TinaColores.tinta,
                    altura: 1.15,
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
