/// Datos para conectar la app con el proyecto de Supabase de Tina.
///
/// La URL y la llave pública (`publishable`) están hechas para ir dentro de la
/// app: lo que protege los datos son las reglas de seguridad de la base de
/// datos (ver `supabase/migrations/`), no esconder esta llave.
///
/// NUNCA pongas aquí la llave `secret` o `service_role`: da control total.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://nklkvmxqtipdvvmmmaan.supabase.co';
  static const String llavePublica =
      'sb_publishable_NC1lfGrBXrXyqWZeUnCmjw_7Ya_VHj3';
}
