import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/vistas.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

/// Cuenta de la clienta con sesión iniciada: sus datos y sus pedidos.
class CuentaPage extends StatelessWidget {
  const CuentaPage({
    super.key,
    required this.nombre,
    required this.correo,
    required this.pedidos,
    required this.unidadesCarrito,
    required this.onPedido,
    required this.onCerrarSesion,
    this.onPanel,
    required this.onAtras,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
  });

  final String nombre;
  final String correo;
  final List<PedidoCompleto> pedidos;
  final int unidadesCarrito;
  final ValueChanged<int> onPedido;
  final VoidCallback onCerrarSesion;

  /// Va al panel de la vendedora. Solo lo recibe la administradora.
  final VoidCallback? onPanel;
  final VoidCallback onAtras;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;

  @override
  Widget build(BuildContext context) {
    return TinaScaffold(
      titulo: 'Mi cuenta',
      conAtras: true,
      activo: DestinoNav.cuenta,
      unidadesCarrito: unidadesCarrito,
      onAtras: onAtras,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      cuerpo: TinaLista(
        anchoMaximo: 760,
        arriba: 26,
        children: [
          Text(
            'Bienvenida',
            style: TinaTipografia.serif(tamano: 30, color: TinaColores.rojo),
          ),
          Text(
            nombre,
            key: const ValueKey('cuenta-nombre'),
            style: TinaTipografia.estilo(
              tamano: 34,
              peso: FontWeight.w800,
              espaciado: -1,
              altura: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            correo,
            style: TinaTipografia.estilo(tamano: 14, color: TinaColores.marron),
          ),
          if (onPanel != null) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: TinaBoton(
                  key: const ValueKey('ir-panel-cuenta'),
                  etiqueta: 'Ir al panel de vendedora',
                  onPressed: onPanel!,
                ),
              ),
            ),
          ],
          const SizedBox(height: 26),
          Text(
            'Mis pedidos',
            style: TinaTipografia.estilo(
              tamano: 20,
              peso: FontWeight.w800,
              espaciado: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          if (pedidos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Todavía no tienes pedidos. ¡Cuando compres, aparecerán aquí!',
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 15,
                  color: TinaColores.marron,
                ),
              ),
            )
          else
            TinaRejilla(
              anchoMinimo: 340,
              children: [
                for (final p in pedidos)
                  TinaTarjetaPedido(
                    key: ValueKey('mi-pedido-${p.pedido.codigo}'),
                    codigo: p.pedido.codigo,
                    fecha: formatoFecha(p.pedido.fecha),
                    productos: p.resumenProductos,
                    total: formatoPesos(p.pedido.total),
                    estado: p.pedido.estadoActual,
                    onTap: () => onPedido(p.pedido.idPedido),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TinaBoton(
                etiqueta: 'Cerrar sesión',
                variante: VarianteBoton.secundario,
                onPressed: onCerrarSesion,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
