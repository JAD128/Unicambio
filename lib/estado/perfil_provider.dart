// =============================================================================
// ARCHIVO: lib/estado/perfil_provider.dart
// DESCRIPCIÓN: Estado global del perfil (teléfono opcional y preferencias de
//              sugerencias). Igual que ArticulosProvider, la UI solo llama a
//              sus métodos y nunca toca Firestore directamente.
// =============================================================================

import 'package:flutter/foundation.dart';

import '../datos/lanzador_whatsapp.dart';
import '../datos/perfil_repositorio.dart';
import '../modelos/categoria.dart';
import '../modelos/perfil_usuario.dart';

/// Estado global del perfil del usuario actual.
class PerfilProvider extends ChangeNotifier {
  /// Repositorio inyectado (nube en la app, memoria en pruebas).
  final PerfilRepositorio _repositorio;

  PerfilProvider(this._repositorio);

  PerfilUsuario _perfil = const PerfilUsuario(uid: '');

  /// Teléfonos consultados de otros vendedores, para no releerlos cada vez.
  final Map<String, String> _telefonos = <String, String>{};

  bool _cargando = false;
  String? _error;

  /// Perfil actual (inmutable).
  PerfilUsuario get perfil => _perfil;

  /// Número normalizado, o cadena vacía si el usuario no lo ha ingresado.
  String get telefono => _perfil.telefono;

  /// Preferencia de sugerencias (apagada por defecto).
  bool get sugerenciasActivas => _perfil.sugerenciasActivas;

  /// Categorías elegidas para sugerencias.
  Set<Categoria> get categoriasSugerencias =>
      Set<Categoria>.unmodifiable(_perfil.categoriasSugerencias);

  /// Última vez que se abrió la bandeja de sugerencias.
  DateTime? get ultimaVista => _perfil.ultimaVista;

  /// `true` mientras se lee o escribe el perfil.
  bool get cargando => _cargando;

  /// Último mensaje de error, si hubo uno.
  String? get error => _error;

  /// Carga el perfil del usuario con [uid].
  Future<void> iniciar(String uid) async {
    if (uid.isEmpty) {
      limpiar();
      return;
    }
    if (_perfil.uid != uid) {
      _perfil = PerfilUsuario.vacio(uid);
      _telefonos.clear();
      notifyListeners();
    }

    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _perfil = await _repositorio.obtener(uid);
      _telefonos[uid] = _perfil.telefono;
    } catch (error) {
      _error = _mensaje(error);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Guarda el número del propio usuario. Cadena vacía lo quita.
  Future<void> guardarTelefono(String texto) async {
    final String limpio = texto.trim();
    if (limpio.isNotEmpty && normalizarTelefonoColombiano(limpio) == null) {
      _error = 'Escribe un celular colombiano de 10 dígitos (ej. 300 123 4567).';
      notifyListeners();
      return;
    }
    await _guardarPerfil(
      _perfil.copyWith(
        telefono: limpio.isEmpty
            ? ''
            : normalizarTelefonoColombiano(limpio)!,
      ),
    );
  }

  /// Cambia el interruptor y/o las categorías de las sugerencias.
  ///
  /// Al activar por primera vez, todas las categorías quedan seleccionadas.
  Future<void> actualizarPreferencias({
    bool? activas,
    Set<Categoria>? categorias,
  }) async {
    Set<Categoria>? elegidas = categorias == null
        ? null
        : Set<Categoria>.from(categorias);
    if (activas == true &&
        elegidas == null &&
        _perfil.categoriasSugerencias.isEmpty) {
      elegidas = Categoria.values.toSet();
    }
    await _guardarPerfil(
      _perfil.copyWith(
        sugerenciasActivas: activas ?? _perfil.sugerenciasActivas,
        categoriasSugerencias: elegidas ?? _perfil.categoriasSugerencias,
      ),
    );
  }

  /// Registra que el usuario ya vio las sugerencias actuales.
  Future<void> marcarVisto() async {
    if (_perfil.uid.isEmpty) return;
    await _guardarPerfil(
      _perfil.copyWith(ultimaVista: DateTime.now()),
    );
  }

  /// Devuelve el WhatsApp público de [uid], o `null` si no lo compartió.
  Future<String?> telefonoDe(String uid) async {
    if (uid.isEmpty) return null;
    if (uid == _perfil.uid) {
      return _perfil.telefono.isEmpty ? null : _perfil.telefono;
    }
    final String? enCache = _telefonos[uid];
    if (enCache != null) return enCache.isEmpty ? null : enCache;
    try {
      final PerfilUsuario otro = await _repositorio.obtener(uid);
      _telefonos[uid] = otro.telefono;
      return otro.telefono.isEmpty ? null : otro.telefono;
    } catch (_) {
      return null;
    }
  }

  /// Limpia el estado al cerrar sesión.
  void limpiar() {
    _perfil = const PerfilUsuario(uid: '');
    _telefonos.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> _guardarPerfil(PerfilUsuario perfil) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repositorio.guardar(perfil);
      _perfil = perfil;
      _telefonos[perfil.uid] = perfil.telefono;
    } catch (error) {
      _error = _mensaje(error);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  String _mensaje(Object error) => error.toString();
}
