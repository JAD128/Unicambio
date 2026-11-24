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
import 'package:unicambio/datos/lanzador_whatsapp.dart';
import 'package:unicambio/datos/perfil_repositorio.dart';
import 'package:unicambio/estado/articulos_provider.dart';
import 'package:unicambio/estado/perfil_provider.dart';
import 'package:unicambio/main.dart';
import 'package:unicambio/pantallas/pantalla_detalle_articulo.dart';
import 'package:unicambio/pantallas/pantalla_favoritos.dart';
import 'package:unicambio/pantallas/pantalla_mis_articulos.dart';
import 'package:unicambio/pantallas/pantalla_publicar.dart';
import 'package:unicambio/modelos/articulo.dart';
import 'package:unicambio/modelos/categoria.dart';
import 'package:unicambio/modelos/perfil_usuario.dart';
import 'package:unicambio/tema/adaptativo.dart';
import 'package:unicambio/tema/tema_app.dart';

/// Lanzador falso que solo recuerda los mensajes enviados.
class LanzadorFalso implements LanzadorWhatsapp {
  String? telefono;
  String? mensajeContacto;
  String? mensajeCompartir;

  @override
  Future<bool> contactar({
    required String telefono,
    required String mensaje,
  }) async {
    this.telefono = telefono;
    mensajeContacto = mensaje;
    return true;
  }

  @override
  Future<bool> compartir(String mensaje) async {
    mensajeCompartir = mensaje;
    return true;
  }
}

/// Envuelve [pantalla] con providers de prueba (repositorios en memoria).
Widget conProvider(
  Widget pantalla, {
  PerfilRepositorio? repositorioPerfil,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ArticulosProvider>(
        create: (_) => ArticulosProvider(
          ArticuloRepositorioMemoria(iniciales: articulosEjemplo),
        ),
      ),
      ChangeNotifierProvider<PerfilProvider>(
        create: (_) => PerfilProvider(
          repositorioPerfil ?? PerfilRepositorioMemoria(),
        ),
      ),
    ],
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

  testWidgets('la hoja iOS tiene fondo opaco y asa',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HojaAdaptativaIos(child: Text('Contenido de la hoja')),
      ),
    );

    final Container hoja = tester.widget(
      find.byKey(const Key('hoja-adaptativa-ios')),
    );
    expect((hoja.decoration! as BoxDecoration).color, TemaApp.colorSuperficie);
    expect(find.text('Contenido de la hoja'), findsOneWidget);
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

  testWidgets('el detalle contacta y comparte por WhatsApp con texto',
      (WidgetTester tester) async {
    final LanzadorFalso lanzador = LanzadorFalso();
    final PerfilRepositorio repositorio = PerfilRepositorioMemoria(
      iniciales: <String, PerfilUsuario>{
        'vendedor': const PerfilUsuario(
          uid: 'vendedor',
          telefono: '573001234567',
        ),
      },
    );
    final Articulo articulo = Articulo(
      id: 'w1',
      titulo: 'Libro de prueba',
      descripcion: 'En buen estado',
      precio: 1000,
      categoria: Categoria.libros,
      tipo: TipoPublicacion.venta,
      vendedor: 'Ana',
      uidAutor: 'vendedor',
      creadoEn: DateTime(2026, 11, 23),
    );

    await tester.pumpWidget(
      conProvider(
        PantallaDetalleArticulo(articulo: articulo, lanzador: lanzador),
        repositorioPerfil: repositorio,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('contactar-vendedor')));
    await tester.pumpAndSettle();
    expect(lanzador.telefono, '573001234567');
    expect(lanzador.mensajeContacto, contains('Libro de prueba'));

    await tester.tap(find.byKey(const Key('compartir-whatsapp')));
    await tester.pumpAndSettle();
    expect(lanzador.mensajeCompartir, contains('Libro de prueba'));
  });
}
