import 'package:flutter/material.dart';

import '../theme/tina_tema.dart';

enum TipoCampo { texto, correo, telefono, contrasena }

/// Campo de texto con etiqueta. Avisa cada cambio con [onChanged]; quien lo
/// usa decide dónde guardar el valor. Si quien lo usa cambia [valor] (por
/// ejemplo, para rellenar el campo con los datos de la clienta), el campo lo
/// muestra.
class TinaCampo extends StatefulWidget {
  const TinaCampo({
    super.key,
    required this.etiqueta,
    this.placeholder = '',
    this.tipo = TipoCampo.texto,
    this.valor = '',
    this.onChanged,
    this.textoError,
  });

  final String etiqueta;
  final String placeholder;
  final TipoCampo tipo;
  final String valor;
  final ValueChanged<String>? onChanged;
  final String? textoError;

  @override
  State<TinaCampo> createState() => _TinaCampoState();
}

class _TinaCampoState extends State<TinaCampo> {
  // Solo maneja el cursor y el texto que se está escribiendo; el dato de la
  // app vive en quien usa el campo.
  bool _encima = false;

  late final TextEditingController _controlador = TextEditingController(
    text: widget.valor,
  );

  @override
  void didUpdateWidget(TinaCampo anterior) {
    super.didUpdateWidget(anterior);
    if (widget.valor != anterior.valor && widget.valor != _controlador.text) {
      _controlador.value = TextEditingValue(
        text: widget.valor,
        selection: TextSelection.collapsed(offset: widget.valor.length),
      );
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  OutlineInputBorder _borde(Color color, double grosor) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: grosor),
  );

  TextInputType get _teclado => switch (widget.tipo) {
    TipoCampo.correo => TextInputType.emailAddress,
    TipoCampo.telefono => TextInputType.phone,
    _ => TextInputType.text,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(
          widget.etiqueta,
          style: TinaTipografia.estilo(tamano: 14, peso: FontWeight.w800),
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _encima = true),
          onExit: (_) => setState(() => _encima = false),
          child: TextFormField(
            controller: _controlador,
            onChanged: widget.onChanged,
            obscureText: widget.tipo == TipoCampo.contrasena,
            keyboardType: _teclado,
            style: TinaTipografia.estilo(tamano: 16),
            cursorColor: TinaColores.naranja,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TinaTipografia.estilo(
                tamano: 16,
                color: TinaColores.marron.withValues(alpha: 0.6),
              ),
              errorText: widget.textoError,
              filled: true,
              fillColor: TinaColores.cremaCampo,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              enabledBorder: _borde(
                _encima ? TinaColores.naranja : TinaColores.dorado,
                1.5,
              ),
              focusedBorder: _borde(TinaColores.naranja, 2),
              errorBorder: _borde(TinaColores.rojo, 1.5),
              focusedErrorBorder: _borde(TinaColores.rojo, 2),
            ),
          ),
        ),
      ],
    );
  }
}
