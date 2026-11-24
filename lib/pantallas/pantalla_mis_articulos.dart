// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_mis_articulos.dart
// DESCRIPCIÓN: Pestaña "Mis artículos". Muestra las publicaciones propias
//              (las de la cuenta autenticada) con opciones de editar y
//              eliminar, conectadas a [ArticulosProvider].
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/almacenamiento_imagenes.dart';
import '../estado/articulos_provider.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import '../widgets/estado_placeholder.dart';
import 'pantalla_publicar.dart';

/// Pantalla "Mis artículos" (pestaña de la barra inferior).
class PantallaMisArticulos extends StatefulWidget {
  const PantallaMisArticulos({super.key});

  @override
  State<PantallaMisArticulos> createState() => _PantallaMisArticulosState();
}

class _PantallaMisArticulosState extends State<PantallaMisArticulos> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ArticulosProvider>().cargarMis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ArticulosProvider proveedor = context.watch<ArticulosProvider>();
    final List<Articulo> mios = proveedor.mios;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis artículos')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Tienes ${mios.length} publicaciones activas',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: proveedor.cargandoMis && mios.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : mios.isEmpty
                ? const EstadoPlaceholder(
                    icono: Icons.inventory_2_outlined,
                    titulo: 'Aún no has publicado nada',
                    subtitulo: 'Toca "Publicar" para crear tu primer anuncio',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: mios.length + (proveedor.hayMasMis ? 1 : 0),
                    separatorBuilder: (BuildContext context, int indice) =>
                        const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int indice) {
                      if (indice == mios.length) {
                        return Center(
                          child: proveedor.cargandoMasMis
                              ? const CircularProgressIndicator()
                              : FilledButton.tonal(
                                  onPressed: proveedor.cargarMasMis,
                                  child: const Text('Cargar más'),
                                ),
                        );
                      }
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

  /// Alterna la publicación entre disponible y finalizada.
  Future<void> _cambiarEstado(BuildContext context) async {
    final ArticulosProvider proveedor = context.read<ArticulosProvider>();
    final EstadoPublicacion nuevo =
        articulo.estado == EstadoPublicacion.disponible
        ? EstadoPublicacion.finalizado
        : EstadoPublicacion.disponible;
    await proveedor.cambiarEstado(articulo.id, nuevo);
  }

  /// Elimina el artículo después de que el usuario confirme en el diálogo.
  Future<void> _eliminar(BuildContext context) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext contexto) => AlertDialog(
        title: const Text('Eliminar artículo'),
        content: Text(
          '¿Eliminar "${articulo.titulo}"? Esta acción no se puede deshacer.',
        ),
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
      final ArticulosProvider proveedor = context.read<ArticulosProvider>();
      await proveedor.eliminar(articulo.id);
      if (proveedor.error == null && articulo.imagenUrl != null) {
        try {
          await AlmacenamientoImagenes().eliminar(articulo.imagenUrl);
        } catch (_) {
          // Si falla el borrado de la foto, el artículo ya se eliminó igual.
        }
      }
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
                  const SizedBox(height: 4),
                  Row(
                    key: Key('estado-mis-${articulo.id}'),
                    children: <Widget>[
                      Icon(
                        articulo.estado == EstadoPublicacion.disponible
                            ? Icons.check_circle_outline
                            : Icons.lock_outline,
                        size: 14,
                        color: articulo.estado == EstadoPublicacion.disponible
                            ? tema.colorScheme.primary
                            : tema.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        articulo.estado.etiquetaPara(articulo.tipo),
                        style: TextStyle(
                          fontSize: 12,
                          color: articulo.estado == EstadoPublicacion.disponible
                              ? tema.colorScheme.primary
                              : tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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
                } else if (valor == 'estado') {
                  _cambiarEstado(context);
                } else if (valor == 'eliminar') {
                  _eliminar(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  key: const Key('cambiar-estado'),
                  value: 'estado',
                  child: Row(
                    children: <Widget>[
                      Icon(
                        articulo.estado == EstadoPublicacion.disponible
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        articulo.estado == EstadoPublicacion.disponible
                            ? 'Marcar como finalizado'
                            : 'Marcar como disponible',
                      ),
                    ],
                  ),
                ),
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
                PopupMenuItem<String>(
                  value: 'eliminar',
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: tema.colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: tema.colorScheme.error),
                      ),
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
