import 'package:flutter/material.dart';

import '../components/components.dart';
import '../data/datos_simulados.dart';
import '../pages/galeria_page.dart';

/// Screen anfitriona de la galería: aquí vive el estado (color, talla,
/// cantidad, destino y unidades en el carrito) y la Page solo lo muestra.
class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  String _color = 'Naranja';
  String _talla = 'M';
  int _cantidad = 1;
  DestinoNav _destino = DestinoNav.inicio;
  int _unidadesCarrito = 0;

  @override
  Widget build(BuildContext context) {
    return GaleriaPage(
      productos: DatosSimulados.productos,
      categorias: DatosSimulados.categorias,
      variantes: DatosSimulados.variantes,
      color: _color,
      talla: _talla,
      cantidad: _cantidad,
      destino: _destino,
      unidadesCarrito: _unidadesCarrito,
      onColor: (valor) => setState(() => _color = valor),
      onTalla: (valor) => setState(() => _talla = valor),
      onCantidad: (valor) => setState(() => _cantidad = valor),
      onDestino: (valor) => setState(() => _destino = valor),
      onAgregar: () => setState(() => _unidadesCarrito += _cantidad),
    );
  }
}
