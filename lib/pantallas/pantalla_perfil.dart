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
