// =============================================================================
// ARCHIVO: lib/config_llm.dart
// DESCRIPCIÓN: Configuración pública del proxy de sugerencias. No contiene
//              secretos: la API key vive únicamente en el Worker.
// =============================================================================

/// Ajustes de conexión con el proxy de sugerencias.
abstract final class ConfiguracionLlm {
  /// URL base del Cloudflare Worker; se puede cambiar con --dart-define.
  static const String urlBase = String.fromEnvironment(
    'UNICAMBIO_LLM_URL',
    defaultValue: 'https://unicambio-sugerencias.unicambiodm26.workers.dev',
  );

  /// Tiempo máximo de espera para una sugerencia.
  static const Duration tiempoEspera = Duration(seconds: 30);
}
