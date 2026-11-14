import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';

/// Panel de la vendedora, sección "Fotos de artículos": elige un artículo y
/// sube, ordena o borra sus fotos. No guarda nada: la Screen decide qué se
/// muestra y hace los cambios.
class PanelFotosArticulosPage extends StatelessWidget {
  const PanelFotosArticulosPage({
    super.key,
    required this.productos,
    required this.idProducto,
    required this.fotos,
    required this.ocupado,
    required this.onSeccion,
    required this.onElegirProducto,
    required this.onSubir,
    required this.onMover,
    required this.onPrincipal,
    required this.onBorrar,
    required this.onSalir,
    required this.onVerTienda,
  });

  final List<Producto> productos;
  final int idProducto;

  /// Fotos del artículo elegido, en su orden.
  final List<ImagenProducto> fotos;

  /// Hay una foto subiéndose o borrándose.
  final bool ocupado;
  final ValueChanged<SeccionPanel> onSeccion;
  final ValueChanged<int> onElegirProducto;
  final VoidCallback onSubir;
  final void Function(ImagenProducto foto, int paso) onMover;
  final ValueChanged<ImagenProducto> onPrincipal;
  final ValueChanged<ImagenProducto> onBorrar;
  final VoidCallback onSalir;
  final VoidCallback onVerTienda;

  Future<void> _confirmarBorrado(BuildContext context, ImagenProducto f) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TinaColores.crema,
        title: Text(
          '¿Borrar esta foto?',
          style: TinaTipografia.estilo(tamano: 18, peso: FontWeight.w800),
        ),
        content: Text(
          'Dejará de verse en la tienda. No se puede deshacer.',
          style: TinaTipografia.estilo(tamano: 14),
        ),
        actions: [
          TextButton(
            key: const ValueKey('borrar-no'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: TinaTipografia.estilo(
                tamano: 14,
                peso: FontWeight.w800,
                color: TinaColores.marron,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('borrar-si'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Borrar',
              style: TinaTipografia.estilo(
                tamano: 14,
                peso: FontWeight.w800,
                color: TinaColores.rojo,
              ),
            ),
          ),
        ],
      ),
    );
    if (seguro == true) onBorrar(f);
  }

  @override
  Widget build(BuildContext context) {
    return TinaScaffold(
      titulo: 'Panel de vendedora',
      conAtras: true,
      conCarrito: false,
      onAtras: onVerTienda,
      onLogo: onVerTienda,
      cuerpo: TinaLista(
        children: [
          Text(
            'Fotos de artículos',
            style: TinaTipografia.estilo(
              tamano: 28,
              peso: FontWeight.w800,
              espaciado: -0.84,
            ),
          ),
          const SizedBox(height: 14),
          TinaPanelSecciones(
            activa: SeccionPanel.fotosArticulos,
            onSeccion: onSeccion,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: DropdownMenu<int>(
              key: const ValueKey('elegir-articulo'),
              initialSelection: idProducto,
              label: const Text('Artículo'),
              width: 340,
              enableFilter: true,
              textStyle: TinaTipografia.estilo(tamano: 15),
              dropdownMenuEntries: [
                for (final p in productos)
                  DropdownMenuEntry<int>(value: p.idProducto, label: p.nombre),
              ],
              onSelected: (id) {
                if (id != null) onElegirProducto(id);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La primera foto es la que se ve en la tienda. Usa fotos JPG, PNG o WEBP de hasta 5 MB.',
            style: TinaTipografia.estilo(
              tamano: 13,
              color: TinaColores.marron,
              altura: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          if (fotos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(
                'Este artículo todavía no tiene fotos.',
                key: const ValueKey('sin-fotos'),
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 15,
                  color: TinaColores.marron,
                ),
              ),
            )
          else
            TinaRejilla(
              anchoMinimo: 200,
              children: [
                for (var i = 0; i < fotos.length; i++)
                  TinaFotoAdmin(
                    key: ValueKey('foto-admin-${fotos[i].idImagen}'),
                    url: fotos[i].url,
                    esPrincipal: i == 0,
                    puedeSubir: i > 0,
                    puedeBajar: i < fotos.length - 1,
                    ocupado: ocupado,
                    onSubir: () => onMover(fotos[i], -1),
                    onBajar: () => onMover(fotos[i], 1),
                    onPrincipal: () => onPrincipal(fotos[i]),
                    onBorrar: () => _confirmarBorrado(context, fotos[i]),
                  ),
              ],
            ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TinaBoton(
                etiqueta: ocupado ? 'Un momento…' : 'Subir foto',
                onPressed: ocupado ? () {} : onSubir,
              ),
            ),
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
                  TinaBoton(
                    etiqueta: 'Cerrar sesión',
                    variante: VarianteBoton.secundario,
                    onPressed: onSalir,
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
