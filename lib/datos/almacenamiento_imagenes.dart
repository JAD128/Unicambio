// =============================================================================
// ARCHIVO: lib/datos/almacenamiento_imagenes.dart
// DESCRIPCIÓN: Sube imágenes de publicaciones a Firebase Storage.
// =============================================================================

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Encapsula la subida de fotografías para no acoplar la interfaz a Storage.
class AlmacenamientoImagenes {
  AlmacenamientoImagenes({
    FirebaseStorage? almacenamiento,
    FirebaseAuth? autenticacion,
  })  : _almacenamiento = almacenamiento ?? FirebaseStorage.instance,
        _autenticacion = autenticacion ?? FirebaseAuth.instance;

  final FirebaseStorage _almacenamiento;
  final FirebaseAuth _autenticacion;

  /// Guarda los bytes en una ruta privada por usuario y devuelve su URL.
  Future<String> subir({
    required String articuloId,
    required Uint8List bytes,
    required String nombreArchivo,
    required String tipoContenido,
  }) async {
    final String? uid = _autenticacion.currentUser?.uid;
    if (uid == null) {
      throw StateError('Inicia sesión para subir la foto.');
    }

    final String extension = nombreArchivo.contains('.')
        ? nombreArchivo.split('.').last.toLowerCase()
        : 'jpg';
    final Reference referencia = _almacenamiento
        .ref()
        .child('articulos/$uid/$articuloId/${DateTime.now().millisecondsSinceEpoch}.$extension');
    await referencia.putData(
      bytes,
      SettableMetadata(contentType: tipoContenido),
    );
    return referencia.getDownloadURL();
  }
}
