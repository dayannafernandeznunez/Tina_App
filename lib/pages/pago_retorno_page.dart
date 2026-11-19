import 'package:flutter/material.dart';

import '../components/components.dart';
import '../data/pedidos.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

/// A dónde llega la clienta cuando vuelve de la página de pago de Wompi y su
/// pago todavía no está aprobado: confirmando, rechazado, cancelado o sin
/// conexión. Cuando el pago sí se aprobó se muestra la confirmación de siempre.
class PagoRetornoPage extends StatelessWidget {
  const PagoRetornoPage({
    super.key,
    required this.estado,
    required this.verificando,
    required this.sinConexion,
    required this.unidadesCarrito,
    required this.onReintentarPago,
    required this.onRevisar,
    required this.onSeguir,
    required this.onLogo,
    required this.onCarrito,
    required this.onNav,
    this.reintentando = false,
  });

  /// Lo último que dijo la base de datos; `null` si aún no ha respondido.
  final EstadoPagoPedido? estado;

  /// Se está consultando el estado del pago.
  final bool verificando;

  /// No se pudo consultar (sin internet o pedido que no existe).
  final bool sinConexion;

  /// Se está abriendo otra vez la página de pago.
  final bool reintentando;

  final int unidadesCarrito;
  final VoidCallback onReintentarPago;
  final VoidCallback onRevisar;
  final VoidCallback onSeguir;
  final VoidCallback onLogo;
  final VoidCallback onCarrito;
  final ValueChanged<DestinoNav> onNav;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    final String titulo;
    final String subtitulo;
    final String mensaje;
    Widget? accion;

    final sinRespuesta = e == null && sinConexion;
    final confirmando =
        !sinRespuesta && (e == null || (e.esperando && verificando));

    if (sinRespuesta) {
      titulo = 'No pudimos';
      subtitulo = 'revisar tu pago';
      mensaje =
          'Revisa tu internet. Si ya pagaste, no te preocupes: tu pedido '
          'queda registrado y la vendedora te escribirá.';
      accion = _acciones([
        TinaBoton(etiqueta: 'Revisar otra vez', onPressed: onRevisar),
        TinaBoton(
          etiqueta: 'Ir al inicio',
          variante: VarianteBoton.secundario,
          onPressed: onSeguir,
        ),
      ]);
    } else if (confirmando) {
      titulo = 'Confirmando';
      subtitulo = 'tu pago…';
      mensaje =
          'Estamos esperando la respuesta de Wompi. No cierres esta página.';
    } else if (e!.esperando) {
      titulo = 'Tu pago está';
      subtitulo = 'en revisión';
      mensaje =
          'Wompi todavía no nos confirma el pago. Si pagaste, llegará en unos '
          'minutos y tu pedido pasará a "Pagado".';
      accion = _acciones([
        TinaBoton(etiqueta: 'Revisar otra vez', onPressed: onRevisar),
        TinaBoton(
          etiqueta: 'Seguir comprando',
          variante: VarianteBoton.secundario,
          onPressed: onSeguir,
        ),
      ]);
    } else if (e.rechazado) {
      titulo = 'No se pudo';
      subtitulo = 'procesar el pago';
      mensaje =
          'Tu banco o tarjeta no aprobó el pago. No se cobró nada. Tu pedido '
          'sigue guardado: puedes intentar de nuevo o con otro medio.';
      accion = _acciones([
        TinaBoton(
          etiqueta: reintentando ? 'Abriendo el pago…' : 'Intentar de nuevo',
          onPressed: reintentando ? () {} : onReintentarPago,
        ),
        TinaBoton(
          etiqueta: 'Seguir comprando',
          variante: VarianteBoton.secundario,
          onPressed: onSeguir,
        ),
      ]);
    } else if (e.pagoEnPedidoCancelado) {
      titulo = 'Recibimos tu pago,';
      subtitulo = 'pero…';
      mensaje =
          'Tu pedido ya había sido cancelado cuando llegó el pago. La '
          'vendedora te escribirá para devolverte el dinero.';
      accion = _acciones([
        TinaBoton(etiqueta: 'Ir al inicio', onPressed: onSeguir),
      ]);
    } else {
      titulo = 'Pedido';
      subtitulo = 'cancelado';
      mensaje =
          'Este pedido fue cancelado y no se cobró nada. Puedes hacer uno '
          'nuevo cuando quieras.';
      accion = _acciones([
        TinaBoton(etiqueta: 'Seguir comprando', onPressed: onSeguir),
      ]);
    }

    return TinaScaffold(
      unidadesCarrito: unidadesCarrito,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      accion: accion,
      cuerpo: TinaLista(
        anchoMaximo: 640,
        arriba: 28,
        children: [
          Center(
            child: Column(
              spacing: 6,
              children: [
                const EstrellaTina(tamano: 52, color: TinaColores.naranja),
                const SizedBox(height: 6),
                Text(
                  titulo,
                  key: const Key('titulo-retorno'),
                  textAlign: TextAlign.center,
                  style: TinaTipografia.estilo(
                    tamano: 36,
                    peso: FontWeight.w800,
                    espaciado: -1.1,
                    altura: 0.95,
                  ),
                ),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: TinaTipografia.serif(
                    tamano: 40,
                    color: TinaColores.rojo,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mensaje,
                  key: const Key('mensaje-retorno'),
                  textAlign: TextAlign.center,
                  style: TinaTipografia.estilo(
                    tamano: 15,
                    color: TinaColores.marron,
                    altura: 1.4,
                  ),
                ),
                if (confirmando) ...[
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: TinaColores.naranja,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (e != null) ...[
            const SizedBox(height: 22),
            TinaFilaResumen(etiqueta: 'Número de pedido', valor: e.codigo),
            TinaFilaResumen(
              etiqueta: 'Total',
              valor: formatoPesos(e.total),
              tipo: TipoFila.total,
            ),
          ],
        ],
      ),
    );
  }

  Widget _acciones(List<Widget> botones) =>
      Column(mainAxisSize: MainAxisSize.min, spacing: 8, children: botones);
}
