// =============================================================================
// ARCHIVO: lib/datos/sugeridor_publicacion_llm.dart
// DESCRIPCIÓN: Sugeridor que prefiere la respuesta del LLM cuando está
//              disponible y conserva el sugeridor local como respaldo.
// =============================================================================

import '../modelos/sugerencia_llm.dart';
import '../modelos/vision.dart';
import 'sugeridor_publicacion.dart';

/// Sugeridor con prioridad LLM y fallback a etiquetas/OCR de ML Kit.
class SugeridorPublicacionLlm extends SugeridorPublicacion {
  const SugeridorPublicacionLlm();

  @override
  SugerenciasPublicacion sugerir(ResultadoVision resultado) {
    final SugerenciasPublicacion base = super.sugerir(resultado);
    final SugerenciaLlm? sugerencia = resultado.sugerencia;
    if (sugerencia == null) return base;

    return SugerenciasPublicacion(
      categoria: sugerencia.categoria,
      titulo: sugerencia.titulo,
      lineasTexto: base.lineasTexto,
      descripcion: sugerencia.descripcion,
      tipoDescripcion: sugerencia.tipoDescripcion,
    );
  }
}
