/// Validaciones de los formularios. Devuelven el mensaje de error, o `null` si
/// el valor es válido.
class Validaciones {
  Validaciones._();

  static String? obligatorio(String valor) =>
      valor.trim().isEmpty ? 'Obligatorio' : null;

  static String? correo(String valor) {
    if (valor.trim().isEmpty) return 'Obligatorio';
    final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor.trim());
    return valido ? null : 'Correo no válido';
  }

  static String? celular(String valor) {
    if (valor.trim().isEmpty) return 'Obligatorio';
    final digitos = valor.replaceAll(RegExp(r'\D'), '');
    return digitos.length == 10 ? null : 'Escribe tu celular de 10 dígitos';
  }

  static String? contrasena(String valor) =>
      valor.length >= 8 ? null : 'Mínimo 8 caracteres';

  /// Claves de los campos de envío: nombre, telefono, correo, direccion,
  /// ciudad y departamento.
  static String? envio(String clave, String valor) => switch (clave) {
    'correo' => correo(valor),
    'telefono' => celular(valor),
    _ => obligatorio(valor),
  };

  static const List<String> camposEnvio = [
    'nombre',
    'telefono',
    'correo',
    'direccion',
    'ciudad',
    'departamento',
  ];

  /// Primer campo de envío inválido, o `null` si todos están bien.
  static String? primerErrorEnvio(Map<String, String> valores) {
    for (final clave in camposEnvio) {
      if (envio(clave, valores[clave] ?? '') != null) return clave;
    }
    return null;
  }
}
