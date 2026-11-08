import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'estrella_tina.dart';
import 'tina_hover.dart';

enum TonoEtiqueta { fuerte, suave }

/// Etiqueta de descuento: "20% en tu primera compra con cuenta". El tono
/// fuerte es naranja; el suave es crema.
class TinaEtiquetaDescuento extends StatelessWidget {
  const TinaEtiquetaDescuento({
    super.key,
    required this.texto,
    this.tono = TonoEtiqueta.fuerte,
  });

  final String texto;
  final TonoEtiqueta tono;

  @override
  Widget build(BuildContext context) {
    final fuerte = tono == TonoEtiqueta.fuerte;
    return TinaHover(
      cursor: MouseCursor.defer,
      builder: (context, encima) => TinaGiro(
        encima: encima,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          decoration: BoxDecoration(
            color: fuerte ? TinaColores.naranja : TinaColores.cremaSuave,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TinaColores.dorado, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              EstrellaTina(
                tamano: 16,
                color: fuerte ? TinaColores.durazno : TinaColores.naranja,
              ),
              Flexible(
                child: Text(
                  texto,
                  style: TinaTipografia.estilo(
                    tamano: 14,
                    peso: FontWeight.w800,
                    altura: 1.2,
                    color: fuerte
                        ? TinaColores.blanco
                        : const Color(0xFFB3123A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
