// =============================================================================
// ARCHIVO: test/widget_test.dart
// DESCRIPCIÓN: Pruebas básicas ("smoke test") que verifican que la aplicación
//              UniCambio se construye correctamente y que ninguna pantalla
//              lanza errores de diseño (como desbordamientos de contenido).
//
// Como las pantallas leen [ArticulosProvider], cada una se monta envuelta en
// un provider con el repositorio EN MEMORIA (sin tocar SQLite).
//
// Se ejecuta con:  flutter test
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:unicambio/datos/articulo_repositorio_memoria.dart';
import 'package:unicambio/datos/articulos_ejemplo.dart';
import 'package:unicambio/estado/articulos_provider.dart';
import 'package:unicambio/main.dart';
import 'package:unicambio/pantallas/pantalla_detalle_articulo.dart';
import 'package:unicambio/pantallas/pantalla_favoritos.dart';
import 'package:unicambio/pantallas/pantalla_mis_articulos.dart';
import 'package:unicambio/pantallas/pantalla_publicar.dart';
import 'package:unicambio/tema/tema_app.dart';

/// Envuelve [pantalla] con un provider de prueba (repositorio en memoria).
Widget conProvider(Widget pantalla) {
  return ChangeNotifierProvider<ArticulosProvider>(
    create: (_) => ArticulosProvider(
      ArticuloRepositorioMemoria(iniciales: articulosEjemplo),
    ),
    child: MaterialApp(theme: TemaApp.claro, home: pantalla),
  );
}

void main() {
  testWidgets('Sin Firebase configurado se muestran instrucciones',
      (WidgetTester tester) async {
    // Construye la aplicación completa y espera el primer cuadro.
    await tester.pumpWidget(const UniCambioApp(firebaseConfigurado: false));

    // El título "UniCambio" debe aparecer en la barra superior.
    expect(find.textContaining('Firebase aún no está configurado'), findsOneWidget);

    // El botón flotante para publicar debe existir.
    expect(find.text('Publicar'), findsNothing);
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

    // Se monta cada pantalla con su provider en memoria.
    // Si alguna se desborda o lanza un error, la prueba falla.
    for (final Widget pantalla in pantallas) {
      await tester.pumpWidget(conProvider(pantalla));
      await tester.pumpAndSettle();
    }
  });
}
