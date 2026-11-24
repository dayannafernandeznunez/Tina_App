import 'package:flutter/material.dart';

import '../logic/filtros_catalogo.dart';
import '../logic/vistas.dart';
import '../models/models.dart';
import '../theme/colores_producto.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';
import 'tina_boton.dart';

/// Los filtros de una categoría: disponibilidad, color con su cantidad y precio.
/// [productos] son todos los de la categoría (sin filtrar), para contar y para
/// saber el rango de precios. No guarda nada: avisa cada cambio con [onCambio].
class TinaPanelFiltros extends StatelessWidget {
  const TinaPanelFiltros({
    super.key,
    required this.productos,
    required this.filtros,
    required this.onCambio,
  });

  final List<ProductoVista> productos;
  final FiltrosCatalogo filtros;
  final ValueChanged<FiltrosCatalogo> onCambio;

  @override
  Widget build(BuildContext context) {
    final colores = FiltrosCatalogo.coloresDe(productos);
    final rango = FiltrosCatalogo.rangoDePrecios(productos);
    final disponibles = productos.where((p) => p.stockTotal > 0).length;
    final agotados = productos.length - disponibles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 22,
      children: [
        _Grupo(
          titulo: 'Disponibilidad',
          hijos: [
            _Opcion(
              key: const ValueKey('filtro-disponible'),
              etiqueta: 'En existencia ($disponibles)',
              marcada: filtros.soloDisponibles,
              onTap: () => onCambio(
                filtros.copyWith(soloDisponibles: !filtros.soloDisponibles),
              ),
            ),
            _Opcion(
              etiqueta: 'Agotado ($agotados)',
              marcada: false,
              deshabilitada: true,
              onTap: () {},
            ),
          ],
        ),
        if (colores.isNotEmpty)
          _Grupo(
            titulo: 'Color',
            hijos: [
              for (final c in colores)
                _Opcion(
                  key: ValueKey('filtro-color-${c.nombre}'),
                  etiqueta: '${c.nombre} (${c.productos})',
                  muestra: colorDeProducto(c.nombre),
                  marcada: filtros.colores.contains(claveColor(c.nombre)),
                  onTap: () {
                    final clave = claveColor(c.nombre);
                    final nuevos = {...filtros.colores};
                    if (!nuevos.add(clave)) nuevos.remove(clave);
                    onCambio(filtros.copyWith(colores: nuevos));
                  },
                ),
            ],
          ),
        if (rango != null && rango.$1 < rango.$2)
          _Grupo(
            titulo: 'Precio',
            hijos: [
              Slider(
                key: const ValueKey('filtro-precio'),
                min: rango.$1.toDouble(),
                max: rango.$2.toDouble(),
                divisions: ((rango.$2 - rango.$1) / 1000).ceil().clamp(1, 200),
                value: (filtros.precioMaximo ?? rango.$2)
                    .clamp(rango.$1, rango.$2)
                    .toDouble(),
                activeColor: TinaColores.naranja,
                inactiveColor: TinaColores.durazno,
                onChanged: (v) {
                  final precio = v.round();
                  onCambio(
                    precio >= rango.$2
                        ? filtros.copyWith(sinPrecioMaximo: true)
                        : filtros.copyWith(precioMaximo: precio),
                  );
                },
              ),
              Text(
                'Hasta ${formatoPesos(filtros.precioMaximo ?? rango.$2)}',
                key: const ValueKey('filtro-precio-texto'),
                style: TinaTipografia.estilo(
                  tamano: 13,
                  color: TinaColores.marron,
                ),
              ),
            ],
          ),
        if (filtros.hayFiltros)
          TinaBoton(
            key: const ValueKey('quitar-filtros'),
            etiqueta: 'Quitar filtros',
            variante: VarianteBoton.secundario,
            onPressed: () => onCambio(filtros.sinFiltros()),
          ),
      ],
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(
          titulo,
          style: TinaTipografia.estilo(tamano: 16, peso: FontWeight.w800),
        ),
        Container(height: 2, width: 52, color: TinaColores.naranja),
        const SizedBox(height: 4),
        ...hijos,
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    super.key,
    required this.etiqueta,
    required this.marcada,
    required this.onTap,
    this.muestra,
    this.deshabilitada = false,
  });

  final String etiqueta;
  final bool marcada;
  final bool deshabilitada;
  final Color? muestra;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !deshabilitada,
      checked: marcada,
      label: etiqueta,
      excludeSemantics: true,
      onTap: deshabilitada ? null : onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: deshabilitada ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            spacing: 10,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: marcada ? TinaColores.naranja : TinaColores.blanco,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: deshabilitada
                        ? TinaColores.durazno
                        : marcada
                        ? TinaColores.naranja
                        : TinaColores.marron,
                    width: 1.5,
                  ),
                ),
                child: marcada
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: TinaColores.blanco,
                      )
                    : null,
              ),
              if (muestra != null)
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: muestra,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
              Flexible(
                child: Text(
                  etiqueta,
                  style: TinaTipografia.estilo(
                    tamano: 14,
                    peso: FontWeight.w600,
                    color: deshabilitada
                        ? TinaColores.marron.withValues(alpha: 0.6)
                        : TinaColores.tinta,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
