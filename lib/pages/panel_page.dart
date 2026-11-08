import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/vistas.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';
import '../utils/adaptable.dart';
import '../utils/formato.dart';

/// Panel de la vendedora: todos los pedidos, filtro por estado y cambio de
/// estado. No guarda nada: la Screen decide qué pedidos se muestran.
class PanelPage extends StatelessWidget {
  const PanelPage({
    super.key,
    required this.pedidos,
    required this.totalPedidos,
    required this.conteoPorEstado,
    required this.filtro,
    required this.onFiltro,
    required this.onCambiarEstado,
    required this.onPedido,
    required this.onVerTienda,
  });

  /// Pedidos ya filtrados.
  final List<PedidoCompleto> pedidos;
  final int totalPedidos;
  final Map<EstadoPedido, int> conteoPorEstado;
  final EstadoPedido? filtro;
  final ValueChanged<EstadoPedido?> onFiltro;
  final void Function(int idPedido, EstadoPedido nuevo) onCambiarEstado;
  final ValueChanged<int> onPedido;
  final VoidCallback onVerTienda;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      TinaChip(
        key: const ValueKey('filtro-todos'),
        etiqueta: 'Todos',
        conteo: totalPedidos,
        activo: filtro == null,
        onTap: () => onFiltro(null),
      ),
      for (final e in EstadoPedido.values)
        TinaChip(
          key: ValueKey('filtro-${e.name}'),
          etiqueta: e.etiqueta,
          conteo: conteoPorEstado[e] ?? 0,
          activo: filtro == e,
          onTap: () => onFiltro(e),
        ),
    ];

    return TinaScaffold(
      titulo: 'Panel de vendedora',
      conAtras: true,
      conCarrito: false,
      onAtras: onVerTienda,
      onLogo: onVerTienda,
      cuerpo: TinaLista(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Pedidos',
                style: TinaTipografia.estilo(
                  tamano: 28,
                  peso: FontWeight.w800,
                  espaciado: -0.84,
                ),
              ),
              Text(
                '$totalPedidos pedidos',
                key: const ValueKey('panel-total'),
                style: TinaTipografia.estilo(
                  tamano: 14,
                  color: TinaColores.marron,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (esEscritorio(context))
            Wrap(spacing: 8, runSpacing: 8, children: chips)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(spacing: 8, children: chips),
            ),
          const SizedBox(height: 16),
          if (pedidos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No hay pedidos con este estado.',
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 15,
                  color: TinaColores.marron,
                ),
              ),
            )
          else
            TinaRejilla(
              anchoMinimo: 460,
              children: [
                for (final p in pedidos)
                  TinaTarjetaPedido(
                    key: ValueKey('pedido-${p.pedido.codigo}'),
                    codigo: p.pedido.codigo,
                    fecha: formatoFecha(p.pedido.fecha),
                    clienta: p.cliente.nombre,
                    productos: p.resumenProductos,
                    total: formatoPesos(p.pedido.total),
                    estado: p.pedido.estadoActual,
                    onTap: () => onPedido(p.pedido.idPedido),
                    onCambiarEstado: (nuevo) =>
                        onCambiarEstado(p.pedido.idPedido, nuevo),
                  ),
              ],
            ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TinaBoton(
                etiqueta: 'Ver tienda',
                variante: VarianteBoton.secundario,
                onPressed: onVerTienda,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
