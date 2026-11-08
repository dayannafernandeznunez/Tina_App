import 'package:flutter/material.dart';

/// Avisa si el mouse está encima. En celular nunca está encima, así que los
/// efectos de hover solo se ven en PC.
class TinaHover extends StatefulWidget {
  const TinaHover({
    super.key,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
  });

  final Widget Function(BuildContext context, bool encima) builder;
  final MouseCursor cursor;

  @override
  State<TinaHover> createState() => _TinaHoverState();
}

class _TinaHoverState extends State<TinaHover> {
  bool _encima = false;

  void _marcar(bool valor) {
    if (_encima != valor) setState(() => _encima = valor);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => _marcar(true),
      onExit: (_) => _marcar(false),
      child: widget.builder(context, _encima),
    );
  }
}

/// Sube un poco al pasar el mouse, con una transición suave. No agrega
/// sombra: solo se mueve.
class TinaLevante extends StatelessWidget {
  const TinaLevante({
    super.key,
    required this.encima,
    required this.child,
    this.dy = -3,
  });

  final bool encima;
  final Widget child;
  final double dy;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, encima ? dy : 0, 0),
      child: child,
    );
  }
}

/// Crece y gira apenas al pasar el mouse (etiquetas, pastillas, logo).
class TinaGiro extends StatelessWidget {
  const TinaGiro({
    super.key,
    required this.encima,
    required this.child,
    this.escala = 1.06,
    this.vueltas = 0.004,
  });

  final bool encima;
  final Widget child;
  final double escala;
  final double vueltas;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      scale: encima ? escala : 1,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        turns: encima ? vueltas : 0,
        child: child,
      ),
    );
  }
}
