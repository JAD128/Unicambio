// =============================================================================
// ARCHIVO: lib/modelos/sugerencia_llm.dart
// DESCRIPCIÓN: Sugerencia devuelta por el proxy de Gemini, ya validada.
// =============================================================================

import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Resultado del LLM para una foto y un tipo de publicación concretos.
class SugerenciaLlm {
  /// Categoría elegida por el modelo.
  final Categoria categoria;

  /// Título sugerido.
  final String titulo;

  /// Descripción sugerida.
  final String descripcion;

  /// Tipo de publicación usado al pedir la sugerencia.
  final TipoPublicacion tipoDescripcion;

  const SugerenciaLlm({
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    required this.tipoDescripcion,
  });

  /// Convierte la respuesta JSON del Worker en un objeto validado.
  factory SugerenciaLlm.fromJson(
    Map<String, dynamic> json,
    TipoPublicacion tipo,
  ) {
    final Object? categoriaCruda = json['categoria'];
    if (categoriaCruda is! String) {
      throw const FormatException('Falta la categoría sugerida');
    }
    final Categoria categoria = Categoria.values.firstWhere(
      (Categoria valor) => valor.name == categoriaCruda,
      orElse: () =>
          throw FormatException('Categoría desconocida: $categoriaCruda'),
    );

    final String titulo = (json['titulo'] as String?)?.trim() ?? '';
    final String descripcion = (json['descripcion'] as String?)?.trim() ?? '';
    if (titulo.length < 3) {
      throw const FormatException('El título sugerido es demasiado corto');
    }
    if (descripcion.length < 20) {
      throw const FormatException('La descripción sugerida es demasiado corta');
    }

    return SugerenciaLlm(
      categoria: categoria,
      titulo: titulo,
      descripcion: descripcion,
      tipoDescripcion: tipo,
    );
  }
}
