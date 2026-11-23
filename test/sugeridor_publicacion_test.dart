// =============================================================================
// ARCHIVO: test/sugeridor_publicacion_test.dart
// DESCRIPCIÓN: Pruebas de la lógica que convierte etiquetas y OCR en
//              sugerencias. No usan ML Kit ni la cámara.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/datos/sugeridor_publicacion.dart';
import 'package:unicambio/modelos/categoria.dart';
import 'package:unicambio/modelos/vision.dart';

/// Crea una etiqueta de prueba.
EtiquetaImagen etiqueta(String texto, double confianza) {
  return EtiquetaImagen(etiqueta: texto, confianza: confianza);
}

void main() {
  const SugeridorPublicacion sugeridor = SugeridorPublicacion();

  test('mapea etiquetas comunes a la categoría correcta', () {
    expect(
      sugeridor
          .sugerir(
            ResultadoVision(etiquetas: <EtiquetaImagen>[etiqueta('book', 0.9)]),
          )
          .categoria,
      Categoria.libros,
    );
    expect(
      sugeridor
          .sugerir(
            ResultadoVision(
              etiquetas: <EtiquetaImagen>[
                etiqueta('laptop', 0.9),
                etiqueta('computer', 0.8),
              ],
            ),
          )
          .categoria,
      Categoria.tecnologia,
    );
    expect(
      sugeridor
          .sugerir(
            ResultadoVision(
              etiquetas: <EtiquetaImagen>[etiqueta('shirt', 0.9)],
            ),
          )
          .categoria,
      Categoria.ropa,
    );
    expect(
      sugeridor
          .sugerir(
            ResultadoVision(
              etiquetas: <EtiquetaImagen>[etiqueta('chair', 0.9)],
            ),
          )
          .categoria,
      Categoria.hogar,
    );
    expect(
      sugeridor
          .sugerir(
            ResultadoVision(
              etiquetas: <EtiquetaImagen>[etiqueta('bicycle', 0.9)],
            ),
          )
          .categoria,
      Categoria.deportes,
    );
  });

  test('ignora etiquetas genéricas o con poca confianza', () {
    expect(
      sugeridor
          .sugerir(
            ResultadoVision(
              etiquetas: <EtiquetaImagen>[
                etiqueta('product', 0.99),
                etiqueta('design', 0.98),
                etiqueta('book', 0.3),
              ],
            ),
          )
          .categoria,
      isNull,
    );
  });

  test('no elige categoría si dos compiten sin margen suficiente', () {
    final SugerenciasPublicacion sugerencias = sugeridor.sugerir(
      ResultadoVision(
        etiquetas: <EtiquetaImagen>[
          etiqueta('book', 0.6),
          etiqueta('shirt', 0.55),
        ],
      ),
    );

    expect(sugerencias.categoria, isNull);
    expect(sugerencias.titulo, 'Libro');
  });

  test('extrae un título del OCR y rechaza precios y tallas', () {
    final SugerenciasPublicacion sugerencias = sugeridor.sugerir(
      ResultadoVision(
        etiquetas: <EtiquetaImagen>[etiqueta('laptop', 0.9)],
        lineasTexto: <String>['\$ 350.000', 'Lenovo IdeaPad 3', 'Talla M'],
      ),
    );

    expect(sugerencias.categoria, Categoria.tecnologia);
    expect(sugerencias.titulo, 'Lenovo IdeaPad 3');
    expect(sugerencias.lineasTexto, contains('Lenovo IdeaPad 3'));
  });

  test('convierte títulos todo en mayúsculas a mayúsculas iniciales', () {
    final SugerenciasPublicacion sugerencias = sugeridor.sugerir(
      ResultadoVision(lineasTexto: <String>['CÁLCULO DE UNA VARIABLE']),
    );

    expect(sugerencias.titulo, 'Cálculo De Una Variable');
  });

  test('usa la etiqueta traducida cuando no hay texto útil', () {
    final SugerenciasPublicacion sugerencias = sugeridor.sugerir(
      ResultadoVision(etiquetas: <EtiquetaImagen>[etiqueta('laptop', 0.9)]),
    );

    expect(sugerencias.titulo, 'Laptop');
  });

  test('usa un nombre genérico si la etiqueta no está en la tabla', () {
    final SugerenciasPublicacion sugerencias = sugeridor.sugerir(
      ResultadoVision(
        etiquetas: <EtiquetaImagen>[etiqueta('electronics', 0.9)],
      ),
    );

    expect(sugerencias.categoria, Categoria.tecnologia);
    expect(sugerencias.titulo, 'Artículo de tecnología');
  });

  test('limpia líneas vacías y repetidas', () {
    final SugerenciasPublicacion sugerencias = sugeridor.sugerir(
      ResultadoVision(
        lineasTexto: <String>[
          '  Lenovo   IdeaPad  ',
          '',
          'lenovo ideapad',
          'Otra línea',
        ],
      ),
    );

    expect(sugerencias.lineasTexto, <String>['Lenovo IdeaPad', 'Otra línea']);
  });

  test('un resultado vacío no produce sugerencias', () {
    final SugerenciasPublicacion sugerencias = sugeridor.sugerir(
      const ResultadoVision(),
    );

    expect(sugerencias.vacia, isTrue);
    expect(sugerencias.titulo, isNull);
    expect(sugerencias.categoria, isNull);
  });
}
