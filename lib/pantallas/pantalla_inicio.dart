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
import '../estado/perfil_provider.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/chip_categoria.dart';
import '../widgets/estado_placeholder.dart';
import '../widgets/panel_filtros.dart';
import '../widgets/tarjeta_articulo.dart';
import 'pantalla_detalle_articulo.dart';
import 'pantalla_perfil.dart';

/// Pantalla de Inicio (pestaña "Inicio" de la barra inferior).
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarNovedades());
  }

  /// Consulta sugerencias según las preferencias guardadas en el perfil.
  Future<void> _cargarNovedades() async {
    final PerfilProvider perfil = context.read<PerfilProvider>();
    await context.read<ArticulosProvider>().cargarNovedades(
          activas: perfil.sugerenciasActivas,
          categorias: perfil.categoriasSugerencias,
          desde: perfil.ultimaVista,
        );
  }

  /// Muestra la bandeja de sugerencias y la marca como vista.
  Future<void> _mostrarNovedades(
    BuildContext context,
    ArticulosProvider proveedor,
  ) async {
    await context.read<PerfilProvider>().marcarVisto();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext contexto) => SafeArea(
        child: ListView.builder(
          itemCount: proveedor.novedades.length,
          itemBuilder: (BuildContext _, int indice) {
            final Articulo articulo = proveedor.novedades[indice];
            return ListTile(
              leading: Icon(articulo.categoria.icono),
              title: Text(articulo.titulo),
              subtitle: Text(articulo.precioTexto),
              onTap: () {
                Navigator.of(contexto).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PantallaDetalleArticulo(articulo: articulo),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
    if (!context.mounted) return;
    await _cargarNovedades();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    // Observa el provider: cada cambio (búsqueda, filtro, favorito...) redibuja.
    final ArticulosProvider proveedor = context.watch<ArticulosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniCambio'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PantallaPerfil(),
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                    ? NetworkImage(
                        FirebaseAuth.instance.currentUser!.photoURL!,
                      )
                    : null,
                child: FirebaseAuth.instance.currentUser?.photoURL == null
                    ? Text(
                        proveedor.vendedorActual.isEmpty
                            ? '?'
                            : proveedor.vendedorActual
                                .substring(0, 1)
                                .toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
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
                  'Hola, ${proveedor.vendedorActual}',
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
                  alFiltrar: () => _mostrarFiltros(context, proveedor),
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

          // ---------------------- Sugerencias in-app --------------------
          if (proveedor.hayNovedades)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: tema.colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.new_releases_outlined),
                  title: Text(
                    '${proveedor.novedades.length} novedades para ti',
                  ),
                  subtitle: const Text('Toca para verlas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _mostrarNovedades(context, proveedor),
                ),
              ),
            ),
          if (proveedor.hayNovedades) const SizedBox(height: 12),

          // ----------------------- Título de sección --------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Resultados (${proveedor.articulos.length}${proveedor.hayMas ? '+' : ''})',
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

  /// Abre el panel de filtros y aplica los valores elegidos al provider.
  Future<void> _mostrarFiltros(
    BuildContext context,
    ArticulosProvider proveedor,
  ) async {
    final ValoresFiltros? valores = await showModalBottomSheet<ValoresFiltros>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PanelFiltros(
        orden: proveedor.orden,
        precioMinimo: proveedor.precioMinimo,
        precioMaximo: proveedor.precioMaximo,
        alAplicar: (ValoresFiltros valor) => valor,
        alLimpiar: () => proveedor.limpiarFiltros(),
      ),
    );
    if (valores == null || !context.mounted) return;
    await context.read<ArticulosProvider>().actualizarFiltros(
          precioMinimo: valores.precioMinimo,
          precioMaximo: valores.precioMaximo,
          orden: valores.orden,
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
      itemCount: proveedor.articulos.length + (proveedor.hayMas ? 1 : 0),
      itemBuilder: (BuildContext context, int indice) {
        if (indice == proveedor.articulos.length) {
          return Center(
            child: OutlinedButton.icon(
              key: const Key('cargar-mas'),
              onPressed: proveedor.cargandoMas
                  ? null
                  : () => proveedor.cargarMas(),
              icon: proveedor.cargandoMas
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: Text(proveedor.cargandoMas ? 'Cargando...' : 'Cargar más'),
            ),
          );
        }
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
