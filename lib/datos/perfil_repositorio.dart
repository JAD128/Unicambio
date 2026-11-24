// =============================================================================
// ARCHIVO: lib/datos/perfil_repositorio.dart
// DESCRIPCIÓN: Contrato de persistencia del perfil y su implementación en RAM
//              (para pruebas y para el respaldo sin Firebase).
// =============================================================================

import '../modelos/perfil_usuario.dart';

/// Operaciones disponibles sobre el perfil de un usuario.
abstract class PerfilRepositorio {
  /// Lee el perfil de [uid], devolviendo uno vacío si no existe.
  Future<PerfilUsuario> obtener(String uid);

  /// Guarda (o crea) el perfil.
  Future<void> guardar(PerfilUsuario perfil);
}

/// Repositorio de perfil que guarda los datos en memoria.
class PerfilRepositorioMemoria implements PerfilRepositorio {
  /// Mapa interno `uid -> perfil`.
  final Map<String, PerfilUsuario> _perfiles = <String, PerfilUsuario>{};

  /// Permite sembrar perfiles iniciales en pruebas.
  PerfilRepositorioMemoria({Map<String, PerfilUsuario>? iniciales}) {
    if (iniciales != null) _perfiles.addAll(iniciales);
  }

  @override
  Future<PerfilUsuario> obtener(String uid) async =>
      _perfiles[uid] ?? PerfilUsuario.vacio(uid);

  @override
  Future<void> guardar(PerfilUsuario perfil) async {
    _perfiles[perfil.uid] = perfil;
  }
}
