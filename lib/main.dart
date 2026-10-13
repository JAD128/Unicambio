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

import 'pantallas/pantalla_favoritos.dart';
import 'pantallas/pantalla_inicio.dart';
import 'pantallas/pantalla_mis_articulos.dart';
import 'pantallas/pantalla_publicar.dart';
import 'tema/tema_app.dart';

/// Función principal: es lo primero que se ejecuta al iniciar la aplicación.
void main() {
  runApp(const UniCambioApp());
}

/// Widget raíz de UniCambio.
/// Configura el título, el tema y la pantalla inicial de la aplicación.
class UniCambioApp extends StatelessWidget {
  const UniCambioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniCambio',
      // Quitamos la cinta roja de "debug" para que se vea limpio en la demo.
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      home: const PantallaPrincipal(),
    );
  }
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
