// =============================================================================
// ARCHIVO: test/generador_descripcion_test.dart
// DESCRIPCIÓN: Pruebas de las plantillas de descripción. Verifican que el
//              texto cambie según el tipo y que no invente precio ni estado.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/datos/generador_descripcion.dart';
import 'package:unicambio/modelos/articulo.dart';
import 'package:unicambio/modelos/categoria.dart';

void main() {
  const GeneradorDescripcion generador = PlantillaGeneradorDescripcion();

  test('la venta usa el título y la categoría', () {
    final String texto = generador.generar(
      titulo: 'Laptop Lenovo',
      categoria: Categoria.tecnologia,
      tipo: TipoPublicacion.venta,
    );

    expect(texto, contains('Laptop Lenovo'));
    expect(texto.toLowerCase(), anyOf(contains('vendo'), contains('venta')));
    expect(texto, contains('clases'));
    expect(texto, isNot(contains('\$')));
  });

  test('el regalo tiene un texto distinto al de la venta', () {
    final String venta = generador.generar(
      titulo: 'Libro de Cálculo',
      categoria: Categoria.libros,
      tipo: TipoPublicacion.venta,
    );
    final String regalo = generador.generar(
      titulo: 'Libro de Cálculo',
      categoria: Categoria.libros,
      tipo: TipoPublicacion.regalo,
    );

    expect(regalo, contains('Regalo'));
    expect(regalo, isNot(equals(venta)));
    expect(regalo, isNot(contains('Vendo')));
  });

  test('el intercambio no habla de precio', () {
    final String texto = generador.generar(
      titulo: 'Calculadora',
      categoria: Categoria.tecnologia,
      tipo: TipoPublicacion.intercambio,
    );

    expect(
      texto.toLowerCase(),
      anyOf(contains('cambio'), contains('intercambiar')),
    );
    expect(texto, isNot(contains('\$')));
  });

  test('sin título usa un nombre genérico según la categoría', () {
    final String texto = generador.generar(
      titulo: null,
      categoria: Categoria.ropa,
      tipo: TipoPublicacion.venta,
    );

    expect(texto, contains('esta prenda'));
    expect(texto, contains('renovar tu look'));
  });

  test('usa una variante estable para el mismo título', () {
    final String primera = generador.generar(
      titulo: 'Mochila',
      categoria: Categoria.ropa,
      tipo: TipoPublicacion.venta,
    );
    final String segunda = generador.generar(
      titulo: 'Mochila',
      categoria: Categoria.ropa,
      tipo: TipoPublicacion.venta,
    );

    expect(segunda, primera);
  });
}
