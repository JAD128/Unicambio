// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_publicar.dart
// DESCRIPCIÓN: Formulario para publicar un artículo nuevo o editar uno
//              existente. Valida los campos y guarda mediante
//              [ArticulosProvider] (Firestore en la app; memoria en pruebas).
//
// El mismo formulario sirve para crear y para editar: si se recibe un
// [articulo], los campos vienen precargados y al guardar se actualiza.
// =============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, MaxLengthEnforcement, TextInputFormatter;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../datos/almacenamiento_imagenes.dart';
import '../datos/generador_descripcion.dart';
import '../datos/servicio_vision.dart';
import '../datos/servicios_publicacion.dart';
import '../datos/sugeridor_publicacion.dart';
import '../estado/articulos_provider.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import '../modelos/vision.dart';
import '../tema/adaptativo.dart';
import '../utilidades/validadores_formulario.dart';
import '../widgets/panel_sugerencias.dart';

/// Pantalla del formulario de publicación.
class PantallaPublicar extends StatefulWidget {
  /// Artículo a editar. Si es `null`, el formulario crea uno nuevo.
  final Articulo? articulo;

  /// Servicio de visión inyectable (en pruebas se usa uno falso).
  final ServicioVision? servicioVision;

  /// Generador de descripciones (por defecto, plantillas locales).
  final GeneradorDescripcion generadorDescripcion;

  /// Sugeridor inyectable; en la app usa LLM con respaldo local.
  final SugeridorPublicacion? sugeridor;

  const PantallaPublicar({
    super.key,
    this.articulo,
    this.servicioVision,
    this.generadorDescripcion = const PlantillaGeneradorDescripcion(),
    this.sugeridor,
  });

  @override
  State<PantallaPublicar> createState() => _PantallaPublicarState();
}

class _PantallaPublicarState extends State<PantallaPublicar> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _claveTitulo = GlobalKey();
  final GlobalKey _claveDescripcion = GlobalKey();
  final GlobalKey _clavePrecio = GlobalKey();
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

  /// Servicio de visión creado perezosamente al elegir la primera foto.
  ServicioVision? _servicioVision;

  /// Sugerencias de la última foto analizada (null si no hay o se descartaron).
  SugerenciasPublicacion? _sugerencias;

  /// `true` mientras ML Kit procesa la foto.
  bool _analizando = false;

  /// Identifica el análisis vigente; si cambia la foto, el resultado viejo
  /// se ignora al llegar (evita mezclar dos fotos).
  int _tokenAnalisis = 0;

  /// `true` cuando el usuario ya eligió una categoría (o edita un artículo):
  /// en ese caso la descripción respeta esa categoría y no la sugerida.
  bool _categoriaTocada = false;

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
    _categoriaTocada = original != null;
    _imagenUrl = original?.imagenUrl;

    // La descripción sugerida se recalcula mientras el usuario escribe.
    _titulo.addListener(_alCambiarTexto);
    _descripcion.addListener(_alCambiarTexto);
  }

  @override
  void dispose() {
    _tokenAnalisis++;
    final ServicioVision? servicio = _servicioVision;
    if (servicio != null) {
      unawaited(servicio.cerrar());
    }
    _titulo.removeListener(_alCambiarTexto);
    _descripcion.removeListener(_alCambiarTexto);
    _titulo.dispose();
    _descripcion.dispose();
    _precio.dispose();
    super.dispose();
  }

  /// Redibuja el panel si el usuario cambia el título o la descripción.
  void _alCambiarTexto() {
    if (!mounted || _sugerencias == null) return;
    setState(() {});
  }

  /// Valida el formulario y guarda (inserta o actualiza) el artículo.
  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) {
      _mostrarPrimerError();
      return;
    }
    setState(() => _guardando = true);
    final ArticulosProvider proveedor = context.read<ArticulosProvider>();

    try {
      final String id =
          widget.articulo?.id ?? 'art_${DateTime.now().microsecondsSinceEpoch}';
      final String? fotoAnterior = widget.articulo?.imagenUrl;
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
        vendedor: widget.articulo?.vendedor ?? proveedor.vendedorActual,
        esFavorito: widget.articulo?.esFavorito ?? false,
        imagenUrl: imagenUrl,
        uidAutor: widget.articulo?.uidAutor ?? proveedor.uidActual,
        estado: widget.articulo?.estado ?? EstadoPublicacion.disponible,
      );

      if (_esEdicion) {
        await proveedor.actualizar(articulo);
      } else {
        await proveedor.insertar(articulo);
      }
      if (!mounted) return;
      if (proveedor.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(proveedor.error!)));
        return;
      }

      // La foto vieja ya no se usa: se borra del bucket (mejor esfuerzo).
      if (fotoAnterior != null && fotoAnterior != imagenUrl) {
        try {
          await AlmacenamientoImagenes().eliminar(fotoAnterior);
        } catch (_) {
          // Si falla el borrado, el artículo ya quedó guardado igual.
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la foto o el artículo: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Lleva el scroll al primer campo con error para que no quede fuera de vista.
  void _mostrarPrimerError() {
    final GlobalKey? clave = validarTitulo(_titulo.text) != null
        ? _claveTitulo
        : validarDescripcion(_descripcion.text) != null
        ? _claveDescripcion
        : validarPrecio(_precio.text, esVenta: true) != null
        ? _clavePrecio
        : null;
    final BuildContext? contexto = clave?.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      alignment: 0.25,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _mostrarOpcionesImagen() async {
    final ImageSource? origen = await mostrarHojaAdaptada<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(
                iconoAdaptativo(
                  material: Icons.photo_library_outlined,
                  cupertino: CupertinoIcons.photo,
                ),
              ),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(
                iconoAdaptativo(
                  material: Icons.photo_camera_outlined,
                  cupertino: CupertinoIcons.camera,
                ),
              ),
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
        _sugerencias = null;
      });
      if (!kIsWeb) {
        unawaited(_analizarFoto(archivo));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la imagen: $error')),
      );
    }
  }

  /// Analiza la foto nueva con ML Kit, sin bloquear el resto del formulario.
  Future<void> _analizarFoto(XFile archivo) async {
    final int token = ++_tokenAnalisis;
    setState(() {
      _analizando = true;
      _sugerencias = null;
    });

    try {
      final ServicioVision servicio = _servicioVision ??=
          widget.servicioVision ??
          ServiciosPublicacion.crearVision(tipoActual: () => _tipo);
      final ResultadoVision resultado = await servicio.analizar(archivo.path);
      if (!mounted || token != _tokenAnalisis) return;

      final SugeridorPublicacion sugeridor =
          widget.sugeridor ?? ServiciosPublicacion.sugeridor;
      final SugerenciasPublicacion sugerencias = sugeridor.sugerir(resultado);
      setState(() {
        _sugerencias = sugerencias.vacia ? null : sugerencias;
        _analizando = false;
      });
    } catch (_) {
      if (!mounted || token != _tokenAnalisis) return;
      setState(() {
        _sugerencias = null;
        _analizando = false;
      });
    }
  }

  /// Texto sugerido para la descripción según el estado actual del formulario.
  String _descripcionSugerida(SugerenciasPublicacion sugerencias) {
    final String? descripcionLlm = sugerencias.descripcion;
    if (descripcionLlm != null &&
        descripcionLlm.trim().isNotEmpty &&
        sugerencias.tipoDescripcion == _tipo) {
      return descripcionLlm.trim();
    }

    final String tituloActual = _titulo.text.trim();
    final String? titulo = tituloActual.isNotEmpty
        ? tituloActual
        : sugerencias.titulo;

    // Si no hay título ni categoría, no hay base para una descripción útil.
    if (titulo == null && sugerencias.categoria == null && !_categoriaTocada) {
      return '';
    }

    final Categoria categoria = _categoriaTocada
        ? _categoria
        : (sugerencias.categoria ?? Categoria.otros);

    return widget.generadorDescripcion.generar(
      titulo: titulo,
      categoria: categoria,
      tipo: _tipo,
    );
  }

  void _aplicarCategoria(Categoria categoria) {
    setState(() {
      _categoria = categoria;
      _categoriaTocada = true;
    });
  }

  void _aplicarTitulo(String titulo) {
    _titulo.value = TextEditingValue(
      text: titulo,
      selection: TextSelection.collapsed(offset: titulo.length),
    );
  }

  void _aplicarDescripcion(String descripcion) {
    _descripcion.value = TextEditingValue(
      text: descripcion,
      selection: TextSelection.collapsed(offset: descripcion.length),
    );
  }

  void _descartarSugerencias() {
    _tokenAnalisis++;
    setState(() {
      _sugerencias = null;
      _analizando = false;
    });
  }

  void _quitarFoto() {
    _tokenAnalisis++;
    setState(() {
      _imagenSeleccionada = null;
      _bytesImagen = null;
      _imagenUrl = null;
      _quitarImagen = true;
      _sugerencias = null;
      _analizando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    // Si la publicación es regalo/intercambio, el precio se oculta.
    final bool mostrarPrecio = _tipo == TipoPublicacion.venta;
    final SugerenciasPublicacion? sugerencias = _sugerencias;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar artículo' : 'Publicar artículo'),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double ancho = anchoContenido(constraints.maxWidth);
            return SingleChildScrollView(
              padding: paddingConTeclado(context),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ancho),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // ---------------------- Nombre del artículo -------------------
                        TextFormField(
                          key: _claveTitulo,
                          controller: _titulo,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLength: tituloMaximo,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          decoration: InputDecoration(
                            labelText: 'Nombre del artículo',
                            hintText: 'Ej: Calculadora científica',
                            helperText:
                                'Entre $tituloMinimo y $tituloMaximo caracteres',
                            prefixIcon: Icon(
                              iconoAdaptativo(
                                material: Icons.title,
                                cupertino: CupertinoIcons.textformat,
                              ),
                            ),
                          ),
                          validator: validarTitulo,
                        ),
                        const SizedBox(height: 14),

                        // ------------------------- Descripción -----------------------
                        TextFormField(
                          key: _claveDescripcion,
                          controller: _descripcion,
                          maxLines: 4,
                          maxLength: descripcionMaxima,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            hintText: 'Describe el estado y los detalles del artículo',
                            helperText: 'Mínimo $descripcionMinima caracteres',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(
                              iconoAdaptativo(
                                material: Icons.description_outlined,
                                cupertino: CupertinoIcons.doc_text,
                              ),
                            ),
                          ),
                          validator: validarDescripcion,
                        ),
                        const SizedBox(height: 20),

                        // --------------------- Tipo de publicación -------------------
                        _SeccionFormulario(
                          titulo: 'Tipo de publicación',
                          child: SegmentedButton<TipoPublicacion>(
                            segments: TipoPublicacion.values
                                .map(
                                  (TipoPublicacion tipo) =>
                                      ButtonSegment<TipoPublicacion>(
                                        value: tipo,
                                        label: Text(tipo.etiqueta),
                                      ),
                                )
                                .toList(),
                            selected: <TipoPublicacion>{_tipo},
                            onSelectionChanged:
                                (Set<TipoPublicacion> seleccion) {
                                  setState(() => _tipo = seleccion.first);
                                },
                            showSelectedIcon: false,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --------------------------- Precio --------------------------
                        // Solo se muestra para ventas; regalo muestra "Gratis" y
                        // intercambio "A convenir" automáticamente.
                        if (mostrarPrecio) ...<Widget>[
                          _SeccionFormulario(
                            titulo: 'Precio',
                            ayuda: 'Opcional. Máximo 99,999,999.',
                            child: TextFormField(
                              key: _clavePrecio,
                              controller: _precio,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*$'),
                                ),
                              ],
                              maxLength: 12,
                              decoration: const InputDecoration(
                                hintText: '0',
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              validator: (String? valor) =>
                                  validarPrecio(valor, esVenta: true),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // -------------------------- Categoría ------------------------
                        _SeccionFormulario(
                          titulo: 'Categoría',
                          child: DropdownButtonFormField<Categoria>(
                            // La key hace que el dropdown se reconstruya al aplicar una
                            // categoría sugerida (initialValue solo se lee al crearse).
                            key: ValueKey<Categoria>(_categoria),
                            initialValue: _categoria,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: Categoria.values
                                .map(
                                  (Categoria categoria) =>
                                      DropdownMenuItem<Categoria>(
                                        value: categoria,
                                        child: Text(categoria.etiqueta),
                                      ),
                                )
                                .toList(),
                            onChanged: (Categoria? valor) {
                              if (valor == null) return;
                              setState(() {
                                _categoria = valor;
                                _categoriaTocada = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ---------------------------- Foto ---------------------------
                        _SeccionFormulario(
                          titulo: 'Foto',
                          ayuda: 'Opcional. Una buena foto ayuda a vender más rápido.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Semantics(
                                label:
                                    _bytesImagen != null || _imagenUrl != null
                                    ? 'Foto seleccionada del artículo'
                                    : 'Sin foto seleccionada',
                                child: _VistaPreviaImagen(
                                  bytes: _bytesImagen,
                                  url: _quitarImagen ? null : _imagenUrl,
                                  categoria: _categoria,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _mostrarOpcionesImagen,
                                      icon: Icon(
                                        iconoAdaptativo(
                                          material: Icons.add_a_photo_outlined,
                                          cupertino: CupertinoIcons.camera,
                                        ),
                                      ),
                                      label: Text(
                                        _bytesImagen != null ||
                                                _imagenUrl != null
                                            ? 'Cambiar foto'
                                            : 'Agregar foto',
                                      ),
                                    ),
                                  ),
                                  if (_bytesImagen != null ||
                                      _imagenUrl != null) ...<Widget>[
                                    const SizedBox(width: 8),
                                    IconButton.outlined(
                                      onPressed: _quitarFoto,
                                      tooltip: 'Quitar foto',
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_analizando)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: <Widget>[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Analizando foto...',
                                  style: tema.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        if (kIsWeb && _bytesImagen != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'El análisis de fotos con ML Kit solo está '
                                    'disponible en Android.',
                                    style: tema.textTheme.bodySmall?.copyWith(
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (sugerencias != null) ...<Widget>[
                          const SizedBox(height: 14),
                          PanelSugerencias(
                            sugerencias: sugerencias,
                            descripcion: _descripcionSugerida(sugerencias),
                            tituloActual: _titulo.text,
                            descripcionActual: _descripcion.text,
                            categoriaActual: _categoria,
                            alAplicarCategoria: _aplicarCategoria,
                            alAplicarTitulo: _aplicarTitulo,
                            alAplicarDescripcion: _aplicarDescripcion,
                            alDescartar: _descartarSugerencias,
                          ),
                        ],
                        const SizedBox(height: 28),

                        // -------------------------- Guardar --------------------------
                        FilledButton.icon(
                          onPressed: _guardando ? null : _guardar,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Sección agrupada del formulario, con encabezado y tarjeta.
class _SeccionFormulario extends StatelessWidget {
  const _SeccionFormulario({
    required this.titulo,
    this.ayuda,
    required this.child,
  });

  final String titulo;
  final String? ayuda;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            titulo.toUpperCase(),
            style: tema.textTheme.labelLarge?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
        if (ayuda != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              ayuda!,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
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
      child: SizedBox(height: 190, width: double.infinity, child: contenido),
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
