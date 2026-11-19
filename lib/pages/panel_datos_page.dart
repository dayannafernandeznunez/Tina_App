import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/metricas.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

/// Panel de la vendedora, sección "Datos cliente": los números de los pedidos
/// para tomar decisiones. No calcula ni guarda nada: muestra lo que le da
/// [Metricas].
class PanelDatosPage extends StatelessWidget {
  const PanelDatosPage({
    super.key,
    required this.metricas,
    required this.onSeccion,
    required this.onVerTienda,
    this.onSalir,
  });

  final Metricas metricas;
  final ValueChanged<SeccionPanel> onSeccion;
  final VoidCallback onVerTienda;
  final VoidCallback? onSalir;

  static String _dias(double? d) {
    if (d == null) return 'Sin datos todavía';
    if (d < 1) return 'Menos de 1 día';
    final n = d.round();
    return n == 1 ? '1 día' : '$n días';
  }

  static String _porcentaje(double v) => '${(v * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final m = metricas;
    final sinPedidos = m.totalPedidos == 0;

    return TinaScaffold(
      titulo: 'Panel de vendedora',
      conAtras: true,
      conCarrito: false,
      onAtras: onVerTienda,
      onLogo: onVerTienda,
      cuerpo: TinaLista(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Datos cliente',
                style: TinaTipografia.estilo(
                  tamano: 28,
                  peso: FontWeight.w800,
                  espaciado: -0.84,
                ),
              ),
              Text(
                '${m.pedidosValidos} pedidos válidos de ${m.totalPedidos}',
                key: const ValueKey('datos-resumen'),
                style: TinaTipografia.estilo(
                  tamano: 14,
                  color: TinaColores.marron,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TinaPanelSecciones(activa: SeccionPanel.datos, onSeccion: onSeccion),
          const SizedBox(height: 8),
          Text(
            'No cuentan los pedidos cancelados. Un pedido es una recompra si '
            'esa clienta ya tenía otro pedido antes.',
            style: TinaTipografia.estilo(
              tamano: 12,
              color: TinaColores.marron,
              altura: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          if (sinPedidos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'Todavía no hay pedidos. Cuando lleguen, aquí vas a ver qué se '
                'vende, qué se vuelve a comprar y cada cuánto.',
                key: const ValueKey('datos-vacio'),
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 15,
                  color: TinaColores.marron,
                ),
              ),
            )
          else ...[
            TinaRejilla(
              anchoMinimo: 150,
              children: [
                _Dato(
                  llave: 'dato-pedidos',
                  etiqueta: 'Pedidos',
                  valor: '${m.totalPedidos}',
                ),
                _Dato(
                  llave: 'dato-total-vendido',
                  etiqueta: 'Total vendido',
                  valor: formatoPesos(m.totalVendido),
                ),
                _Dato(
                  llave: 'dato-cobrado',
                  etiqueta: 'Ya cobrado',
                  valor: formatoPesos(m.cobrado),
                ),
                _Dato(
                  llave: 'dato-por-cobrar',
                  etiqueta: 'Por cobrar',
                  valor: formatoPesos(m.porCobrar),
                ),
                _Dato(
                  llave: 'dato-descuentos',
                  etiqueta: 'Descuentos dados',
                  valor: formatoPesos(m.totalDescuentos),
                ),
                _Dato(
                  llave: 'dato-ticket',
                  etiqueta: 'Compra promedio',
                  valor: formatoPesos(m.ticketPromedio),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Seccion(
              titulo: 'Estado actual de los pedidos',
              hijo: _Barras(
                llave: 'estados',
                filas: [
                  for (final e in EstadoPedido.values)
                    _Barra(
                      e.etiqueta,
                      m.pedidosPorEstado[e] ?? 0,
                      '${m.pedidosPorEstado[e] ?? 0}',
                    ),
                ],
              ),
            ),
            _Seccion(
              titulo: 'Balance general de las ventas',
              hijo: Column(
                key: const ValueKey('balance'),
                children: [
                  TinaFilaResumen(
                    etiqueta: 'Productos vendidos',
                    valor: formatoPesos(m.ventasProductos),
                  ),
                  TinaFilaResumen(
                    etiqueta: 'Descuentos',
                    detalle:
                        '${m.pedidosConDescuento} '
                        '${m.pedidosConDescuento == 1 ? 'pedido' : 'pedidos'}',
                    valor: '-${formatoPesos(m.totalDescuentos)}',
                    tipo: TipoFila.descuento,
                  ),
                  TinaFilaResumen(
                    etiqueta: 'Envíos',
                    valor: formatoPesos(m.totalEnvios),
                  ),
                  TinaFilaResumen(
                    etiqueta: 'Total vendido',
                    valor: formatoPesos(m.totalVendido),
                    tipo: TipoFila.total,
                  ),
                  const SizedBox(height: 6),
                  TinaFilaResumen(
                    etiqueta: 'Ya cobrado',
                    detalle: 'Pagado, en preparación, enviado o entregado',
                    valor: formatoPesos(m.cobrado),
                  ),
                  TinaFilaResumen(
                    etiqueta: 'Por cobrar',
                    detalle: 'Pedidos pendientes de pago',
                    valor: formatoPesos(m.porCobrar),
                  ),
                  TinaFilaResumen(
                    etiqueta: 'Cancelado',
                    detalle: 'No suma al total',
                    valor: formatoPesos(m.cancelado),
                  ),
                ],
              ),
            ),
            _Seccion(
              titulo: 'Producto más vendido',
              vacio: 'Todavía no hay ventas.',
              hijo: _Barras(
                llave: 'mas-vendidos',
                filas: [
                  for (final f in m.productosMasVendidos)
                    _Barra(
                      f.nombre,
                      f.valor,
                      '${f.valor} uds · ${formatoPesos(f.extra)}',
                    ),
                ],
              ),
            ),
            _Seccion(
              titulo: 'Producto más recomprado',
              nota:
                  'Cuántas veces una misma clienta volvió a pedirlo en otro '
                  'pedido.',
              vacio: 'Todavía nadie ha recomprado un producto.',
              hijo: _Barras(
                llave: 'mas-recomprados',
                filas: [
                  for (final f in m.productosMasRecomprados)
                    _Barra(
                      f.nombre,
                      f.valor,
                      '${f.valor} ${f.valor == 1 ? 'recompra' : 'recompras'}'
                      ' · ${f.extra} ${f.extra == 1 ? 'clienta' : 'clientas'}',
                    ),
                ],
              ),
            ),
            _Seccion(
              titulo: 'Colores más vendidos',
              vacio: 'Todavía no hay ventas.',
              hijo: _Barras(
                llave: 'colores',
                filas: [
                  for (final f in m.coloresMasVendidos)
                    _Barra(f.nombre, f.valor, '${f.valor} uds'),
                ],
              ),
            ),
            _Seccion(
              titulo: 'Recompra de las clientas',
              hijo: Column(
                key: const ValueKey('recompra'),
                children: [
                  TinaFilaResumen(etiqueta: 'Clientas', valor: '${m.clientas}'),
                  TinaFilaResumen(
                    etiqueta: 'Volvieron a comprar',
                    detalle: _porcentaje(m.tasaRecompra),
                    valor: '${m.clientasRecurrentes}',
                  ),
                  TinaFilaResumen(
                    etiqueta: 'Tiempo promedio de recompra',
                    detalle: 'Entre un pedido y el siguiente',
                    valor: _dias(m.diasPromedioRecompra),
                  ),
                  TinaFilaResumen(
                    etiqueta: 'Tiempo típico (mediana)',
                    valor: _dias(m.diasMedianaRecompra),
                  ),
                ],
              ),
            ),
            _Seccion(
              titulo: 'Ciudades con mayor recompra',
              vacio: 'Todavía no hay recompras.',
              hijo: _Barras(
                llave: 'ciudades',
                filas: [
                  for (final f in m.ciudades)
                    _Barra(
                      f.nombre,
                      f.valor,
                      '${f.valor} ${f.valor == 1 ? 'recompra' : 'recompras'}'
                      ' de ${f.extra} ${f.extra == 1 ? 'pedido' : 'pedidos'}',
                    ),
                ],
              ),
            ),
            _Seccion(
              titulo: 'Cómo pagan',
              hijo: _Barras(
                llave: 'metodos',
                filas: [
                  for (final e in m.pedidosPorMetodo.entries)
                    _Barra(e.key.etiqueta, e.value, '${e.value}'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                spacing: 12,
                children: [
                  TinaBoton(
                    etiqueta: 'Ver tienda',
                    variante: VarianteBoton.secundario,
                    onPressed: onVerTienda,
                  ),
                  if (onSalir != null)
                    TinaBoton(
                      etiqueta: 'Cerrar sesión',
                      variante: VarianteBoton.secundario,
                      onPressed: onSalir!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un número grande con su nombre.
class _Dato extends StatelessWidget {
  const _Dato({
    required this.llave,
    required this.etiqueta,
    required this.valor,
  });

  final String llave;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(llave),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: TinaColores.cremaCampo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TinaColores.dorado, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            etiqueta,
            style: TinaTipografia.estilo(
              tamano: 13,
              peso: FontWeight.w800,
              color: TinaColores.marron,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TinaTipografia.estilo(
                tamano: 26,
                peso: FontWeight.w800,
                espaciado: -0.6,
                color: TinaColores.naranja,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un bloque con título; si no tiene filas muestra [vacio].
class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.hijo,
    this.nota,
    this.vacio,
  });

  final String titulo;
  final String? nota;
  final String? vacio;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    final h = hijo;
    final sinFilas = h is _Barras && h.filas.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TinaTipografia.estilo(
              tamano: 20,
              peso: FontWeight.w800,
              espaciado: -0.4,
            ),
          ),
          if (nota != null) ...[
            const SizedBox(height: 2),
            Text(
              nota!,
              style: TinaTipografia.estilo(
                tamano: 12,
                color: TinaColores.marron,
                altura: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (sinFilas)
            Text(
              vacio ?? 'Sin datos todavía.',
              style: TinaTipografia.estilo(
                tamano: 14,
                color: TinaColores.marron,
              ),
            )
          else
            h,
        ],
      ),
    );
  }
}

class _Barra {
  const _Barra(this.nombre, this.valor, this.texto);

  final String nombre;
  final int valor;
  final String texto;
}

/// Filas con una barra proporcional al valor más grande.
class _Barras extends StatelessWidget {
  const _Barras({required this.llave, required this.filas});

  final String llave;
  final List<_Barra> filas;

  @override
  Widget build(BuildContext context) {
    final mayor = filas.fold(0, (m, f) => f.valor > m ? f.valor : m);
    return Column(
      key: ValueKey('barras-$llave'),
      spacing: 10,
      children: [
        for (final f in filas)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      f.nombre,
                      style: TinaTipografia.estilo(
                        tamano: 14,
                        peso: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    f.texto,
                    textAlign: TextAlign.end,
                    style: TinaTipografia.estilo(
                      tamano: 13,
                      color: TinaColores.marron,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: mayor == 0 ? 0 : f.valor / mayor,
                  minHeight: 8,
                  backgroundColor: TinaColores.cremaSuave,
                  color: TinaColores.naranja,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
