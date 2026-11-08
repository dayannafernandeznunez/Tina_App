import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';
import 'tina_boton_redondo.dart';
import 'tina_carrito_redondo.dart';
import 'tina_logo.dart';

/// Barra superior de 64 px: botón de volver (opcional), título o logo, y el
/// carrito con el número de unidades. Se puede usar como `appBar` de un
/// Scaffold.
class TinaBarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  const TinaBarraSuperior({
    super.key,
    this.titulo,
    this.conAtras = false,
    this.carrito = 0,
    this.conCarrito = true,
    this.onAtras,
    this.onCarrito,
    this.onLogo,
  });

  final String? titulo;
  final bool conAtras;
  final int carrito;
  final bool conCarrito;
  final VoidCallback? onAtras;
  final VoidCallback? onCarrito;
  final VoidCallback? onLogo;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final hayTitulo = titulo != null && titulo!.isNotEmpty;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: TinaColores.cremaBarra,
        border: Border(
          bottom: BorderSide(color: TinaColores.dorado, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: conAtras
                ? TinaBotonRedondo(
                    etiqueta: 'Volver',
                    icono: Icons.chevron_left_rounded,
                    tamanoIcono: 28,
                    onPressed: onAtras,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: hayTitulo
                  ? Text(
                      titulo!,
                      overflow: TextOverflow.ellipsis,
                      style: TinaTipografia.estilo(
                        tamano: 18,
                        peso: FontWeight.w800,
                        espaciado: -0.36,
                      ),
                    )
                  : TinaLogo(onTap: onLogo),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: !conCarrito
                ? null
                : TinaCarritoRedondo(carrito: carrito, onCarrito: onCarrito),
          ),
        ],
      ),
    );
  }
}
