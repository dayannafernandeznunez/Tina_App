import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import '../utils/adaptable.dart';
import 'estrella_tina.dart';

/// Intro animada de Tina: las letras se escriben una por una con un lápiz que
/// las traza y luego se desvanece; la estrella de la ı aparece con un rebote,
/// después entra el eslogan y al final toda la intro sale suavemente. Se
/// puede saltar con un toque o un clic.
///
/// Solo maneja su propia animación. Quien la usa decide cuándo mostrarla y se
/// entera con [onTerminar] (al acabar o al saltarla).
class TinaIntro extends StatefulWidget {
  const TinaIntro({super.key, required this.onTerminar});

  final VoidCallback onTerminar;

  @override
  State<TinaIntro> createState() => _TinaIntroState();
}

class _TinaIntroState extends State<TinaIntro>
    with SingleTickerProviderStateMixin {
  static const List<String> _letras = ['T', 'ı', 'n', 'a'];
  static const List<double> _inicios = [0.04, 0.18, 0.31, 0.45];
  static const double _duracionLetra = 0.13;

  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  bool _terminada = false;

  @override
  void initState() {
    super.initState();
    _controlador.addStatusListener((estado) {
      if (estado == AnimationStatus.completed) _terminar();
    });
    _controlador.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si la persona pidió menos animaciones en su sistema, no se muestra.
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _terminar());
    }
  }

  void _terminar() {
    if (_terminada) return;
    _terminada = true;
    widget.onTerminar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  /// Avance (0 a 1) de un tramo de la animación.
  double _tramo(
    double t,
    double desde,
    double hasta, [
    Curve curva = Curves.linear,
  ]) {
    return curva.transform(((t - desde) / (hasta - desde)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final tamano = esEscritorio(context) ? 120.0 : 92.0;
    final estilo = TinaTipografia.estilo(
      tamano: tamano,
      peso: FontWeight.w800,
      color: TinaColores.naranja,
      espaciado: -tamano * 0.015,
      altura: 1,
    );

    return Semantics(
      button: true,
      label: 'Bienvenida a Tina. Toca para saltar la animación',
      excludeSemantics: true,
      onTap: _terminar,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _terminar,
          child: AnimatedBuilder(
            animation: _controlador,
            builder: (context, _) {
              final t = _controlador.value;
              final salida = 1 - _tramo(t, 0.9, 1.0);
              final progresos = [
                for (var i = 0; i < _letras.length; i++)
                  _tramo(
                    t,
                    _inicios[i],
                    _inicios[i] + _duracionLetra,
                    Curves.easeInOut,
                  ),
              ];
              final lapizVisible = 1 - _tramo(t, 0.62, 0.68);
              final estrella = Curves.elasticOut.transform(
                _tramo(t, 0.62, 0.80),
              );
              final eslogan = _tramo(t, 0.72, 0.90);

              return Material(
                color: TinaColores.crema,
                child: Opacity(
                  opacity: salida,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < _letras.length; i++)
                              _Letra(
                                llave: ValueKey('intro-letra-$i'),
                                letra: _letras[i],
                                estilo: estilo,
                                progreso: progresos[i],
                                lapiz: lapizVisible,
                                tamano: tamano,
                                estrella: i == 1 ? estrella : null,
                              ),
                          ],
                        ),
                        SizedBox(height: tamano * 0.18),
                        Opacity(
                          opacity: _tramo(t, 0.72, 0.78),
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              (1 - Curves.elasticOut.transform(eslogan)) * 34,
                            ),
                            child: Text(
                              'Tan latinas como tú',
                              style: TinaTipografia.serif(
                                tamano: tamano * 0.3,
                                color: TinaColores.rojo,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: tamano * 0.5),
                        Opacity(
                          opacity: _tramo(t, 0.2, 0.3) * 0.7,
                          child: Text(
                            'Toca para saltar',
                            style: TinaTipografia.estilo(
                              tamano: 13,
                              color: TinaColores.marron,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Una letra que se va descubriendo de izquierda a derecha mientras un lápiz
/// la traza. Con [estrella] pone la estrella de Tina sobre la letra.
class _Letra extends StatelessWidget {
  const _Letra({
    required this.llave,
    required this.letra,
    required this.estilo,
    required this.progreso,
    required this.lapiz,
    required this.tamano,
    this.estrella,
  });

  final Key llave;
  final String letra;
  final TextStyle estilo;
  final double progreso;
  final double lapiz;
  final double tamano;
  final double? estrella;

  @override
  Widget build(BuildContext context) {
    final escribiendo = progreso > 0 && progreso < 1;
    return Stack(
      key: llave,
      clipBehavior: Clip.none,
      children: [
        // Da el tamaño de la letra completa, sin verse.
        Opacity(opacity: 0, child: Text(letra, style: estilo)),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: progreso,
            child: Text(letra, style: estilo),
          ),
        ),
        if (escribiendo)
          Positioned.fill(
            child: Align(
              alignment: Alignment(progreso * 2 - 1, 0.55),
              child: Opacity(
                opacity: lapiz,
                child: Transform.rotate(
                  angle: -0.7,
                  child: Icon(
                    Icons.edit_rounded,
                    size: tamano * 0.34,
                    color: TinaColores.tinta,
                  ),
                ),
              ),
            ),
          ),
        if (estrella != null)
          Positioned(
            left: 0,
            right: 0,
            top: -tamano * 0.1,
            child: Center(
              child: Transform.rotate(
                angle: (1 - estrella!.clamp(0.0, 1.0)) * 1.2,
                child: Transform.scale(
                  scale: estrella,
                  child: EstrellaTina(
                    tamano: tamano * 0.3,
                    color: TinaColores.rojo,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
