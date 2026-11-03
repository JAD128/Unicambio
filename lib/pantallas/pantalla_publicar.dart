// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_publicar.dart
// DESCRIPCIÓN: Formulario para publicar un artículo nuevo o editar uno
//              existente. Valida los campos y guarda mediante
//              [ArticulosProvider] (que usa SQLite).
//
// El mismo formulario sirve para crear y para editar: si se recibe un
// [articulo], los campos vienen precargados y al guardar se actualiza.
// =============================================================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../datos/almacenamiento_imagenes.dart';
import '../estado/articulos_provider.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Pantalla del formulario de publicación.
class PantallaPublicar extends StatefulWidget {
  /// Artículo a editar. Si es `null`, el formulario crea uno nuevo.
  final Articulo? articulo;

  const PantallaPublicar({super.key, this.articulo});

  @override
  State<PantallaPublicar> createState() => _PantallaPublicarState();
}

class _PantallaPublicarState extends State<PantallaPublicar> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  late final TextEditingController _precio;
  late TipoPublicacion _tipo;
  late Categoria _categoria;
  final ImagePicker _selectorImagen = ImagePicker();
  XFile? _imagenSeleccionada;
  Uint8List? _bytesImagen;
  String? _imagenUrl;
  bool _quitarImagen = false;
  bool _guardando = false;

  bool get _esEdicion => widget.articulo != null;

  @override
  void initState() {
    super.initState();
    final Articulo? original = widget.articulo;
    _titulo = TextEditingController(text: original?.titulo ?? '');
    _descripcion = TextEditingController(text: original?.descripcion ?? '');
    _precio = TextEditingController(
      text: original == null || original.precio <= 0
          ? ''
          : original.precio.toStringAsFixed(0),
    );
    _tipo = original?.tipo ?? TipoPublicacion.venta;
    _categoria = original?.categoria ?? Categoria.libros;
    _imagenUrl = original?.imagenUrl;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _precio.dispose();
    super.dispose();
  }

  /// Valida el formulario y guarda (inserta o actualiza) el artículo.
  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final ArticulosProvider proveedor = context.read<ArticulosProvider>();

    try {
      final String id = widget.articulo?.id ??
          'art_${DateTime.now().microsecondsSinceEpoch}';
      String? imagenUrl = _quitarImagen ? null : _imagenUrl;
      if (_imagenSeleccionada != null && _bytesImagen != null) {
        imagenUrl = await AlmacenamientoImagenes().subir(
          articuloId: id,
          bytes: _bytesImagen!,
          nombreArchivo: _imagenSeleccionada!.name,
          tipoContenido: _imagenSeleccionada!.mimeType ?? 'image/jpeg',
        );
      }

      final double precio = _tipo == TipoPublicacion.venta
          ? (double.tryParse(_precio.text) ?? 0)
          : 0;
      final Articulo articulo = Articulo(
        id: id,
        titulo: _titulo.text.trim(),
        descripcion: _descripcion.text.trim(),
        precio: precio,
        categoria: _categoria,
        tipo: _tipo,
        vendedor: widget.articulo?.vendedor ?? vendedorPropio,
        esFavorito: widget.articulo?.esFavorito ?? false,
        imagenUrl: imagenUrl,
      );

      if (_esEdicion) {
        await proveedor.actualizar(articulo);
      } else {
        await proveedor.insertar(articulo);
      }
      if (!mounted) return;
      if (proveedor.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(proveedor.error!)),
        );
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la foto o el artículo: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _mostrarOpcionesImagen() async {
    final ImageSource? origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    try {
      final XFile? archivo = await _selectorImagen.pickImage(
        source: origen,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (archivo == null) return;
      final Uint8List bytes = await archivo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imagenSeleccionada = archivo;
        _bytesImagen = bytes;
        _quitarImagen = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la imagen: $error')),
      );
    }
  }

  void _quitarFoto() {
    setState(() {
      _imagenSeleccionada = null;
      _bytesImagen = null;
      _imagenUrl = null;
      _quitarImagen = true;
    });
  }
  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    // Si la publicación es regalo/intercambio, el precio se oculta.
    final bool mostrarPrecio = _tipo == TipoPublicacion.venta;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar artículo' : 'Publicar artículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ---------------------- Nombre del artículo -------------------
              TextFormField(
                controller: _titulo,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del artículo',
                  hintText: 'Ej: Calculadora científica',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (String? valor) =>
                    (valor == null || valor.trim().isEmpty)
                        ? 'Escribe un título'
                        : null,
              ),
              const SizedBox(height: 14),

              // ------------------------- Descripción -----------------------
              TextFormField(
                controller: _descripcion,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe el estado y los detalles del artículo',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (String? valor) =>
                    (valor == null || valor.trim().isEmpty)
                        ? 'Escribe una descripción'
                        : null,
              ),
              const SizedBox(height: 20),

              // --------------------- Tipo de publicación -------------------
              _TituloSeccion(texto: 'Tipo de publicación', tema: tema),
              const SizedBox(height: 8),
              SegmentedButton<TipoPublicacion>(
                segments: TipoPublicacion.values
                    .map(
                      (TipoPublicacion tipo) => ButtonSegment<TipoPublicacion>(
                        value: tipo,
                        label: Text(tipo.etiqueta),
                      ),
                    )
                    .toList(),
                selected: <TipoPublicacion>{_tipo},
                onSelectionChanged: (Set<TipoPublicacion> seleccion) {
                  setState(() => _tipo = seleccion.first);
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 20),

              // --------------------------- Precio --------------------------
              // Solo se muestra para ventas; regalo muestra "Gratis" y
              // intercambio "A convenir" automáticamente.
              if (mostrarPrecio) ...<Widget>[
                _TituloSeccion(texto: 'Precio', tema: tema),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _precio,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (String? valor) {
                    if (valor == null || valor.trim().isEmpty) return null;
                    final double? numero = double.tryParse(valor.trim());
                    return (numero == null || numero < 0)
                        ? 'Precio no válido'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // -------------------------- Categoría ------------------------
              _TituloSeccion(texto: 'Categoría', tema: tema),
              const SizedBox(height: 8),
              DropdownButtonFormField<Categoria>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: Categoria.values
                    .map(
                      (Categoria categoria) => DropdownMenuItem<Categoria>(
                        value: categoria,
                        child: Text(categoria.etiqueta),
                      ),
                    )
                    .toList(),
                onChanged: (Categoria? valor) {
                  if (valor != null) setState(() => _categoria = valor);
                },
              ),
              const SizedBox(height: 24),

              // ---------------------------- Foto ---------------------------
              _VistaPreviaImagen(
                bytes: _bytesImagen,
                url: _quitarImagen ? null : _imagenUrl,
                categoria: _categoria,
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _mostrarOpcionesImagen,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                        _bytesImagen != null || _imagenUrl != null
                            ? 'Cambiar foto'
                            : 'Agregar foto',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                  if (_bytesImagen != null || _imagenUrl != null) ...<Widget>[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _quitarFoto,
                      tooltip: 'Quitar foto',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),

              // -------------------------- Guardar --------------------------
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _guardando
                      ? 'Guardando...'
                      : _esEdicion
                          ? 'Guardar cambios'
                          : 'Publicar artículo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Título pequeño que separa las secciones del formulario.
class _TituloSeccion extends StatelessWidget {
  final String texto;
  final ThemeData tema;

  const _TituloSeccion({required this.texto, required this.tema});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

/// Muestra la foto elegida o un espacio para indicar que no hay imagen.
class _VistaPreviaImagen extends StatelessWidget {
  const _VistaPreviaImagen({
    required this.bytes,
    required this.url,
    required this.categoria,
  });

  final Uint8List? bytes;
  final String? url;
  final Categoria categoria;

  @override
  Widget build(BuildContext context) {
    final Widget contenido;
    if (bytes != null) {
      contenido = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (url != null) {
      contenido = Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _marcador(context),
      );
    } else {
      contenido = _marcador(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: contenido,
      ),
    );
  }

  Widget _marcador(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            categoria.icono,
            size: 54,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}
