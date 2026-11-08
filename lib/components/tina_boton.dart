import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'estrella_tina.dart';

enum VarianteBoton { principal, secundario }

/// Botón de Tina. El principal es naranja con estrella; el secundario es
/// crema con borde dorado. Ocupa todo el ancho disponible.
class TinaBoton extends StatefulWidget {
  const TinaBoton({
    super.key,
    required this.etiqueta,
    required this.onPressed,
    this.variante = VarianteBoton.principal,
  });

  final String etiqueta;
  final VoidCallback onPressed;
  final VarianteBoton variante;

  @override
  State<TinaBoton> createState() => _TinaBotonState();
}

class _TinaBotonState extends State<TinaBoton> {
  // Solo anima el botón al apretarlo; no es un dato de la app.
  bool _presionado = false;
  bool _encima = false;

  void _marcar(bool valor) => setState(() => _presionado = valor);

  @override
  Widget build(BuildContext context) {
    final principal = widget.variante == VarianteBoton.principal;

    final decoracion = principal
        ? BoxDecoration(
            color: _presionado
                ? const Color(0xFFE85F00)
                : _encima
                ? TinaColores.naranjaHover
                : TinaColores.naranja,
            borderRadius: BorderRadius.circular(999),
          )
        : BoxDecoration(
            color: _presionado || _encima
                ? TinaColores.cremaHover
                : TinaColores.crema,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _encima ? TinaColores.naranja : TinaColores.dorado,
              width: 2,
            ),
          );

    return Semantics(
      button: true,
      label: widget.etiqueta,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _encima = true),
        onExit: (_) => setState(() => _encima = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _marcar(true),
          onTapUp: (_) => _marcar(false),
          onTapCancel: () => _marcar(false),
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                0,
                _presionado ? 1 : (_encima ? -2 : 0),
                0,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                constraints: const BoxConstraints(
                  minHeight: 54,
                  minWidth: double.infinity,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: decoracion,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.etiqueta,
                        textAlign: TextAlign.center,
                        style: TinaTipografia.estilo(
                          tamano: 17,
                          peso: FontWeight.w800,
                          color: principal
                              ? TinaColores.blanco
                              : TinaColores.tinta,
                          espaciado: -0.17,
                        ),
                      ),
                    ),
                    if (principal) ...[
                      const SizedBox(width: 10),
                      const EstrellaTina(
                        tamano: 13,
                        color: TinaColores.durazno,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
