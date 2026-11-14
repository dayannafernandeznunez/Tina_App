/// Tabla CLIENTE. Las clientas sin cuenta también tienen su fila, con
/// `cuentaRegistrada` en falso.
class Cliente {
  const Cliente({
    required this.idCliente,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.cuentaRegistrada,
    required this.fechaRegistro,
    this.fechaUltimoInicioSesion,
  });

  /// Arma la clienta a partir de una fila de Supabase.
  factory Cliente.desdeMapa(Map<String, dynamic> fila) => Cliente(
    idCliente: fila['id_cliente'] as int,
    nombre: fila['nombre'] as String,
    correo: fila['correo'] as String,
    telefono: (fila['telefono'] as String?) ?? '',
    cuentaRegistrada: (fila['cuenta_registrada'] as bool?) ?? false,
    fechaRegistro: DateTime.parse(fila['fecha_registro'] as String),
    fechaUltimoInicioSesion: fila['fecha_ultimo_inicio_sesion'] == null
        ? null
        : DateTime.parse(fila['fecha_ultimo_inicio_sesion'] as String),
  );

  final int idCliente;
  final String nombre;
  final String correo;
  final String telefono;
  final bool cuentaRegistrada;
  final DateTime fechaRegistro;
  final DateTime? fechaUltimoInicioSesion;
}

/// Tabla USUARIO: quienes entran al panel (administradora) y el sistema que
/// registra los cambios automáticos de estado.
class Usuario {
  const Usuario({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  final int idUsuario;
  final String nombre;
  final String correo;
  final String rol;
}

/// Tabla PROMOCION. `tipo` es `primera_compra` o `volumen`.
class Promocion {
  const Promocion({
    required this.idPromocion,
    required this.nombre,
    required this.tipo,
    required this.porcentaje,
    required this.cantidadMinima,
    required this.activa,
  });

  /// Arma la promoción a partir de una fila de Supabase.
  factory Promocion.desdeMapa(Map<String, dynamic> fila) => Promocion(
    idPromocion: fila['id_promocion'] as int,
    nombre: fila['nombre'] as String,
    tipo: fila['tipo'] as String,
    porcentaje: fila['porcentaje'] as int,
    cantidadMinima: (fila['cantidad_minima'] as int?) ?? 1,
    activa: (fila['activa'] as bool?) ?? true,
  );

  final int idPromocion;
  final String nombre;
  final String tipo;
  final int porcentaje;
  final int cantidadMinima;
  final bool activa;
}
