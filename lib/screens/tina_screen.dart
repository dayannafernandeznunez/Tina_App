import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../components/components.dart';
import '../data/administradora.dart';
import '../data/catalogo.dart';
import '../data/pedidos.dart';
import '../data/sesion.dart';
import '../data/datos_simulados.dart';
import '../logic/calculos.dart';
import '../logic/borrador_producto.dart';
import '../logic/metricas.dart';
import '../logic/validaciones.dart';
import '../logic/vistas.dart';
import '../models/models.dart';
import '../pages/carrito_page.dart';
import '../pages/checkout_page.dart';
import '../pages/editar_producto_page.dart';
import '../pages/confirmacion_page.dart';
import '../pages/cuenta_page.dart';
import '../pages/detalle_page.dart';
import '../pages/inicio_page.dart';
import '../pages/lista_page.dart';
import '../pages/login_page.dart';
import '../pages/panel_page.dart';
import '../pages/panel_datos_page.dart';
import '../pages/panel_fotos_articulos_page.dart';
import '../pages/panel_fotos_sitio_page.dart';
import '../pages/panel_productos_page.dart';
import '../pages/pago_retorno_page.dart';
import '../pages/pedido_page.dart';
import '../theme/tina_tema.dart';
import '../utils/abrir_url.dart';
import '../utils/adaptable.dart';
import '../utils/formato.dart';

/// Las pantallas de la app. Cada una es una ruta de la pila de navegación.
enum Ruta {
  inicio,
  lista,
  detalle,
  carrito,
  checkout,
  confirmacion,
  login,
  cuenta,
  panel,
  productoEditar,
  pedido,

  /// A donde vuelve la clienta después de la página de pago de Wompi.
  pagoRetorno,
}

/// Screen anfitriona de la app.
///
/// Todo el estado vive aquí: el catálogo con su stock, el carrito, los
/// pedidos, la sesión, la selección del detalle y los formularios. Las Pages
/// solo muestran lo que reciben y reportan cada interacción con un callback;
/// ninguna guarda datos de la app por su cuenta.
class TinaScreen extends StatefulWidget {
  const TinaScreen({
    super.key,
    this.catalogo,
    this.sesiones,
    this.pedidos,
    this.admin,
    this.pagoEnLinea = false,
    this.selectorFotos = const SelectorFotosDispositivo(),
    this.abrirUrl = abrirEnLaMismaPestana,
    this.urlInicial,
    this.pausaSondeo = const Duration(seconds: 2),
  });

  /// Cómo se abre la página de pago de Wompi.
  final AbrirUrl abrirUrl;

  /// La dirección con la que se abrió la app. Si trae `?pedido=…&t=…`, la
  /// clienta viene de pagar en Wompi. Por defecto es la de la pestaña.
  final Uri? urlInicial;

  /// Cuánto se espera entre una consulta y otra del estado del pago.
  final Duration pausaSondeo;

  /// De dónde se lee el catálogo (categorías, productos, variantes, promociones
  /// y fotos). Si es `null`, la app trabaja solo con los datos simulados.
  final CatalogoRepositorio? catalogo;

  /// El inicio de sesión de la tienda, igual para clientas y administradora.
  /// Si es `null`, la app funciona en modo de ejemplo: las cuentas son de
  /// mentira y el panel se abre sin cuenta.
  final SesionRepositorio? sesiones;

  /// Crear pedidos y leerlos. Si es `null`, los pedidos viven solo en la
  /// memoria de la app (modo de ejemplo).
  final PedidosRepositorio? pedidos;

  /// Si el pago en línea con Wompi está conectado. Mientras no lo esté, solo se
  /// puede comprar con contraentrega (en Cali).
  final bool pagoEnLinea;

  /// Lo que solo puede hacer la administradora: cambiar fotos. Si es `null`,
  /// no se puede cambiar ninguna foto.
  final AdministradoraRepositorio? admin;

  /// Cómo se eligen las fotos en el dispositivo.
  final SelectorFotos selectorFotos;

  @override
  State<TinaScreen> createState() => _TinaScreenState();
}

class _TinaScreenState extends State<TinaScreen> {
  // ---------------------------------------------------------------- datos
  // El catálogo arranca con los datos simulados y, si hay un repositorio, se
  // reemplaza por el de Supabase apenas llega. Los pedidos siguen simulados.
  List<Categoria> _categorias = [...DatosSimulados.categorias];
  List<Producto> _productos = [...DatosSimulados.productos];
  List<Promocion> _promociones = [...DatosSimulados.promociones];
  List<ImagenProducto> _imagenes = [];
  List<AjusteSitio> _ajustesSitio = [];
  List<Usuario> _usuarios = [...DatosSimulados.usuarios];

  bool _cargandoCatalogo = false;

  // ------------------------------------------------- administradora y fotos
  bool _esAdmin = false;
  bool _authOcupado = false;
  SeccionPanel _seccionPanel = SeccionPanel.pedidos;
  int? _idProductoFotos;
  bool _fotosOcupado = false;
  String? _claveSitioOcupada;
  BorradorProducto? _borrador;
  bool _mostrarErroresProducto = false;
  int _contadorVariantes = 0;

  List<VarianteProducto> _variantes = [...DatosSimulados.variantes];
  List<Cliente> _clientes = [...DatosSimulados.clientes];
  List<Pedido> _pedidos = [...DatosSimulados.pedidos];
  List<DetallePedido> _detalles = [...DatosSimulados.detalles];
  List<Envio> _envios = [...DatosSimulados.envios];
  List<Pago> _pagos = [...DatosSimulados.pagos];
  List<Comprobante> _comprobantes = [...DatosSimulados.comprobantes];
  List<HistorialEstado> _historial = [...DatosSimulados.historial];

  // -------------------------------------------------------------- carrito
  List<CarritoItem> _items = [];
  int _siguienteItem = 1;

  // --------------------------------------------------------------- sesión
  Cliente? _sesion;
  ModoCompra _modo = ModoCompra.invitada;

  // ----------------------------------------------------------- navegación
  List<Ruta> _pila = [Ruta.inicio];

  // ------------------------------------------------- estado de pantallas
  String? _categoriaActiva; // null = todas
  int _idProducto = 1;
  String _color = '';
  String _talla = '';
  int _cantidad = 1;
  int _foto = 0;

  final Map<String, String> _datosEnvio = {};
  bool _mostrarErrores = false;
  MetodoPago _metodoPago = MetodoPago.wompi;
  bool _comprando = false;

  bool _registro = false;

  // La intro animada sale una vez por inicio de sesión, la primera vez que se
  // llega a la portada.
  bool _introPendiente = false;
  bool _loginDesdeCheckout = false;
  String _authNombre = '';
  String _authCorreo = '';
  String _authClave = '';
  String? _authError;

  EstadoPedido? _filtro;
  int? _idPedidoVer;
  int? _ultimoPedido;

  // ------------------------------------------- vuelta de la página de pago
  int? _retornoId;
  String? _retornoToken;
  EstadoPagoPedido? _retornoEstado;
  bool _retornoVerificando = false;
  bool _retornoSinConexion = false;
  bool _retornoReintentando = false;

  // ------------------------------------------------------------ derivados
  int get _unidades => _items.fold(0, (s, i) => s + i.cantidad);

  /// Con cuentas reales, quien tiene la sesión iniciada compra con su cuenta:
  /// la base de datos identifica a la compradora por su sesión.
  bool get _conCuenta =>
      _sesion != null &&
      (_modo == ModoCompra.cuenta || widget.sesiones != null);

  bool get _aplicaPrimeraCompra =>
      _conCuenta && Calculos.esPrimeraCompra(_sesion!.idCliente, _pedidos);

  /// La contraentrega solo existe si el envío es a Cali, Valle del Cauca.
  bool get _puedeContraentrega => Calculos.esCali(
    _datosEnvio['ciudad'] ?? '',
    _datosEnvio['departamento'] ?? '',
  );

  /// Si eligió contraentrega y luego cambió la ciudad, vuelve a pago en línea.
  MetodoPago get _metodoEfectivo =>
      _metodoPago == MetodoPago.contraentrega && !_puedeContraentrega
      ? MetodoPago.wompi
      : _metodoPago;

  ResumenCarrito get _resumen => Calculos.resumen(
    items: _items,
    variantes: _variantes,
    productos: _productos,
    promociones: _promociones,
    primeraCompra: _aplicaPrimeraCompra,
    costoEnvio: Calculos.costoEnvio(_metodoEfectivo),
  );

  List<String> get _nombresCategorias => [
    for (final c in _categorias) c.nombre,
  ];

  ProductoVista _vista(Producto p) {
    final todas = [
      for (final i in _imagenes)
        if (i.idProducto == p.idProducto) i,
    ]..sort((a, b) => a.orden.compareTo(b.orden));
    final generales = [
      for (final i in todas)
        if (i.color == null) i.url,
    ];
    final porColor = <String, List<String>>{};
    for (final i in todas) {
      if (i.color != null) {
        (porColor[claveColor(i.color!)] ??= []).add(i.url);
      }
    }
    return ProductoVista(
      producto: p,
      categoria: _categorias
          .firstWhere((c) => c.idCategoria == p.idCategoria)
          .nombre,
      variantes: [
        for (final v in _variantes)
          if (v.idProducto == p.idProducto) v,
      ],
      fotos: generales.isNotEmpty ? generales : [for (final i in todas) i.url],
      fotosPorColor: porColor,
    );
  }

  /// Foto principal de cada producto que tenga fotos (id del producto ->
  /// dirección): la primera foto general y, si no tiene, la primera de todas.
  Map<int, String> get _fotosPrincipales {
    final primeras = <int, ImagenProducto>{};
    for (final i in _imagenes) {
      final actual = primeras[i.idProducto];
      if (actual == null || _antesComoPortada(i, actual)) {
        primeras[i.idProducto] = i;
      }
    }
    return {for (final e in primeras.entries) e.key: e.value.url};
  }

  /// ¿[a] debe ser portada antes que [b]? Las generales ganan a las de color.
  bool _antesComoPortada(ImagenProducto a, ImagenProducto b) {
    if ((a.color == null) != (b.color == null)) return a.color == null;
    return a.orden < b.orden;
  }

  List<ProductoVista> _vistas({String? categoria}) => [
    for (final p in _productos)
      if (p.activo) _vista(p),
  ].where((v) => categoria == null || v.categoria == categoria).toList();

  ProductoVista get _vistaDetalle =>
      _vista(_productos.firstWhere((p) => p.idProducto == _idProducto));

  List<PedidoCompleto> get _pedidosCompletos => armarPedidos(
    pedidos: _pedidos,
    detalles: _detalles,
    variantes: _variantes,
    productos: _productos,
    clientes: _clientes,
    envios: _envios,
    pagos: _pagos,
    comprobantes: _comprobantes,
    historial: _historial,
    usuarios: _usuarios,
  );

  // --------------------------------------------------------------- catálogo
  @override
  void initState() {
    super.initState();
    if (widget.catalogo != null) {
      _cargandoCatalogo = true;
      _cargarCatalogo();
    }
    if (widget.sesiones != null) {
      // Con cuentas reales no hay clientas ni pedidos de ejemplo: los pedidos
      // reales llegarán con la conexión de pedidos.
      _clientes = [];
      _pedidos = [];
      _detalles = [];
      _envios = [];
      _pagos = [];
      _comprobantes = [];
      _historial = [];
      _restaurarSesion();
    }

    // ¿Viene de pagar en Wompi? Wompi la devuelve a ?pedido=<id>&t=<llave>.
    final inicial = widget.urlInicial ?? Uri.base;
    final id = int.tryParse(inicial.queryParameters['pedido'] ?? '');
    final token = inicial.queryParameters['t'];
    if (widget.pedidos != null && id != null && token != null) {
      _retornoId = id;
      _retornoToken = token;
      _retornoVerificando = true;
      _pila = [Ruta.inicio, Ruta.pagoRetorno];
      _verificarPago();
    }
  }

  Future<void> _cargarCatalogo() async {
    try {
      final catalogo = await widget.catalogo!.cargar();
      if (!mounted) return;
      setState(() {
        _categorias = [...catalogo.categorias];
        _productos = [...catalogo.productos];
        _variantes = [...catalogo.variantes];
        _promociones = [...catalogo.promociones];
        _imagenes = [...catalogo.imagenes];
        _ajustesSitio = [...catalogo.ajustesSitio];
        _cargandoCatalogo = false;
      });
    } catch (error) {
      debugPrint('No se pudo leer el catálogo de Supabase: $error');
      if (!mounted) return;
      setState(() => _cargandoCatalogo = false);
      _aviso('No pudimos conectar con la tienda. Mostramos datos de ejemplo.');
    }
  }

  // ------------------------------------------- administradora y sus fotos
  /// Lugares del sitio que la tienda ya muestra.
  static const Set<String> _clavesSitioEnUso = {'portada_inicio'};

  /// Sin cuentas reales (modo de ejemplo) el panel se abre sin cuenta; con
  /// ellas, solo si quien entró es administradora.
  bool get _puedeVerPanel => widget.sesiones == null || _esAdmin;

  String? _urlSitio(String clave) {
    for (final a in _ajustesSitio) {
      if (a.clave == clave && a.tieneFoto) return a.url;
    }
    return null;
  }

  int get _productoFotos =>
      _idProductoFotos ??
      (_productos.isEmpty ? 0 : _productos.first.idProducto);

  /// Las fotos generales del producto (las de color se manejan al editarlo).
  List<ImagenProducto> get _fotosDelProducto => [
    for (final i in _imagenes)
      if (i.idProducto == _productoFotos && i.color == null) i,
  ]..sort((a, b) => a.orden.compareTo(b.orden));

  Future<void> _restaurarSesion() async {
    final activa = await widget.sesiones!.restaurar();
    if (!mounted || activa == null) return;
    setState(() {
      _esAdmin = activa.esAdministradora;
      _sesion = activa.cliente;
      _modo = ModoCompra.cuenta;
      _clientes = [
        for (final c in _clientes)
          if (c.idCliente != activa.cliente.idCliente) c,
        activa.cliente,
      ];
    });
    _cargarPedidos();
  }

  /// Modo de ejemplo: el enlace de la página de ingreso abre el panel.
  void _irAPanel() {
    setState(() => _seccionPanel = SeccionPanel.pedidos);
    _empujar(Ruta.panel);
  }

  Future<void> _entrarConCuenta(String correo) async {
    final repo = widget.sesiones!;
    setState(() {
      _authOcupado = true;
      _authError = null;
    });
    try {
      if (_registro) {
        final resultado = await repo.registrar(
          nombre: _authNombre.trim(),
          correo: correo,
          clave: _authClave,
        );
        if (!mounted) return;
        final activa = resultado.sesion;
        if (activa == null) {
          setState(() {
            _authOcupado = false;
            _registro = false;
            _authClave = '';
          });
          _aviso(
            'Te enviamos un correo para confirmar tu cuenta. Después inicia sesión.',
          );
          return;
        }
        _abrirSesion(activa);
      } else {
        _abrirSesion(await repo.iniciarSesion(correo, _authClave));
      }
    } on ErrorSesion catch (e) {
      if (!mounted) return;
      setState(() {
        _authOcupado = false;
        _authError = e.mensaje;
      });
    } catch (error) {
      debugPrint('Error al entrar: $error');
      if (!mounted) return;
      setState(() {
        _authOcupado = false;
        _authError = 'No pudimos entrar. Inténtalo de nuevo.';
      });
    }
  }

  /// Quien entra va a donde le toca: la administradora al panel, las clientas
  /// a la tienda (o de vuelta a su compra).
  void _abrirSesion(SesionActiva activa) {
    final cliente = activa.cliente;
    setState(() {
      _authOcupado = false;
      _esAdmin = activa.esAdministradora;
      _clientes = [
        for (final c in _clientes)
          if (c.idCliente != cliente.idCliente) c,
        cliente,
      ];
    });
    _cargarPedidos(cliente: cliente, esAdministradora: activa.esAdministradora);
    if (activa.esAdministradora) {
      setState(() {
        _sesion = cliente;
        _modo = ModoCompra.cuenta;
        _authNombre = '';
        _authCorreo = '';
        _authClave = '';
        _authError = null;
        _registro = false;
        _loginDesdeCheckout = false;
        _seccionPanel = SeccionPanel.pedidos;
        _pila = [Ruta.inicio, Ruta.panel];
      });
      _aviso('Hola, ${cliente.nombre}.');
      return;
    }
    _completarEntrada(cliente);
  }

  // ------------------------------------------------- productos e inventario
  String _claveNueva() => 'n${_contadorVariantes++}';

  List<ProductoVista> _vistasAdmin() => [for (final p in _productos) _vista(p)];

  void _nuevoProducto() {
    if (_categorias.isEmpty) {
      _aviso('Primero hace falta una categoría.');
      return;
    }
    setState(() {
      _borrador = BorradorProducto.nuevo(
        idCategoria: _categorias.first.idCategoria,
        claveVariante: _claveNueva(),
      );
      _mostrarErroresProducto = false;
    });
    _empujar(Ruta.productoEditar);
  }

  void _editarProducto(int idProducto) {
    final producto = _productos.firstWhere((p) => p.idProducto == idProducto);
    setState(() {
      _borrador = BorradorProducto.desde(
        producto,
        [
          for (final v in _variantes)
            if (v.idProducto == idProducto) v,
        ],
        fotos: [
          for (final i in _imagenes)
            if (i.idProducto == idProducto) i,
        ],
      );
      _mostrarErroresProducto = false;
    });
    _empujar(Ruta.productoEditar);
  }

  void _cambiarBorrador(BorradorProducto Function(BorradorProducto) cambio) {
    final actual = _borrador;
    if (actual == null) return;
    setState(() => _borrador = cambio(actual));
  }

  void _campoProducto(String campo, String valor) => _cambiarBorrador(
    (b) => switch (campo) {
      'nombre' => b.copyWith(nombre: valor),
      'descripcion' => b.copyWith(descripcion: valor),
      'tecnica' => b.copyWith(tecnica: valor),
      'precio' => b.copyWith(precio: valor),
      _ => b,
    },
  );

  void _campoVariante(String clave, String campo, String valor) =>
      _cambiarBorrador((b) {
        if (campo != 'color') {
          return b.conVariante(clave, (v) => v.copyWith(talla: valor));
        }
        // Si era el único renglón de ese color, las fotos que ya había elegido
        // para él siguen al color con su nuevo nombre.
        final anterior = b.variantes.firstWhere((v) => v.clave == clave).color;
        final unico =
            anterior.trim().isNotEmpty &&
            b.variantes
                    .where((v) => claveColor(v.color) == claveColor(anterior))
                    .length ==
                1;
        final cambiado = b.conVariante(clave, (v) => v.copyWith(color: valor));
        if (!unico || valor.trim().isEmpty) return cambiado;
        return cambiado.copyWith(
          fotosNuevas: [
            for (final f in cambiado.fotosNuevas)
              f.color != null && claveColor(f.color!) == claveColor(anterior)
                  ? f.conColor(valor.trim())
                  : f,
          ],
        );
      });

  /// Elige una foto del dispositivo para el color dado (`null` = portada). Se
  /// sube cuando se guarda el producto.
  Future<void> _agregarFotoBorrador(String? color) async {
    final foto = await _elegirFoto();
    if (foto == null || !mounted) return;
    _cambiarBorrador(
      (b) => b.copyWith(
        fotosNuevas: [
          ...b.fotosNuevas,
          FotoNueva(clave: _claveNueva(), foto: foto, color: color),
        ],
      ),
    );
  }

  void _quitarFotoNueva(String clave) => _cambiarBorrador(
    (b) => b.copyWith(
      fotosNuevas: [
        for (final f in b.fotosNuevas)
          if (f.clave != clave) f,
      ],
    ),
  );

  void _quitarFotoExistente(int idImagen) => _cambiarBorrador(
    (b) => b.copyWith(idsFotosABorrar: [...b.idsFotosABorrar, idImagen]),
  );

  void _quitarVariante(String clave) => _cambiarBorrador(
    (b) => b.copyWith(
      variantes: [
        for (final v in b.variantes)
          if (v.clave != clave) v,
      ],
    ),
  );

  void _agregarVariante() => _cambiarBorrador(
    (b) => b.copyWith(
      variantes: [
        ...b.variantes,
        BorradorVariante(clave: _claveNueva()),
      ],
    ),
  );

  void _cerrarEditorProducto() {
    setState(() {
      _borrador = null;
      _mostrarErroresProducto = false;
      if (_pila.length > 1) _pila = _pila.sublist(0, _pila.length - 1);
    });
  }

  Future<void> _guardarProducto() async {
    final borrador = _borrador;
    if (borrador == null) return;
    if (borrador.errores().isNotEmpty) {
      setState(() => _mostrarErroresProducto = true);
      return;
    }
    if (!_hayAdmin()) return;

    int? idCreado;
    final idsGuardados = <String, int>{};
    final fotosSubidas = <String>{};
    final fotosBorradas = <int>{};
    await _accionFotos(() async {
      final admin = widget.admin!;
      try {
        final producto = await admin.guardarProducto(borrador.aProducto());
        idCreado = producto.idProducto;
        final variantes = <VarianteProducto>[];
        for (final v in borrador.variantes) {
          final guardada = await admin.guardarVariante(
            v.aVariante(producto.idProducto),
          );
          idsGuardados[v.clave] = guardada.idVariante;
          variantes.add(guardada);
        }
        for (final id in borrador.idsVariantesOriginales) {
          if (!borrador.variantes.any((v) => v.idVariante == id)) {
            await admin.borrarVariante(id);
          }
        }

        // Fotos: primero se borran las que se quitaron y luego se suben las
        // nuevas, la portada antes que las de color.
        for (final id in borrador.idsFotosABorrar) {
          final foto = borrador.fotosExistentes.firstWhere(
            (f) => f.idImagen == id,
          );
          await admin.borrarFotoProducto(foto);
          fotosBorradas.add(id);
          if (mounted) {
            setState(() {
              _imagenes = [
                for (final f in _imagenes)
                  if (f.idImagen != id) f,
              ];
            });
          }
        }
        var orden = _imagenes
            .where((i) => i.idProducto == producto.idProducto)
            .fold(0, (m, i) => i.orden > m ? i.orden : m);
        final porSubir = [
          ...borrador.fotosNuevas.where((f) => f.color == null),
          ...borrador.fotosNuevas.where((f) => f.color != null),
        ];
        for (final f in porSubir) {
          orden++;
          final imagen = await admin.subirFotoProducto(
            idProducto: producto.idProducto,
            foto: f.foto,
            orden: orden,
            color: f.color,
          );
          fotosSubidas.add(f.clave);
          if (mounted) setState(() => _imagenes = [..._imagenes, imagen]);
        }

        if (!mounted) return;
        setState(() {
          _productos = [
            for (final p in _productos)
              if (p.idProducto != producto.idProducto) p,
            producto,
          ]..sort((a, b) => a.idProducto.compareTo(b.idProducto));
          _variantes = [
            for (final v in _variantes)
              if (v.idProducto != producto.idProducto) v,
            ...variantes,
          ];
          _borrador = null;
          if (_pila.length > 1) _pila = _pila.sublist(0, _pila.length - 1);
        });
      } catch (_) {
        // Lo que alcanzó a guardarse queda en el formulario con su id, así al
        // reintentar no se duplica, y el catálogo se vuelve a leer.
        if (mounted) {
          setState(() {
            _borrador = _borrador
                ?.conIds(idProducto: idCreado, idsVariantes: idsGuardados)
                .sinFotosHechas(
                  clavesSubidas: fotosSubidas,
                  idsBorradas: fotosBorradas,
                );
          });
          _cargarCatalogo();
        }
        rethrow;
      }
    }, exito: borrador.esNuevo ? 'Producto creado.' : 'Cambios guardados.');
  }

  Future<void> _alternarVisible(int idProducto) async {
    if (!_hayAdmin()) return;
    final actual = _productos.firstWhere((p) => p.idProducto == idProducto);
    final nuevo = actual.copyWith(activo: !actual.activo);
    await _accionFotos(
      () async {
        final guardado = await widget.admin!.guardarProducto(nuevo);
        setState(() {
          _productos = [
            for (final p in _productos)
              p.idProducto == idProducto ? guardado : p,
          ];
        });
      },
      exito: nuevo.activo ? 'Ahora se ve en la tienda.' : 'Ahora está oculto.',
    );
  }

  Widget _editorProducto() {
    final borrador = _borrador!;
    return EditarProductoPage(
      key: ValueKey('editar-${borrador.idProducto}'),
      borrador: borrador,
      categorias: _categorias,
      errores: borrador.errores(),
      mostrarErrores: _mostrarErroresProducto,
      ocupado: _fotosOcupado,
      onCampo: _campoProducto,
      onCategoria: (id) => _cambiarBorrador((b) => b.copyWith(idCategoria: id)),
      onVisible: (v) => _cambiarBorrador((b) => b.copyWith(activo: v)),
      onVarianteCampo: _campoVariante,
      onVarianteStock: (clave, n) => _cambiarBorrador(
        (b) => b.conVariante(clave, (v) => v.copyWith(stock: n)),
      ),
      onQuitarVariante: _quitarVariante,
      onAgregarVariante: _agregarVariante,
      onAgregarFoto: _agregarFotoBorrador,
      onQuitarFotoNueva: _quitarFotoNueva,
      onQuitarFotoExistente: _quitarFotoExistente,
      onGuardar: _guardarProducto,
      onCancelar: _cerrarEditorProducto,
    );
  }

  /// Corre un cambio de fotos mostrando "un momento" y avisando el resultado.
  /// Una sola acción a la vez.
  Future<void> _accionFotos(
    Future<void> Function() accion, {
    required String exito,
    String? clave,
  }) async {
    if (_fotosOcupado) return;
    setState(() {
      _fotosOcupado = true;
      _claveSitioOcupada = clave;
    });
    try {
      await accion();
      if (mounted) _aviso(exito);
    } on ErrorAdministradora catch (e) {
      if (mounted) _aviso(e.mensaje);
    } catch (error) {
      debugPrint('No se pudo guardar el cambio de fotos: $error');
      if (mounted) _aviso('No se pudo guardar el cambio. Inténtalo de nuevo.');
    } finally {
      if (mounted) {
        setState(() {
          _fotosOcupado = false;
          _claveSitioOcupada = null;
        });
      }
    }
  }

  bool _hayAdmin() {
    if (widget.admin != null) return true;
    _aviso('Para guardar cambios hace falta la conexión con la tienda.');
    return false;
  }

  Future<FotoElegida?> _elegirFoto() async {
    final foto = await widget.selectorFotos.elegir();
    if (foto == null) return null;
    final problema = foto.problema;
    if (problema != null) {
      if (mounted) _aviso(problema);
      return null;
    }
    return foto;
  }

  Future<void> _subirFotoProducto() async {
    if (!_hayAdmin()) return;
    final foto = await _elegirFoto();
    if (foto == null) return;
    final idProducto = _productoFotos;
    final fotos = _fotosDelProducto;
    final orden = (fotos.isEmpty ? 0 : fotos.last.orden) + 1;
    await _accionFotos(() async {
      final nueva = await widget.admin!.subirFotoProducto(
        idProducto: idProducto,
        foto: foto,
        orden: orden,
      );
      setState(() => _imagenes = [..._imagenes, nueva]);
    }, exito: 'Foto subida.');
  }

  Future<void> _aplicarOrdenFotos(List<ImagenProducto> enOrden) {
    return _accionFotos(() async {
      await widget.admin!.ordenarFotosProducto(enOrden);
      final nuevos = {
        for (var i = 0; i < enOrden.length; i++) enOrden[i].idImagen: i + 1,
      };
      setState(() {
        _imagenes = [
          for (final f in _imagenes)
            nuevos.containsKey(f.idImagen)
                ? f.copyWith(orden: nuevos[f.idImagen])
                : f,
        ];
      });
    }, exito: 'Orden guardado.');
  }

  Future<void> _moverFoto(ImagenProducto foto, int paso) async {
    if (!_hayAdmin()) return;
    final lista = [..._fotosDelProducto];
    final de = lista.indexWhere((f) => f.idImagen == foto.idImagen);
    final a = de + paso;
    if (de < 0 || a < 0 || a >= lista.length) return;
    lista.insert(a, lista.removeAt(de));
    await _aplicarOrdenFotos(lista);
  }

  Future<void> _hacerPrincipal(ImagenProducto foto) async {
    if (!_hayAdmin()) return;
    final lista = [
      foto,
      for (final f in _fotosDelProducto)
        if (f.idImagen != foto.idImagen) f,
    ];
    await _aplicarOrdenFotos(lista);
  }

  Future<void> _borrarFotoProducto(ImagenProducto foto) async {
    if (!_hayAdmin()) return;
    await _accionFotos(() async {
      await widget.admin!.borrarFotoProducto(foto);
      setState(() {
        _imagenes = [
          for (final f in _imagenes)
            if (f.idImagen != foto.idImagen) f,
        ];
      });
    }, exito: 'Foto borrada.');
  }

  void _reemplazarAjuste(AjusteSitio nuevo) {
    setState(() {
      _ajustesSitio = [
        for (final a in _ajustesSitio) a.clave == nuevo.clave ? nuevo : a,
      ];
    });
  }

  Future<void> _subirFotoSitio(String clave) async {
    if (!_hayAdmin()) return;
    final foto = await _elegirFoto();
    if (foto == null) return;
    final ajuste = _ajustesSitio.firstWhere((a) => a.clave == clave);
    await _accionFotos(
      () async {
        _reemplazarAjuste(
          await widget.admin!.subirFotoSitio(ajuste: ajuste, foto: foto),
        );
      },
      clave: clave,
      exito: _clavesSitioEnUso.contains(clave)
          ? 'Foto guardada. Ya se ve en la tienda.'
          : 'Foto guardada.',
    );
  }

  Future<void> _quitarFotoSitio(String clave) async {
    if (!_hayAdmin()) return;
    final ajuste = _ajustesSitio.firstWhere((a) => a.clave == clave);
    await _accionFotos(
      () async {
        _reemplazarAjuste(await widget.admin!.quitarFotoSitio(ajuste));
      },
      clave: clave,
      exito: 'Foto quitada.',
    );
  }

  // -------------------------------------------------------------- avisos
  void _aviso(String texto) {
    final mensajes = ScaffoldMessenger.of(context);
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            texto,
            style: TinaTipografia.estilo(
              tamano: 14,
              peso: FontWeight.w800,
              color: TinaColores.blanco,
            ),
          ),
          backgroundColor: TinaColores.tinta,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          // En pantallas anchas el aviso no se estira de lado a lado.
          width: esEscritorio(context) ? 440 : null,
          duration: const Duration(milliseconds: 2800),
        ),
      );
  }

  // ----------------------------------------------------------- navegación
  void _empujar(Ruta ruta) => setState(() => _pila = [..._pila, ruta]);

  void _raiz(Ruta ruta) => setState(() => _pila = [ruta]);

  void _volver() {
    if (_pila.length > 1) {
      setState(() => _pila = _pila.sublist(0, _pila.length - 1));
    }
  }

  void _irInicio() {
    _categoriaActiva = null;
    _raiz(Ruta.inicio);
  }

  void _irCarrito() => _raiz(Ruta.carrito);

  void _irCuenta() {
    _authError = null;
    _raiz(_sesion == null ? Ruta.login : Ruta.cuenta);
  }

  void _onNav(DestinoNav destino) {
    switch (destino) {
      case DestinoNav.inicio:
        _irInicio();
      case DestinoNav.categorias:
        _categoriaActiva ??= _categorias.first.nombre;
        _raiz(Ruta.lista);
      case DestinoNav.carrito:
        _irCarrito();
      case DestinoNav.cuenta:
        _irCuenta();
    }
  }

  void _onCategoria(String? categoria) {
    if (categoria == null) {
      _irInicio();
    } else {
      _categoriaActiva = categoria;
      _raiz(Ruta.lista);
    }
  }

  // -------------------------------------------------------------- detalle
  void _abrirProducto(int idProducto) {
    final vista = _vista(
      _productos.firstWhere((p) => p.idProducto == idProducto),
    );
    // Empieza por la primera variante con stock.
    final inicial = vista.variantes.firstWhere(
      (v) => v.stock > 0,
      orElse: () => vista.variantes.first,
    );
    _idProducto = idProducto;
    _color = inicial.color;
    _talla = inicial.talla;
    _cantidad = 1;
    _foto = 0;
    _empujar(Ruta.detalle);
  }

  int _limitarCantidad(int cantidad, int stock) =>
      cantidad.clamp(1, stock < 1 ? 1 : stock);

  void _elegirColor(String color) {
    final vista = _vistaDetalle;
    final tallas = vista.tallasDe(color);
    setState(() {
      _color = color;
      _foto = 0;
      if (!tallas.contains(_talla)) _talla = tallas.first;
      _cantidad = _limitarCantidad(_cantidad, vista.stockDe(_color, _talla));
    });
  }

  void _elegirTalla(String talla) {
    setState(() {
      _talla = talla;
      _cantidad = _limitarCantidad(
        _cantidad,
        _vistaDetalle.stockDe(_color, _talla),
      );
    });
  }

  void _agregarAlCarrito() {
    final vista = _vistaDetalle;
    final variante = vista.variante(_color, _talla);
    if (variante == null || variante.stock < 1) {
      _aviso('Esa combinación está agotada.');
      return;
    }

    final existente = _items
        .where((i) => i.idVariante == variante.idVariante)
        .firstOrNull;
    final yaTiene = existente?.cantidad ?? 0;
    final nueva = yaTiene + _cantidad;
    if (nueva > variante.stock) {
      _aviso('Solo quedan ${variante.stock} de ${vista.producto.nombre}.');
      return;
    }

    setState(() {
      if (existente == null) {
        _items = [
          ..._items,
          CarritoItem(
            idItem: _siguienteItem++,
            idCarrito: 1,
            idVariante: variante.idVariante,
            cantidad: _cantidad,
          ),
        ];
      } else {
        _items = [
          for (final i in _items)
            i.idItem == existente.idItem ? i.copyWith(cantidad: nueva) : i,
        ];
      }
    });
    _aviso('Agregaste $_cantidad × ${vista.producto.nombre} al carrito.');
    _raiz(Ruta.carrito);
  }

  // -------------------------------------------------------------- carrito
  void _cambiarCantidadItem(int idItem, int cantidad) {
    setState(() {
      _items = [
        for (final i in _items)
          i.idItem == idItem ? i.copyWith(cantidad: cantidad) : i,
      ];
    });
  }

  void _quitarItem(int idItem) {
    setState(
      () => _items = [
        for (final i in _items)
          if (i.idItem != idItem) i,
      ],
    );
    _aviso('Quitaste el producto del carrito.');
  }

  void _irCheckout() {
    // Si hay sesión, rellena los datos que ya conocemos.
    final c = _sesion;
    if (c != null) {
      if ((_datosEnvio['nombre'] ?? '').isEmpty) {
        _datosEnvio['nombre'] = c.nombre;
      }
      if ((_datosEnvio['correo'] ?? '').isEmpty) {
        _datosEnvio['correo'] = c.correo;
      }
      if ((_datosEnvio['telefono'] ?? '').isEmpty && c.telefono.isNotEmpty) {
        _datosEnvio['telefono'] = c.telefono;
      }
    }
    _mostrarErrores = false;
    _empujar(Ruta.checkout);
  }

  void _elegirModo(ModoCompra modo) {
    if (modo == ModoCompra.cuenta && _sesion == null) {
      _loginDesdeCheckout = true;
      _authError = null;
      _empujar(Ruta.login);
      return;
    }
    setState(() => _modo = modo);
  }

  void _elegirMetodo(MetodoPago metodo) => setState(() => _metodoPago = metodo);

  void _escribirEnvio(String clave, String valor) {
    setState(() => _datosEnvio[clave] = valor);
  }

  // -------------------------------------------------------- pedidos reales
  /// Lee de Supabase los pedidos que esta persona puede ver y reemplaza los de
  /// la memoria. Sin sesión no hay nada que leer.
  Future<void> _cargarPedidos({
    Cliente? cliente,
    bool? esAdministradora,
  }) async {
    final repo = widget.pedidos;
    final quien = cliente ?? _sesion;
    if (repo == null || quien == null) return;
    try {
      final datos = await repo.cargar(
        esAdministradora: esAdministradora ?? _esAdmin,
      );
      if (!mounted) return;
      setState(() {
        _pedidos = [...datos.pedidos];
        _detalles = [...datos.detalles];
        _envios = [...datos.envios];
        _pagos = [...datos.pagos];
        _comprobantes = [...datos.comprobantes];
        _historial = [...datos.historial];
        _usuarios = [...datos.usuarios];
        _clientes = [
          for (final c in datos.clientes)
            if (c.idCliente != quien.idCliente) c,
          quien,
        ];
      });
    } catch (error) {
      debugPrint('No se pudieron leer los pedidos: $error');
    }
  }

  /// Crea el pedido en la base de datos y muestra la confirmación.
  Future<void> _pagarReal() async {
    final repo = widget.pedidos!;
    final metodo = _metodoEfectivo;
    if (metodo != MetodoPago.contraentrega && !widget.pagoEnLinea) {
      _aviso(
        'El pago en línea estará disponible muy pronto. '
        'Si estás en Cali, puedes elegir contraentrega.',
      );
      return;
    }
    if (_comprando) return;
    setState(() => _comprando = true);

    final resumen = _resumen;
    final nombre = _datosEnvio['nombre']!.trim();
    final correo = _datosEnvio['correo']!.trim();
    final telefono = _datosEnvio['telefono']!.trim();
    final envio = DatosEnvio(
      nombreDestinatario: nombre,
      telefono: telefono,
      departamento: _datosEnvio['departamento']!.trim(),
      ciudad: _datosEnvio['ciudad']!.trim(),
      direccion: _datosEnvio['direccion']!.trim(),
    );

    try {
      final creado = await repo.crear(
        lineas: [
          for (final l in resumen.lineas)
            LineaPedidoNueva(
              idVariante: l.variante.idVariante,
              cantidad: l.item.cantidad,
            ),
        ],
        envio: envio,
        compradora: DatosCompradora(
          nombre: nombre,
          correo: correo,
          telefono: telefono,
        ),
        metodo: metodo,
      );
      if (!mounted) return;

      // Pago en línea: el pedido ya existe y tiene el stock apartado. Se abre la
      // página de pago de Wompi; la clienta vuelve cuando termine.
      if (metodo != MetodoPago.contraentrega) {
        await _irAPagarEnWompi(
          creado.idPedido,
          creado.token,
          cancelarSiFalla: true,
        );
        return;
      }

      // Lo que se muestra en la confirmación, armado con lo que respondió la
      // base de datos. Si hay sesión, enseguida se vuelve a leer todo de allí.
      final ahora = DateTime.now();
      final comprador =
          _sesion ??
          Cliente(
            idCliente: creado.idCliente,
            nombre: nombre,
            correo: correo,
            telefono: telefono,
            cuentaRegistrada: false,
            fechaRegistro: ahora,
          );
      final id = creado.idPedido;
      setState(() {
        _clientes = [
          for (final c in _clientes)
            if (c.idCliente != comprador.idCliente) c,
          comprador,
        ];
        _pedidos = [
          Pedido(
            idPedido: id,
            idCliente: comprador.idCliente,
            idPromocion: resumen.promocion?.idPromocion,
            fecha: ahora,
            estadoActual: EstadoPedido.pendiente,
            subtotal: creado.subtotal,
            descuento: creado.descuento,
            total: creado.total,
            metodoPago: metodo,
          ),
          ..._pedidos.where((p) => p.idPedido != id),
        ];
        _detalles = [
          for (var i = 0; i < resumen.lineas.length; i++)
            DetallePedido(
              idDetalle: id * 1000 + i,
              idPedido: id,
              idVariante: resumen.lineas[i].variante.idVariante,
              cantidad: resumen.lineas[i].item.cantidad,
              precioUnitario: resumen.lineas[i].producto.precio,
              subtotal: resumen.lineas[i].total,
            ),
          ..._detalles.where((d) => d.idPedido != id),
        ];
        _envios = [
          Envio(
            idEnvio: id,
            idPedido: id,
            nombreDestinatario: envio.nombreDestinatario,
            telefono: envio.telefono,
            departamento: envio.departamento,
            ciudad: envio.ciudad,
            direccion: envio.direccion,
            costo: creado.costoEnvio,
          ),
          ..._envios.where((e) => e.idPedido != id),
        ];
        _pagos = [
          Pago(
            idPago: id,
            idPedido: id,
            monto: creado.total,
            estado: 'pendiente',
            fecha: ahora,
            proveedor: metodo.valorBd,
          ),
          ..._pagos.where((p) => p.idPedido != id),
        ];
        _historial = [
          HistorialEstado(
            idHistorial: id * 10,
            idPedido: id,
            idUsuario: 0,
            estadoNuevo: EstadoPedido.pendiente.name,
            notificado: false,
            fecha: ahora,
          ),
          ..._historial.where((h) => h.idPedido != id),
        ];
        _items = [];
        _metodoPago = MetodoPago.wompi;
        _ultimoPedido = id;
        _mostrarErrores = false;
        _pila = [Ruta.inicio, Ruta.confirmacion];
      });

      // La contraentrega queda lista al crearse: se le avisa a la vendedora por
      // WhatsApp. (Los pagos con Wompi los avisa el servidor al aprobarse.) No
      // se espera la respuesta y nunca estorba la compra.
      final llave = creado.token;
      if (llave != null) unawaited(repo.avisarPedido(creado.idPedido, llave));

      // El stock cambió en la base de datos: se vuelve a leer.
      _cargarCatalogo();
      _cargarPedidos();
    } on ErrorPedido catch (e) {
      if (!mounted) return;
      _aviso(e.mensaje);
      // Si faltó stock, lo que ve la clienta ya no es lo real: se actualiza.
      _cargarCatalogo();
    } finally {
      if (mounted) setState(() => _comprando = false);
    }
  }

  /// Pide el enlace de pago y manda a la clienta a Wompi. Si no se puede abrir y
  /// el pedido es nuevo ([cancelarSiFalla]), se cancela para devolver el stock.
  /// Devuelve `true` si salió hacia Wompi.
  Future<bool> _irAPagarEnWompi(
    int idPedido,
    String? token, {
    required bool cancelarSiFalla,
  }) async {
    final repo = widget.pedidos!;
    final itemsPrevios = _items;
    try {
      if (token == null) {
        throw const ErrorPedido('No pudimos abrir la página de pago.');
      }
      final url = await repo.iniciarPagoWompi(idPedido, token);
      // El carrito ya se volvió pedido: se vacía antes de salir.
      if (mounted && cancelarSiFalla) setState(() => _items = []);
      await widget.abrirUrl(url);
      return true;
    } on ErrorPedido catch (e) {
      if (mounted) _aviso(e.mensaje);
    } catch (_) {
      if (mounted) _aviso('No pudimos abrir la página de pago.');
    }
    if (cancelarSiFalla && token != null) {
      try {
        await repo.cancelarPedidoPropio(idPedido, token);
      } catch (_) {
        // El pedido queda pendiente; la vendedora puede cancelarlo desde el panel.
      }
      if (mounted) setState(() => _items = itemsPrevios);
      _cargarCatalogo();
    }
    return false;
  }

  /// Después de pagar, pregunta a la base de datos cómo quedó el pago. Wompi
  /// avisa a la tienda por su cuenta, así que puede tardar unos segundos.
  Future<void> _verificarPago() async {
    final repo = widget.pedidos!;
    final id = _retornoId!;
    final token = _retornoToken!;
    const intentos = 8;
    for (var i = 0; i < intentos; i++) {
      try {
        final estado = await repo.consultarEstado(id, token);
        if (!mounted) return;
        setState(() {
          _retornoEstado = estado;
          _retornoSinConexion = false;
        });
        if (!estado.esperando) break;
      } on ErrorPedido {
        if (!mounted) return;
        setState(() => _retornoSinConexion = true);
        break;
      }
      if (i < intentos - 1) await Future<void>.delayed(widget.pausaSondeo);
      if (!mounted) return;
    }
    setState(() => _retornoVerificando = false);
    if (_retornoEstado?.pagado ?? false) {
      // El stock y los pedidos cambiaron: se vuelven a leer.
      _cargarCatalogo();
      _cargarPedidos();
    }
  }

  void _revisarPagoOtraVez() {
    setState(() {
      _retornoVerificando = true;
      _retornoSinConexion = false;
    });
    _verificarPago();
  }

  /// El pago fue rechazado: abre otra vez Wompi con el mismo pedido.
  Future<void> _reintentarPago() async {
    if (_retornoReintentando) return;
    setState(() => _retornoReintentando = true);
    await _irAPagarEnWompi(_retornoId!, _retornoToken, cancelarSiFalla: false);
    if (mounted) setState(() => _retornoReintentando = false);
  }

  // ------------------------------------------------------------------ pago
  void _pagar() {
    if (_items.isEmpty) return;

    if (Validaciones.primerErrorEnvio(_datosEnvio) != null) {
      setState(() => _mostrarErrores = true);
      _aviso('Revisa los datos de envío.');
      return;
    }

    // El stock se vuelve a comprobar al pagar.
    final resumenActual = _resumen;
    final metodo = _metodoEfectivo;
    final pagaEnLinea = metodo != MetodoPago.contraentrega;
    for (final linea in resumenActual.lineas) {
      if (linea.item.cantidad > linea.variante.stock) {
        _aviso('Ya no hay stock suficiente de ${linea.producto.nombre}.');
        return;
      }
    }

    // Con pedidos reales, la base de datos crea el pedido y descuenta el stock.
    if (widget.pedidos != null) {
      _pagarReal();
      return;
    }

    final ahora = DateTime.now();
    final nombre = _datosEnvio['nombre']!.trim();
    final correo = _datosEnvio['correo']!.trim();
    final telefono = _datosEnvio['telefono']!.trim();

    // Quién compra: la clienta con sesión, una clienta que ya existe con ese
    // correo, o una fila nueva sin cuenta.
    var clientes = _clientes;
    Cliente cliente;
    if (_conCuenta) {
      cliente = _sesion!;
    } else {
      final existente = _clientes
          .where((c) => c.correo.toLowerCase() == correo.toLowerCase())
          .firstOrNull;
      if (existente != null) {
        cliente = existente;
      } else {
        cliente = Cliente(
          idCliente:
              _clientes.fold(0, (m, c) => c.idCliente > m ? c.idCliente : m) +
              1,
          nombre: nombre,
          correo: correo,
          telefono: telefono,
          cuentaRegistrada: false,
          fechaRegistro: ahora,
        );
        clientes = [..._clientes, cliente];
      }
    }

    final idPedido =
        _pedidos.fold(0, (m, p) => p.idPedido > m ? p.idPedido : m) + 1;
    final numero = idPedido.toString().padLeft(4, '0');
    final idDetalle = _detalles.fold(
      0,
      (m, d) => d.idDetalle > m ? d.idDetalle : m,
    );
    final idHistorial = _historial.fold(
      0,
      (m, h) => h.idHistorial > m ? h.idHistorial : m,
    );
    final ciudad = _datosEnvio['ciudad']!.trim();

    final pedido = Pedido(
      idPedido: idPedido,
      idCliente: cliente.idCliente,
      idPromocion: resumenActual.promocion?.idPromocion,
      fecha: ahora,
      estadoActual: pagaEnLinea ? EstadoPedido.pagado : EstadoPedido.pendiente,
      subtotal: resumenActual.subtotal,
      descuento: resumenActual.descuento,
      total: resumenActual.totalConEnvio,
      metodoPago: metodo,
    );

    final detallesNuevos = [
      for (var i = 0; i < resumenActual.lineas.length; i++)
        DetallePedido(
          idDetalle: idDetalle + i + 1,
          idPedido: idPedido,
          idVariante: resumenActual.lineas[i].variante.idVariante,
          cantidad: resumenActual.lineas[i].item.cantidad,
          // El precio se copia al detalle: un cambio de precio posterior no
          // altera este pedido.
          precioUnitario: resumenActual.lineas[i].producto.precio,
          subtotal: resumenActual.lineas[i].total,
        ),
    ];

    // En el modo de ejemplo el pago en línea siempre sale aprobado; la
    // contraentrega queda pendiente hasta que llegue la transferencia.
    final pago = Pago(
      idPago: _pagos.fold(0, (m, p) => p.idPago > m ? p.idPago : m) + 1,
      idPedido: idPedido,
      referencia: pagaEnLinea ? 'WMP-${48213 + idPedido}-$numero' : null,
      monto: pedido.total,
      estado: pagaEnLinea ? 'aprobado' : 'pendiente',
      fecha: ahora,
      proveedor: metodo.valorBd,
    );
    final comprobante = Comprobante(
      idComprobante:
          _comprobantes.fold(
            0,
            (m, c) => c.idComprobante > m ? c.idComprobante : m,
          ) +
          1,
      idPago: pago.idPago,
      numero: 'C-$numero',
      fechaEmision: ahora,
    );
    final envio = Envio(
      idEnvio: _envios.fold(0, (m, e) => e.idEnvio > m ? e.idEnvio : m) + 1,
      idPedido: idPedido,
      nombreDestinatario: nombre,
      telefono: telefono,
      departamento: _datosEnvio['departamento']!.trim(),
      ciudad: ciudad,
      direccion: _datosEnvio['direccion']!.trim(),
      costo: resumenActual.costoEnvio,
    );
    final historialNuevo = [
      HistorialEstado(
        idHistorial: idHistorial + 1,
        idPedido: idPedido,
        idUsuario: 2,
        estadoNuevo: EstadoPedido.pendiente.name,
        notificado: true,
        fecha: ahora,
      ),
      if (pagaEnLinea)
        HistorialEstado(
          idHistorial: idHistorial + 2,
          idPedido: idPedido,
          idUsuario: 2,
          estadoAnterior: EstadoPedido.pendiente.name,
          estadoNuevo: EstadoPedido.pagado.name,
          notificado: true,
          fecha: ahora,
        ),
    ];

    // El stock baja por cada unidad comprada.
    final descuentoStock = {
      for (final l in resumenActual.lineas)
        l.variante.idVariante: l.item.cantidad,
    };

    setState(() {
      _clientes = clientes;
      _pedidos = [..._pedidos, pedido];
      _detalles = [..._detalles, ...detallesNuevos];
      _pagos = [..._pagos, pago];
      if (pagaEnLinea) _comprobantes = [..._comprobantes, comprobante];
      _envios = [..._envios, envio];
      _historial = [..._historial, ...historialNuevo];
      _variantes = [
        for (final v in _variantes)
          descuentoStock.containsKey(v.idVariante)
              ? v.copyWith(stock: v.stock - descuentoStock[v.idVariante]!)
              : v,
      ];
      _items = [];
      _metodoPago = MetodoPago.wompi;
      _ultimoPedido = idPedido;
      _mostrarErrores = false;
      _pila = [Ruta.inicio, Ruta.confirmacion];
    });
  }

  // ---------------------------------------------------------------- sesión
  void _escribirAuth(String clave, String valor) {
    setState(() {
      switch (clave) {
        case 'nombre':
          _authNombre = valor;
        case 'correo':
          _authCorreo = valor;
        case 'clave':
          _authClave = valor;
      }
      _authError = null;
    });
  }

  void _alternarRegistro() {
    setState(() {
      _registro = !_registro;
      _authError = null;
    });
  }

  void _entrar() {
    final correo = _authCorreo.trim();
    // Cada campo vacío avisa con su propio mensaje.
    final String? error;
    if (_registro && Validaciones.obligatorio(_authNombre) != null) {
      error = 'Escribe tu nombre.';
    } else if (correo.isEmpty) {
      error = 'Escribe tu correo.';
    } else {
      error =
          Validaciones.correo(correo) ?? Validaciones.contrasena(_authClave);
    }
    if (error != null) {
      setState(() => _authError = error);
      return;
    }

    // Con cuentas reales, Supabase decide; abajo sigue el modo de ejemplo.
    if (widget.sesiones != null) {
      _entrarConCuenta(correo);
      return;
    }

    final existente = _clientes
        .where((c) => c.correo.toLowerCase() == correo.toLowerCase())
        .firstOrNull;

    Cliente cliente;
    if (_registro) {
      if (existente != null && existente.cuentaRegistrada) {
        setState(() => _authError = 'Ya existe una cuenta con ese correo.');
        return;
      }
      final ahora = DateTime.now();
      cliente = Cliente(
        // Si ya compró como invitada, su fila se convierte en cuenta.
        idCliente:
            existente?.idCliente ??
            _clientes.fold(0, (m, c) => c.idCliente > m ? c.idCliente : m) + 1,
        nombre: _authNombre.trim(),
        correo: correo,
        telefono: existente?.telefono ?? '',
        cuentaRegistrada: true,
        fechaRegistro: existente?.fechaRegistro ?? ahora,
        fechaUltimoInicioSesion: ahora,
      );
      _clientes = [
        for (final c in _clientes)
          c.idCliente == cliente.idCliente ? cliente : c,
        if (existente == null) cliente,
      ];
    } else {
      if (existente == null || !existente.cuentaRegistrada) {
        setState(
          () => _authError = 'No encontramos una cuenta con ese correo.',
        );
        return;
      }
      cliente = existente;
    }

    _completarEntrada(cliente);
  }

  /// Lo que pasa cuando una clienta ya entró: va a la tienda o vuelve a su
  /// compra.
  void _completarEntrada(Cliente cliente) {
    setState(() {
      _sesion = cliente;
      _modo = ModoCompra.cuenta;
      _authNombre = '';
      _authCorreo = '';
      _authClave = '';
      _authError = null;
      _registro = false;
      _introPendiente = true;
    });

    if (_loginDesdeCheckout) {
      _aviso('Hola, ${cliente.nombre}.');
      _loginDesdeCheckout = false;
      // Al volver al checkout se rellenan los datos que ya conocemos y se
      // limpian los avisos de campos vacíos.
      setState(() {
        _mostrarErrores = false;
        if ((_datosEnvio['nombre'] ?? '').isEmpty) {
          _datosEnvio['nombre'] = cliente.nombre;
        }
        if ((_datosEnvio['correo'] ?? '').isEmpty) {
          _datosEnvio['correo'] = cliente.correo;
        }
        if ((_datosEnvio['telefono'] ?? '').isEmpty &&
            cliente.telefono.isNotEmpty) {
          _datosEnvio['telefono'] = cliente.telefono;
        }
      });
      _volver();
    } else {
      // La intro da la bienvenida al llegar a la portada.
      _irInicio();
    }
  }

  void _cerrarSesion() {
    final repo = widget.sesiones;
    if (repo != null) {
      repo.cerrarSesion().catchError((Object error) {
        debugPrint('Error al cerrar la sesión: $error');
      });
    }
    setState(() {
      _sesion = null;
      _esAdmin = false;
      _modo = ModoCompra.invitada;
      _introPendiente = false;
    });
    _irInicio();
  }

  void _atrasDeLogin() {
    if (_loginDesdeCheckout) {
      _loginDesdeCheckout = false;
      _volver();
    } else {
      _irInicio();
    }
  }

  // ----------------------------------------------------------------- panel
  Future<void> _cambiarEstadoReal(int idPedido, EstadoPedido nuevo) async {
    final completo = _pedidosCompletos.firstWhere(
      (p) => p.pedido.idPedido == idPedido,
    );
    if (completo.pedido.estadoActual == nuevo) return;
    try {
      await widget.pedidos!.cambiarEstado(idPedido, nuevo);
      if (!mounted) return;
      await _cargarPedidos();
      // Al cancelar, el stock vuelve: se actualiza el catálogo.
      if (nuevo == EstadoPedido.cancelado) _cargarCatalogo();
      if (!mounted) return;
      _aviso('${completo.pedido.codigo} ahora está: ${nuevo.etiqueta}.');
    } on ErrorPedido catch (e) {
      if (!mounted) return;
      _aviso(e.mensaje);
      // La lista se vuelve a leer para que el selector muestre el estado real.
      _cargarPedidos();
    }
  }

  void _cambiarEstado(int idPedido, EstadoPedido nuevo) {
    if (widget.pedidos != null) {
      _cambiarEstadoReal(idPedido, nuevo);
      return;
    }
    final completo = _pedidosCompletos.firstWhere(
      (p) => p.pedido.idPedido == idPedido,
    );
    final anterior = completo.pedido.estadoActual;
    if (anterior == nuevo) return;

    final ahora = DateTime.now();
    final idHistorial = _historial.fold(
      0,
      (m, h) => h.idHistorial > m ? h.idHistorial : m,
    );

    setState(() {
      _pedidos = [
        for (final p in _pedidos)
          p.idPedido == idPedido ? p.copyWith(estadoActual: nuevo) : p,
      ];

      // Cada cambio de estado deja un registro con quién lo hizo.
      _historial = [
        ..._historial,
        HistorialEstado(
          idHistorial: idHistorial + 1,
          idPedido: idPedido,
          idUsuario: 1,
          estadoAnterior: anterior.name,
          estadoNuevo: nuevo.name,
          notificado: true,
          fecha: ahora,
        ),
      ];

      // Al despachar se asigna una guía.
      if (nuevo == EstadoPedido.enviado) {
        _envios = [
          for (final e in _envios)
            e.idPedido == idPedido && e.guia == null
                ? Envio(
                    idEnvio: e.idEnvio,
                    idPedido: e.idPedido,
                    nombreDestinatario: e.nombreDestinatario,
                    telefono: e.telefono,
                    departamento: e.departamento,
                    ciudad: e.ciudad,
                    direccion: e.direccion,
                    costo: e.costo,
                    guia: 'GUIA-48${idPedido.toString().padLeft(5, '0')}',
                  )
                : e,
        ];
      }

      // Al cancelar, el stock vuelve al catálogo.
      if (nuevo == EstadoPedido.cancelado) {
        final devolver = {
          for (final d in _detalles.where((d) => d.idPedido == idPedido))
            d.idVariante: d.cantidad,
        };
        _variantes = [
          for (final v in _variantes)
            devolver.containsKey(v.idVariante)
                ? v.copyWith(stock: v.stock + devolver[v.idVariante]!)
                : v,
        ];
      }
    });

    _aviso(
      '${completo.pedido.codigo} ahora está: ${nuevo.etiqueta}. '
      'Avisamos a ${completo.cliente.nombre.split(' ').first} por correo y WhatsApp.',
    );
  }

  void _verPedido(int idPedido) {
    _idPedidoVer = idPedido;
    _empujar(Ruta.pedido);
  }

  // ----------------------------------------------------------------- build
  Page<void> _pagina(Ruta ruta) {
    final Widget hijo = switch (ruta) {
      Ruta.inicio => InicioPage(
        fotoPortada: _urlSitio('portada_inicio'),
        productos: _vistas(),
        categorias: _nombresCategorias,
        promociones: _promociones,
        unidadesCarrito: _unidades,
        onProducto: _abrirProducto,
        onCategoria: _onCategoria,
        onCarrito: _irCarrito,
        onLogo: _irInicio,
        onNav: _onNav,
      ),
      Ruta.lista => ListaPage(
        onLogo: _irInicio,
        categoriaActiva: _categoriaActiva ?? _categorias.first.nombre,
        categorias: _nombresCategorias,
        productos: _vistas(
          categoria: _categoriaActiva ?? _categorias.first.nombre,
        ),
        unidadesCarrito: _unidades,
        onProducto: _abrirProducto,
        onCategoria: _onCategoria,
        onAtras: _irInicio,
        onCarrito: _irCarrito,
        onNav: _onNav,
      ),
      Ruta.detalle => DetallePage(
        onNav: _onNav,
        vista: _vistaDetalle,
        promociones: _promociones,
        color: _color,
        talla: _talla,
        cantidad: _cantidad,
        foto: _foto,
        unidadesCarrito: _unidades,
        onAtras: _volver,
        onCarrito: _irCarrito,
        onLogo: _irInicio,
        onColor: _elegirColor,
        onTalla: _elegirTalla,
        onCantidad: (n) => setState(() => _cantidad = n),
        onFoto: (i) => setState(() => _foto = i),
        onAgregar: _agregarAlCarrito,
      ),
      Ruta.carrito => CarritoPage(
        onLogo: _irInicio,
        fotos: _fotosPrincipales,
        resumen: _resumen,
        promociones: _promociones,
        nota: Calculos.notaDescuento(
          resumen: _resumen,
          promociones: _promociones,
          conCuenta: _aplicaPrimeraCompra,
        ),
        conCuenta: _aplicaPrimeraCompra,
        onCantidad: _cambiarCantidadItem,
        onQuitar: _quitarItem,
        onContinuar: _irCheckout,
        onVerAccesorios: _irInicio,
        onAtras: _irInicio,
        onNav: _onNav,
      ),
      Ruta.checkout => CheckoutPage(
        onLogo: _irInicio,
        onNav: _onNav,
        resumen: _resumen,
        promociones: _promociones,
        modo: _conCuenta ? ModoCompra.cuenta : _modo,
        haySesion: _sesion != null,
        valores: _datosEnvio,
        mostrarErrores: _mostrarErrores,
        metodo: _metodoEfectivo,
        puedeContraentrega: _puedeContraentrega,
        ocupado: _comprando,
        onMetodo: _elegirMetodo,
        onModo: _elegirModo,
        onCampo: _escribirEnvio,
        onPagar: _pagar,
        onAtras: _volver,
        onCarrito: _irCarrito,
      ),
      Ruta.confirmacion => _confirmacion(),
      Ruta.login => _login(),
      Ruta.cuenta => CuentaPage(
        onLogo: _irInicio,
        nombre: _sesion?.nombre ?? '',
        correo: _sesion?.correo ?? '',
        pedidos: [
          for (final p in _pedidosCompletos)
            if (p.cliente.idCliente == _sesion?.idCliente) p,
        ],
        unidadesCarrito: _unidades,
        onPedido: _verPedido,
        onCerrarSesion: _cerrarSesion,
        onPanel: _esAdmin ? _irAPanel : null,
        onAtras: _irInicio,
        onCarrito: _irCarrito,
        onNav: _onNav,
      ),
      Ruta.panel => _puedeVerPanel ? _panel() : _login(),
      Ruta.productoEditar =>
        _puedeVerPanel && _borrador != null ? _editorProducto() : _panel(),
      Ruta.pedido => PedidoPage(
        pedido: _pedidosCompletos.firstWhere(
          (p) => p.pedido.idPedido == _idPedidoVer,
        ),
        onAtras: _volver,
      ),
      Ruta.pagoRetorno => _pagoRetorno(),
    };
    return MaterialPage<void>(
      key: ValueKey(ruta),
      name: ruta.name,
      child: hijo,
    );
  }

  Widget _login() => LoginPage(
    onLogo: _irInicio,
    registro: _registro,
    nombre: _authNombre,
    correo: _authCorreo,
    clave: _authClave,
    error: _authError,
    textoPromocion: _promociones
        .firstWhere((p) => p.tipo == 'primera_compra')
        .nombre,
    unidadesCarrito: _unidades,
    onToggle: _alternarRegistro,
    onCampo: _escribirAuth,
    onEntrar: _entrar,
    // Con cuentas reales no hay acceso aparte: la administradora entra
    // por este mismo ingreso y va directo a su panel.
    onVendedora: widget.sesiones == null ? _irAPanel : null,
    ocupado: _authOcupado,
    mostrarPrueba: widget.sesiones == null,
    onAtras: _atrasDeLogin,
    onCarrito: _irCarrito,
    onNav: _onNav,
  );

  Widget _confirmacion() {
    final completo = _pedidosCompletos.firstWhere(
      (p) => p.pedido.idPedido == _ultimoPedido,
    );
    return ConfirmacionPage(
      onNav: _onNav,
      codigoPedido: completo.pedido.codigo,
      numeroComprobante: completo.comprobante?.numero ?? '—',
      referenciaPago: completo.pago?.referencia ?? '—',
      contraentrega: completo.pedido.metodoPago == MetodoPago.contraentrega,
      totalPagado: formatoPesos(completo.pedido.total),
      unidadesCarrito: _unidades,
      onSeguir: _irInicio,
      onVerPedido: () => _verPedido(completo.pedido.idPedido),
      onLogo: _irInicio,
      onCarrito: _irCarrito,
    );
  }

  Widget _pagoRetorno() {
    final e = _retornoEstado;
    if (e != null && e.pagado) {
      return ConfirmacionPage(
        onNav: _onNav,
        codigoPedido: e.codigo,
        numeroComprobante: e.comprobante ?? '—',
        referenciaPago: e.referencia ?? '—',
        totalPagado: formatoPesos(e.total),
        unidadesCarrito: _unidades,
        onSeguir: _irInicio,
        // Sin cuenta no hay dónde ver el pedido; solo se ofrece con sesión.
        onVerPedido: _sesion == null ? null : () => _onNav(DestinoNav.cuenta),
        onLogo: _irInicio,
        onCarrito: _irCarrito,
      );
    }
    return PagoRetornoPage(
      estado: e,
      verificando: _retornoVerificando,
      sinConexion: _retornoSinConexion,
      reintentando: _retornoReintentando,
      unidadesCarrito: _unidades,
      onReintentarPago: _reintentarPago,
      onRevisar: _revisarPagoOtraVez,
      onSeguir: _irInicio,
      onLogo: _irInicio,
      onCarrito: _irCarrito,
      onNav: _onNav,
    );
  }

  Widget _panel() {
    switch (_seccionPanel) {
      case SeccionPanel.pedidos:
        final todos = _pedidosCompletos;
        return PanelPage(
          pedidos: [
            for (final p in todos)
              if (_filtro == null || p.pedido.estadoActual == _filtro) p,
          ],
          totalPedidos: todos.length,
          conteoPorEstado: {
            for (final e in EstadoPedido.values)
              e: todos.where((p) => p.pedido.estadoActual == e).length,
          },
          filtro: _filtro,
          onFiltro: (e) => setState(() => _filtro = e),
          onCambiarEstado: _cambiarEstado,
          onPedido: _verPedido,
          onVerTienda: _irInicio,
          onSeccion: (s) => setState(() => _seccionPanel = s),
          onSalir: widget.sesiones == null ? null : _cerrarSesion,
        );
      case SeccionPanel.datos:
        return PanelDatosPage(
          metricas: Metricas.calcular(
            pedidos: _pedidos,
            detalles: _detalles,
            variantes: _variantes,
            productos: _productos,
            envios: _envios,
          ),
          onSeccion: (s) => setState(() => _seccionPanel = s),
          onVerTienda: _irInicio,
          onSalir: widget.sesiones == null ? null : _cerrarSesion,
        );
      case SeccionPanel.productos:
        return PanelProductosPage(
          productos: _vistasAdmin(),
          ocupado: _fotosOcupado,
          onSeccion: (s) => setState(() => _seccionPanel = s),
          onNuevo: _nuevoProducto,
          onEditar: _editarProducto,
          onAlternar: _alternarVisible,
          onVerTienda: _irInicio,
          onSalir: widget.sesiones == null ? null : _cerrarSesion,
        );
      case SeccionPanel.fotosArticulos:
        return PanelFotosArticulosPage(
          productos: _productos,
          idProducto: _productoFotos,
          fotos: _fotosDelProducto,
          ocupado: _fotosOcupado,
          onSeccion: (s) => setState(() => _seccionPanel = s),
          onElegirProducto: (id) => setState(() => _idProductoFotos = id),
          onSubir: _subirFotoProducto,
          onMover: _moverFoto,
          onPrincipal: _hacerPrincipal,
          onBorrar: _borrarFotoProducto,
          onSalir: _cerrarSesion,
          onVerTienda: _irInicio,
        );
      case SeccionPanel.fotosSitio:
        return PanelFotosSitioPage(
          ajustes: _ajustesSitio,
          clavesEnUso: _clavesSitioEnUso,
          claveOcupada: _fotosOcupado ? (_claveSitioOcupada ?? '') : null,
          onSeccion: (s) => setState(() => _seccionPanel = s),
          onSubir: _subirFotoSitio,
          onQuitar: _quitarFotoSitio,
          onSalir: _cerrarSesion,
          onVerTienda: _irInicio,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // El botón "atrás" del sistema retrocede por la pila de rutas; solo sale
    // de la app cuando queda una pantalla.
    final mostrarIntro = _introPendiente && _pila.last == Ruta.inicio;
    return Stack(
      children: [
        Positioned.fill(
          child: PopScope(
            canPop: _pila.length <= 1,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _volver();
            },
            child: Navigator(
              pages: [for (final ruta in _pila) _pagina(ruta)],
              onDidRemovePage: (page) {
                if (_pila.length > 1 && page.key == ValueKey(_pila.last)) {
                  setState(() => _pila = _pila.sublist(0, _pila.length - 1));
                }
              },
            ),
          ),
        ),
        if (_cargandoCatalogo)
          const Positioned.fill(
            child: ColoredBox(
              key: ValueKey('cargando-catalogo'),
              color: TinaColores.crema,
              child: Center(
                child: CircularProgressIndicator(color: TinaColores.naranja),
              ),
            ),
          ),
        if (mostrarIntro)
          Positioned.fill(
            child: TinaIntro(
              key: const ValueKey('intro'),
              onTerminar: () => setState(() => _introPendiente = false),
            ),
          ),
      ],
    );
  }
}
