// =============================================================================
// ARCHIVO: lib/main.dart
// DESCRIPCIÓN: Punto de entrada de la aplicación UniCambio.
//
// Aquí se arranca la app y se define la estructura principal de navegación:
//   - 3 pestañas en la barra inferior: Inicio, Favoritos y Mis artículos.
//   - Un botón flotante "Publicar" que abre el formulario de publicación.
//
// NOTA (primer avance): el cambio de pestaña es lo único "interactivo"; el
// resto de la app es visual (datos de ejemplo, sin base de datos).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'datos/articulo_repositorio.dart';
import 'datos/articulo_repositorio_memoria.dart';
import 'datos/articulos_ejemplo.dart';
import 'datos/semilla.dart';
import 'estado/articulos_provider.dart';
import 'firebase_options.dart';
import 'pantallas/pantalla_autenticacion.dart';
import 'pantallas/pantalla_favoritos.dart';
import 'pantallas/pantalla_inicio.dart';
import 'pantallas/pantalla_mis_articulos.dart';
import 'pantallas/pantalla_publicar.dart';
import 'tema/tema_app.dart';

/// Función principal: es lo primero que se ejecuta al iniciar la aplicación.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? errorFirebase;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    errorFirebase = error;
  }

  // google_sign_in 7.x exige inicializarse exactamente una vez antes de usarlo.
  // Si falla, el botón de Google lo notificará al intentar usarse.
  try {
    await GoogleSignIn.instance.initialize();
  } catch (_) {}

  // Prepara los datos: SQLite en plataformas con sqflite (Android/iOS);
  // si no está disponible (p. ej. web o escritorio), usa la lista en memoria
  // para que la interfaz siga siendo navegable.
  final ArticuloRepositorio repositorio = await _crearRepositorio();
  final ArticulosProvider proveedorArticulos = ArticulosProvider(repositorio);
  await proveedorArticulos.iniciar();

  runApp(
    ChangeNotifierProvider<ArticulosProvider>.value(
      value: proveedorArticulos,
      child: UniCambioApp(errorFirebase: errorFirebase),
    ),
  );
}

/// Crea el repositorio que usará toda la app y siembra los datos de ejemplo
/// (la siembra solo actúa si la base de datos está vacía).
Future<ArticuloRepositorio> _crearRepositorio() async {
  try {
    final ArticuloRepositorioSqflite repositorio = ArticuloRepositorioSqflite();
    await sembrarDatosDeEjemplo(repositorio);
    return repositorio;
  } catch (_) {
    // sqflite no corre en web/escritorio sin ffi: caemos a memoria.
    return ArticuloRepositorioMemoria(iniciales: articulosEjemplo);
  }
}

/// Widget raíz de UniCambio.
/// Configura el título, el tema y la pantalla inicial de la aplicación.
class UniCambioApp extends StatelessWidget {
  const UniCambioApp({
    super.key,
    this.errorFirebase,
    this.firebaseConfigurado = true,
  });

  /// Error de inicialización, si Firebase no pudo arrancar.
  final Object? errorFirebase;

  /// Permite mostrar el aviso de configuración en pruebas de widgets.
  final bool firebaseConfigurado;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniCambio',
      // Quitamos la cinta roja de "debug" para que se vea limpio en la demo.
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      home: errorFirebase != null
          ? _PantallaErrorFirebase(error: errorFirebase!)
          : !firebaseConfigurado
              ? const _PantallaConfigurarFirebase()
              : const _PuertaAutenticacion(),
    );
  }
}

/// Decide qué contenido mostrar a partir de la sesión persistida por Firebase.
class _PuertaAutenticacion extends StatelessWidget {
  const _PuertaAutenticacion();

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, estado) {
          if (estado.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return estado.data == null
              ? const PantallaAutenticacion()
              : const PantallaPrincipal();
        },
      );
}

class _PantallaConfigurarFirebase extends StatelessWidget {
  const _PantallaConfigurarFirebase();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Firebase aún no está configurado. Ejecuta flutterfire configure para generar las opciones de esta plataforma.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

class _PantallaErrorFirebase extends StatelessWidget {
  const _PantallaErrorFirebase({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudo iniciar Firebase. Revisa la configuración del proyecto.\n\n$error', textAlign: TextAlign.center),
          ),
        ),
      );
}

/// Contenedor principal con la barra de navegación inferior.
/// Es "Stateful" porque debe recordar qué pestaña está seleccionada.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  /// Índice de la pestaña actual (0 = Inicio, 1 = Favoritos, 2 = Mis artículos).
  int _indiceActual = 0;

  /// Lista de pantallas que corresponden a cada pestaña.
  static const List<Widget> _pestanias = <Widget>[
    PantallaInicio(),
    PantallaFavoritos(),
    PantallaMisArticulos(),
  ];

  /// Abre la pantalla del formulario de publicación.
  void _abrirPublicar() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaPublicar()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Muestra la pestaña seleccionada.
      body: _pestanias[_indiceActual],

      // Botón flotante para publicar un artículo nuevo.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirPublicar,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),

      // Barra de navegación inferior con las 3 secciones.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (int indice) {
          setState(() => _indiceActual = indice);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Mis artículos',
          ),
        ],
      ),
    );
  }
}
