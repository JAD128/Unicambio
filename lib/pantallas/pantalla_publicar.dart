// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_publicar.dart
// DESCRIPCIÓN: Formulario para publicar un artículo nuevo o editar uno
//              existente. Valida los campos y guarda mediante
//              [ArticulosProvider] (que usa SQLite).
//
// El mismo formulario sirve para crear y para editar: si se recibe un
// [articulo], los campos vienen precargados y al guardar se actualiza.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    if (!_formKey.currentState!.validate()) return;

    // En regalo/intercambio el precio no aplica; en venta se lee el campo.
    final double precio =
        _tipo == TipoPublicacion.venta ? (double.tryParse(_precio.text) ?? 0) : 0;

    final Articulo articulo = Articulo(
      // Mismo formato de id que usa el resto de la app (y la semilla).
      id: widget.articulo?.id ??
          'art_${DateTime.now().microsecondsSinceEpoch}',
      titulo: _titulo.text.trim(),
      descripcion: _descripcion.text.trim(),
      precio: precio,
      categoria: _categoria,
      tipo: _tipo,
      vendedor: widget.articulo?.vendedor ?? vendedorPropio,
      esFavorito: widget.articulo?.esFavorito ?? false,
    );

    final ArticulosProvider proveedor = context.read<ArticulosProvider>();
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
              // Solo visual: la cámara/galería llega en el Avance 8.
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las fotos llegarán en un próximo avance.'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Agregar foto'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // -------------------------- Guardar --------------------------
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.check),
                label: Text(_esEdicion ? 'Guardar cambios' : 'Publicar artículo'),
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
