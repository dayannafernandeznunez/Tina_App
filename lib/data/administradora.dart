import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Un problema que se le puede mostrar tal cual a la administradora.
class ErrorAdministradora implements Exception {
  const ErrorAdministradora(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Una foto elegida en el computador o en el celular, antes de subirla.
class FotoElegida {
  const FotoElegida({required this.bytes, required this.nombre});

  final Uint8List bytes;
  final String nombre;

  /// Tamaño máximo que aceptan las carpetas de fotos (5 MB).
  static const int maximoBytes = 5 * 1024 * 1024;

  String get extension {
    final punto = nombre.lastIndexOf('.');
    return punto < 0 ? '' : nombre.substring(punto + 1).toLowerCase();
  }

  /// Tipo de archivo según la extensión; `null` si no es una imagen permitida.
  String? get tipo => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => null,
  };

  /// Un mensaje si la foto no se puede subir; `null` si está bien.
  String? get problema {
    if (tipo == null) return 'Usa una foto JPG, PNG o WEBP.';
    if (bytes.length > maximoBytes) {
      return 'La foto pesa más de 5 MB. Prueba con una más liviana.';
    }
    return null;
  }
}

/// Abre el selector de fotos del dispositivo.
abstract class SelectorFotos {
  /// `null` si la persona cierra el selector sin elegir nada.
  Future<FotoElegida?> elegir();
}

class SelectorFotosDispositivo implements SelectorFotos {
  const SelectorFotosDispositivo();

  @override
  Future<FotoElegida?> elegir() async {
    final archivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (archivo == null) return null;
    return FotoElegida(
      bytes: await archivo.readAsBytes(),
      nombre: archivo.name,
    );
  }
}

/// Todo lo que solo puede hacer la administradora: cambiar las fotos de los
/// artículos y del sitio. La sesión (entrar y salir) la maneja
/// `SesionRepositorio`, igual para clientas y administradora.
abstract class AdministradoraRepositorio {
  /// Sube una foto a un artículo y la deja al final de sus fotos.
  Future<ImagenProducto> subirFotoProducto({
    required int idProducto,
    required FotoElegida foto,
    required int orden,
  });

  Future<void> borrarFotoProducto(ImagenProducto foto);

  /// Deja las fotos en el orden dado (la primera pasa a ser la principal).
  Future<void> ordenarFotosProducto(List<ImagenProducto> enOrden);

  /// Pone o cambia la foto de un lugar del sitio y devuelve el ajuste nuevo.
  Future<AjusteSitio> subirFotoSitio({
    required AjusteSitio ajuste,
    required FotoElegida foto,
  });

  /// Quita la foto de un lugar del sitio: vuelve el diseño por defecto.
  Future<AjusteSitio> quitarFotoSitio(AjusteSitio ajuste);

  /// Crea el producto (si su `idProducto` es 0) o lo actualiza. Devuelve el
  /// producto guardado, con su id.
  Future<Producto> guardarProducto(Producto producto);

  /// Crea la variante (si su `idVariante` es 0) o la actualiza; aquí se cambia
  /// el stock. Devuelve la variante guardada, con su id.
  Future<VarianteProducto> guardarVariante(VarianteProducto variante);

  /// Borra una variante. Si ya tiene pedidos no se puede: lanza
  /// [ErrorAdministradora] y conviene dejarla con stock 0.
  Future<void> borrarVariante(int idVariante);
}

/// Hace todo lo anterior con Supabase (Auth, base de datos y Storage). Las
/// reglas de seguridad de la base de datos son las que impiden que otra
/// persona haga lo mismo.
class AdministradoraSupabase implements AdministradoraRepositorio {
  AdministradoraSupabase([SupabaseClient? cliente])
    : _c = cliente ?? Supabase.instance.client;

  final SupabaseClient _c;

  static const String _carpetaProductos = 'productos';
  static const String _carpetaSitio = 'sitio';

  Future<String> _subir(String carpeta, String ruta, FotoElegida foto) async {
    await _c.storage
        .from(carpeta)
        .uploadBinary(
          ruta,
          foto.bytes,
          fileOptions: FileOptions(contentType: foto.tipo, upsert: false),
        );
    return _c.storage.from(carpeta).getPublicUrl(ruta);
  }

  Future<void> _quitarArchivo(String carpeta, String? ruta) async {
    if (ruta == null || ruta.isEmpty) return;
    try {
      await _c.storage.from(carpeta).remove([ruta]);
    } catch (_) {
      // Un archivo suelto no afecta a la tienda: lo importante ya se guardó.
    }
  }

  @override
  Future<ImagenProducto> subirFotoProducto({
    required int idProducto,
    required FotoElegida foto,
    required int orden,
  }) async {
    final ruta =
        'producto-$idProducto/${DateTime.now().millisecondsSinceEpoch}.${foto.extension}';
    final url = await _subir(_carpetaProductos, ruta, foto);
    try {
      final fila = await _c
          .from('imagen_producto')
          .insert({
            'id_producto': idProducto,
            'url': url,
            'ruta': ruta,
            'orden': orden,
          })
          .select()
          .single();
      return ImagenProducto.desdeMapa(fila);
    } catch (_) {
      await _quitarArchivo(_carpetaProductos, ruta);
      rethrow;
    }
  }

  @override
  Future<void> borrarFotoProducto(ImagenProducto foto) async {
    await _c.from('imagen_producto').delete().eq('id_imagen', foto.idImagen);
    await _quitarArchivo(_carpetaProductos, foto.ruta);
  }

  @override
  Future<void> ordenarFotosProducto(List<ImagenProducto> enOrden) async {
    for (var i = 0; i < enOrden.length; i++) {
      await _c
          .from('imagen_producto')
          .update({'orden': i + 1})
          .eq('id_imagen', enOrden[i].idImagen);
    }
  }

  @override
  Future<AjusteSitio> subirFotoSitio({
    required AjusteSitio ajuste,
    required FotoElegida foto,
  }) async {
    final ruta =
        '${ajuste.clave}/${DateTime.now().millisecondsSinceEpoch}.${foto.extension}';
    final url = await _subir(_carpetaSitio, ruta, foto);
    try {
      await _c
          .from('ajuste_sitio')
          .update({
            'url': url,
            'ruta': ruta,
            'actualizado': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('clave', ajuste.clave);
    } catch (_) {
      await _quitarArchivo(_carpetaSitio, ruta);
      rethrow;
    }
    await _quitarArchivo(_carpetaSitio, ajuste.ruta);
    return AjusteSitio(
      clave: ajuste.clave,
      descripcion: ajuste.descripcion,
      url: url,
      ruta: ruta,
    );
  }

  @override
  Future<AjusteSitio> quitarFotoSitio(AjusteSitio ajuste) async {
    await _c
        .from('ajuste_sitio')
        .update({
          'url': null,
          'ruta': null,
          'actualizado': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('clave', ajuste.clave);
    await _quitarArchivo(_carpetaSitio, ajuste.ruta);
    return AjusteSitio(clave: ajuste.clave, descripcion: ajuste.descripcion);
  }

  @override
  Future<Producto> guardarProducto(Producto producto) async {
    final datos = {
      'id_categoria': producto.idCategoria,
      'nombre': producto.nombre,
      'descripcion': producto.descripcion,
      'tecnica': producto.tecnica,
      'precio': producto.precio,
      'activo': producto.activo,
    };
    try {
      final fila = producto.idProducto == 0
          ? await _c.from('producto').insert(datos).select().single()
          : await _c
                .from('producto')
                .update(datos)
                .eq('id_producto', producto.idProducto)
                .select()
                .single();
      return Producto.desdeMapa(fila);
    } on PostgrestException catch (e) {
      throw _traducir(e, 'No se pudo guardar el producto.');
    }
  }

  @override
  Future<VarianteProducto> guardarVariante(VarianteProducto variante) async {
    final datos = {
      'id_producto': variante.idProducto,
      'color': variante.color,
      'talla': variante.talla,
      'stock': variante.stock,
    };
    try {
      final fila = variante.idVariante == 0
          ? await _c.from('variante_producto').insert(datos).select().single()
          : await _c
                .from('variante_producto')
                .update(datos)
                .eq('id_variante', variante.idVariante)
                .select()
                .single();
      return VarianteProducto.desdeMapa(fila);
    } on PostgrestException catch (e) {
      throw _traducir(e, 'No se pudo guardar el stock.');
    }
  }

  @override
  Future<void> borrarVariante(int idVariante) async {
    try {
      await _c.from('variante_producto').delete().eq('id_variante', idVariante);
    } on PostgrestException catch (e) {
      throw _traducir(e, 'No se pudo borrar esa fila.');
    }
  }

  /// Pasa los errores de la base de datos a un mensaje para la administradora.
  ErrorAdministradora _traducir(PostgrestException e, String generico) {
    if (e.code == '23505') {
      return const ErrorAdministradora(
        'Ya hay una fila con ese color y esa talla.',
      );
    }
    if (e.code == '23503') {
      return const ErrorAdministradora(
        'Esa fila ya tiene pedidos o está en un carrito, así que no se puede '
        'borrar. Déjala con stock 0.',
      );
    }
    return ErrorAdministradora(generico);
  }
}
