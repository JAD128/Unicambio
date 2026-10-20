// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_inicio.dart
// DESCRIPCIÓN: Pantalla principal de UniCambio. Muestra:
//   - Un saludo al estudiante.
//   - La barra de búsqueda (filtra por título en tiempo real).
//   - La fila de filtros por categoría.
//   - La cuadrícula con los artículos de la base de datos (vía provider).
//
// Los datos llegan de [ArticulosProvider]: esta pantalla solo observa el estado
// (`context.watch`) y envía acciones (`context.read`); nunca toca SQLite.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../estado/articulos_provider.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/chip_categoria.dart';
import '../widgets/estado_placeholder.dart';
import '../widgets/tarjeta_articulo.dart';
import 'pantalla_detalle_articulo.dart';

/// Pantalla de Inicio (pestaña "Inicio" de la barra inferior).
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    // Observa el provider: cada cambio (búsqueda, filtro, favorito...) redibuja.
    final ArticulosProvider proveedor = context.watch<ArticulosProvider>();

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
                CampoBusqueda(
                  textoInicial: proveedor.textoBusqueda,
                  alCambiar: (String texto) =>
                      context.read<ArticulosProvider>().actualizarBusqueda(texto),
                ),
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
                // Chip "Todos": se marca cuando no hay categoría elegida.
                ChipCategoria(
                  seleccionada: proveedor.categoriaSeleccionada == null,
                  alSeleccionar: () => context
                      .read<ArticulosProvider>()
                      .seleccionarCategoria(null),
                ),
                // Un chip por cada categoría disponible.
                ...Categoria.values.map(
                  (Categoria categoria) => ChipCategoria(
                    categoria: categoria,
                    seleccionada: proveedor.categoriaSeleccionada == categoria,
                    alSeleccionar: () => context
                        .read<ArticulosProvider>()
                        .seleccionarCategoria(categoria),
                  ),
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

          // ----------------- Cuadrícula (o estado vacío) ----------------
          Expanded(child: _CuerpoLista(proveedor: proveedor)),
        ],
      ),
    );
  }
}

/// Muestra la lista de artículos o el estado que corresponda:
/// carga, error, vacío o resultados.
class _CuerpoLista extends StatelessWidget {
  final ArticulosProvider proveedor;

  const _CuerpoLista({required this.proveedor});

  @override
  Widget build(BuildContext context) {
    if (proveedor.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (proveedor.error != null) {
      return EstadoPlaceholder(
        icono: Icons.error_outline,
        titulo: 'No se pudieron cargar los artículos',
        subtitulo: proveedor.error,
      );
    }
    if (proveedor.listaVacia) {
      return const EstadoPlaceholder(
        icono: Icons.search_off,
        titulo: 'No hay artículos',
        subtitulo: 'Publica el primero o prueba otra búsqueda.',
      );
    }

    // Relleno inferior para que el botón "Publicar" no tape tarjetas.
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: proveedor.articulos.length,
      itemBuilder: (BuildContext context, int indice) {
        final Articulo articulo = proveedor.articulos[indice];
        return TarjetaArticulo(
          articulo: articulo,
          alTocar: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PantallaDetalleArticulo(articulo: articulo),
              ),
            );
          },
          alTocarFavorito: () => context
              .read<ArticulosProvider>()
              .alternarFavorito(articulo.id),
        );
      },
    );
  }
}
