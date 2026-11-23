// =============================================================================
// ARCHIVO: test/sugeridor_publicacion_llm_test.dart
// DESCRIPCIÓN: Pruebas de prioridad LLM y respaldo local del sugeridor.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/datos/sugeridor_publicacion_llm.dart';
import 'package:unicambio/modelos/articulo.dart';
import 'package:unicambio/modelos/categoria.dart';
import 'package:unicambio/modelos/sugerencia_llm.dart';
import 'package:unicambio/modelos/vision.dart';

void main() {
  const SugeridorPublicacionLlm sugeridor = SugeridorPublicacionLlm();

  test('prefiere categoría, título y descripción del LLM', () {
    const ResultadoVision resultado = ResultadoVision(
      etiquetas: <EtiquetaImagen>[
        EtiquetaImagen(etiqueta: 'book', confianza: 0.9),
      ],
      sugerencia: SugerenciaLlm(
        categoria: Categoria.tecnologia,
        titulo: 'Calculadora científica',
        descripcion: 'Calculadora útil para tus clases universitarias.',
        tipoDescripcion: TipoPublicacion.venta,
      ),
    );

    final SugerenciasPublicacion sugerencias = sugeridor.sugerir(resultado);

    expect(sugerencias.categoria, Categoria.tecnologia);
    expect(sugerencias.titulo, 'Calculadora científica');
    expect(
      sugerencias.descripcion,
      'Calculadora útil para tus clases universitarias.',
    );
    expect(sugerencias.tipoDescripcion, TipoPublicacion.venta);
  });

  test('sin respuesta del LLM usa el sugeridor local', () {
    const ResultadoVision resultado = ResultadoVision(
      etiquetas: <EtiquetaImagen>[
        EtiquetaImagen(etiqueta: 'book', confianza: 0.9),
      ],
    );

    final SugerenciasPublicacion sugerencias = sugeridor.sugerir(resultado);

    expect(sugerencias.categoria, Categoria.libros);
    expect(sugerencias.descripcion, isNull);
    expect(sugerencias.tipoDescripcion, isNull);
  });
}
