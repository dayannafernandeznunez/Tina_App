import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/calculos.dart';
import '../models/models.dart';
import '../theme/colores_producto.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

/// Carrito: líneas editables, descuentos y total.
class CarritoPage extends StatelessWidget {
  const CarritoPage({
    super.key,
    required this.resumen,
    required this.promociones,
    required this.nota,
    required this.conCuenta,
    required this.onCantidad,
    required this.onQuitar,
    required this.onContinuar,
    required this.onVerAccesorios,
    required this.onAtras,
    required this.onLogo,
    required this.onNav,
  });

  final ResumenCarrito resumen;
  final List<Promocion> promociones;
  final String nota;
  final bool conCuenta;

  /// (idItem, nueva cantidad)
  final void Function(int idItem, int cantidad) onCantidad;
  final ValueChanged<int> onQuitar;
  final VoidCallback onContinuar;
  final VoidCallback onVerAccesorios;
  final VoidCallback onAtras;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;

  @override
  Widget build(BuildContext context) {
    final volumen = promociones.firstWhere((p) => p.tipo == 'volumen');
    final primera = promociones.firstWhere((p) => p.tipo == 'primera_compra');
    final llegoAVolumen = resumen.unidades >= volumen.cantidadMinima;

    return TinaScaffold(
      titulo: 'Tu carrito',
      conAtras: true,
      activo: DestinoNav.carrito,
      unidadesCarrito: resumen.unidades,
      onAtras: onAtras,
      onCarrito: () {},
      onLogo: onLogo,
      onNav: onNav,
      accion: resumen.vacio
          ? null
          : TinaBoton(etiqueta: 'Continuar', onPressed: onContinuar),
      cuerpo: resumen.vacio
          ? _Vacio(onVerAccesorios: onVerAccesorios)
          : TinaLista(
              arriba: 18,
              children: [
                TinaDosColumnas(
                  tarjetaDerecha: true,
                  izquierda: Column(
                    spacing: 12,
                    children: [
                      for (final linea in resumen.lineas)
                        TinaItemCarrito(
                          key: ValueKey('item-${linea.item.idItem}'),
                          nombre: linea.producto.nombre,
                          variante: linea.variante.talla == 'Única'
                              ? linea.variante.color
                              : '${linea.variante.color} · Talla ${linea.variante.talla}',
                          color: colorDeProducto(linea.variante.color),
                          cantidad: linea.item.cantidad,
                          maximo: linea.variante.stock,
                          total: formatoPesos(linea.total),
                          onCantidad: (n) => onCantidad(linea.item.idItem, n),
                          onQuitar: () => onQuitar(linea.item.idItem),
                        ),
                    ],
                  ),
                  derecha: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (llegoAVolumen)
                              TinaEtiquetaDescuento(texto: volumen.nombre)
                            else ...[
                              TinaEtiquetaDescuento(
                                texto: primera.nombre,
                                tono: conCuenta
                                    ? TonoEtiqueta.fuerte
                                    : TonoEtiqueta.suave,
                              ),
                              TinaEtiquetaDescuento(
                                texto: volumen.nombre,
                                tono: TonoEtiqueta.suave,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nota,
                        key: const ValueKey('nota-descuento'),
                        style: TinaTipografia.estilo(
                          tamano: 13,
                          color: TinaColores.marron,
                          altura: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TinaFilaResumen(
                        etiqueta: 'Subtotal',
                        valor: formatoPesos(resumen.subtotal),
                      ),
                      if (resumen.porcentaje > 0)
                        TinaFilaResumen(
                          etiqueta:
                              'Descuento ${resumen.porcentaje}% (${resumen.promocion?.tipo == 'volumen' ? '${volumen.cantidadMinima}+ unidades' : 'primera compra con cuenta'})',
                          valor: '−${formatoPesos(resumen.descuento)}',
                          tipo: TipoFila.descuento,
                        ),
                      TinaFilaResumen(
                        etiqueta: 'Total',
                        valor: formatoPesos(resumen.total),
                        tipo: TipoFila.total,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.onVerAccesorios});

  final VoidCallback onVerAccesorios;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              const EstrellaTina(tamano: 44, color: TinaColores.naranja),
              Text(
                'Tu carrito está vacío',
                textAlign: TextAlign.center,
                style: TinaTipografia.serif(
                  tamano: 30,
                  color: TinaColores.rojo,
                ),
              ),
              Text(
                'Agrega algo hecho a mano y aparecerá aquí.',
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 15,
                  color: TinaColores.marron,
                ),
              ),
              const SizedBox(height: 8),
              TinaBoton(etiqueta: 'Ver accesorios', onPressed: onVerAccesorios),
            ],
          ),
        ),
      ),
    );
  }
}
