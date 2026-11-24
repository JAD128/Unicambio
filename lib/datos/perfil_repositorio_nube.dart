// =============================================================================
// ARCHIVO: lib/datos/perfil_repositorio_nube.dart
// DESCRIPCIÓN: Implementación de [PerfilRepositorio] sobre Firestore.
//
// Estructura:
//   usuarios/{uid}  → teléfono opcional, preferencias y última vista
//
// Se usa `set(..., merge: true)` para no sobrescribir la subcolección
// `favoritos` que ya vive debajo del mismo documento.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/categoria.dart';
import '../modelos/perfil_usuario.dart';
import 'perfil_repositorio.dart';

/// Repositorio de perfil respaldado por Cloud Firestore.
class PerfilRepositorioNube implements PerfilRepositorio {
  /// Firestore inyectable para pruebas.
  final FirebaseFirestore _db;

  PerfilRepositorioNube({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Colección que comparte el documento de perfil con los favoritos.
  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _db.collection('usuarios');

  @override
  Future<PerfilUsuario> obtener(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _usuarios.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return PerfilUsuario.vacio(uid);
    }

    final Map<String, Object?> datos =
        Map<String, Object?>.from(doc.data()!);
    datos['uid'] = doc.id;
    final Object? fecha = datos['ultimaVista'];
    if (fecha is Timestamp) datos['ultimaVista'] = fecha.toDate();
    return PerfilUsuario.fromMap(datos);
  }

  @override
  Future<void> guardar(PerfilUsuario perfil) async {
    final Map<String, Object?> datos = <String, Object?>{
      'telefono': perfil.telefono,
      'sugerenciasActivas': perfil.sugerenciasActivas,
      'categoriasSugerencias': perfil.categoriasSugerencias
          .map((Categoria categoria) => categoria.name)
          .toList(),
    };
    if (perfil.ultimaVista != null) {
      datos['ultimaVista'] = Timestamp.fromDate(perfil.ultimaVista!);
    }
    await _usuarios.doc(perfil.uid).set(datos, SetOptions(merge: true));
  }
}
