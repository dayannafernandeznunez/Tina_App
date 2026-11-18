import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/calculos.dart';
import '../logic/validaciones.dart';
import '../models/models.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

enum ModoCompra { cuenta, invitada }

/// Finalizar compra: cómo compra, datos de envío y resumen. Los valores de los
/// campos los guarda la Screen.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({
    super.key,
    required this.resumen,
    required this.promociones,
    required this.modo,
    required this.haySesion,
    required this.valores,
    required this.mostrarErrores,
    required this.metodo,
    required this.puedeContraentrega,
    this.ocupado = false,
    required this.onMetodo,
    required this.onModo,
    required this.onCampo,
    required this.onPagar,
    required this.onAtras,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
  });

  final ResumenCarrito resumen;
  final List<Promocion> promociones;
  final ModoCompra modo;
  final bool haySesion;
  final Map<String, String> valores;
  final bool mostrarErrores;

  /// Cómo paga: en línea (Wompi) o contraentrega.
  final MetodoPago metodo;

  /// Si el envío es a Cali, Valle del Cauca, y por eso hay contraentrega.
  final bool puedeContraentrega;

  /// Se está creando el pedido: el botón no se puede volver a tocar.
  final bool ocupado;
  final ValueChanged<MetodoPago> onMetodo;
  final ValueChanged<ModoCompra> onModo;
  final void Function(String clave, String valor) onCampo;
  final VoidCallback onPagar;
  final VoidCallback onAtras;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;

  Widget _campo({
    required String clave,
    required String etiqueta,
    String placeholder = '',
    TipoCampo tipo = TipoCampo.texto,
  }) {
    final valor = valores[clave] ?? '';
    return TinaCampo(
      key: ValueKey('campo-$clave'),
      etiqueta: etiqueta,
      placeholder: placeholder,
      tipo: tipo,
      valor: valor,
      onChanged: (v) => onCampo(clave, v),
      textoError: mostrarErrores ? Validaciones.envio(clave, valor) : null,
    );
  }

  Widget _titulo(String texto) => Text(
    texto,
    style: TinaTipografia.estilo(
      tamano: 20,
      peso: FontWeight.w800,
      espaciado: -0.4,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final primera = promociones.firstWhere((p) => p.tipo == 'primera_compra');
    final volumen = promociones.firstWhere((p) => p.tipo == 'volumen');
    final conCuenta = modo == ModoCompra.cuenta && haySesion;

    return TinaScaffold(
      titulo: 'Finalizar compra',
      conAtras: true,
      unidadesCarrito: resumen.unidades,
      onAtras: onAtras,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      accion: TinaBoton(
        key: const ValueKey('boton-pagar'),
        etiqueta: ocupado
            ? 'Un momento…'
            : metodo == MetodoPago.contraentrega
            ? 'Confirmar pedido · ${formatoPesos(resumen.totalConEnvio)}'
            : 'Pagar con Wompi · ${formatoPesos(resumen.totalConEnvio)}',
        onPressed: ocupado ? () {} : onPagar,
      ),
      cuerpo: TinaLista(
        children: [
          TinaDosColumnas(
            flexIzquierda: 11,
            flexDerecha: 9,
            tarjetaDerecha: true,
            izquierda: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _titulo('¿Cómo quieres comprar?'),
                const SizedBox(height: 12),
                TinaOpcionCompra(
                  key: const ValueKey('opcion-cuenta'),
                  titulo: haySesion
                      ? 'Comprar con mi cuenta'
                      : 'Iniciar sesión / Crear cuenta',
                  subtitulo: haySesion
                      ? 'Sesión iniciada. Compras con tu cuenta.'
                      : 'Te llevamos a iniciar sesión o crear tu cuenta.',
                  seleccionada: conCuenta,
                  onTap: () => onModo(ModoCompra.cuenta),
                  extra: TinaEtiquetaDescuento(texto: primera.nombre),
                ),
                const SizedBox(height: 12),
                TinaOpcionCompra(
                  key: const ValueKey('opcion-invitada'),
                  titulo: 'Comprar como invitada',
                  subtitulo:
                      'Sin crear cuenta. No aplica el ${primera.porcentaje}%.',
                  seleccionada: !conCuenta,
                  onTap: () => onModo(ModoCompra.invitada),
                ),
                const SizedBox(height: 26),
                _titulo('Datos de envío'),
                const SizedBox(height: 12),
                Column(
                  spacing: 14,
                  children: [
                    _campo(
                      clave: 'nombre',
                      etiqueta: 'Nombre completo',
                      placeholder: 'Como aparece en tu cédula',
                    ),
                    _campo(
                      clave: 'telefono',
                      etiqueta: 'Celular (WhatsApp)',
                      placeholder: '300 000 0000',
                      tipo: TipoCampo.telefono,
                    ),
                    _campo(
                      clave: 'correo',
                      etiqueta: 'Correo',
                      placeholder: 'tu@correo.com',
                      tipo: TipoCampo.correo,
                    ),
                    _campo(
                      clave: 'direccion',
                      etiqueta: 'Dirección',
                      placeholder: 'Calle, número, barrio',
                    ),
                    _campo(
                      clave: 'ciudad',
                      etiqueta: 'Ciudad',
                      placeholder: 'Cali',
                    ),
                    _campo(
                      clave: 'departamento',
                      etiqueta: 'Departamento',
                      placeholder: 'Valle del Cauca',
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _titulo('¿Cómo pagas?'),
                const SizedBox(height: 12),
                TinaOpcionCompra(
                  key: const ValueKey('opcion-wompi'),
                  titulo: 'Pagar en línea',
                  subtitulo:
                      'Con tarjeta, PSE o Nequi, en la página segura de Wompi.',
                  seleccionada: metodo == MetodoPago.wompi,
                  onTap: () => onMetodo(MetodoPago.wompi),
                ),
                if (puedeContraentrega) ...[
                  const SizedBox(height: 12),
                  TinaOpcionCompra(
                    key: const ValueKey('opcion-contraentrega'),
                    titulo: 'Contraentrega en Cali',
                    subtitulo:
                        'Te escribimos por WhatsApp para coordinar la entrega. '
                        'Pagas por transferencia y no se cobra envío.',
                    seleccionada: metodo == MetodoPago.contraentrega,
                    onTap: () => onMetodo(MetodoPago.contraentrega),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Text(
                    'La contraentrega está disponible solo en Cali, Valle del Cauca.',
                    key: const ValueKey('nota-contraentrega'),
                    style: TinaTipografia.estilo(
                      tamano: 12,
                      color: TinaColores.marron,
                    ),
                  ),
                ],
              ],
            ),
            derecha: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _titulo('Resumen del pedido'),
                const SizedBox(height: 4),
                for (final l in resumen.lineas)
                  TinaFilaResumen(
                    etiqueta: '${l.producto.nombre} ×${l.item.cantidad}',
                    detalle: l.variante.talla == 'Única'
                        ? l.variante.color
                        : '${l.variante.color} · Talla ${l.variante.talla}',
                    valor: formatoPesos(l.total),
                  ),
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
                  key: const ValueKey('fila-envio'),
                  etiqueta: 'Envío',
                  valor: resumen.costoEnvio == 0
                      ? 'Gratis'
                      : formatoPesos(resumen.costoEnvio),
                ),
                TinaFilaResumen(
                  etiqueta: 'Total',
                  valor: formatoPesos(resumen.totalConEnvio),
                  tipo: TipoFila.total,
                ),
                const SizedBox(height: 14),
                Text(
                  metodo == MetodoPago.contraentrega
                      ? 'Al confirmar, te escribimos por WhatsApp para coordinar la entrega y el pago por transferencia.'
                      : 'Al pagar, te llevamos a Wompi para completar el pago de forma segura.',
                  style: TinaTipografia.estilo(
                    tamano: 13,
                    color: TinaColores.marron,
                    altura: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
