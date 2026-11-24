import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';

/// Panel de la vendedora, sección "Colecciones": crear una colección, ponerle
/// foto, mostrarla u ocultarla y borrarla. No guarda nada: avisa con callbacks.
class PanelColeccionesPage extends StatelessWidget {
  const PanelColeccionesPage({
    super.key,
    required this.colecciones,
    required this.productosPorColeccion,
    required this.nombre,
    required this.subtitulo,
    required this.editandoId,
    required this.idPorBorrar,
    required this.ocupado,
    required this.onCampo,
    required this.onGuardar,
    required this.onCancelarEdicion,
    required this.onEditar,
    required this.onAlternar,
    required this.onSubirFoto,
    required this.onQuitarFoto,
    required this.onBorrar,
    required this.onSeccion,
    required this.onVerTienda,
    this.onSalir,
  });

  /// Todas, también las ocultas.
  final List<Coleccion> colecciones;

  /// Cuántos productos tiene cada colección (por su id).
  final Map<int, int> productosPorColeccion;

  /// Lo que se escribió en el formulario.
  final String nombre;
  final String subtitulo;

  /// La colección que se está editando; `null` si se está creando una nueva.
  final int? editandoId;

  /// La colección a la que se le tocó "Borrar" y falta confirmar.
  final int? idPorBorrar;
  final bool ocupado;

  /// `campo` es `nombre` o `subtitulo`.
  final void Function(String campo, String valor) onCampo;
  final VoidCallback onGuardar;
  final VoidCallback onCancelarEdicion;
  final ValueChanged<int> onEditar;
  final ValueChanged<int> onAlternar;
  final ValueChanged<int> onSubirFoto;
  final ValueChanged<int> onQuitarFoto;
  final ValueChanged<int> onBorrar;
  final ValueChanged<SeccionPanel> onSeccion;
  final VoidCallback onVerTienda;
  final VoidCallback? onSalir;

  @override
  Widget build(BuildContext context) {
    return TinaScaffold(
      titulo: 'Panel de vendedora',
      conAtras: true,
      conCarrito: false,
      onAtras: onVerTienda,
      onLogo: onVerTienda,
      cuerpo: TinaLista(
        anchoMaximo: 900,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Colecciones',
                style: TinaTipografia.estilo(
                  tamano: 28,
                  peso: FontWeight.w800,
                  espaciado: -0.84,
                ),
              ),
              Text(
                '${colecciones.length} '
                '${colecciones.length == 1 ? 'colección' : 'colecciones'}',
                key: const ValueKey('resumen-colecciones'),
                style: TinaTipografia.estilo(
                  tamano: 14,
                  color: TinaColores.marron,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TinaPanelSecciones(
            activa: SeccionPanel.colecciones,
            onSeccion: onSeccion,
          ),
          const SizedBox(height: 8),
          Text(
            'Una colección junta productos que van bien (por ejemplo "Con amor, '
            'para mí"). Los productos se asignan a una colección al crearlos o '
            'editarlos, en la sección Productos.',
            style: TinaTipografia.estilo(
              tamano: 13,
              color: TinaColores.marron,
              altura: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: TinaColores.blanco.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  editandoId == null ? 'Nueva colección' : 'Editar colección',
                  style: TinaTipografia.estilo(
                    tamano: 18,
                    peso: FontWeight.w800,
                  ),
                ),
                TinaCampo(
                  key: const ValueKey('coleccion-nombre'),
                  etiqueta: 'Nombre',
                  placeholder: 'Ej.: Con amor, para mí',
                  valor: nombre,
                  onChanged: (v) => onCampo('nombre', v),
                ),
                TinaCampo(
                  key: const ValueKey('coleccion-subtitulo'),
                  etiqueta: 'Subtítulo (opcional)',
                  placeholder: 'Ej.: Ideales para regalar',
                  valor: subtitulo,
                  onChanged: (v) => onCampo('subtitulo', v),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 260,
                      child: TinaBoton(
                        key: const ValueKey('guardar-coleccion'),
                        etiqueta: ocupado
                            ? 'Guardando…'
                            : editandoId == null
                            ? 'Crear colección'
                            : 'Guardar cambios',
                        onPressed: ocupado ? () {} : onGuardar,
                      ),
                    ),
                    if (editandoId != null)
                      SizedBox(
                        width: 200,
                        child: TinaBoton(
                          key: const ValueKey('cancelar-coleccion'),
                          etiqueta: 'Cancelar',
                          variante: VarianteBoton.secundario,
                          onPressed: ocupado ? () {} : onCancelarEdicion,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (colecciones.isEmpty)
            Padding(
              key: const ValueKey('panel-sin-colecciones'),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Todavía no hay colecciones. ¡Crea la primera!',
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 15,
                  color: TinaColores.marron,
                ),
              ),
            )
          else
            Column(
              spacing: 14,
              children: [
                for (final c in colecciones)
                  _TarjetaColeccion(
                    key: ValueKey('coleccion-${c.idColeccion}'),
                    coleccion: c,
                    productos: productosPorColeccion[c.idColeccion] ?? 0,
                    porBorrar: idPorBorrar == c.idColeccion,
                    ocupado: ocupado,
                    onEditar: () => onEditar(c.idColeccion),
                    onAlternar: () => onAlternar(c.idColeccion),
                    onSubirFoto: () => onSubirFoto(c.idColeccion),
                    onQuitarFoto: () => onQuitarFoto(c.idColeccion),
                    onBorrar: () => onBorrar(c.idColeccion),
                  ),
              ],
            ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                spacing: 12,
                children: [
                  TinaBoton(
                    etiqueta: 'Ver tienda',
                    variante: VarianteBoton.secundario,
                    onPressed: onVerTienda,
                  ),
                  if (onSalir != null)
                    TinaBoton(
                      etiqueta: 'Cerrar sesión',
                      variante: VarianteBoton.secundario,
                      onPressed: onSalir!,
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

class _TarjetaColeccion extends StatelessWidget {
  const _TarjetaColeccion({
    super.key,
    required this.coleccion,
    required this.productos,
    required this.porBorrar,
    required this.ocupado,
    required this.onEditar,
    required this.onAlternar,
    required this.onSubirFoto,
    required this.onQuitarFoto,
    required this.onBorrar,
  });

  final Coleccion coleccion;
  final int productos;
  final bool porBorrar;
  final bool ocupado;
  final VoidCallback onEditar;
  final VoidCallback onAlternar;
  final VoidCallback onSubirFoto;
  final VoidCallback onQuitarFoto;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    Widget enlace(
      String texto,
      VoidCallback onTap,
      Key llave, {
      Color? color,
    }) => GestureDetector(
      key: llave,
      behavior: HitTestBehavior.opaque,
      onTap: ocupado ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          texto,
          style: TinaTipografia.estilo(
            tamano: 13,
            peso: FontWeight.w800,
            color: color ?? TinaColores.naranja,
          ).copyWith(decoration: TextDecoration.underline),
        ),
      ),
    );

    final id = coleccion.idColeccion;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TinaColores.blanco.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: TinaColores.cremaSuave,
            ),
            clipBehavior: Clip.antiAlias,
            child: coleccion.tieneFoto
                ? TinaImagenRed(url: coleccion.url!, radio: 0)
                : const Center(
                    child: EstrellaTina(tamano: 30, color: TinaColores.durazno),
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  coleccion.nombre,
                  style: TinaTipografia.estilo(
                    tamano: 17,
                    peso: FontWeight.w800,
                  ),
                ),
                if (coleccion.subtitulo.isNotEmpty)
                  Text(
                    coleccion.subtitulo,
                    style: TinaTipografia.serif(
                      tamano: 15,
                      color: TinaColores.marron,
                    ),
                  ),
                Text(
                  '$productos ${productos == 1 ? 'producto' : 'productos'}'
                  '${coleccion.activa ? '' : ' · oculta'}',
                  style: TinaTipografia.estilo(
                    tamano: 13,
                    color: TinaColores.marron,
                  ),
                ),
                Wrap(
                  spacing: 16,
                  children: [
                    enlace(
                      'Editar',
                      onEditar,
                      ValueKey('editar-coleccion-$id'),
                    ),
                    enlace(
                      coleccion.tieneFoto ? 'Cambiar foto' : 'Subir foto',
                      onSubirFoto,
                      ValueKey('foto-coleccion-$id'),
                    ),
                    if (coleccion.tieneFoto)
                      enlace(
                        'Quitar foto',
                        onQuitarFoto,
                        ValueKey('quitar-foto-coleccion-$id'),
                      ),
                    enlace(
                      porBorrar ? 'Confirmar: borrar' : 'Borrar',
                      onBorrar,
                      ValueKey('borrar-coleccion-$id'),
                      color: TinaColores.rojo,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                key: ValueKey('visible-coleccion-$id'),
                value: coleccion.activa,
                onChanged: ocupado ? null : (_) => onAlternar(),
                activeTrackColor: TinaColores.naranja,
                activeThumbColor: TinaColores.blanco,
                inactiveTrackColor: TinaColores.cremaSuave,
                inactiveThumbColor: TinaColores.marron,
              ),
              Text(
                coleccion.activa ? 'Visible' : 'Oculta',
                style: TinaTipografia.estilo(
                  tamano: 12,
                  peso: FontWeight.w800,
                  color: coleccion.activa
                      ? TinaColores.naranja
                      : TinaColores.marron,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
