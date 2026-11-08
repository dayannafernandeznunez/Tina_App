import 'package:flutter/material.dart';

import '../components/components.dart';
import '../data/datos_simulados.dart';
import '../logic/calculos.dart';
import '../logic/validaciones.dart';
import '../logic/vistas.dart';
import '../models/models.dart';
import '../pages/carrito_page.dart';
import '../pages/checkout_page.dart';
import '../pages/confirmacion_page.dart';
import '../pages/cuenta_page.dart';
import '../pages/detalle_page.dart';
import '../pages/inicio_page.dart';
import '../pages/lista_page.dart';
import '../pages/login_page.dart';
import '../pages/panel_page.dart';
import '../pages/pedido_page.dart';
import '../theme/tina_tema.dart';
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
  pedido,
}

/// Screen anfitriona de la app.
///
/// Todo el estado vive aquí: el catálogo con su stock, el carrito, los
/// pedidos, la sesión, la selección del detalle y los formularios. Las Pages
/// solo muestran lo que reciben y reportan cada interacción con un callback;
/// ninguna guarda datos de la app por su cuenta.
class TinaScreen extends StatefulWidget {
  const TinaScreen({super.key});

  @override
  State<TinaScreen> createState() => _TinaScreenState();
}

class _TinaScreenState extends State<TinaScreen> {
  // ---------------------------------------------------------------- datos
  // Copias de los datos simulados: aquí es donde cambian al usar la app.
  final List<Categoria> _categorias = [...DatosSimulados.categorias];
  final List<Producto> _productos = [...DatosSimulados.productos];
  final List<Promocion> _promociones = [...DatosSimulados.promociones];
  final List<Usuario> _usuarios = [...DatosSimulados.usuarios];

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

  // ------------------------------------------------------------ derivados
  int get _unidades => _items.fold(0, (s, i) => s + i.cantidad);

  bool get _conCuenta => _modo == ModoCompra.cuenta && _sesion != null;

  bool get _aplicaPrimeraCompra =>
      _conCuenta && Calculos.esPrimeraCompra(_sesion!.idCliente, _pedidos);

  ResumenCarrito get _resumen => Calculos.resumen(
    items: _items,
    variantes: _variantes,
    productos: _productos,
    promociones: _promociones,
    primeraCompra: _aplicaPrimeraCompra,
  );

  List<String> get _nombresCategorias => [
    for (final c in _categorias) c.nombre,
  ];

  ProductoVista _vista(Producto p) => ProductoVista(
    producto: p,
    categoria: _categorias
        .firstWhere((c) => c.idCategoria == p.idCategoria)
        .nombre,
    variantes: [
      for (final v in _variantes)
        if (v.idProducto == p.idProducto) v,
    ],
  );

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

  void _escribirEnvio(String clave, String valor) {
    setState(() => _datosEnvio[clave] = valor);
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
    for (final linea in resumenActual.lineas) {
      if (linea.item.cantidad > linea.variante.stock) {
        _aviso('Ya no hay stock suficiente de ${linea.producto.nombre}.');
        return;
      }
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
      estadoActual: EstadoPedido.pagado,
      subtotal: resumenActual.subtotal,
      descuento: resumenActual.descuento,
      total: resumenActual.total,
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

    // El pago de la prueba siempre sale aprobado.
    final pago = Pago(
      idPago: _pagos.fold(0, (m, p) => p.idPago > m ? p.idPago : m) + 1,
      idPedido: idPedido,
      referenciaWompi: 'WMP-${48213 + idPedido}-$numero',
      monto: pedido.total,
      estado: 'aprobado',
      fecha: ahora,
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
      costo: Calculos.costoEnvio(ciudad),
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
      _comprobantes = [..._comprobantes, comprobante];
      _envios = [..._envios, envio];
      _historial = [..._historial, ...historialNuevo];
      _variantes = [
        for (final v in _variantes)
          descuentoStock.containsKey(v.idVariante)
              ? v.copyWith(stock: v.stock - descuentoStock[v.idVariante]!)
              : v,
      ];
      _items = [];
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
    setState(() {
      _sesion = null;
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
  void _cambiarEstado(int idPedido, EstadoPedido nuevo) {
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
        modo: _modo,
        haySesion: _sesion != null,
        valores: _datosEnvio,
        mostrarErrores: _mostrarErrores,
        onModo: _elegirModo,
        onCampo: _escribirEnvio,
        onPagar: _pagar,
        onAtras: _volver,
        onCarrito: _irCarrito,
      ),
      Ruta.confirmacion => _confirmacion(),
      Ruta.login => LoginPage(
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
        onVendedora: () => _empujar(Ruta.panel),
        onAtras: _atrasDeLogin,
        onCarrito: _irCarrito,
        onNav: _onNav,
      ),
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
        onAtras: _irInicio,
        onCarrito: _irCarrito,
        onNav: _onNav,
      ),
      Ruta.panel => _panel(),
      Ruta.pedido => PedidoPage(
        pedido: _pedidosCompletos.firstWhere(
          (p) => p.pedido.idPedido == _idPedidoVer,
        ),
        onAtras: _volver,
      ),
    };
    return MaterialPage<void>(
      key: ValueKey(ruta),
      name: ruta.name,
      child: hijo,
    );
  }

  Widget _confirmacion() {
    final completo = _pedidosCompletos.firstWhere(
      (p) => p.pedido.idPedido == _ultimoPedido,
    );
    return ConfirmacionPage(
      onNav: _onNav,
      codigoPedido: completo.pedido.codigo,
      numeroComprobante: completo.comprobante?.numero ?? '—',
      referenciaPago: completo.pago?.referenciaWompi ?? '—',
      totalPagado: formatoPesos(completo.pedido.total),
      unidadesCarrito: _unidades,
      onSeguir: _irInicio,
      onVerPedido: () => _verPedido(completo.pedido.idPedido),
      onLogo: _irInicio,
      onCarrito: _irCarrito,
    );
  }

  Widget _panel() {
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
    );
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
