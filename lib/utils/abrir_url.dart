import 'package:url_launcher/url_launcher.dart';

/// Abre una dirección. En la web lo hace en la misma pestaña: así, cuando la
/// clienta termina de pagar en Wompi, vuelve a la tienda en esa misma pestaña.
typedef AbrirUrl = Future<void> Function(String url);

Future<void> abrirEnLaMismaPestana(String url) async {
  final abrio = await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
  if (!abrio) throw StateError('No se pudo abrir $url');
}

/// Abre una dirección en una pestaña nueva (WhatsApp, redes sociales): la
/// tienda se queda abierta donde estaba.
Future<void> abrirEnPestanaNueva(String url) async {
  await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
}
