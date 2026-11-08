import 'package:flutter/material.dart';

import '../components/components.dart';
import '../theme/tina_tema.dart';

/// Ingreso y registro de clientas. Los valores y el error los guarda la Screen.
class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    required this.registro,
    required this.nombre,
    required this.correo,
    required this.clave,
    required this.error,
    required this.textoPromocion,
    required this.unidadesCarrito,
    required this.onToggle,
    required this.onCampo,
    required this.onEntrar,
    required this.onVendedora,
    required this.onAtras,
    required this.onCarrito,
    required this.onLogo,
    required this.onNav,
  });

  final bool registro;
  final String nombre;
  final String correo;
  final String clave;
  final String? error;
  final String textoPromocion;
  final int unidadesCarrito;
  final VoidCallback onToggle;
  final void Function(String clave, String valor) onCampo;
  final VoidCallback onEntrar;
  final VoidCallback onVendedora;
  final VoidCallback onAtras;
  final VoidCallback onCarrito;
  final VoidCallback onLogo;
  final ValueChanged<DestinoNav> onNav;

  @override
  Widget build(BuildContext context) {
    return TinaScaffold(
      titulo: 'Mi cuenta',
      conAtras: true,
      activo: DestinoNav.cuenta,
      unidadesCarrito: unidadesCarrito,
      onAtras: onAtras,
      onCarrito: onCarrito,
      onLogo: onLogo,
      onNav: onNav,
      cuerpo: TinaLista(
        anchoMaximo: 520,
        arriba: 26,
        children: [
          Text(
            registro ? 'Bienvenida' : 'Hola de nuevo',
            style: TinaTipografia.serif(tamano: 30, color: TinaColores.rojo),
          ),
          Text(
            registro ? 'Crea tu cuenta' : 'Inicia sesión',
            style: TinaTipografia.estilo(
              tamano: 36,
              peso: FontWeight.w800,
              espaciado: -1.1,
              altura: 1,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TinaEtiquetaDescuento(texto: textoPromocion),
          ),
          const SizedBox(height: 22),
          Column(
            spacing: 14,
            children: [
              if (registro)
                TinaCampo(
                  key: const ValueKey('login-nombre'),
                  etiqueta: 'Nombre',
                  placeholder: '¿Cómo te llamas?',
                  valor: nombre,
                  onChanged: (v) => onCampo('nombre', v),
                ),
              TinaCampo(
                key: const ValueKey('login-correo'),
                etiqueta: 'Correo',
                placeholder: 'tu@correo.com',
                tipo: TipoCampo.correo,
                valor: correo,
                onChanged: (v) => onCampo('correo', v),
              ),
              TinaCampo(
                key: const ValueKey('login-clave'),
                etiqueta: 'Contraseña',
                placeholder: 'Mínimo 8 caracteres',
                tipo: TipoCampo.contrasena,
                valor: clave,
                onChanged: (v) => onCampo('clave', v),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              key: const ValueKey('login-error'),
              style: TinaTipografia.estilo(
                tamano: 14,
                peso: FontWeight.w800,
                color: TinaColores.rojo,
              ),
            ),
          ],
          const SizedBox(height: 22),
          TinaBoton(
            etiqueta: registro ? 'Crear cuenta' : 'Iniciar sesión',
            onPressed: onEntrar,
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                registro ? '¿Ya tienes cuenta?' : '¿No tienes cuenta?',
                style: TinaTipografia.estilo(
                  tamano: 14,
                  color: TinaColores.marron,
                ),
              ),
              TinaHover(
                builder: (context, encima) => GestureDetector(
                  key: const ValueKey('login-toggle'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      registro ? 'Inicia sesión' : 'Regístrate',
                      style: TinaTipografia.estilo(
                        tamano: 14,
                        peso: FontWeight.w800,
                        color: encima
                            ? const Color(0xFFD95800)
                            : TinaColores.naranja,
                      ).copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!registro)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Para probar: valentina.rios@correo.com y cualquier contraseña de 8 o más caracteres.',
                textAlign: TextAlign.center,
                style: TinaTipografia.estilo(
                  tamano: 12,
                  color: TinaColores.marron,
                  altura: 1.35,
                ),
              ),
            ),
          const SizedBox(height: 18),
          const Divider(color: TinaColores.dorado, thickness: 1),
          const SizedBox(height: 8),
          Center(
            child: TinaHover(
              builder: (context, encima) => GestureDetector(
                key: const ValueKey('ir-panel'),
                behavior: HitTestBehavior.opaque,
                onTap: onVendedora,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  child: Text(
                    'Soy vendedora · ir al panel',
                    style: TinaTipografia.estilo(
                      tamano: 14,
                      peso: FontWeight.w800,
                      color: encima ? TinaColores.naranja : TinaColores.marron,
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
