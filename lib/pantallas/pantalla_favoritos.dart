// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_favoritos.dart
// DESCRIPCIÓN: Pestaña "Favoritos". Muestra los artículos marcados como
//              favoritos (dato real desde SQLite, vía [ArticulosProvider]).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/articulos_provider.dart';
import '../modelos/articulo.dart';
import '../widgets/estado_placeholder.dart';
import '../widgets/tarjeta_articulo.dart';
import 'pantalla_detalle_articulo.dart';

/// Pantalla de Favoritos (pestaña "Favoritos" de la barra inferior).
class PantallaFavoritos extends StatelessWidget {
  const PantallaFavoritos({super.key});

  @override
  Widget build(BuildContext context) {
    final ArticulosProvider proveedor = context.watch<ArticulosProvider>();
    final List<Articulo> favoritos = proveedor.favoritos;

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favoritos.isEmpty
          ? const EstadoPlaceholder(
              icono: Icons.favorite_border,
              titulo: 'Todavía no tienes favoritos',
              subtitulo: 'Guarda artículos para verlos aquí',
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: favoritos.length,
              itemBuilder: (BuildContext context, int indice) {
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
