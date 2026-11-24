import 'package:supabase_flutter/supabase_flutter.dart';

/// Un problema que se le puede mostrar tal cual a la persona que se suscribe.
class ErrorSuscripcion implements Exception {
  const ErrorSuscripcion(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Guardar el correo de quien quiere enterarse de lo nuevo. Nadie puede leer la
/// lista desde la tienda: solo la administradora, en Supabase.
abstract class SuscripcionRepositorio {
  /// Lanza [ErrorSuscripcion] si el correo no sirve o no se pudo guardar.
  Future<void> suscribir(String correo);
}

class SuscripcionSupabase implements SuscripcionRepositorio {
  SuscripcionSupabase([SupabaseClient? cliente])
    : _c = cliente ?? Supabase.instance.client;

  final SupabaseClient _c;

  @override
  Future<void> suscribir(String correo) async {
    try {
      await _c.rpc('suscribirse', params: {'p_correo': correo});
    } on PostgrestException catch (e) {
      throw ErrorSuscripcion(e.message);
    } catch (_) {
      throw const ErrorSuscripcion(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }
}
