import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Un problema de sesión que se le puede mostrar tal cual a la persona.
class ErrorSesion implements Exception {
  const ErrorSesion(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Quién entró: su fila de clienta y si además es administradora. Quien no es
/// administradora es clienta.
class SesionActiva {
  const SesionActiva({required this.cliente, required this.esAdministradora});

  final Cliente cliente;
  final bool esAdministradora;
}

/// Lo que pasó al crear una cuenta.
class ResultadoRegistro {
  const ResultadoRegistro({this.sesion});

  /// La sesión abierta; `null` si primero hay que confirmar el correo.
  final SesionActiva? sesion;

  bool get requiereConfirmarCorreo => sesion == null;
}

/// El inicio de sesión de la tienda: uno solo para clientas y administradora.
abstract class SesionRepositorio {
  /// La sesión que ya estaba abierta (por ejemplo, al recargar la página).
  Future<SesionActiva?> restaurar();

  /// Lanza [ErrorSesion] si los datos no son correctos o no hay conexión.
  Future<SesionActiva> iniciarSesion(String correo, String clave);

  Future<ResultadoRegistro> registrar({
    required String nombre,
    required String correo,
    required String clave,
  });

  Future<void> cerrarSesion();
}

/// Maneja las sesiones con Supabase Auth.
class SesionSupabase implements SesionRepositorio {
  SesionSupabase([SupabaseClient? cliente])
    : _c = cliente ?? Supabase.instance.client;

  final SupabaseClient _c;

  /// Junta la cuenta de Auth con su fila de cliente y su rol.
  Future<SesionActiva> _armar(User usuario) async {
    final rol = await _c
        .from('usuario')
        .select('rol')
        .eq('id_auth', usuario.id)
        .maybeSingle();

    var fila = await _c
        .from('cliente')
        .select()
        .eq('id_auth', usuario.id)
        .maybeSingle();
    // Las cuentas anteriores al trigger no tienen fila: se crea al entrar.
    fila ??= await _c
        .from('cliente')
        .insert({
          'id_auth': usuario.id,
          'nombre': _nombreDe(usuario),
          'correo': usuario.email ?? '',
          'cuenta_registrada': true,
        })
        .select()
        .single();

    return SesionActiva(
      cliente: Cliente.desdeMapa(fila),
      esAdministradora: rol?['rol'] == 'administradora',
    );
  }

  String _nombreDe(User usuario) {
    final nombre = usuario.userMetadata?['nombre'];
    if (nombre is String && nombre.trim().isNotEmpty) return nombre.trim();
    return (usuario.email ?? 'Clienta').split('@').first;
  }

  @override
  Future<SesionActiva?> restaurar() async {
    final usuario = _c.auth.currentUser;
    if (usuario == null) return null;
    try {
      return await _armar(usuario);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SesionActiva> iniciarSesion(String correo, String clave) async {
    final AuthResponse respuesta;
    try {
      respuesta = await _c.auth.signInWithPassword(
        email: correo,
        password: clave,
      );
    } on AuthException catch (e) {
      if (e.code == 'email_not_confirmed') {
        throw const ErrorSesion(
          'Primero confirma tu correo: te enviamos un mensaje.',
        );
      }
      throw const ErrorSesion('Correo o contraseña incorrectos.');
    } catch (_) {
      throw const ErrorSesion(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
    final usuario = respuesta.user;
    if (usuario == null) {
      throw const ErrorSesion('Correo o contraseña incorrectos.');
    }
    try {
      return await _armar(usuario);
    } catch (_) {
      await _c.auth.signOut();
      throw const ErrorSesion(
        'No pudimos abrir tu cuenta. Inténtalo de nuevo.',
      );
    }
  }

  @override
  Future<ResultadoRegistro> registrar({
    required String nombre,
    required String correo,
    required String clave,
  }) async {
    final AuthResponse respuesta;
    try {
      respuesta = await _c.auth.signUp(
        email: correo,
        password: clave,
        data: {'nombre': nombre},
      );
    } on AuthException catch (e) {
      if (e.code == 'user_already_exists') {
        throw const ErrorSesion('Ya existe una cuenta con ese correo.');
      }
      if (e.code == 'weak_password') {
        throw const ErrorSesion('Esa contraseña es muy fácil. Usa otra.');
      }
      throw const ErrorSesion(
        'No pudimos crear tu cuenta. Inténtalo de nuevo.',
      );
    } catch (_) {
      throw const ErrorSesion(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
    final usuario = respuesta.user;
    // Con la confirmación de correo activada, un correo que ya existe responde
    // "bien" pero sin identidades: se avisa igual.
    if (usuario != null && (usuario.identities?.isEmpty ?? false)) {
      throw const ErrorSesion('Ya existe una cuenta con ese correo.');
    }
    if (respuesta.session == null || usuario == null) {
      return const ResultadoRegistro();
    }
    return ResultadoRegistro(sesion: await _armar(usuario));
  }

  @override
  Future<void> cerrarSesion() => _c.auth.signOut();
}
