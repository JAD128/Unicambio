// =============================================================================
// ARCHIVO: lib/datos/servicios_publicacion.dart
// DESCRIPCIÓN: Fábrica compartida de los servicios de sugerencias. Mantiene
//              el cableado LLM fuera de main.dart y de las pantallas.
// =============================================================================

import 'cache_sugerencias_llm.dart';
import 'cliente_sugerencias_llm.dart';
import 'servicio_vision.dart';
import 'servicio_vision_con_llm.dart';
import 'sugeridor_publicacion_llm.dart';

/// Punto único de creación de los servicios del formulario de publicación.
abstract final class ServiciosPublicacion {
  static final ClienteSugerenciasLlm cliente = ClienteSugerenciasLlm();

  static final CacheSugerenciasLlm cache = CacheSugerenciasLlm();

  static const SugeridorPublicacionLlm sugeridor = SugeridorPublicacionLlm();

  /// Crea el servicio de visión con ML Kit + proxy de sugerencias.
  static ServicioVision crearVision({
    required TipoPublicacionActual tipoActual,
  }) {
    return ServicioVisionConLlm(
      vision: ServicioVisionMlKit(),
      cliente: cliente,
      cache: cache,
      tipoActual: tipoActual,
    );
  }
}
