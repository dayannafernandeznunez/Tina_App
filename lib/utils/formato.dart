/// Pesos colombianos con punto de miles: 55000 -> $55.000
String formatoPesos(num valor) {
  final entero = valor.round().abs().toString();
  final conPuntos = entero.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${valor < 0 ? '-' : ''}\$$conPuntos';
}

const List<String> _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// 24 oct 2026
String formatoFecha(DateTime fecha) =>
    '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}';
