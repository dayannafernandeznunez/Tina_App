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
    required this.onAgregarFoto,
    required this.onQuitarFotoNueva,
    required this.onQuitarFotoExistente,
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

  /// Elegir una foto para el color dado; `null` es la portada (foto general).
  final ValueChanged<String?> onAgregarFoto;

  /// Quitar una foto elegida que todavía no se ha subido (por su clave).
  final ValueChanged<String> onQuitarFotoNueva;

  /// Quitar una foto que el producto ya tiene (por su id); se borra al guardar.
  final ValueChanged<int> onQuitarFotoExistente;
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
            'Colores y stock',
            style: TinaTipografia.estilo(
              tamano: 20,
              peso: FontWeight.w800,
              espaciado: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cada color tiene su propio stock. Si un color se agota, ponle 0: la '
            'tienda lo muestra como agotado. Si la pieza no tiene tallas, deja '
            '"Única".',
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
          const SizedBox(height: 8),
          Text(
            'Stock total: ${borrador.stockTotal}',
            key: const ValueKey('stock-total-borrador'),
            style: TinaTipografia.estilo(
              tamano: 13,
              peso: FontWeight.w800,
              color: TinaColores.marron,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Fotos',
            style: TinaTipografia.estilo(
              tamano: 20,
              peso: FontWeight.w800,
              espaciado: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'La portada es la foto con que se ve el producto en la tienda. '
            'Cuando la clienta elige un color, ve las fotos de ese color; si un '
            'color no tiene fotos, ve la portada.',
            style: TinaTipografia.estilo(
              tamano: 13,
              color: TinaColores.marron,
              altura: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            spacing: 12,
            children: [
              _GrupoFotos(
                llave: 'portada',
                titulo: 'Portada',
                error: _error('foto'),
                existentes: borrador.fotosDe(null),
                nuevas: borrador.nuevasDe(null),
                ocupado: ocupado,
                onAgregar: () => onAgregarFoto(null),
                onQuitarNueva: onQuitarFotoNueva,
                onQuitarExistente: onQuitarFotoExistente,
              ),
              for (final color in borrador.colores)
                _GrupoFotos(
                  llave: claveColor(color),
                  titulo: 'Fotos de $color',
                  existentes: borrador.fotosDe(color),
                  nuevas: borrador.nuevasDe(color),
                  ocupado: ocupado,
                  onAgregar: () => onAgregarFoto(color),
                  onQuitarNueva: onQuitarFotoNueva,
                  onQuitarExistente: onQuitarFotoExistente,
                ),
              if (borrador.fotosHuerfanas.isNotEmpty)
                _GrupoFotos(
                  llave: 'huerfanas',
                  titulo: 'De un color que ya no está en la lista',
                  existentes: borrador.fotosHuerfanas,
                  nuevas: const [],
                  ocupado: ocupado,
                  onAgregar: null,
                  onQuitarNueva: onQuitarFotoNueva,
                  onQuitarExistente: onQuitarFotoExistente,
                ),
            ],
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

/// Las fotos de un grupo (la portada o un color): miniaturas con su "x" para
/// quitarlas y el botón para agregar otra.
class _GrupoFotos extends StatelessWidget {
  const _GrupoFotos({
    required this.llave,
    required this.titulo,
    required this.existentes,
    required this.nuevas,
    required this.ocupado,
    required this.onAgregar,
    required this.onQuitarNueva,
    required this.onQuitarExistente,
    this.error,
  });

  final String llave;
  final String titulo;
  final String? error;
  final List<ImagenProducto> existentes;
  final List<FotoNueva> nuevas;
  final bool ocupado;

  /// `null` si a este grupo no se le pueden agregar fotos.
  final VoidCallback? onAgregar;
  final ValueChanged<String> onQuitarNueva;
  final ValueChanged<int> onQuitarExistente;

  @override
  Widget build(BuildContext context) {
    final hayFotos = existentes.isNotEmpty || nuevas.isNotEmpty;
    return Container(
      key: ValueKey('fotos-grupo-$llave'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TinaColores.cremaCampo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: error != null ? TinaColores.rojo : TinaColores.dorado,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(
            titulo,
            style: TinaTipografia.estilo(tamano: 15, peso: FontWeight.w800),
          ),
          if (hayFotos)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final f in existentes)
                  _Miniatura(
                    key: ValueKey('foto-existente-${f.idImagen}'),
                    imagen: Image.network(
                      f.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _FotoRota(),
                    ),
                    llaveQuitar: ValueKey('quitar-foto-${f.idImagen}'),
                    onQuitar: ocupado
                        ? null
                        : () => onQuitarExistente(f.idImagen),
                  ),
                for (final f in nuevas)
                  _Miniatura(
                    key: ValueKey('foto-nueva-${f.clave}'),
                    nueva: true,
                    imagen: Image.memory(
                      f.foto.bytes,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _FotoRota(),
                    ),
                    llaveQuitar: ValueKey('quitar-foto-nueva-${f.clave}'),
                    onQuitar: ocupado ? null : () => onQuitarNueva(f.clave),
                  ),
              ],
            )
          else
            Text(
              onAgregar == null ? '' : 'Todavía no hay fotos.',
              style: TinaTipografia.estilo(
                tamano: 13,
                color: TinaColores.marron,
              ),
            ),
          if (error != null)
            Text(
              error!,
              key: ValueKey('error-fotos-$llave'),
              style: TinaTipografia.estilo(
                tamano: 14,
                peso: FontWeight.w800,
                color: TinaColores.rojo,
              ),
            ),
          if (onAgregar != null)
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: TinaBoton(
                  key: ValueKey('agregar-foto-$llave'),
                  etiqueta: 'Agregar foto',
                  variante: VarianteBoton.secundario,
                  onPressed: ocupado ? () {} : onAgregar!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({
    super.key,
    required this.imagen,
    required this.llaveQuitar,
    required this.onQuitar,
    this.nueva = false,
  });

  final Widget imagen;
  final Key llaveQuitar;
  final VoidCallback? onQuitar;

  /// Todavía no se ha subido: se marca para que se note.
  final bool nueva;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imagen,
            ),
          ),
          if (nueva)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: TinaColores.naranja,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nueva',
                  style: TinaTipografia.estilo(
                    tamano: 10,
                    peso: FontWeight.w800,
                    color: TinaColores.blanco,
                  ),
                ),
              ),
            ),
          Positioned(
            right: -6,
            top: -6,
            child: GestureDetector(
              key: llaveQuitar,
              behavior: HitTestBehavior.opaque,
              onTap: onQuitar,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: TinaColores.rojo,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: TinaColores.blanco,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoRota extends StatelessWidget {
  const _FotoRota();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: TinaColores.cremaSuave,
    child: Center(child: Icon(Icons.image_outlined, color: TinaColores.marron)),
  );
}
