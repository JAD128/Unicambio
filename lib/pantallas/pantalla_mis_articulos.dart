// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_mis_articulos.dart
// DESCRIPCIÓN: Pestaña "Mis artículos". Muestra las publicaciones propias
//              (por ahora las del vendedor provisional) con opciones de
//              editar y eliminar, conectadas a [ArticulosProvider].
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/articulos_provider.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import '../widgets/estado_placeholder.dart';
import 'pantalla_publicar.dart';

/// Pantalla "Mis artículos" (pestaña de la barra inferior).
class PantallaMisArticulos extends StatelessWidget {
  const PantallaMisArticulos({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ArticulosProvider proveedor = context.watch<ArticulosProvider>();

    // Por ahora "míos" = los que tienen el vendedor provisional. En el
    // Avance 9 se filtrará por la cuenta autenticada.
    final List<Articulo> mios = proveedor.todos
        .where((Articulo articulo) => articulo.vendedor == vendedorPropio)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis artículos')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Encabezado con el número de publicaciones.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Tienes ${mios.length} publicaciones activas',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Lista vertical de tarjetas horizontales (o estado vacío).
          Expanded(
            child: mios.isEmpty
                ? const EstadoPlaceholder(
                    icono: Icons.inventory_2_outlined,
                    titulo: 'Aún no has publicado nada',
                    subtitulo: 'Toca "Publicar" para crear tu primer anuncio',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: mios.length,
                    separatorBuilder: (BuildContext context, int indice) =>
                        const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int indice) {
                      return _TarjetaMiArticulo(articulo: mios[indice]);
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

  /// Elimina el artículo después de que el usuario confirme en el diálogo.
  Future<void> _eliminar(BuildContext context) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext contexto) => AlertDialog(
        title: const Text('Eliminar artículo'),
        content: Text('¿Eliminar "${articulo.titulo}"? Esta acción no se puede deshacer.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true && context.mounted) {
      context.read<ArticulosProvider>().eliminar(articulo.id);
    }
  }

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

            // ---------------- Menú de opciones ----------------
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String valor) {
                if (valor == 'editar') {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PantallaPublicar(articulo: articulo),
                    ),
                  );
                } else if (valor == 'eliminar') {
                  _eliminar(context);
                }
              },
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
