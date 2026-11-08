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

  final int idPromocion;
  final String nombre;
  final String tipo;
  final int porcentaje;
  final int cantidadMinima;
  final bool activa;
}
