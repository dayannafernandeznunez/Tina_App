import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';

/// Cuatro razones para comprar tranquila, con su ícono.
class TinaGarantias extends StatelessWidget {
  const TinaGarantias({super.key});

  static const List<(IconData, String)> _items = [
    (Icons.local_shipping_outlined, 'Envíos a todo el país'),
    (Icons.chat_bubble_outline_rounded, 'Te escribimos para coordinar'),
    (Icons.back_hand_outlined, 'Hecho a mano con mucho amor'),
    (Icons.verified_user_outlined, 'Pagos seguros y confiables'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final columnas = restricciones.maxWidth < 700 ? 2 : 4;
        final ancho = (restricciones.maxWidth - 16 * (columnas - 1)) / columnas;
        return Wrap(
          key: const ValueKey('garantias'),
          spacing: 16,
          runSpacing: 22,
          children: [
            for (final (icono, texto) in _items)
              SizedBox(
                width: ancho,
                child: Column(
                  spacing: 10,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: TinaColores.melocoton,
                      ),
                      child: Icon(icono, color: TinaColores.naranja, size: 26),
                    ),
                    Text(
                      texto.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TinaTipografia.estilo(
                        tamano: 12,
                        peso: FontWeight.w800,
                        espaciado: 0.4,
                        altura: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
