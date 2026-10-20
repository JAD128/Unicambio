// =============================================================================
// ARCHIVO: lib/estado/articulos_provider.dart
// DESCRIPCIÓN: Estado global de la aplicación. Es un `ChangeNotifier` que usa
//              el repositorio para leer/guardar artículos y AVISA a las
//              pantallas cuando algo cambia.
//
// ¿Por qué existe? Porque varias pantallas necesitan los mismos datos:
//   - Inicio muestra la lista (con búsqueda y filtro).
//   - Favoritos muestra los marcados como favoritos.
//   - Mis artículos muestra los del usuario.
// Si cada pantalla leyera por su cuenta, no se sincronizarían. Con este estado
// central, cuando marcas un favorito, TODAS las pantallas se enteran.
//
// Patrón: la UI llama a los métodos de este provider -> el provider llama al
// repositorio -> y llama a `notifyListeners()` para que la UI se redibuje.
// =============================================================================

import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../datos/articulo_repositorio.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Estado global encargado de los artículos de UniCambio.
class ArticulosProvider extends ChangeNotifier {
  /// Repositorio de datos (inyectado para poder usar la BD real o una de prueba).
  final ArticuloRepositorio _repositorio;

  ArticulosProvider(this._repositorio);

  // ---------------------------------------------------------------------------
  // Estado interno (privado). Nadie lo modifica desde afuera.
  // ---------------------------------------------------------------------------

  /// Lista completa de artículos cargados (sin aplicar búsqueda ni filtro).
  List<Articulo> _todos = <Articulo>[];

  /// Lista de artículos que se está mostrando en Inicio (según búsqueda/filtro).
  List<Articulo> _articulos = <Articulo>[];

  /// Lista de artículos marcados como favoritos.
  List<Articulo> _favoritos = <Articulo>[];

  /// `true` mientras se está leyendo/escribiendo en la base de datos.
  bool _cargando = false;

  /// Mensaje de error para mostrar en pantalla (null si no hay error).
  String? _error;

  /// Texto actual del buscador.
  String _textoBusqueda = '';

  /// Categoría seleccionada en los filtros (null = "Todos").
  Categoria? _categoriaSeleccionada;

  // ---------------------------------------------------------------------------
  // Getters públicos: lo único que las pantallas pueden leer.
  // ---------------------------------------------------------------------------

  /// Todos los artículos cargados, sin filtrar (los que hay en la base).
  List<Articulo> get todos => UnmodifiableListView<Articulo>(_todos);

  /// Artículos a mostrar en Inicio (filtrados por búsqueda y categoría).
  /// Se devuelve "no modificable" para que la UI no altere el estado por error.
  List<Articulo> get articulos => UnmodifiableListView<Articulo>(_articulos);

  /// Artículos favoritos.
  List<Articulo> get favoritos => UnmodifiableListView<Articulo>(_favoritos);

  /// Indica si hay una operación en curso (para mostrar un spinner).
  bool get cargando => _cargando;

  /// Error actual, si hubo alguno.
  String? get error => _error;

  /// Texto que hay escrito en el buscador.
  String get textoBusqueda => _textoBusqueda;

  /// Categoría seleccionada en los filtros.
  Categoria? get categoriaSeleccionada => _categoriaSeleccionada;

  /// `true` si la lista visible está vacía (útil para el estado vacío).
  bool get listaVacia => _articulos.isEmpty;

  /// Devuelve el artículo con ese id, o `null` si no existe.
  Articulo? articuloPorId(String id) {
    for (final Articulo articulo in _todos) {
      if (articulo.id == id) return articulo;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Carga inicial
  // ---------------------------------------------------------------------------

  /// Carga los artículos y los favoritos desde la base de datos.
  /// Se llama una vez al abrir la app (en `main.dart`).
  Future<void> iniciar() => _ejecutar(_refrescar);

  // ---------------------------------------------------------------------------
  // Búsqueda y filtros
  // ---------------------------------------------------------------------------

  /// Actualiza el texto de búsqueda y recarga la lista.
  Future<void> actualizarBusqueda(String texto) {
    _textoBusqueda = texto;
    return _ejecutar(_refrescar);
  }

  /// Cambia la categoría seleccionada (null = "Todos") y recarga la lista.
  Future<void> seleccionarCategoria(Categoria? categoria) {
    _categoriaSeleccionada = categoria;
    return _ejecutar(_refrescar);
  }

  // ---------------------------------------------------------------------------
  // Operaciones sobre los artículos (CRUD + favoritos)
  // ---------------------------------------------------------------------------

  /// Inserta un artículo nuevo y refresca las listas.
  Future<void> insertar(Articulo articulo) {
    return _ejecutar(() async {
      await _repositorio.insertar(articulo);
      await _refrescar();
    });
  }

  /// Actualiza un artículo existente y refresca las listas.
  Future<void> actualizar(Articulo articulo) {
    return _ejecutar(() async {
      await _repositorio.actualizar(articulo);
      await _refrescar();
    });
  }

  /// Elimina un artículo por su id y refresca las listas.
  Future<void> eliminar(String id) {
    return _ejecutar(() async {
      await _repositorio.eliminar(id);
      await _refrescar();
    });
  }

  /// Marca/desmarca un artículo como favorito y refresca las listas.
  Future<void> alternarFavorito(String id) {
    return _ejecutar(() async {
      await _repositorio.alternarFavorito(id);
      await _refrescar();
    });
  }

  // ---------------------------------------------------------------------------
  // Métodos internos
  // ---------------------------------------------------------------------------

  /// Recarga las listas desde el repositorio, aplicando la búsqueda y el filtro
  /// actuales. No avisa a la UI (eso lo hace [_ejecutar]).
  Future<void> _refrescar() async {
    _todos = await _repositorio.obtenerTodos();
    _articulos = await _repositorio.buscar(
      _textoBusqueda,
      categoria: _categoriaSeleccionada,
    );
    _favoritos = await _repositorio.obtenerFavoritos();
  }

  /// Envuelve cualquier operación con el manejo de estado (cargando + error).
  ///
  /// Así no repetimos el mismo `try/catch` en cada método:
  /// - Antes: activa `cargando` y avisa a la UI.
  /// - Al terminar: desactiva `cargando` y avisa otra vez.
  /// - Si falla: guarda el mensaje de error para mostrarlo.
  Future<void> _ejecutar(Future<void> Function() accion) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await accion();
    } catch (e) {
      _error = 'Ocurrió un error al acceder a los datos: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
