// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_favoritos.dart
// DESCRIPCIÓN: Pestaña "Favoritos". Muestra los artículos marcados como
//              favoritos, cargados por páginas desde [ArticulosProvider].
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/articulos_provider.dart';
import '../modelos/articulo.dart';
import '../widgets/estado_placeholder.dart';
import '../widgets/tarjeta_articulo.dart';
import 'pantalla_detalle_articulo.dart';

/// Pantalla de Favoritos (pestaña "Favoritos" de la barra inferior).
class PantallaFavoritos extends StatefulWidget {
  const PantallaFavoritos({super.key});

  @override
  State<PantallaFavoritos> createState() => _PantallaFavoritosState();
}

class _PantallaFavoritosState extends State<PantallaFavoritos> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ArticulosProvider>().cargarFavoritos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ArticulosProvider proveedor = context.watch<ArticulosProvider>();
    final List<Articulo> favoritos = proveedor.favoritos;

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: proveedor.cargandoFavoritos && favoritos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : favoritos.isEmpty
              ? const EstadoPlaceholder(
                  icono: Icons.favorite_border,
                  titulo: 'Todavía no tienes favoritos',
                  subtitulo: 'Guarda artículos para verlos aquí',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: favoritos.length + (proveedor.hayMasFavoritos ? 1 : 0),
                  itemBuilder: (BuildContext context, int indice) {
                    if (indice == favoritos.length) {
                      return Center(
                        child: proveedor.cargandoMasFavoritos
                            ? const CircularProgressIndicator()
                            : FilledButton.tonal(
                                onPressed: proveedor.cargarMasFavoritos,
                                child: const Text('Cargar más'),
                              ),
                      );
                    }
                    final Articulo articulo = favoritos[indice];
                    return TarjetaArticulo(
                      articulo: articulo,
                      alTocar: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PantallaDetalleArticulo(articulo: articulo),
                          ),
                        );
                      },
                      alTocarFavorito: () => context
                          .read<ArticulosProvider>()
                          .alternarFavorito(articulo.id),
                    );
                  },
                ),
    );
  }
}
