// =============================================================================
// ARCHIVO: lib/datos/articulo_repositorio_memoria.dart
// DESCRIPCIÓN: Otra implementación de [ArticuloRepositorio], pero que guarda
//              los artículos EN MEMORIA (una lista en RAM), sin base de datos.
//
// ¿Para qué sirve, si la app usa SQLite?
//   1. PRUEBAS: son instantáneas y no necesitan un dispositivo ni SQLite.
//   2. Demuestra la ventaja del patrón repositorio: podemos cambiar la forma de
//      guardar datos sin tocar las pantallas ni el provider.
//
// Al implementar la misma interfaz, se puede usar en lugar de
// [ArticuloRepositorioSqflite] sin cambiar nada más.
// =============================================================================

import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import 'articulo_repositorio.dart';

/// Repositorio que guarda los artículos en una lista en memoria.
class ArticuloRepositorioMemoria implements ArticuloRepositorio {
  /// Lista interna de artículos (simula la tabla de la base de datos).
  final List<Articulo> _articulos;

  /// Permite crear el repositorio con datos iniciales (útil en pruebas).
  ArticuloRepositorioMemoria({List<Articulo>? iniciales})
      : _articulos = List<Articulo>.from(iniciales ?? const <Articulo>[]);

  /// Ordena una lista por título (para imitar el `ORDER BY titulo` de SQL).
  List<Articulo> _ordenados(Iterable<Articulo> articulos) {
    final List<Articulo> lista = articulos.toList();
    lista.sort((Articulo a, Articulo b) => a.titulo.compareTo(b.titulo));
    return lista;
  }

  @override
  Future<List<Articulo>> obtenerTodos() async => _ordenados(_articulos);

  @override
  bool get enTiempoReal => false;

  /// Solo hay datos locales: no hay cambios externos que escuchar.
  @override
  Stream<List<Articulo>> observarTodos() =>
      const Stream<List<Articulo>>.empty();

  @override
  Future<List<Articulo>> obtenerFavoritos() async =>
      _ordenados(_articulos.where((Articulo a) => a.esFavorito));

  @override
  Future<Articulo?> obtenerPorId(String id) async {
    for (final Articulo articulo in _articulos) {
      if (articulo.id == id) {
        return articulo;
      }
    }
    return null;
  }

  @override
  Future<void> insertar(Articulo articulo) async {
    // Si ya existe un artículo con ese id, lo reemplaza; si no, lo agrega.
    final int indice =
        _articulos.indexWhere((Articulo a) => a.id == articulo.id);
    if (indice >= 0) {
      _articulos[indice] = articulo;
    } else {
      _articulos.add(articulo);
    }
  }

  @override
  Future<void> actualizar(Articulo articulo) => insertar(articulo);

  @override
  Future<void> eliminar(String id) async {
    _articulos.removeWhere((Articulo a) => a.id == id);
  }

  @override
  Future<void> alternarFavorito(String id) async {
    final int indice = _articulos.indexWhere((Articulo a) => a.id == id);
    if (indice >= 0) {
      final Articulo actual = _articulos[indice];
      _articulos[indice] = actual.copyWith(esFavorito: !actual.esFavorito);
    }
  }

  @override
  Future<List<Articulo>> buscar(String texto, {Categoria? categoria}) async {
    final String textoLimpio = texto.trim().toLowerCase();
    final Iterable<Articulo> resultado = _articulos.where((Articulo a) {
      final bool coincideTexto = textoLimpio.isEmpty ||
          a.titulo.toLowerCase().contains(textoLimpio);
      final bool coincideCategoria =
          categoria == null || a.categoria == categoria;
      return coincideTexto && coincideCategoria;
    });
    return _ordenados(resultado);
  }

  @override
  Future<List<Articulo>> filtrarPorCategoria(Categoria categoria) =>
      buscar('', categoria: categoria);
}
