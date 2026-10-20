// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_detalle_articulo.dart
// DESCRIPCIÓN: Muestra toda la información de un artículo seleccionado:
//              imagen, título, precio, descripción, vendedor y botón de
//              contacto.
//
// El estado del favorito se lee del provider (por id), así que el corazón
// refleja cambios hechos en otras pantallas y los que se hacen aquí.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/articulos_provider.dart';
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
    // Versión fresca del artículo según el provider (por si cambió el favorito).
    final Articulo actual = context.watch<ArticulosProvider>().articuloPorId(articulo.id) ?? articulo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del artículo'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context
                .read<ArticulosProvider>()
                .alternarFavorito(articulo.id),
            icon: Icon(
              actual.esFavorito ? Icons.favorite : Icons.favorite_border,
              color: actual.esFavorito ? const Color(0xFFE53935) : null,
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
            _CabeceraImagen(articulo: actual),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ----------------- Etiquetas superiores ----------------
                  Row(
                    children: <Widget>[
                      _Pastilla(
                        icono: actual.tipo.icono,
                        texto: actual.tipo.etiqueta,
                        color: actual.tipo.color,
                      ),
                      const SizedBox(width: 8),
                      _Pastilla(
                        icono: actual.categoria.icono,
                        texto: actual.categoria.etiqueta,
                        color: tema.colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // -------------------------- Título ---------------------
                  Text(
                    actual.titulo,
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // -------------------------- Precio ---------------------
                  Text(
                    actual.precioTexto,
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: actual.tipo == TipoPublicacion.venta
                          ? tema.colorScheme.primary
                          : actual.tipo.color,
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
                    actual.descripcion,
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
                  _TarjetaVendedor(nombre: actual.vendedor),
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El chat con el vendedor llegará pronto.'),
                ),
              );
            },
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
