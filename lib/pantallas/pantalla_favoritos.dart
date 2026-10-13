// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_favoritos.dart
// DESCRIPCIÓN: Pestaña "Favoritos". Muestra los artículos que el estudiante
//              guardó (datos de ejemplo).
//
// NOTA (primer avance): es SOLO VISUAL. Aún no se pueden añadir ni quitar
// favoritos; se muestran los que vienen precargados en los datos de ejemplo.
// =============================================================================

import 'package:flutter/material.dart';

import '../datos/articulos_ejemplo.dart';
import '../modelos/articulo.dart';
import '../widgets/tarjeta_articulo.dart';
import 'pantalla_detalle_articulo.dart';

/// Pantalla de Favoritos (pestaña "Favoritos" de la barra inferior).
class PantallaFavoritos extends StatelessWidget {
  const PantallaFavoritos({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favoritosEjemplo.isEmpty
          // Caso poco probable con datos de ejemplo, pero dejamos el mensaje
          // listo para cuando se conecte la lógica real.
          ? _MensajeVacio(tema: tema)
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: favoritosEjemplo.length,
              itemBuilder: (BuildContext context, int indice) {
                final Articulo articulo = favoritosEjemplo[indice];
                return TarjetaArticulo(
                  articulo: articulo,
                  // Abre el detalle del artículo al tocarlo.
                  alTocar: () {
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
    );
  }
}

/// Mensaje que se muestra cuando no hay artículos favoritos.
class _MensajeVacio extends StatelessWidget {
  final ThemeData tema;

  const _MensajeVacio({required this.tema});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.favorite_border,
            size: 64,
            color: tema.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no tienes favoritos',
            style: tema.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Guarda artículos para verlos aquí',
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
