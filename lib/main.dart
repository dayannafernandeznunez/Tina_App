import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/administradora.dart';
import 'data/catalogo.dart';
import 'data/pedidos.dart';
import 'data/sesion.dart';
import 'screens/tina_screen.dart';
import 'theme/tina_tema.dart';
import 'utils/abrir_url.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.llavePublica,
  );
  runApp(
    TinaApp(
      catalogo: CatalogoSupabase(),
      sesiones: SesionSupabase(),
      pedidos: PedidosSupabase(),
      admin: AdministradoraSupabase(),
      // El pago en línea pasa por las funciones del servidor de Supabase
      // (iniciar-pago y wompi-eventos); ver supabase/LEEME.md para activarlas.
      pagoEnLinea: true,
    ),
  );
}

/// La app se adapta al ancho: en pantallas anchas (PC) usa barra superior con
/// enlaces, grillas de 4 columnas y dos columnas en detalle, carrito y
/// checkout; en pantallas angostas (celular) usa la navegación inferior.
class TinaApp extends StatelessWidget {
  /// Con [catalogo] la tienda lee de la nube; sin él, usa datos simulados
  /// (así funcionan las pruebas, sin red).
  const TinaApp({
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

  /// La dirección con la que se abrió la app (en las pruebas se pone a mano).
  final Uri? urlInicial;

  /// Espera entre una consulta y otra del estado del pago.
  final Duration pausaSondeo;

  final CatalogoRepositorio? catalogo;

  /// El inicio de sesión (clientas y administradora). Sin él, las cuentas son
  /// de ejemplo.
  final SesionRepositorio? sesiones;

  /// Crear y leer pedidos. Sin él, los pedidos viven solo en la memoria.
  final PedidosRepositorio? pedidos;

  /// Si el pago en línea con Wompi está conectado.
  final bool pagoEnLinea;

  /// Lo que solo puede hacer la administradora: cambiar fotos.
  final AdministradoraRepositorio? admin;

  final SelectorFotos selectorFotos;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tina',
      debugShowCheckedModeBanner: false,
      theme: TinaTema.crear(),
      home: TinaScreen(
        catalogo: catalogo,
        sesiones: sesiones,
        pedidos: pedidos,
        pagoEnLinea: pagoEnLinea,
        admin: admin,
        selectorFotos: selectorFotos,
        abrirUrl: abrirUrl,
        urlInicial: urlInicial,
        pausaSondeo: pausaSondeo,
      ),
    );
  }
}
