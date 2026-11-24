import 'package:flutter/material.dart';

import '../config/tienda_config.dart';
import '../theme/tina_tema.dart';
import '../utils/abrir_url.dart';
import 'tina_hover.dart';
import 'tina_logo.dart';

/// Pie de página de la tienda: quiénes somos, a dónde ir, cómo funcionan los
/// envíos y los pagos, y las redes (solo las que estén en [TiendaConfig]).
class TinaPiePagina extends StatelessWidget {
  const TinaPiePagina({
    super.key,
    required this.categorias,
    required this.onCategoria,
    required this.onLogo,
  });

  final List<String> categorias;

  /// `null` significa "Todos".
  final ValueChanged<String?> onCategoria;
  final VoidCallback onLogo;

  static const List<String> _medios = [
    'Tarjeta de crédito',
    'Tarjeta débito',
    'PSE',
    'Nequi',
    'Transferencia',
  ];

  @override
  Widget build(BuildContext context) {
    final redes = <(String, String)>[
      if (TiendaConfig.instagram.isNotEmpty)
        ('Instagram', 'https://www.instagram.com/${TiendaConfig.instagram}/'),
      if (TiendaConfig.tiktok.isNotEmpty)
        ('TikTok', 'https://www.tiktok.com/@${TiendaConfig.tiktok}'),
      if (TiendaConfig.facebook.isNotEmpty) ('Facebook', TiendaConfig.facebook),
      if (TiendaConfig.whatsapp.isNotEmpty)
        (
          'WhatsApp',
          'https://wa.me/${TiendaConfig.whatsapp}'
              '?text=${Uri.encodeComponent(TiendaConfig.mensajeWhatsapp)}',
        ),
    ];

    final columnas = <Widget>[
      _Columna(
        titulo: 'Tina',
        hijos: [
          Text(
            'Accesorios hechos a mano, uno por uno. Tan latinas como tú.',
            style: TinaTipografia.estilo(
              tamano: 14,
              color: TinaColores.marron,
              altura: 1.4,
            ),
          ),
        ],
      ),
      _Columna(
        titulo: 'Comprar',
        hijos: [
          _Enlace(
            key: const ValueKey('pie-todos'),
            texto: 'Todos los accesorios',
            onTap: () => onCategoria(null),
          ),
          for (final c in categorias)
            _Enlace(
              key: ValueKey('pie-$c'),
              texto: c,
              onTap: () => onCategoria(c),
            ),
        ],
      ),
      _Columna(
        titulo: 'Envíos y pagos',
        hijos: [
          for (final t in const [
            'Envío de \$5.000 a todo el país.',
            'Contraentrega en Cali, sin costo de envío.',
            'Pagos seguros con Wompi.',
          ])
            Text(
              t,
              style: TinaTipografia.estilo(
                tamano: 14,
                color: TinaColores.marron,
                altura: 1.4,
              ),
            ),
        ],
      ),
      if (redes.isNotEmpty)
        _Columna(
          titulo: 'Escríbenos y síguenos',
          hijos: [
            for (final (nombre, url) in redes)
              _Enlace(
                key: ValueKey('pie-red-$nombre'),
                texto: nombre,
                onTap: () => abrirEnPestanaNueva(url),
              ),
          ],
        ),
    ];

    return Container(
      key: const ValueKey('pie-pagina'),
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
      decoration: BoxDecoration(
        color: TinaColores.blanco.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 22,
        children: [
          TinaLogo(onTap: onLogo, tamano: 34),
          LayoutBuilder(
            builder: (context, restricciones) {
              final porFila = restricciones.maxWidth < 560
                  ? 1
                  : restricciones.maxWidth < 860
                  ? 2
                  : columnas.length;
              final ancho =
                  (restricciones.maxWidth - 28 * (porFila - 1)) / porFila;
              return Wrap(
                spacing: 28,
                runSpacing: 24,
                children: [
                  for (final c in columnas) SizedBox(width: ancho, child: c),
                ],
              );
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _medios)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: TinaColores.campo,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    m,
                    style: TinaTipografia.estilo(
                      tamano: 12,
                      peso: FontWeight.w800,
                      color: TinaColores.marron,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            '© ${DateTime.now().year} Tina. Hecho a mano en Colombia.',
            style: TinaTipografia.estilo(tamano: 12, color: TinaColores.marron),
          ),
        ],
      ),
    );
  }
}

class _Columna extends StatelessWidget {
  const _Columna({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          titulo.toUpperCase(),
          style: TinaTipografia.estilo(
            tamano: 13,
            peso: FontWeight.w800,
            espaciado: 0.6,
          ),
        ),
        ...hijos,
      ],
    );
  }
}

class _Enlace extends StatelessWidget {
  const _Enlace({super.key, required this.texto, required this.onTap});

  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: texto,
      excludeSemantics: true,
      onTap: onTap,
      child: TinaHover(
        builder: (context, encima) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Text(
            texto,
            style: TinaTipografia.estilo(
              tamano: 14,
              peso: FontWeight.w700,
              color: encima ? TinaColores.naranja : TinaColores.tinta,
            ),
          ),
        ),
      ),
    );
  }
}
