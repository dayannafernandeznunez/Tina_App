import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_hover.dart';

/// Selector de cantidad con botones − y +. No guarda la cantidad: recibe
/// [valor] y avisa con [onChanged] solo si el nuevo valor está entre [minimo]
/// y [maximo] (por ejemplo, el stock disponible).
class TinaSelectorCantidad extends StatelessWidget {
  const TinaSelectorCantidad({
    super.key,
    required this.valor,
    required this.onChanged,
    this.minimo = 1,
    this.maximo = 99,
  });

  final int valor;
  final ValueChanged<int> onChanged;
  final int minimo;
  final int maximo;

  void _cambiar(int nuevo) {
    if (nuevo >= minimo && nuevo <= maximo) onChanged(nuevo);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: TinaColores.cremaCampo,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TinaColores.dorado, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BotonCantidad(
            llave: const ValueKey('cantidad-menos'),
            etiqueta: 'Menos',
            simbolo: '−',
            color: TinaColores.tinta,
            activo: valor > minimo,
            onTap: () => _cambiar(valor - 1),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 30),
            child: Text(
              '$valor',
              textAlign: TextAlign.center,
              style: TinaTipografia.estilo(tamano: 17, peso: FontWeight.w800),
            ),
          ),
          _BotonCantidad(
            llave: const ValueKey('cantidad-mas'),
            etiqueta: 'Más',
            simbolo: '+',
            color: TinaColores.naranja,
            activo: valor < maximo,
            onTap: () => _cambiar(valor + 1),
          ),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  const _BotonCantidad({
    required this.llave,
    required this.etiqueta,
    required this.simbolo,
    required this.color,
    required this.activo,
    required this.onTap,
  });

  final Key llave;
  final String etiqueta;
  final String simbolo;
  final Color color;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: activo,
      label: etiqueta,
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => TinaGiro(
          encima: encima,
          escala: 1.15,
          vueltas: 0,
          child: GestureDetector(
            key: llave,
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Text(
                  simbolo,
                  style: TinaTipografia.estilo(
                    tamano: 22,
                    peso: FontWeight.w800,
                    color: activo ? color : color.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
