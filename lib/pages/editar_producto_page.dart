import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/borrador_producto.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';

/// Crear o editar un producto, con sus colores, tallas y stock. No guarda
/// nada: cada cambio se avisa con un callback y la Screen decide qué mostrar.
class EditarProductoPage extends StatelessWidget {
  const EditarProductoPage({
    super.key,
    required this.borrador,
    required this.categorias,
    required this.errores,
    required this.mostrarErrores,
    required this.ocupado,
    required this.onCampo,
    required this.onCategoria,
    required this.onVisible,
    required this.onVarianteCampo,
    required this.onVarianteStock,
    required this.onQuitarVariante,
    required this.onAgregarVariante,
    required this.onGuardar,
    required this.onCancelar,
  });

  final BorradorProducto borrador;
  final List<Categoria> categorias;

  /// Lo que está mal, por campo (ver `BorradorProducto.errores`).
  final Map<String, String> errores;

  /// Hasta que se intenta guardar no se marcan los campos vacíos.
  final bool mostrarErrores;
  final bool ocupado;

  /// `campo` es `nombre`, `descripcion`, `tecnica` o `precio`.
  final void Function(String campo, String valor) onCampo;
  final ValueChanged<int> onCategoria;
  final ValueChanged<bool> onVisible;

  /// `campo` es `color` o `talla`.
  final void Function(String clave, String campo, String valor) onVarianteCampo;
  final void Function(String clave, int stock) onVarianteStock;
  final ValueChanged<String> onQuitarVariante;
  final VoidCallback onAgregarVariante;
  final VoidCallback onGuardar;
  final VoidCallback onCancelar;

  String? _error(String clave) => mostrarErrores ? errores[clave] : null;

  @override
  Widget build(BuildContext context) {
    return TinaScaffold(
      titulo: borrador.esNuevo ? 'Nuevo producto' : 'Editar producto',
      conAtras: true,
      conCarrito: false,
      onAtras: onCancelar,
      onLogo: onCancelar,
      cuerpo: TinaLista(
        anchoMaximo: 760,
        children: [
          Text(
            borrador.esNuevo ? 'Nuevo producto' : 'Editar producto',
            style: TinaTipografia.estilo(
              tamano: 28,
              peso: FontWeight.w800,
              espaciado: -0.84,
            ),
          ),
          const SizedBox(height: 18),
          Column(
            spacing: 14,
            children: [
              TinaCampo(
                key: const ValueKey('prod-nombre'),
                etiqueta: 'Nombre',
                placeholder: 'Ej.: Maxi collar 3D con mostacilla',
                valor: borrador.nombre,
                textoError: _error('nombre'),
                onChanged: (v) => onCampo('nombre', v),
              ),
              TinaCampo(
                key: const ValueKey('prod-descripcion'),
                etiqueta: 'Descripción',
                placeholder: 'Cuenta cómo es la pieza',
                lineas: 4,
                valor: borrador.descripcion,
                onChanged: (v) => onCampo('descripcion', v),
              ),
              TinaCampo(
                key: const ValueKey('prod-tecnica'),
                etiqueta: 'Técnica',
                placeholder: 'Ej.: Porcelanicrón moldeado a mano',
                valor: borrador.tecnica,
                onChanged: (v) => onCampo('tecnica', v),
              ),
              TinaCampo(
                key: const ValueKey('prod-precio'),
                etiqueta: 'Precio en pesos',
                placeholder: 'Ej.: 55000',
                tipo: TipoCampo.numero,
                valor: borrador.precio,
                textoError: _error('precio'),
                onChanged: (v) => onCampo('precio', v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Categoría',
            style: TinaTipografia.estilo(tamano: 14, peso: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: DropdownMenu<int>(
              key: const ValueKey('prod-categoria'),
              initialSelection: borrador.idCategoria == 0
                  ? null
                  : borrador.idCategoria,
              hintText: 'Elige una categoría',
              width: 340,
              errorText: _error('categoria'),
              textStyle: TinaTipografia.estilo(tamano: 15),
              dropdownMenuEntries: [
                for (final c in categorias)
                  DropdownMenuEntry<int>(value: c.idCategoria, label: c.nombre),
              ],
              onSelected: (id) {
                if (id != null) onCategoria(id);
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '¿Se ve en la tienda?',
            style: TinaTipografia.estilo(tamano: 14, peso: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TinaChip(
                key: const ValueKey('prod-visible'),
                etiqueta: 'Visible',
                activo: borrador.activo,
                onTap: () => onVisible(true),
              ),
              TinaChip(
                key: const ValueKey('prod-oculto'),
                etiqueta: 'Oculto',
                activo: !borrador.activo,
                onTap: () => onVisible(false),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Colores, tallas y stock',
            style: TinaTipografia.estilo(
              tamano: 20,
              peso: FontWeight.w800,
              espaciado: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cada fila es una combinación que se puede comprar. Si la pieza no '
            'tiene tallas, deja "Única".',
            style: TinaTipografia.estilo(
              tamano: 13,
              color: TinaColores.marron,
              altura: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (_error('variantes') != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _error('variantes')!,
                style: TinaTipografia.estilo(
                  tamano: 14,
                  peso: FontWeight.w800,
                  color: TinaColores.rojo,
                ),
              ),
            ),
          Column(
            spacing: 12,
            children: [
              for (final v in borrador.variantes)
                _FilaVariante(
                  key: ValueKey('var-${v.clave}'),
                  variante: v,
                  error: _error('color-${v.clave}'),
                  puedeQuitar: borrador.variantes.length > 1,
                  onCampo: (campo, valor) =>
                      onVarianteCampo(v.clave, campo, valor),
                  onStock: (n) => onVarianteStock(v.clave, n),
                  onQuitar: () => onQuitarVariante(v.clave),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TinaBoton(
                key: const ValueKey('agregar-variante'),
                etiqueta: 'Agregar otro color o talla',
                variante: VarianteBoton.secundario,
                onPressed: onAgregarVariante,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                spacing: 12,
                children: [
                  TinaBoton(
                    key: const ValueKey('guardar-producto'),
                    etiqueta: ocupado
                        ? 'Guardando…'
                        : borrador.esNuevo
                        ? 'Crear producto'
                        : 'Guardar cambios',
                    onPressed: ocupado ? () {} : onGuardar,
                  ),
                  TinaBoton(
                    key: const ValueKey('cancelar-producto'),
                    etiqueta: 'Cancelar',
                    variante: VarianteBoton.secundario,
                    onPressed: ocupado ? () {} : onCancelar,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaVariante extends StatelessWidget {
  const _FilaVariante({
    super.key,
    required this.variante,
    required this.error,
    required this.puedeQuitar,
    required this.onCampo,
    required this.onStock,
    required this.onQuitar,
  });

  final BorradorVariante variante;
  final String? error;
  final bool puedeQuitar;
  final void Function(String campo, String valor) onCampo;
  final ValueChanged<int> onStock;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final clave = variante.clave;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TinaColores.cremaCampo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TinaColores.dorado, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                flex: 3,
                child: TinaCampo(
                  key: ValueKey('var-$clave-color'),
                  etiqueta: 'Color',
                  placeholder: 'Ej.: Naranja',
                  valor: variante.color,
                  textoError: error,
                  onChanged: (v) => onCampo('color', v),
                ),
              ),
              Expanded(
                flex: 2,
                child: TinaCampo(
                  key: ValueKey('var-$clave-talla'),
                  etiqueta: 'Talla',
                  placeholder: 'Única',
                  valor: variante.talla,
                  onChanged: (v) => onCampo('talla', v),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  Text(
                    'Stock',
                    style: TinaTipografia.estilo(
                      tamano: 14,
                      peso: FontWeight.w800,
                    ),
                  ),
                  TinaSelectorCantidad(
                    key: ValueKey('var-$clave-stock'),
                    valor: variante.stock,
                    minimo: 0,
                    maximo: 9999,
                    onChanged: onStock,
                  ),
                ],
              ),
              if (puedeQuitar)
                GestureDetector(
                  key: ValueKey('var-$clave-quitar'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onQuitar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Text(
                      'Quitar',
                      style: TinaTipografia.estilo(
                        tamano: 13,
                        peso: FontWeight.w800,
                        color: TinaColores.rojo,
                      ).copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
