import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'datos_simulados.dart';

/// Todo lo que la tienda muestra y que la administradora puede cambiar: las
/// categorías, los productos con sus variantes y fotos, las promociones y las
/// fotos del sitio.
class Catalogo {
  const Catalogo({
    required this.categorias,
    required this.productos,
    required this.variantes,
    required this.promociones,
    this.imagenes = const [],
    this.ajustesSitio = const [],
  });

  final List<Categoria> categorias;
  final List<Producto> productos;
  final List<VarianteProducto> variantes;
  final List<Promocion> promociones;
  final List<ImagenProducto> imagenes;

  /// Los lugares del sitio donde la administradora puede poner una foto
  /// (`portada_inicio`, `logo`...), con la foto que tienen ahora.
  final List<AjusteSitio> ajustesSitio;
}

/// De dónde sale el catálogo. La app solo conoce esta interfaz, así que se
/// puede leer de Supabase o de los datos simulados (pruebas, sin conexión).
abstract class CatalogoRepositorio {
  Future<Catalogo> cargar();
}

/// Lee el catálogo desde las tablas de Supabase.
class CatalogoSupabase implements CatalogoRepositorio {
  CatalogoSupabase([SupabaseClient? cliente])
    : _cliente = cliente ?? Supabase.instance.client;

  final SupabaseClient _cliente;

  @override
  Future<Catalogo> cargar() async {
    final respuestas = await Future.wait<List<Map<String, dynamic>>>([
      _cliente
          .from('categoria')
          .select()
          .order('id_categoria', ascending: true),
      _cliente.from('producto').select().order('id_producto', ascending: true),
      _cliente
          .from('variante_producto')
          .select()
          .order('id_variante', ascending: true),
      _cliente
          .from('promocion')
          .select()
          .order('id_promocion', ascending: true),
      _cliente
          .from('imagen_producto')
          .select()
          .order('id_producto', ascending: true)
          .order('orden', ascending: true),
      _cliente.from('ajuste_sitio').select(),
    ]);

    return Catalogo(
      categorias: respuestas[0].map(Categoria.desdeMapa).toList(),
      productos: respuestas[1].map(Producto.desdeMapa).toList(),
      variantes: respuestas[2].map(VarianteProducto.desdeMapa).toList(),
      promociones: respuestas[3].map(Promocion.desdeMapa).toList(),
      imagenes: respuestas[4].map(ImagenProducto.desdeMapa).toList(),
      ajustesSitio: respuestas[5].map(AjusteSitio.desdeMapa).toList(),
    );
  }
}

/// Devuelve los datos simulados: sirve para las pruebas y para trabajar sin
/// conexión.
class CatalogoSimulado implements CatalogoRepositorio {
  const CatalogoSimulado();

  @override
  Future<Catalogo> cargar() async => Catalogo(
    categorias: DatosSimulados.categorias,
    productos: DatosSimulados.productos,
    variantes: DatosSimulados.variantes,
    promociones: DatosSimulados.promociones,
  );
}
