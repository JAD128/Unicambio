// =============================================================================
// ARCHIVO: test/cache_sugerencias_llm_test.dart
// DESCRIPCIÓN: Pruebas de la caché temporal de sugerencias del LLM.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/datos/cache_sugerencias_llm.dart';
import 'package:unicambio/modelos/articulo.dart';
import 'package:unicambio/modelos/categoria.dart';
import 'package:unicambio/modelos/sugerencia_llm.dart';

SugerenciaLlm _sugerencia(TipoPublicacion tipo) => SugerenciaLlm(
  categoria: Categoria.libros,
  titulo: 'Libro de prueba',
  descripcion: 'Descripción de prueba con más de veinte caracteres.',
  tipoDescripcion: tipo,
);

void main() {
  test('devuelve la misma sugerencia para la misma foto y tipo', () {
    final CacheSugerenciasLlm cache = CacheSugerenciasLlm();
    const List<int> bytes = <int>[1, 2, 3, 4];
    final SugerenciaLlm original = _sugerencia(TipoPublicacion.venta);

    cache.guardar(
      bytes: bytes,
      tipo: TipoPublicacion.venta,
      sugerencia: original,
    );

    expect(
      cache.leer(bytes: bytes, tipo: TipoPublicacion.venta),
      same(original),
    );
    expect(cache.longitud, 1);
  });

  test('distingue fotos y tipos distintos', () {
    final CacheSugerenciasLlm cache = CacheSugerenciasLlm();
    const List<int> bytes = <int>[1, 2, 3, 4];

    cache.guardar(
      bytes: bytes,
      tipo: TipoPublicacion.venta,
      sugerencia: _sugerencia(TipoPublicacion.venta),
    );

    expect(
      cache.leer(bytes: <int>[1, 2, 3, 5], tipo: TipoPublicacion.venta),
      isNull,
    );
    expect(cache.leer(bytes: bytes, tipo: TipoPublicacion.regalo), isNull);
  });
}
