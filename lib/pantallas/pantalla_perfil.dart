// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_perfil.dart
// DESCRIPCIÓN: Perfil de la cuenta autenticada. Permite ver y editar el nombre
//              visible, cambiar o quitar la foto de perfil y cerrar sesión.
//              La foto se sube a Supabase Storage y la URL se guarda en
//              Firebase Auth (`photoURL`).
// =============================================================================

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../datos/almacenamiento_imagenes.dart';
import '../estado/articulos_provider.dart';
import '../estado/perfil_provider.dart';
import '../modelos/categoria.dart';

/// Pantalla "Mi perfil".
class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final ImagePicker _selectorImagen = ImagePicker();

  /// `true` mientras se sube/borra la foto o se guarda el nombre.
  bool _guardando = false;

  /// Evita pedir dos veces el mismo perfil al abrir la pantalla.
  bool _perfilSolicitado = false;

  /// Usuario actual de Firebase (null si ya se cerró la sesión).
  User? get _usuario => FirebaseAuth.instance.currentUser;

  /// Nombre visible: displayName, o la parte antes de la @ del correo.
  String get _nombre {
    final User? usuario = _usuario;
    final String nombre = (usuario?.displayName ?? '').trim();
    if (nombre.isNotEmpty) return nombre;
    return (usuario?.email ?? 'estudiante').split('@').first;
  }

  /// Inicial que se muestra cuando no hay foto de perfil.
  String get _inicial =>
      _nombre.isEmpty ? '?' : _nombre.substring(0, 1).toUpperCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarPerfil());
  }

  /// Carga el perfil si la pantalla se abre directamente (no desde el gate).
  Future<void> _cargarPerfil() async {
    if (_perfilSolicitado) return;
    final String? uid = _usuario?.uid;
    if (uid == null) return;
    _perfilSolicitado = true;
    if (!mounted) return;
    await context.read<PerfilProvider>().iniciar(uid);
  }

  /// Muestra un mensaje corto al guardar una preferencia.
  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  /// Pide otra vez las sugerencias después de cambiar preferencias.
  Future<void> _recargarNovedades(PerfilProvider perfil) async {
    await context.read<ArticulosProvider>().cargarNovedades(
          activas: perfil.sugerenciasActivas,
          categorias: perfil.categoriasSugerencias,
          desde: perfil.ultimaVista,
        );
  }

  /// Guarda los datos de la sesión en el provider para que el saludo y las
  /// nuevas publicaciones usen el nombre actualizado.
  void _sincronizarProvider() {
    final User? usuario = _usuario;
    if (usuario == null) return;
    context.read<ArticulosProvider>().configurarUsuario(
          uid: usuario.uid,
          nombre: usuario.displayName,
          correo: usuario.email,
        );
  }

  /// Edita el número de WhatsApp opcional (autodeclarado, sin verificación).
  Future<void> _editarTelefono(PerfilProvider perfil) async {
    final TextEditingController controlador = TextEditingController(
      text: perfil.telefono.startsWith('57')
          ? perfil.telefono.substring(2)
          : perfil.telefono,
    );
    final String? nuevo = await showDialog<String>(
      context: context,
      builder: (BuildContext contexto) => AlertDialog(
        title: const Text('WhatsApp (opcional)'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Celular a 10 dígitos',
            prefixText: '+57 ',
            helperText:
                'Solo para que otros estudiantes puedan escribirte. No verificado.',
            helperMaxLines: 2,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Cancelar'),
          ),
          if (perfil.telefono.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(''),
              child: const Text('Quitar'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(controlador.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nuevo == null) return;

    await perfil.guardarTelefono(nuevo);
    if (!mounted) return;
    if (perfil.error != null) {
      _avisar(perfil.error!);
      return;
    }
    await _recargarNovedades(perfil);
    _avisar(nuevo.isEmpty ? 'Número quitado.' : 'Número guardado.');
  }

  /// Elige las categorías que se verán en las sugerencias.
  Future<void> _editarCategorias(PerfilProvider perfil) async {
    final Set<Categoria> seleccionadas =
        Set<Categoria>.from(perfil.categoriasSugerencias);
    final Set<Categoria>? resultado = await showDialog<Set<Categoria>>(
      context: context,
      builder: (BuildContext contexto) => StatefulBuilder(
        builder: (BuildContext contexto, StateSetter actualizar) => AlertDialog(
          title: const Text('Categorías sugeridas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Elige al menos una categoría.'),
                ...Categoria.values.map(
                  (Categoria categoria) => CheckboxListTile(
                    value: seleccionadas.contains(categoria),
                    title: Text(categoria.etiqueta),
                    onChanged: (bool? marcado) => actualizar(() {
                      if (marcado == true) {
                        seleccionadas.add(categoria);
                      } else {
                        seleccionadas.remove(categoria);
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(contexto).pop(seleccionadas),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (resultado == null) return;
    if (resultado.isEmpty) {
      _avisar('Elige al menos una categoría.');
      return;
    }

    await perfil.actualizarPreferencias(categorias: resultado);
    if (!mounted) return;
    await _recargarNovedades(perfil);
    _avisar('Categorías actualizadas.');
  }

  /// Abre un diálogo para editar el nombre visible.
  Future<void> _editarNombre() async {
    final TextEditingController controlador =
        TextEditingController(text: _nombre);
    final String? nuevo = await showDialog<String>(
      context: context,
      builder: (BuildContext contexto) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre visible'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(contexto).pop(controlador.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevo == null || nuevo.isEmpty || nuevo == _nombre) return;
    setState(() => _guardando = true);
    try {
      await _usuario?.updateDisplayName(nuevo);
      await _usuario?.reload();
      if (!mounted) return;
      _sincronizarProvider();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre actualizado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar el nombre: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Pide elegir galería o cámara y sube la nueva foto de perfil.
  Future<void> _cambiarFoto() async {
    final ImageSource? origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext contexto) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(contexto, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(contexto, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    XFile? archivo;
    try {
      archivo = await _selectorImagen.pickImage(
        source: origen,
        imageQuality: 82,
        maxWidth: 800,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la imagen: $error')),
      );
      return;
    }
    if (archivo == null) return;

    final Uint8List bytes = await archivo.readAsBytes();
    final String? fotoAnterior = _usuario?.photoURL;
    setState(() => _guardando = true);
    try {
      final String url = await AlmacenamientoImagenes().subir(
        articuloId: 'perfil',
        bytes: bytes,
        nombreArchivo: archivo.name,
        tipoContenido: archivo.mimeType ?? 'image/jpeg',
      );
      await _usuario?.updatePhotoURL(url);
      await _usuario?.reload();

      // La foto anterior ya no se usa: se borra del bucket (mejor esfuerzo).
      if (fotoAnterior != null && fotoAnterior != url) {
        try {
          await AlmacenamientoImagenes().eliminar(fotoAnterior);
        } catch (_) {
          // Si falla el borrado, la foto nueva ya quedó guardada.
        }
      }

      if (!mounted) return;
      _sincronizarProvider();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir la foto: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Quita la foto de perfil (de Firebase Auth y del bucket).
  Future<void> _quitarFoto() async {
    final String? foto = _usuario?.photoURL;
    if (foto == null) return;
    setState(() => _guardando = true);
    try {
      await _usuario?.updatePhotoURL(null);
      await _usuario?.reload();
      try {
        await AlmacenamientoImagenes().eliminar(foto);
      } catch (_) {
        // Si falla el borrado, la foto ya no aparece en el perfil igual.
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil eliminada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo quitar la foto: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Cierra la sesión después de confirmar.
  Future<void> _cerrarSesion() async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext contexto) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ArticulosProvider proveedor = context.watch<ArticulosProvider>();
    final PerfilProvider perfil = context.watch<PerfilProvider>();
    final String? foto = _usuario?.photoURL;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: <Widget>[
          if (_guardando) const LinearProgressIndicator(),
          const SizedBox(height: 8),

          // ---------------------- Avatar + datos ----------------------
          Center(
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 54,
                      backgroundColor:
                          tema.colorScheme.primary.withValues(alpha: 0.12),
                      backgroundImage:
                          foto != null ? NetworkImage(foto) : null,
                      child: foto == null
                          ? Text(
                              _inicial,
                              style: tema.textTheme.headlineLarge?.copyWith(
                                color: tema.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: tema.colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _guardando ? null : _cambiarFoto,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _nombre,
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _usuario?.email ?? 'Sin correo',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------ Estadísticas ----------------------
          Row(
            children: <Widget>[
              Expanded(
                child: _TarjetaDato(
                  valor: '${proveedor.mios.length}',
                  etiqueta: 'Publicaciones',
                  icono: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TarjetaDato(
                  valor: '${proveedor.favoritos.length}',
                  etiqueta: 'Favoritos',
                  icono: Icons.favorite_border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ------------------- WhatsApp y sugerencias -----------------
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('WhatsApp (opcional)'),
                  subtitle: Text(
                    perfil.telefono.isEmpty
                        ? 'Agrega tu número para que te puedan contactar'
                        : '+${perfil.telefono} · No verificado',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: perfil.cargando
                      ? null
                      : () => _editarTelefono(perfil),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none_outlined),
                  title: const Text('Sugerencias en la app'),
                  subtitle: const Text(
                    'Avisos de nuevos artículos solo mientras la app está abierta.',
                  ),
                  value: perfil.sugerenciasActivas,
                  onChanged: perfil.cargando
                      ? null
                      : (bool valor) async {
                          await perfil.actualizarPreferencias(activas: valor);
                          if (!mounted) return;
                          await _recargarNovedades(perfil);
                          _avisar(
                            valor
                                ? 'Sugerencias activadas para todas las categorías.'
                                : 'Sugerencias desactivadas.',
                          );
                        },
                ),
                if (perfil.sugerenciasActivas)
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('Categorías sugeridas'),
                    subtitle: Text(
                      perfil.categoriasSugerencias.isEmpty
                          ? 'Ninguna categoría elegida'
                          : perfil.categoriasSugerencias
                              .map((Categoria c) => c.etiqueta)
                              .join(', '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: perfil.cargando
                        ? null
                        : () => _editarCategorias(perfil),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------- Acciones -------------------------
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar nombre'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _guardando ? null : _editarNombre,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Cambiar foto'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _guardando ? null : _cambiarFoto,
                ),
                if (foto != null) ...<Widget>[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Quitar foto'),
                    onTap: _guardando ? null : _quitarFoto,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta pequeña con un número y una etiqueta (estadísticas del perfil).
class _TarjetaDato extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final IconData icono;

  const _TarjetaDato({
    required this.valor,
    required this.etiqueta,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: <Widget>[
            Icon(icono, color: tema.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              valor,
              style: tema.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              etiqueta,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
