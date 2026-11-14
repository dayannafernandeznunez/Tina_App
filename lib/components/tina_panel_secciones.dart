import 'package:flutter/material.dart';

import 'tina_chip.dart';

/// Las partes del panel de la vendedora.
enum SeccionPanel {
  pedidos('Pedidos'),
  productos('Productos'),
  fotosArticulos('Fotos de artículos'),
  fotosSitio('Fotos del sitio');

  const SeccionPanel(this.etiqueta);

  final String etiqueta;
}

/// Pestañas para moverse entre las partes del panel.
class TinaPanelSecciones extends StatelessWidget {
  const TinaPanelSecciones({
    super.key,
    required this.activa,
    required this.onSeccion,
  });

  final SeccionPanel activa;
  final ValueChanged<SeccionPanel> onSeccion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in SeccionPanel.values)
          TinaChip(
            key: ValueKey('seccion-${s.name}'),
            etiqueta: s.etiqueta,
            activo: s == activa,
            onTap: () => onSeccion(s),
          ),
      ],
    );
  }
}
