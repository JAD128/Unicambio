// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_inicio.dart
// DESCRIPCIÓN: Pantalla principal de UniCambio. Muestra:
//   - Un saludo al estudiante.
//   - La barra de búsqueda.
//   - La fila de filtros por categoría.
//   - La cuadrícula con los artículos de ejemplo.
//
// NOTA (primer avance): la búsqueda y los filtros son SOLO VISUALES. Al tocar
// una tarjeta sí se abre el detalle, porque eso es navegación básica.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../datos/articulos_ejemplo.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/chip_categoria.dart';
import '../widgets/tarjeta_articulo.dart';
import 'pantalla_detalle_articulo.dart';

/// Pantalla de Inicio (pestaña "Inicio" de la barra inferior).
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  /// Abre la pantalla de detalle para el [articulo] seleccionado.
  void _abrirDetalle(BuildContext context, Articulo articulo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleArticulo(articulo: articulo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniCambio'),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ----------------- Saludo + barra de búsqueda -----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Hola, ${FirebaseAuth.instance.currentUser?.displayName ?? 'estudiante'}',
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Encuentra, intercambia y regala lo que necesitas',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                const CampoBusqueda(),
              ],
            ),
          ),

          // ---------------------- Filtros por categoría -----------------
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: <Widget>[
                // El chip "Todos" se muestra seleccionado por defecto.
                const ChipCategoria(seleccionada: true),
                // Un chip por cada categoría disponible.
                ...Categoria.values.map(
                  (Categoria categoria) => ChipCategoria(categoria: categoria),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ----------------------- Título de sección --------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Artículos recientes',
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --------------- Cuadrícula de artículos de ejemplo -----------
          Expanded(
            child: GridView.builder(
              // Relleno inferior para que el botón "Publicar" no tape tarjetas.
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: articulosEjemplo.length,
              itemBuilder: (BuildContext context, int indice) {
                final Articulo articulo = articulosEjemplo[indice];
                return TarjetaArticulo(
                  articulo: articulo,
                  alTocar: () => _abrirDetalle(context, articulo),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
