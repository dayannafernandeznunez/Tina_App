import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import '../utils/adaptable.dart';

/// Franja fija al pie de una pantalla con la acción principal (un botón). En
/// escritorio el botón queda a la derecha, con un ancho fijo.
class TinaBarraAccion extends StatelessWidget {
  const TinaBarraAccion({super.key, required this.hijo});

  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    final escritorio = esEscritorio(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        escritorio ? 24 : 20,
        14,
        escritorio ? 24 : 20,
        16,
      ),
      decoration: const BoxDecoration(
        color: TinaColores.cremaBarra,
        border: Border(top: BorderSide(color: TinaColores.dorado, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: anchoContenido),
            child: escritorio
                ? Align(
                    heightFactor: 1,
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: 380, child: hijo),
                  )
                : hijo,
          ),
        ),
      ),
    );
  }
}
