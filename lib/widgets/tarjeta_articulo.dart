// =============================================================================
// ARCHIVO: lib/widgets/tarjeta_articulo.dart
// DESCRIPCIÓN: Tarjeta que muestra un artículo resumido (usada en Inicio,
//              Favoritos y Mis artículos).
//
// Composición de la tarjeta:
//   - Zona superior: "foto" simulada con un degradado + ícono de la categoría.
//   - Insignia del tipo de publicación (Venta / Intercambio / Regalo).
//   - Botón de favorito (corazón).
//   - Zona inferior: título, categoría y precio.
//
// NOTA (primer avance): es SOLO VISUAL. El botón de favorito todavía no cambia
// el estado del artículo; esa lógica se implementará más adelante.
// =============================================================================

import 'package:flutter/material.dart';

import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Tarjeta reutilizable para mostrar un [Articulo].
class TarjetaArticulo extends StatelessWidget {
  /// Artículo que se va a mostrar.
  final Articulo articulo;

  /// Acción al tocar la tarjeta (abrir el detalle). Puede ser `null`.
  final VoidCallback? alTocar;

  /// Acción al tocar el corazón de favoritos. Puede ser `null`.
  final VoidCallback? alTocarFavorito;

  const TarjetaArticulo({
    super.key,
    required this.articulo,
    this.alTocar,
    this.alTocarFavorito,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: alTocar,
        child: Column(
          // La imagen ocupa el espacio que sobre y el texto usa su altura natural,
          // evitando que la tarjeta se desborde dentro de la cuadrícula.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _ImagenArticulo(
                articulo: articulo,
                alTocarFavorito: alTocarFavorito,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ----------------------- Título -----------------------
                  Text(
                    articulo.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // --------------------- Categoría ----------------------
                  Row(
                    children: <Widget>[
                      Icon(
                        articulo.categoria.icono,
                        size: 13,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          articulo.categoria.etiqueta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ---------------------- Precio ------------------------
                  Text(
                    articulo.precioTexto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      // El precio destacado usa el color principal, salvo en
                      // regalos e intercambios, donde usamos el color del tipo.
                      color: articulo.tipo == TipoPublicacion.venta
                          ? tema.colorScheme.primary
                          : articulo.tipo.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zona superior de la tarjeta: imagen simulada + insignia + favorito.
///
/// Es privada (empieza con "_") porque solo se usa dentro de este archivo.
class _ImagenArticulo extends StatelessWidget {
  final Articulo articulo;
  final VoidCallback? alTocarFavorito;

  const _ImagenArticulo({
    required this.articulo,
    this.alTocarFavorito,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorTipo = articulo.tipo.color;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Fondo con degradado que simula la foto del artículo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                colorTipo.withValues(alpha: 0.85),
                colorTipo.withValues(alpha: 0.50),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              articulo.categoria.icono,
              size: 52,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),

        // Insignia del tipo de publicación (arriba a la izquierda).
        Positioned(
          top: 8,
          left: 8,
          child: _InsigniaTipo(tipo: articulo.tipo),
        ),

        // Botón de favorito (arriba a la derecha).
        Positioned(
          top: 4,
          right: 4,
          child: _BotonFavorito(
            esFavorito: articulo.esFavorito,
            alTocar: alTocarFavorito,
          ),
        ),
      ],
    );
  }
}

/// Etiqueta blanca que indica si el artículo es venta, intercambio o regalo.
class _InsigniaTipo extends StatelessWidget {
  final TipoPublicacion tipo;

  const _InsigniaTipo({required this.tipo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(tipo.icono, size: 13, color: tipo.color),
          const SizedBox(width: 4),
          Text(
            tipo.etiqueta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tipo.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular (corazón) que marca o desmarca un artículo como favorito.
/// Por ahora solo muestra el estado; la acción se conectará más adelante.
class _BotonFavorito extends StatelessWidget {
  final bool esFavorito;
  final VoidCallback? alTocar;

  const _BotonFavorito({required this.esFavorito, this.alTocar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        // `?? () {}` permite que el botón se vea activo aunque aún no haga nada.
        onTap: alTocar ?? () {},
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            esFavorito ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: esFavorito ? const Color(0xFFE53935) : Colors.black54,
          ),
        ),
      ),
    );
  }
}
