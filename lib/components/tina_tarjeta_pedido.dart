import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/tina_tema.dart';
import 'tina_hover.dart';
import 'tina_estado_pedido.dart';

/// Resumen de un pedido para listas: código, fecha, productos, total y estado.
/// Si recibe [onCambiarEstado] muestra además un menú para cambiar el estado
/// (lo usa la vendedora en el panel).
class TinaTarjetaPedido extends StatelessWidget {
  const TinaTarjetaPedido({
    super.key,
    required this.codigo,
    required this.fecha,
    required this.productos,
    required this.total,
    required this.estado,
    required this.onTap,
    this.clienta,
    this.onCambiarEstado,
  });

  final String codigo;
  final String fecha;
  final String? clienta;
  final String productos;
  final String total;
  final EstadoPedido estado;
  final VoidCallback onTap;
  final ValueChanged<EstadoPedido>? onCambiarEstado;

  @override
  Widget build(BuildContext context) {
    return TinaHover(
      builder: (context, encima) => TinaLevante(
        encima: encima,
        dy: -2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: encima ? TinaColores.cremaSuave : TinaColores.cremaCampo,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: encima ? TinaColores.naranja : TinaColores.dorado,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      codigo,
                      style: TinaTipografia.estilo(
                        tamano: 16,
                        peso: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(child: TinaEstadoPedido(estado: estado)),
                  ],
                ),
                Text(
                  clienta == null ? fecha : '$fecha · $clienta',
                  style: TinaTipografia.estilo(
                    tamano: 13,
                    color: TinaColores.marron,
                  ),
                ),
                Text(
                  productos,
                  style: TinaTipografia.estilo(tamano: 14, altura: 1.3),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      total,
                      style: TinaTipografia.estilo(
                        tamano: 18,
                        peso: FontWeight.w800,
                        color: TinaColores.naranja,
                      ),
                    ),
                    if (onCambiarEstado != null) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: _MenuEstado(
                            llave: ValueKey('estado-$codigo'),
                            estado: estado,
                            onChanged: onCambiarEstado!,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuEstado extends StatelessWidget {
  const _MenuEstado({
    required this.llave,
    required this.estado,
    required this.onChanged,
  });

  final Key llave;
  final EstadoPedido estado;
  final ValueChanged<EstadoPedido> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: TinaColores.crema,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TinaColores.dorado, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EstadoPedido>(
          key: llave,
          value: estado,
          isDense: true,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: TinaColores.cremaCampo,
          icon: const Icon(Icons.expand_more_rounded, color: TinaColores.tinta),
          style: TinaTipografia.estilo(tamano: 14, peso: FontWeight.w800),
          items: [
            for (final e in EstadoPedido.values)
              DropdownMenuItem(
                value: e,
                child: Text(
                  e.etiqueta,
                  style: TinaTipografia.estilo(
                    tamano: 14,
                    peso: FontWeight.w800,
                  ),
                ),
              ),
          ],
          onChanged: (nuevo) {
            if (nuevo != null && nuevo != estado) onChanged(nuevo);
          },
        ),
      ),
    );
  }
}
