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
        etiqueta: 'Pagar con Wompi · ${formatoPesos(resumen.total)}',
        onPressed: onPagar,
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
                  etiqueta: 'Total',
                  valor: formatoPesos(resumen.total),
                  tipo: TipoFila.total,
                ),
                const SizedBox(height: 14),
                Text(
                  'Al pagar, te llevamos a Wompi para completar el pago de forma segura.',
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
