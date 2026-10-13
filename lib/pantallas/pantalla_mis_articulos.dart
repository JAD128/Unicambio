// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_mis_articulos.dart
// DESCRIPCIÓN: Pestaña "Mis artículos". Muestra las publicaciones que hizo el
//              propio estudiante, con opciones de editar y eliminar.
//
// NOTA (primer avance): es SOLO VISUAL. Las opciones "Editar" y "Eliminar" del
// menú todavía no cambian nada; la lógica llegará en la siguiente etapa.
// =============================================================================

import 'package:flutter/material.dart';

import '../datos/articulos_ejemplo.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Pantalla "Mis artículos" (pestaña de la barra inferior).
class PantallaMisArticulos extends StatelessWidget {
  const PantallaMisArticulos({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis artículos')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Encabezado con el número de publicaciones.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Tienes ${misArticulosEjemplo.length} publicaciones activas',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Lista vertical de tarjetas horizontales.
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: misArticulosEjemplo.length,
              separatorBuilder: (BuildContext context, int indice) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int indice) {
                return _TarjetaMiArticulo(
                  articulo: misArticulosEjemplo[indice],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta horizontal para una publicación propia.
/// A la izquierda muestra la miniatura y a la derecha la información y el menú.
class _TarjetaMiArticulo extends StatelessWidget {
  final Articulo articulo;

  const _TarjetaMiArticulo({required this.articulo});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            // ----------------------- Miniatura -----------------------
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    articulo.tipo.color.withValues(alpha: 0.85),
                    articulo.tipo.color.withValues(alpha: 0.50),
                  ],
                ),
              ),
              child: Icon(
                articulo.categoria.icono,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 12),

            // ------------------- Información central ------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    articulo.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Insignia con el tipo de publicación.
                  _EtiquetaTipo(tipo: articulo.tipo),
                  const SizedBox(height: 6),
                  Text(
                    articulo.precioTexto,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: articulo.tipo == TipoPublicacion.venta
                          ? tema.colorScheme.primary
                          : articulo.tipo.color,
                    ),
                  ),
                ],
              ),
            ),

            // --------------- Menú de opciones (visual) ----------------
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (_) {},
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'editar',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'eliminar',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pequeña etiqueta que indica el tipo de publicación (Venta/Intercambio/Regalo).
class _EtiquetaTipo extends StatelessWidget {
  final TipoPublicacion tipo;

  const _EtiquetaTipo({required this.tipo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(tipo.icono, size: 14, color: tipo.color),
        const SizedBox(width: 4),
        Text(
          tipo.etiqueta,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tipo.color,
          ),
        ),
      ],
    );
  }
}
