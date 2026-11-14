import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';

/// Panel de la vendedora, sección "Fotos del sitio": cada lugar de la página
/// con la foto que tiene y botones para cambiarla o quitarla. No guarda nada.
class PanelFotosSitioPage extends StatelessWidget {
  const PanelFotosSitioPage({
    super.key,
    required this.ajustes,
    required this.clavesEnUso,
    required this.claveOcupada,
    required this.onSeccion,
    required this.onSubir,
    required this.onQuitar,
    required this.onSalir,
    required this.onVerTienda,
  });

  final List<AjusteSitio> ajustes;

  /// Lugares que la tienda ya muestra. Los demás se pueden preparar, pero
  /// todavía no se ven en la página.
  final Set<String> clavesEnUso;

  /// Lugar que está subiendo o quitando una foto; `null` si ninguno.
  final String? claveOcupada;
  final ValueChanged<SeccionPanel> onSeccion;
  final ValueChanged<String> onSubir;
  final ValueChanged<String> onQuitar;
  final VoidCallback onSalir;
  final VoidCallback onVerTienda;

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
            'Fotos del sitio',
            style: TinaTipografia.estilo(
              tamano: 28,
              peso: FontWeight.w800,
              espaciado: -0.84,
            ),
          ),
          const SizedBox(height: 14),
          TinaPanelSecciones(
            activa: SeccionPanel.fotosSitio,
            onSeccion: onSeccion,
          ),
          const SizedBox(height: 8),
          Text(
            'Lo que cambies aquí se ve en la tienda para todas las personas. Usa fotos JPG, PNG o WEBP de hasta 5 MB.',
            style: TinaTipografia.estilo(
              tamano: 13,
              color: TinaColores.marron,
              altura: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          TinaRejilla(
            anchoMinimo: 440,
            children: [
              for (final a in ajustes)
                _TarjetaAjuste(
                  key: ValueKey('ajuste-${a.clave}'),
                  ajuste: a,
                  enUso: clavesEnUso.contains(a.clave),
                  ocupado: claveOcupada != null,
                  trabajando: claveOcupada == a.clave,
                  onSubir: () => onSubir(a.clave),
                  onQuitar: () => onQuitar(a.clave),
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

class _TarjetaAjuste extends StatelessWidget {
  const _TarjetaAjuste({
    super.key,
    required this.ajuste,
    required this.enUso,
    required this.ocupado,
    required this.trabajando,
    required this.onSubir,
    required this.onQuitar,
  });

  final AjusteSitio ajuste;
  final bool enUso;
  final bool ocupado;
  final bool trabajando;
  final VoidCallback onSubir;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinaColores.cremaCampo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TinaColores.dorado, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            ajuste.descripcion,
            style: TinaTipografia.estilo(tamano: 16, peso: FontWeight.w800),
          ),
          if (!enUso)
            Text(
              'Todavía no se muestra en la tienda.',
              key: ValueKey('sin-uso-${ajuste.clave}'),
              style: TinaTipografia.estilo(
                tamano: 12,
                color: TinaColores.marron,
              ),
            ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: TinaColores.cremaSuave,
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TinaColores.dorado),
              ),
              child: ajuste.tieneFoto
                  ? TinaImagenRed(url: ajuste.url!, radio: 16)
                  : Center(
                      child: Text(
                        'Sin foto: se ve el diseño de Tina',
                        textAlign: TextAlign.center,
                        style: TinaTipografia.estilo(
                          tamano: 13,
                          color: TinaColores.marron,
                        ),
                      ),
                    ),
            ),
          ),
          TinaBoton(
            key: ValueKey('subir-${ajuste.clave}'),
            etiqueta: trabajando
                ? 'Un momento…'
                : ajuste.tieneFoto
                ? 'Cambiar foto'
                : 'Subir foto',
            variante: VarianteBoton.secundario,
            onPressed: ocupado ? () {} : onSubir,
          ),
          if (ajuste.tieneFoto)
            Center(
              child: GestureDetector(
                key: ValueKey('quitar-${ajuste.clave}'),
                behavior: HitTestBehavior.opaque,
                onTap: ocupado ? null : onQuitar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Text(
                    'Quitar foto',
                    style: TinaTipografia.estilo(
                      tamano: 13,
                      peso: FontWeight.w800,
                      color: TinaColores.rojo,
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
