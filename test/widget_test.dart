// =============================================================================
// ARCHIVO: test/widget_test.dart
// DESCRIPCIÓN: Pruebas básicas ("smoke test") que verifican que la aplicación
//              UniCambio se construye correctamente y que ninguna pantalla
//              lanza errores de diseño (como desbordamientos de contenido).
//
// Se ejecuta con:  flutter test
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/datos/articulos_ejemplo.dart';
import 'package:unicambio/main.dart';
import 'package:unicambio/pantallas/pantalla_detalle_articulo.dart';
import 'package:unicambio/pantallas/pantalla_favoritos.dart';
import 'package:unicambio/pantallas/pantalla_mis_articulos.dart';
import 'package:unicambio/pantallas/pantalla_publicar.dart';
import 'package:unicambio/tema/tema_app.dart';

void main() {
  testWidgets('La pantalla de Inicio muestra el título UniCambio',
      (WidgetTester tester) async {
    // Construye la aplicación completa y espera el primer cuadro.
    await tester.pumpWidget(const UniCambioApp());

    // El título "UniCambio" debe aparecer en la barra superior.
    expect(find.text('UniCambio'), findsOneWidget);

    // El botón flotante para publicar debe existir.
    expect(find.text('Publicar'), findsOneWidget);
  });

  testWidgets('Todas las pantallas se construyen sin errores',
      (WidgetTester tester) async {
    // Lista de pantallas independientes que queremos verificar.
    final List<Widget> pantallas = <Widget>[
      const PantallaFavoritos(),
      const PantallaMisArticulos(),
      PantallaDetalleArticulo(articulo: articulosEjemplo.first),
      const PantallaPublicar(),
    ];

    // Se monta cada pantalla en su propia MaterialApp con el tema de la app.
    // Si alguna se desborda o lanza un error, la prueba falla.
    for (final Widget pantalla in pantallas) {
      await tester.pumpWidget(
        MaterialApp(theme: TemaApp.claro, home: pantalla),
      );
      await tester.pumpAndSettle();
    }
  });
}
