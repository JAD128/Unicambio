// =============================================================================
// ARCHIVO: lib/datos/cache_sugerencias_llm.dart
// DESCRIPCIÓN: Caché en memoria de las sugerencias del LLM para no repetir
//              la misma petición al cambiar de pestaña o reconstruir la UI.
// =============================================================================

import 'package:unicambio/modelos/articulo.dart';
import 'package:unicambio/modelos/sugerencia_llm.dart';

/// Caché pequeña y temporal de sugerencias por imagen y tipo.
class CacheSugerenciasLlm {
  final Map<String, SugerenciaLlm> _valores = <String, SugerenciaLlm>{};

  /// Cantidad máxima de entradas conservadas.
  static const int _limite = 20;

  /// Devuelve la sugerencia guardada, si existe.
  SugerenciaLlm? leer({
    required List<int> bytes,
    required TipoPublicacion tipo,
  }) {
    return _valores[_clave(bytes: bytes, tipo: tipo)];
  }

  /// Guarda una sugerencia y descarta la entrada más antigua si hace falta.
  void guardar({
    required List<int> bytes,
    required TipoPublicacion tipo,
    required SugerenciaLlm sugerencia,
  }) {
    final String clave = _clave(bytes: bytes, tipo: tipo);
    if (!_valores.containsKey(clave) && _valores.length >= _limite) {
      _valores.remove(_valores.keys.first);
    }
    _valores[clave] = sugerencia;
  }

  /// Cantidad de entradas actuales (útil en pruebas).
  int get longitud => _valores.length;

  String _clave({required List<int> bytes, required TipoPublicacion tipo}) {
    int hash = 0x811c9dc5;
    for (final int codigo in tipo.name.codeUnits) {
      hash = _mezclar(hash, codigo);
    }
    for (final int byte in bytes) {
      hash = _mezclar(hash, byte);
    }
    return '${bytes.length}:${hash.toRadixString(16)}';
  }

  int _mezclar(int hash, int valor) {
    return ((hash ^ valor) * 0x01000193) & 0xffffffff;
  }
}
