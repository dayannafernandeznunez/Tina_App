import 'package:flutter/material.dart';

import '../components/components.dart';
import '../logic/charm_bar.dart';
import '../theme/colores_producto.dart';
import '../theme/tina_tema.dart';
import '../utils/formato.dart';

/// Charm Bar: la clienta arma su collar en cuatro pasos (color, cuántos charms,
/// cómo van puestos y cuáles). No guarda nada: la elección vive en la Screen.
class CharmBarPage extends StatelessWidget {
  const CharmBarPage({
    super.key,
    required this.charmBar,
    required this.armado,
    required this.unidadesCarrito,
    required this.onColor,
    required this.onModo,
    required this.onCantidad,
    required this.onAgregarCharm,
    required this.onQuitarCharm,
    required this.onAgregarAlCarrito,
    required this.onVerTienda,
    required this.onAtras,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
    this.fotoPortada,
    this.enlaces = const EnlacesTienda(),
  });

  final EnlacesTienda enlaces;

  final CharmBar charmBar;
  final ArmadoCollar armado;
  final int unidadesCarrito;

  /// La foto grande de la página, que sube la administradora (puede no haber).
  final String? fotoPortada;
  final ValueChanged<String> onColor;
  final ValueChanged<String> onModo;
  final ValueChanged<int> onCantidad;
  final ValueChanged<int> onAgregarCharm;
  final ValueChanged<int> onQuitarCharm;
  final VoidCallback onAgregarAlCarrito;
  final VoidCallback onVerTienda;
  final VoidCallback onAtras;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;

  @override
  Widget build(BuildContext context) {
    final disponible = charmBar.disponible;
    final precio = armado.precio(charmBar);

    return TinaScaffold(
      titulo: 'Charm Bar',
      conAtras: true,
      conPromo: true,
      enlaces: enlaces,
      activo: DestinoNav.categorias,
      unidadesCarrito: unidadesCarrito,
      onAtras: onAtras,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      accion: !disponible
          ? null
          : TinaBoton(
              key: const ValueKey('armar-agregar'),
              etiqueta: armado.completo
                  ? 'Añadir al carrito · ${formatoPesos(precio)}'
                  : armado.faltan == 1
                  ? 'Elige 1 charm más'
                  : 'Elige ${armado.faltan} charms más',
              onPressed: onAgregarAlCarrito,
            ),
      cuerpo: TinaLista(
        arriba: 18,
        children: [
          _Portada(foto: fotoPortada),
          const SizedBox(height: 28),
          if (!disponible)
            _Pronto(onVerTienda: onVerTienda)
          else
            TinaDosColumnas(
              flexIzquierda: 5,
              flexDerecha: 6,
              izquierda: _Vista(
                charmBar: charmBar,
                armado: armado,
                onQuitarCharm: onQuitarCharm,
              ),
              derecha: _Pasos(
                charmBar: charmBar,
                armado: armado,
                precio: precio,
                onColor: onColor,
                onModo: onModo,
                onCantidad: onCantidad,
                onAgregarCharm: onAgregarCharm,
              ),
            ),
        ],
      ),
    );
  }
}

/// La foto grande de arriba; sin foto, la banda de marca con el título.
class _Portada extends StatelessWidget {
  const _Portada({this.foto});

  final String? foto;

  @override
  Widget build(BuildContext context) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          'ARMA TU COLLAR',
          style: TinaTipografia.estilo(
            tamano: 13,
            peso: FontWeight.w800,
            color: TinaColores.blanco,
            espaciado: 1.4,
          ),
        ),
        Text(
          'Charm Bar',
          style: TinaTipografia.estilo(
            tamano: 40,
            peso: FontWeight.w800,
            color: TinaColores.blanco,
            espaciado: -1.4,
          ),
        ),
        Text(
          'Elige el collar, elige tus charms y hazlo único.',
          style: TinaTipografia.serif(tamano: 22, color: TinaColores.blanco),
        ),
      ],
    );
    if (foto == null) {
      return TinaEncabezadoMarca(
        key: const ValueKey('charm-portada-marca'),
        child: titulo,
      );
    }
    return ClipRRect(
      key: const ValueKey('charm-portada-foto'),
      borderRadius: BorderRadius.circular(32),
      child: AspectRatio(
        aspectRatio: 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TinaImagenRed(url: foto!, radio: 0),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC2A1608), Color(0x002A1608)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Align(alignment: Alignment.bottomLeft, child: titulo),
            ),
          ],
        ),
      ),
    );
  }
}

/// El Charm Bar todavía no tiene collar base o charms a la venta.
class _Pronto extends StatelessWidget {
  const _Pronto({required this.onVerTienda});

  final VoidCallback onVerTienda;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('charm-pronto'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: TinaColores.blanco.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        spacing: 14,
        children: [
          const EstrellaTina(tamano: 40, color: TinaColores.naranja),
          Text(
            'El Charm Bar abre muy pronto',
            textAlign: TextAlign.center,
            style: TinaTipografia.estilo(
              tamano: 24,
              peso: FontWeight.w800,
              espaciado: -0.5,
            ),
          ),
          Text(
            'Estamos preparando los collares y los charms. Mientras tanto, mira '
            'el resto de los accesorios.',
            textAlign: TextAlign.center,
            style: TinaTipografia.estilo(
              tamano: 15,
              color: TinaColores.marron,
              altura: 1.4,
            ),
          ),
          SizedBox(
            width: 260,
            child: TinaBoton(etiqueta: 'Ver la tienda', onPressed: onVerTienda),
          ),
        ],
      ),
    );
  }
}

/// A la izquierda: la foto del collar con el color elegido y los charms que
/// lleva hasta ahora.
class _Vista extends StatelessWidget {
  const _Vista({
    required this.charmBar,
    required this.armado,
    required this.onQuitarCharm,
  });

  final CharmBar charmBar;
  final ArmadoCollar armado;
  final ValueChanged<int> onQuitarCharm;

  @override
  Widget build(BuildContext context) {
    final fotos = charmBar.base?.fotosPara(armado.color) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.4, -0.5),
                      radius: 1.2,
                      colors: [
                        Color(0xFFFFB347),
                        TinaColores.naranja,
                        TinaColores.rosa,
                      ],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
                if (fotos.isNotEmpty) TinaImagenRed(url: fotos.first, radio: 0),
              ],
            ),
          ),
        ),
        Container(
          key: const ValueKey('armar-elegidos'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TinaColores.blanco.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                'Tus charms (${armado.elegidos}/${armado.cantidad})',
                key: const ValueKey('armar-contador'),
                style: TinaTipografia.estilo(tamano: 15, peso: FontWeight.w800),
              ),
              if (armado.seleccion.isEmpty)
                Text(
                  'Toca los charms de la derecha para ponerlos en tu collar.',
                  style: TinaTipografia.estilo(
                    tamano: 13,
                    color: TinaColores.marron,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in armado.seleccion.entries)
                      _ChipElegido(
                        key: ValueKey('charm-elegido-${e.key}'),
                        nombre: charmBar.charm(e.key)?.nombre ?? 'Charm',
                        cantidad: e.value,
                        onQuitar: () => onQuitarCharm(e.key),
                      ),
                  ],
                ),
              Text(
                'Tu collar llegará armado con los charms que elijas. Si lo '
                'pediste con charms removibles, podrás cambiarlos de lugar.',
                style: TinaTipografia.estilo(
                  tamano: 12,
                  color: TinaColores.marron,
                  altura: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipElegido extends StatelessWidget {
  const _ChipElegido({
    super.key,
    required this.nombre,
    required this.cantidad,
    required this.onQuitar,
  });

  final String nombre;
  final int cantidad;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: TinaColores.campo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text(
            cantidad > 1 ? '$nombre × $cantidad' : nombre,
            style: TinaTipografia.estilo(tamano: 13, peso: FontWeight.w700),
          ),
          Semantics(
            button: true,
            label: 'Quitar $nombre',
            excludeSemantics: true,
            onTap: onQuitar,
            child: GestureDetector(
              key: ValueKey('quitar-charm-$nombre'),
              behavior: HitTestBehavior.opaque,
              onTap: onQuitar,
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: TinaColores.rojo,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A la derecha: los cuatro pasos y el precio final.
class _Pasos extends StatelessWidget {
  const _Pasos({
    required this.charmBar,
    required this.armado,
    required this.precio,
    required this.onColor,
    required this.onModo,
    required this.onCantidad,
    required this.onAgregarCharm,
  });

  final CharmBar charmBar;
  final ArmadoCollar armado;
  final int precio;
  final ValueChanged<String> onColor;
  final ValueChanged<String> onModo;
  final ValueChanged<int> onCantidad;
  final ValueChanged<int> onAgregarCharm;

  @override
  Widget build(BuildContext context) {
    final modos = charmBar.modosDe(armado.color);
    final base = charmBar.base!.producto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 22,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              'Crea un collar único',
              style: TinaTipografia.estilo(
                tamano: 28,
                peso: FontWeight.w800,
                espaciado: -0.8,
              ),
            ),
            Text(
              'Desde ${formatoPesos(base.precio)}',
              style: TinaTipografia.estilo(
                tamano: 18,
                peso: FontWeight.w800,
                color: TinaColores.naranja,
              ),
            ),
          ],
        ),
        _Paso(
          numero: 1,
          titulo: 'Elige el color del collar',
          hijo: Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final c in charmBar.colores)
                _Muestra(
                  key: ValueKey('armar-color-$c'),
                  nombre: c,
                  color: colorDeProducto(c),
                  activa: c == armado.color,
                  onTap: () => onColor(c),
                ),
            ],
          ),
        ),
        _Paso(
          numero: 2,
          titulo: '¿Cuántos charms quieres?',
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TinaSelectorCantidad(
                  key: const ValueKey('armar-cantidad'),
                  valor: armado.cantidad,
                  maximo: CharmBar.maximoCharms,
                  onChanged: onCantidad,
                ),
              ),
              Text(
                'Recomendado: ${CharmBar.recomendados} charms',
                style: TinaTipografia.estilo(
                  tamano: 12,
                  color: TinaColores.marron,
                ),
              ),
            ],
          ),
        ),
        if (modos.isNotEmpty)
          _Paso(
            numero: 3,
            titulo: '¿Cómo quieres tus charms?',
            hijo: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in modos)
                  TinaChip(
                    key: ValueKey('armar-modo-$m'),
                    etiqueta: m,
                    activo: m == armado.modo,
                    onTap: () => onModo(m),
                  ),
              ],
            ),
          ),
        _Paso(
          numero: 4,
          titulo: 'Personaliza tus charms',
          detalle: 'Charms ${armado.elegidos}/${armado.cantidad}',
          hijo: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in charmBar.charms)
                _TarjetaCharm(
                  key: ValueKey('charm-${c.idVariante}'),
                  nombre: c.nombre,
                  precio: formatoPesos(c.precio),
                  foto: c.foto,
                  elegidos: armado.seleccion[c.idVariante] ?? 0,
                  onTap: () => onAgregarCharm(c.idVariante),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              'Precio final',
              style: TinaTipografia.estilo(
                tamano: 14,
                peso: FontWeight.w800,
                color: TinaColores.marron,
              ),
            ),
            Text(
              formatoPesos(precio),
              key: const ValueKey('armar-precio'),
              style: TinaTipografia.estilo(
                tamano: 30,
                peso: FontWeight.w800,
                espaciado: -0.8,
                color: TinaColores.naranja,
              ),
            ),
            Text(
              'El collar más cada charm. El envío se suma al pagar.',
              style: TinaTipografia.estilo(
                tamano: 12,
                color: TinaColores.marron,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.titulo,
    required this.hijo,
    this.detalle,
  });

  final int numero;
  final String titulo;
  final String? detalle;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Row(
          spacing: 10,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: TinaColores.tinta,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$numero',
                style: TinaTipografia.estilo(
                  tamano: 13,
                  peso: FontWeight.w800,
                  color: TinaColores.blanco,
                ),
              ),
            ),
            Flexible(
              child: Text(
                titulo,
                style: TinaTipografia.estilo(tamano: 16, peso: FontWeight.w800),
              ),
            ),
            if (detalle != null)
              Text(
                detalle!,
                style: TinaTipografia.estilo(
                  tamano: 13,
                  peso: FontWeight.w700,
                  color: TinaColores.marron,
                ),
              ),
          ],
        ),
        hijo,
      ],
    );
  }
}

class _Muestra extends StatelessWidget {
  const _Muestra({
    super.key,
    required this.nombre,
    required this.color,
    required this.activa,
    required this.onTap,
  });

  final String nombre;
  final Color color;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activa,
      label: nombre,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          spacing: 4,
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: activa ? TinaColores.naranja : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
              ),
            ),
            Text(
              nombre,
              style: TinaTipografia.estilo(
                tamano: 12,
                peso: activa ? FontWeight.w800 : FontWeight.w600,
                color: activa ? TinaColores.naranja : TinaColores.tinta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaCharm extends StatelessWidget {
  const _TarjetaCharm({
    super.key,
    required this.nombre,
    required this.precio,
    required this.elegidos,
    required this.onTap,
    this.foto,
  });

  final String nombre;
  final String precio;
  final String? foto;
  final int elegidos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$nombre, $precio',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 82,
          child: Column(
            spacing: 4,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: TinaColores.blanco.withValues(alpha: 0.9),
                      border: Border.all(
                        color: elegidos > 0
                            ? TinaColores.naranja
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: foto != null
                        ? TinaImagenRed(url: foto!, radio: 0)
                        : const Center(
                            child: EstrellaTina(
                              tamano: 28,
                              color: TinaColores.durazno,
                            ),
                          ),
                  ),
                  if (elegidos > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        key: ValueKey('cuenta-$nombre'),
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: TinaColores.naranja,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$elegidos',
                          style: TinaTipografia.estilo(
                            tamano: 12,
                            peso: FontWeight.w800,
                            color: TinaColores.blanco,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 11,
                  peso: FontWeight.w700,
                  altura: 1.15,
                ),
              ),
              Text(
                precio,
                style: TinaTipografia.estilo(
                  tamano: 11,
                  peso: FontWeight.w800,
                  color: TinaColores.naranja,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
