// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_detalle_articulo.dart
// DESCRIPCIÓN: Muestra toda la información de un artículo seleccionado:
//              imagen, título, precio, descripción, vendedor y botón de
//              contacto.
//
// NOTA (primer avance): es SOLO VISUAL. El botón "Contactar" y el corazón de
// favorito todavía no realizan acciones.
// =============================================================================

import 'package:flutter/material.dart';

import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Pantalla de detalle. Recibe el [articulo] que se quiere mostrar.
class PantallaDetalleArticulo extends StatelessWidget {
  /// Artículo que se muestra en el detalle.
  final Articulo articulo;

  const PantallaDetalleArticulo({super.key, required this.articulo});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del artículo'),
        actions: <Widget>[
          // Corazón de favoritos (solo muestra el estado actual).
          IconButton(
            onPressed: () {},
            icon: Icon(
              articulo.esFavorito ? Icons.favorite : Icons.favorite_border,
              color: articulo.esFavorito ? const Color(0xFFE53935) : null,
            ),
            tooltip: 'Favorito',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ------------------ Imagen grande simulada ------------------
            _CabeceraImagen(articulo: articulo),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ----------------- Etiquetas superiores ----------------
                  Row(
                    children: <Widget>[
                      _Pastilla(
                        icono: articulo.tipo.icono,
                        texto: articulo.tipo.etiqueta,
                        color: articulo.tipo.color,
                      ),
                      const SizedBox(width: 8),
                      _Pastilla(
                        icono: articulo.categoria.icono,
                        texto: articulo.categoria.etiqueta,
                        color: tema.colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // -------------------------- Título ---------------------
                  Text(
                    articulo.titulo,
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // -------------------------- Precio ---------------------
                  Text(
                    articulo.precioTexto,
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: articulo.tipo == TipoPublicacion.venta
                          ? tema.colorScheme.primary
                          : articulo.tipo.color,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ----------------------- Descripción -------------------
                  Text(
                    'Descripción',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    articulo.descripcion,
                    style: tema.textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // ------------------------- Vendedor --------------------
                  Text(
                    'Publicado por',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TarjetaVendedor(nombre: articulo.vendedor),
                ],
              ),
            ),
          ],
        ),
      ),

      // Botón fijo en la parte inferior para contactar al vendedor.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Contactar al vendedor'),
          ),
        ),
      ),
    );
  }
}

/// Imagen grande simulada del artículo (degradado + ícono de la categoría).
class _CabeceraImagen extends StatelessWidget {
  final Articulo articulo;

  const _CabeceraImagen({required this.articulo});

  @override
  Widget build(BuildContext context) {
    final Color colorTipo = articulo.tipo.color;

    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorTipo.withValues(alpha: 0.90),
            colorTipo.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          articulo.categoria.icono,
          size: 96,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

/// Pastilla de color con ícono y texto (para tipo y categoría).
class _Pastilla extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const _Pastilla({
    required this.icono,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con la información del estudiante que publicó el artículo.
class _TarjetaVendedor extends StatelessWidget {
  final String nombre;

  const _TarjetaVendedor({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    // Tomamos la primera letra del nombre para el avatar circular.
    final String inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 22,
              backgroundColor: tema.colorScheme.primaryContainer,
              child: Text(
                inicial,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tema.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Estudiante de la universidad',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.verified_outlined, color: Color(0xFF00897B)),
          ],
        ),
      ),
    );
  }
}
