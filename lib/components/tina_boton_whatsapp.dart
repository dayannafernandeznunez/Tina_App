import 'package:flutter/material.dart';

import '../config/tienda_config.dart';
import '../utils/abrir_url.dart';

/// Botón verde de WhatsApp, siempre visible en una esquina. Si la tienda no
/// tiene un número en [TiendaConfig.whatsapp], no se muestra nada.
class TinaBotonWhatsapp extends StatelessWidget {
  const TinaBotonWhatsapp({super.key});

  @override
  Widget build(BuildContext context) {
    if (TiendaConfig.whatsapp.isEmpty) return const SizedBox.shrink();
    final url =
        'https://wa.me/${TiendaConfig.whatsapp}'
        '?text=${Uri.encodeComponent(TiendaConfig.mensajeWhatsapp)}';
    return Semantics(
      button: true,
      label: 'Escríbenos por WhatsApp',
      excludeSemantics: true,
      onTap: () => abrirEnPestanaNueva(url),
      child: GestureDetector(
        key: const ValueKey('boton-whatsapp'),
        onTap: () => abrirEnPestanaNueva(url),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFF25D366),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
