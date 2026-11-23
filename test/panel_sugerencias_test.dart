// =============================================================================
// ARCHIVO: test/panel_sugerencias_test.dart
// DESCRIPCIÓN: Pruebas del panel que muestra las sugerencias. Verifican que
//              cada campo se aplique solo al tocar su botón y que "Descartar"
//              avise correctamente.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/modelos/categoria.dart';
import 'package:unicambio/modelos/vision.dart';
import 'package:unicambio/tema/tema_app.dart';
import 'package:unicambio/widgets/panel_sugerencias.dart';

/// Envuelve el panel en una app mínima para poder probarlo.
Widget conPanel(Widget panel) {
  return MaterialApp(
    theme: TemaApp.claro,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: panel,
      ),
    ),
  );
}

void main() {
  testWidgets('muestra las sugerencias y avisa al tocar cada botón', (
    WidgetTester tester,
  ) async {
    Categoria? categoriaAplicada;
    String? tituloAplicado;
    String? descripcionAplicada;

    await tester.pumpWidget(
      conPanel(
        PanelSugerencias(
          sugerencias: const SugerenciasPublicacion(
            categoria: Categoria.tecnologia,
            titulo: 'Laptop Lenovo',
            lineasTexto: <String>['Lenovo IdeaPad 3', 'Laptop Lenovo'],
          ),
          descripcion:
              'Vendo Laptop Lenovo, una opción práctica para tus clases.',
          tituloActual: '',
          descripcionActual: '',
          categoriaActual: Categoria.libros,
          alAplicarCategoria: (Categoria categoria) =>
              categoriaAplicada = categoria,
          alAplicarTitulo: (String titulo) => tituloAplicado = titulo,
          alAplicarDescripcion: (String descripcion) =>
              descripcionAplicada = descripcion,
          alDescartar: () {},
        ),
      ),
    );

    expect(find.text('Sugerencias de la foto'), findsOneWidget);
    expect(find.text('Tecnología'), findsOneWidget);
    expect(find.text('Laptop Lenovo'), findsWidgets);

    await tester.tap(find.byKey(const Key('sugerencia-categoria-usar')));
    await tester.tap(find.byKey(const Key('sugerencia-titulo-usar')));
    await tester.tap(find.byKey(const Key('sugerencia-descripcion-usar')));

    expect(categoriaAplicada, Categoria.tecnologia);
    expect(tituloAplicado, 'Laptop Lenovo');
    expect(descripcionAplicada, contains('Laptop Lenovo'));
  });

  testWidgets('usa "Reemplazar" cuando el campo ya tiene texto', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      conPanel(
        PanelSugerencias(
          sugerencias: const SugerenciasPublicacion(
            categoria: Categoria.libros,
            titulo: 'Libro de Cálculo',
          ),
          descripcion: 'Vendo Libro de Cálculo.',
          tituloActual: 'Título anterior',
          descripcionActual: 'Descripción anterior',
          categoriaActual: Categoria.libros,
          alAplicarCategoria: (_) {},
          alAplicarTitulo: (_) {},
          alAplicarDescripcion: (_) {},
          alDescartar: () {},
        ),
      ),
    );

    expect(find.text('Reemplazar'), findsNWidgets(2));
  });

  testWidgets('permite usar una línea del OCR como título', (
    WidgetTester tester,
  ) async {
    String? tituloAplicado;

    await tester.pumpWidget(
      conPanel(
        PanelSugerencias(
          sugerencias: const SugerenciasPublicacion(
            lineasTexto: <String>['Lenovo IdeaPad 3'],
          ),
          descripcion: '',
          tituloActual: '',
          descripcionActual: '',
          categoriaActual: Categoria.libros,
          alAplicarCategoria: (_) {},
          alAplicarTitulo: (String titulo) => tituloAplicado = titulo,
          alAplicarDescripcion: (_) {},
          alDescartar: () {},
        ),
      ),
    );

    await tester.tap(find.text('Texto detectado (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Lenovo IdeaPad 3'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('sugerencia-linea-0')),
        matching: find.text('Usar'),
      ),
    );

    expect(tituloAplicado, 'Lenovo IdeaPad 3');
  });

  testWidgets('descartar avisa al padre', (WidgetTester tester) async {
    bool descartado = false;

    await tester.pumpWidget(
      conPanel(
        PanelSugerencias(
          sugerencias: const SugerenciasPublicacion(
            categoria: Categoria.libros,
            titulo: 'Libro',
          ),
          descripcion: '',
          tituloActual: '',
          descripcionActual: '',
          categoriaActual: Categoria.otros,
          alAplicarCategoria: (_) {},
          alAplicarTitulo: (_) {},
          alAplicarDescripcion: (_) {},
          alDescartar: () => descartado = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('sugerencia-descartar')));
    expect(descartado, isTrue);
  });

  testWidgets('no se dibuja si no hay nada que sugerir', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      conPanel(
        PanelSugerencias(
          sugerencias: const SugerenciasPublicacion(),
          descripcion: '',
          tituloActual: '',
          descripcionActual: '',
          categoriaActual: Categoria.libros,
          alAplicarCategoria: (_) {},
          alAplicarTitulo: (_) {},
          alAplicarDescripcion: (_) {},
          alDescartar: () {},
        ),
      ),
    );

    expect(find.text('Sugerencias de la foto'), findsNothing);
  });
}
