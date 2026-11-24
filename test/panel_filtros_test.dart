// =============================================================================
// ARCHIVO: test/panel_filtros_test.dart
// DESCRIPCIÓN: Pruebas del panel de filtros (bottom sheet) de Inicio.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/modelos/consulta_articulos.dart';
import 'package:unicambio/widgets/panel_filtros.dart';

/// Monta un botón que abre el panel y captura lo que devuelve.
Widget conPanel({
  required ValueChanged<ValoresFiltros> alAplicar,
  required VoidCallback alLimpiar,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) => ElevatedButton(
          key: const Key('abrir-panel'),
          onPressed: () => showModalBottomSheet<ValoresFiltros>(
            context: context,
            isScrollControlled: true,
            builder: (_) => PanelFiltros(
              orden: OrdenArticulos.titulo,
              alAplicar: alAplicar,
              alLimpiar: alLimpiar,
            ),
          ),
          child: const Text('Abrir'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('aplica orden y rango de precio', (WidgetTester tester) async {
    ValoresFiltros? aplicados;
    await tester.pumpWidget(
      conPanel(alAplicar: (ValoresFiltros v) => aplicados = v, alLimpiar: () {}),
    );

    await tester.tap(find.byKey(const Key('abrir-panel')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('filtro-precio-min')), '100');
    await tester.enterText(find.byKey(const Key('filtro-precio-max')), '500');
    await tester.tap(find.text('mayor a menor'));
    await tester.tap(find.byKey(const Key('filtro-aplicar')));
    await tester.pumpAndSettle();

    expect(aplicados, isNotNull);
    final ValoresFiltros valores = aplicados!;
    expect(valores.orden, OrdenArticulos.precioDesc);
    expect(valores.precioMinimo, 100);
    expect(valores.precioMaximo, 500);
  });

  testWidgets('rechaza un rango invertido', (WidgetTester tester) async {
    ValoresFiltros? aplicados;
    await tester.pumpWidget(
      conPanel(alAplicar: (ValoresFiltros v) => aplicados = v, alLimpiar: () {}),
    );

    await tester.tap(find.byKey(const Key('abrir-panel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('filtro-precio-min')), '500');
    await tester.enterText(find.byKey(const Key('filtro-precio-max')), '100');
    await tester.tap(find.byKey(const Key('filtro-aplicar')));
    await tester.pumpAndSettle();

    expect(
      find.text('El precio mínimo no puede ser mayor que el máximo.'),
      findsOneWidget,
    );
    expect(aplicados, isNull);
  });

  testWidgets('el panel se puede desplazar cuando aparece el teclado',
      (WidgetTester tester) async {
    await tester.pumpWidget(conPanel(alAplicar: (_) {}, alLimpiar: () {}));
    await tester.tap(find.byKey(const Key('abrir-panel')));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byKey(const Key('filtro-aplicar')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('el botón Limpiar avisa al padre', (WidgetTester tester) async {
    bool limpio = false;
    await tester.pumpWidget(
      conPanel(alAplicar: (_) {}, alLimpiar: () => limpio = true),
    );

    await tester.tap(find.byKey(const Key('abrir-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filtro-limpiar')));
    await tester.pumpAndSettle();

    expect(limpio, isTrue);
  });
}
