import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'estrella_tina.dart';

/// Cinta naranja con lo que da confianza, separado por estrellitas.
class TinaCintaConfianza extends StatelessWidget {
  const TinaCintaConfianza({super.key});

  static const List<String> frases = [
    'Hechos a mano',
    'Piezas únicas',
    'Envío a todo el país',
    'Contraentrega en Cali',
    'Pagos seguros',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('cinta-confianza'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: TinaColores.naranja,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          for (var i = 0; i < frases.length; i++) ...[
            if (i > 0)
              const EstrellaTina(tamano: 11, color: TinaColores.durazno),
            Text(
              frases[i],
              style: TinaTipografia.estilo(
                tamano: 14,
                peso: FontWeight.w800,
                color: TinaColores.blanco,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
