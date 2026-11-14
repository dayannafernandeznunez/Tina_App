import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_imagen_red.dart';

/// Una foto en el panel de la vendedora, con sus acciones. No guarda nada:
/// cada botón avisa con su callback y la Screen hace el cambio.
class TinaFotoAdmin extends StatelessWidget {
  const TinaFotoAdmin({
    super.key,
    required this.url,
    required this.esPrincipal,
    required this.puedeSubir,
    required this.puedeBajar,
    required this.ocupado,
    required this.onSubir,
    required this.onBajar,
    required this.onPrincipal,
    required this.onBorrar,
  });

  final String url;
  final bool esPrincipal;

  /// Si hay una foto antes que esta (se puede mover hacia el inicio).
  final bool puedeSubir;

  /// Si hay una foto después que esta.
  final bool puedeBajar;
  final bool ocupado;
  final VoidCallback onSubir;
  final VoidCallback onBajar;
  final VoidCallback onPrincipal;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: TinaColores.cremaSuave,
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: TinaColores.dorado, width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: TinaImagenRed(url: url, radio: 22)),
                if (esPrincipal)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: TinaColores.naranja,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Principal',
                        style: TinaTipografia.estilo(
                          tamano: 12,
                          peso: FontWeight.w800,
                          color: TinaColores.blanco,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 0,
          children: [
            if (puedeSubir)
              _Accion(
                llave: const ValueKey('foto-antes'),
                etiqueta: '← Antes',
                activa: !ocupado,
                onTap: onSubir,
              ),
            if (puedeBajar)
              _Accion(
                llave: const ValueKey('foto-despues'),
                etiqueta: 'Después →',
                activa: !ocupado,
                onTap: onBajar,
              ),
            if (!esPrincipal)
              _Accion(
                llave: const ValueKey('foto-principal'),
                etiqueta: 'Hacer principal',
                activa: !ocupado,
                onTap: onPrincipal,
              ),
            _Accion(
              llave: const ValueKey('foto-borrar'),
              etiqueta: 'Borrar',
              activa: !ocupado,
              peligro: true,
              onTap: onBorrar,
            ),
          ],
        ),
      ],
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({
    required this.llave,
    required this.etiqueta,
    required this.activa,
    required this.onTap,
    this.peligro = false,
  });

  final Key llave;
  final String etiqueta;
  final bool activa;
  final bool peligro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = peligro ? TinaColores.rojo : TinaColores.tinta;
    return Semantics(
      button: true,
      enabled: activa,
      label: etiqueta,
      excludeSemantics: true,
      onTap: activa ? onTap : null,
      child: GestureDetector(
        key: llave,
        behavior: HitTestBehavior.opaque,
        onTap: activa ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text(
            etiqueta,
            style: TinaTipografia.estilo(
              tamano: 13,
              peso: FontWeight.w800,
              color: activa ? color : color.withValues(alpha: 0.35),
            ).copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ),
    );
  }
}
