// =============================================================================
// ARCHIVO: lib/modelos/vision.dart
// DESCRIPCIÓN: Modelos con los resultados del análisis de una foto y con las
//              sugerencias que se muestran en el formulario de publicación.
//
// Estos modelos NO dependen de ML Kit ni de Flutter: la pantalla recibe datos
// simples y puede probarse sin usar la cámara ni los modelos nativos.
// =============================================================================

import 'articulo.dart';
import 'categoria.dart';
import 'sugerencia_llm.dart';

/// Etiqueta detectada en una imagen, con su nivel de confianza (0 a 1).
class EtiquetaImagen {
  /// Nombre de la etiqueta tal como lo devuelve ML Kit (normalmente en inglés).
  final String etiqueta;

  /// Confianza del modelo en esa etiqueta (0.0 a 1.0).
  final double confianza;

  const EtiquetaImagen({required this.etiqueta, required this.confianza});
}

/// Resultado de analizar una foto con etiquetado y reconocimiento de texto.
class ResultadoVision {
  /// Etiquetas detectadas, de mayor a menor confianza.
  final List<EtiquetaImagen> etiquetas;

  /// Líneas de texto detectadas por OCR (pueden estar vacías).
  final List<String> lineasTexto;

  /// Sugerencia del proxy LLM, si la petición terminó correctamente.
  final SugerenciaLlm? sugerencia;

  const ResultadoVision({
    this.etiquetas = const <EtiquetaImagen>[],
    this.lineasTexto = const <String>[],
    this.sugerencia,
  });

  /// `true` si no se obtuvo ninguna etiqueta ni texto.
  bool get vacio => etiquetas.isEmpty && lineasTexto.isEmpty;
}

/// Sugerencias calculadas a partir de una foto.
///
/// Si el proxy LLM respondió, [descripcion] se usa solo mientras el tipo de
/// publicación siga siendo [tipoDescripcion]; si el usuario cambia de venta a
/// regalo o intercambio, la pantalla vuelve a la descripción por plantillas.
class SugerenciasPublicacion {
  /// Categoría sugerida, o `null` si no hubo etiquetas suficientemente claras.
  final Categoria? categoria;

  /// Título sugerido, o `null` si no se pudo inferir.
  final String? titulo;

  /// Líneas de texto detectadas, para que el usuario pueda elegir una.
  final List<String> lineasTexto;

  /// Descripción escrita por el LLM (opcional).
  final String? descripcion;

  /// Tipo usado para generar [descripcion].
  final TipoPublicacion? tipoDescripcion;

  const SugerenciasPublicacion({
    this.categoria,
    this.titulo,
    this.lineasTexto = const <String>[],
    this.descripcion,
    this.tipoDescripcion,
  });

  /// `true` si no hay nada útil que mostrar.
  bool get vacia =>
      categoria == null &&
      titulo == null &&
      lineasTexto.isEmpty &&
      descripcion == null;
}
