// =============================================================================
// ARCHIVO: lib/estado/articulos_provider.dart
// DESCRIPCIÓN: Estado global de la aplicación. Es un `ChangeNotifier` que usa
//              el repositorio para leer/guardar artículos y AVISA a las
//              pantallas cuando algo cambia.
//
// ¿Por qué existe? Porque varias pantallas necesitan los mismos datos:
//   - Inicio muestra la lista paginada (con búsqueda y filtros).
//   - Favoritos muestra los marcados como favoritos.
//   - Mis artículos muestra los del usuario.
// Si cada pantalla leyera por su cuenta, no se sincronizarían. Con este estado
// central, cuando marcas un favorito, TODAS las pantallas se enteran.
//
// Patrón: la UI llama a los métodos de este provider -> el provider llama al
// repositorio -> y llama a `notifyListeners()` para que la UI se redibuje.
// =============================================================================

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import '../datos/articulo_repositorio.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import '../modelos/consulta_articulos.dart';
import '../modelos/pagina_articulos.dart';

/// Estado global encargado de los artículos de UniCambio.
class ArticulosProvider extends ChangeNotifier {
  /// Repositorio de datos (inyectado para poder usar la BD real o una de prueba).
  final ArticuloRepositorio _repositorio;

  /// Cantidad de artículos que se piden por página.
  static const int _tamanoPagina = 12;

  ArticulosProvider(this._repositorio);

  // ---------------------------------------------------------------------------
  // Estado interno (privado). Nadie lo modifica desde afuera.
  // ---------------------------------------------------------------------------

  /// Página de artículos que se está mostrando en Inicio.
  List<Articulo> _articulos = <Articulo>[];

  /// Página de artículos publicados por la cuenta actual.
  List<Articulo> _mis = <Articulo>[];

  /// Página de artículos marcados como favoritos.
  List<Articulo> _favoritos = <Articulo>[];

  /// Artículos recientes listos para sugerir dentro de la app.
  List<Articulo> _novedades = <Articulo>[];

  /// Detalles consultados por id (evita volver a leer el mismo documento).
  final Map<String, Articulo> _cacheDetalle = <String, Articulo>{};

  /// `true` mientras se está leyendo/escribiendo en la base de datos.
  bool _cargando = false;

  /// Mensaje de error para mostrar en pantalla (null si no hay error).
  String? _error;

  /// Texto actual del buscador.
  String _textoBusqueda = '';

  /// Categoría seleccionada en los filtros (null = "Todos").
  Categoria? _categoriaSeleccionada;

  /// Precio mínimo del filtro (null = sin límite inferior).
  double? _precioMinimo;

  /// Precio máximo del filtro (null = sin límite superior).
  double? _precioMaximo;

  /// Orden elegido para los resultados.
  OrdenArticulos _orden = OrdenArticulos.titulo;

  /// Marcador opaco devuelto por el repositorio para pedir la siguiente página.
  Object? _cursor;

  /// Cursor de "Mis artículos" y de Favoritos (listas independientes).
  Object? _cursorMis;
  Object? _cursorFavoritos;

  /// `true` si el repositorio indicó que quedan más artículos en cada lista.
  bool _hayMas = false;
  bool _hayMasMis = false;
  bool _hayMasFavoritos = false;

  /// `true` mientras se pide una página adicional en cada lista.
  bool _cargandoMas = false;
  bool _cargandoMasMis = false;
  bool _cargandoMasFavoritos = false;

  /// `true` mientras se carga la primera página de cada lista.
  bool _cargandoMis = false;
  bool _cargandoFavoritos = false;
  bool _cargandoNovedades = false;

  /// Contadores para descartar respuestas viejas de cada lista.
  int _tokenPagina = 0;
  int _tokenMis = 0;
  int _tokenFavoritos = 0;
  int _tokenNovedades = 0;

  /// Escucha de cambios en tiempo real (solo si el repositorio la soporta).
  StreamSubscription<List<Articulo>>? _suscripcion;

  /// `true` tras [dispose]; evita avisar a una UI ya destruida.
  bool _destruido = false;

  /// `uid` de Firebase de la sesión actual (null si no hay sesión).
  String? _uidActual;

  /// Nombre visible de la sesión actual (para publicar y saludar).
  String _vendedorActual = vendedorPropio;

  // ---------------------------------------------------------------------------
  // Getters públicos: lo único que las pantallas pueden leer.
  // ---------------------------------------------------------------------------

  /// Artículos a mostrar en Inicio (página filtrada y ordenada).
  /// Se devuelve "no modificable" para que la UI no altere el estado por error.
  List<Articulo> get articulos => UnmodifiableListView<Articulo>(_articulos);

  /// Página de artículos publicados por la cuenta actual.
  List<Articulo> get mios => UnmodifiableListView<Articulo>(_mis);

  /// Página de artículos favoritos.
  List<Articulo> get favoritos => UnmodifiableListView<Articulo>(_favoritos);

  /// Artículos nuevos para mostrar en la bandeja de sugerencias.
  List<Articulo> get novedades => UnmodifiableListView<Articulo>(_novedades);

  /// `true` cuando hay al menos una sugerencia sin ver.
  bool get hayNovedades => _novedades.isNotEmpty;

  /// `true` mientras se consultan las sugerencias.
  bool get cargandoNovedades => _cargandoNovedades;

  /// Indica si hay una operación principal en curso (spinner de pantalla).
  bool get cargando => _cargando;

  /// Indica si se está cargando una página adicional en cada lista.
  bool get cargandoMas => _cargandoMas;
  bool get cargandoMasMis => _cargandoMasMis;
  bool get cargandoMasFavoritos => _cargandoMasFavoritos;

  /// Indica si se está cargando la primera página de cada lista.
  bool get cargandoMis => _cargandoMis;
  bool get cargandoFavoritos => _cargandoFavoritos;

  /// Error actual, si hubo alguno.
  String? get error => _error;

  /// Texto que hay escrito en el buscador.
  String get textoBusqueda => _textoBusqueda;

  /// Categoría seleccionada en los filtros.
  Categoria? get categoriaSeleccionada => _categoriaSeleccionada;

  /// Precio mínimo del filtro.
  double? get precioMinimo => _precioMinimo;

  /// Precio máximo del filtro.
  double? get precioMaximo => _precioMaximo;

  /// Orden elegido para los resultados.
  OrdenArticulos get orden => _orden;

  /// `true` si todavía quedan páginas por cargar en cada lista.
  bool get hayMas => _hayMas;
  bool get hayMasMis => _hayMasMis;
  bool get hayMasFavoritos => _hayMasFavoritos;

  /// `uid` del usuario actual (null si no hay sesión).
  String? get uidActual => _uidActual;

  /// Nombre visible del usuario actual (para el saludo y las publicaciones).
  String get vendedorActual => _vendedorActual;

  /// `true` si la lista visible está vacía (útil para el estado vacío).
  bool get listaVacia => _articulos.isEmpty;

  /// Devuelve el artículo con ese id desde la caché o las listas cargadas.
  Articulo? articuloPorId(String id) {
    final Articulo? enCache = _cacheDetalle[id];
    if (enCache != null) return enCache;
    for (final List<Articulo> lista in <List<Articulo>>[
      _articulos,
      _mis,
      _favoritos,
    ]) {
      for (final Articulo articulo in lista) {
        if (articulo.id == id) return articulo;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Carga inicial
  // ---------------------------------------------------------------------------

  /// Carga solo la primera página de Inicio.
  /// Mis artículos y Favoritos se piden bajo demanda desde sus pantallas.
  Future<void> iniciar() async {
    _reiniciarPagina();
    await _ejecutar(_recargarPagina);
    _escucharCambios();
  }

  /// Guarda los datos de la sesión actual (uid y nombre visible).
  ///
  /// `main.dart` lo llama al restaurar/iniciar sesión y la pantalla de perfil
  /// al editar el nombre, para que el saludo y las publicaciones se actualicen.
  void configurarUsuario({
    required String uid,
    String? nombre,
    String? correo,
  }) {
    final bool cambioDeCuenta = uid != _uidActual;
    _uidActual = uid;
    final String limpio = (nombre ?? '').trim();
    _vendedorActual = limpio.isNotEmpty
        ? limpio
        : (correo ?? '').split('@').first.trim();
    if (_vendedorActual.isEmpty) _vendedorActual = vendedorPropio;

    if (cambioDeCuenta) {
      _reiniciarMis();
      _reiniciarFavoritos();
      unawaited(_recargarMis());
      unawaited(_recargarFavoritos());
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Búsqueda, filtros y paginación
  // ---------------------------------------------------------------------------

  /// Actualiza el texto de búsqueda y recarga la primera página.
  Future<void> actualizarBusqueda(String texto) {
    _textoBusqueda = texto;
    _reiniciarPagina();
    return _ejecutar(_recargarPagina);
  }

  /// Cambia la categoría seleccionada (null = "Todos") y recarga la página.
  Future<void> seleccionarCategoria(Categoria? categoria) {
    _categoriaSeleccionada = categoria;
    _reiniciarPagina();
    return _ejecutar(_recargarPagina);
  }

  /// Aplica el rango de precio y el orden elegidos desde el panel de filtros.
  Future<void> actualizarFiltros({
    double? precioMinimo,
    double? precioMaximo,
    OrdenArticulos? orden,
  }) {
    _precioMinimo = precioMinimo;
    _precioMaximo = precioMaximo;
    if (orden != null) _orden = orden;
    _reiniciarPagina();
    return _ejecutar(_recargarPagina);
  }

  /// Quita todos los filtros (incluido texto y categoría) y recarga la página.
  Future<void> limpiarFiltros() {
    _textoBusqueda = '';
    _categoriaSeleccionada = null;
    _precioMinimo = null;
    _precioMaximo = null;
    _orden = OrdenArticulos.titulo;
    _reiniciarPagina();
    return _ejecutar(_recargarPagina);
  }

  /// Pide la siguiente página con el cursor devuelto por el repositorio.
  Future<void> cargarMas() async {
    if (!_hayMas || _cursor == null || _cargandoMas) return;

    final Object? cursor = _cursor;
    final int token = ++_tokenPagina;
    _cargandoMas = true;
    _error = null;
    notifyListeners();

    try {
      final PaginaArticulos pagina = await _repositorio.buscarPagina(
        _consultaActual(),
        cursor: cursor,
      );
      if (token != _tokenPagina) return;
      _articulos = List<Articulo>.from(_articulos)..addAll(pagina.articulos);
      _cursor = pagina.cursor;
      _hayMas = pagina.hayMas;
    } catch (e) {
      if (token == _tokenPagina) _error = _mensajeDeError(e);
    } finally {
      if (token == _tokenPagina) {
        _cargandoMas = false;
        notifyListeners();
      }
    }
  }

  /// Carga la primera página de "Mis artículos" (vacía sin sesión).
  Future<void> cargarMis() async {
    final String? uid = _uidActual;
    if (uid == null) {
      _reiniciarMis();
      notifyListeners();
      return;
    }

    final int token = ++_tokenMis;
    _cargandoMis = true;
    _error = null;
    notifyListeners();
    try {
      final PaginaArticulos pagina = await _repositorio.buscarPagina(
        ConsultaArticulos(uidAutor: uid, limite: _tamanoPagina),
      );
      if (token != _tokenMis || _destruido) return;
      _mis = pagina.articulos;
      _cursorMis = pagina.cursor;
      _hayMasMis = pagina.hayMas;
    } catch (e) {
      if (token == _tokenMis && !_destruido) _error = _mensajeDeError(e);
    } finally {
      if (token == _tokenMis && !_destruido) {
        _cargandoMis = false;
        notifyListeners();
      }
    }
  }

  /// Anexa la siguiente página de "Mis artículos".
  Future<void> cargarMasMis() async {
    if (!_hayMasMis || _cursorMis == null || _cargandoMasMis) return;

    final Object? cursor = _cursorMis;
    final int token = ++_tokenMis;
    _cargandoMasMis = true;
    _error = null;
    notifyListeners();
    try {
      final PaginaArticulos pagina = await _repositorio.buscarPagina(
        ConsultaArticulos(uidAutor: _uidActual, limite: _tamanoPagina),
        cursor: cursor,
      );
      if (token != _tokenMis || _destruido) return;
      _mis = List<Articulo>.from(_mis)..addAll(pagina.articulos);
      _cursorMis = pagina.cursor;
      _hayMasMis = pagina.hayMas;
    } catch (e) {
      if (token == _tokenMis && !_destruido) _error = _mensajeDeError(e);
    } finally {
      if (token == _tokenMis && !_destruido) {
        _cargandoMasMis = false;
        notifyListeners();
      }
    }
  }

  /// Carga la primera página de favoritos.
  Future<void> cargarFavoritos() async {
    final int token = ++_tokenFavoritos;
    _cargandoFavoritos = true;
    _error = null;
    notifyListeners();
    try {
      final PaginaArticulos pagina =
          await _repositorio.buscarPaginaFavoritos(limite: _tamanoPagina);
      if (token != _tokenFavoritos || _destruido) return;
      _favoritos = pagina.articulos;
      _cursorFavoritos = pagina.cursor;
      _hayMasFavoritos = pagina.hayMas;
    } catch (e) {
      if (token == _tokenFavoritos && !_destruido) {
        _error = _mensajeDeError(e);
      }
    } finally {
      if (token == _tokenFavoritos && !_destruido) {
        _cargandoFavoritos = false;
        notifyListeners();
      }
    }
  }

  /// Anexa la siguiente página de favoritos.
  Future<void> cargarMasFavoritos() async {
    if (!_hayMasFavoritos || _cursorFavoritos == null || _cargandoMasFavoritos) {
      return;
    }

    final Object? cursor = _cursorFavoritos;
    final int token = ++_tokenFavoritos;
    _cargandoMasFavoritos = true;
    _error = null;
    notifyListeners();
    try {
      final PaginaArticulos pagina = await _repositorio.buscarPaginaFavoritos(
        limite: _tamanoPagina,
        cursor: cursor,
      );
      if (token != _tokenFavoritos || _destruido) return;
      _favoritos = List<Articulo>.from(_favoritos)..addAll(pagina.articulos);
      _cursorFavoritos = pagina.cursor;
      _hayMasFavoritos = pagina.hayMas;
    } catch (e) {
      if (token == _tokenFavoritos && !_destruido) {
        _error = _mensajeDeError(e);
      }
    } finally {
      if (token == _tokenFavoritos && !_destruido) {
        _cargandoMasFavoritos = false;
        notifyListeners();
      }
    }
  }

  /// Lee un artículo por id y actualiza la caché del detalle.
  Future<void> refrescarArticulo(String id) async {
    try {
      final Articulo? actual = await _repositorio.obtenerPorId(id);
      if (actual == null || _destruido) return;
      _cacheDetalle[id] = actual;
      _reemplazarEnListas(actual);
      notifyListeners();
    } catch (e) {
      if (!_destruido) {
        _error = _mensajeDeError(e);
        notifyListeners();
      }
    }
  }

  /// Carga sugerencias recientes según las preferencias del perfil.
  ///
  /// No es una notificación push: solo se consulta mientras la app está abierta.
  /// Sin [desde] se usa una ventana de 7 días para la primera activación.
  Future<void> cargarNovedades({
    required bool activas,
    required Set<Categoria> categorias,
    DateTime? desde,
  }) async {
    if (!activas) {
      _tokenNovedades++;
      _novedades = <Articulo>[];
      _cargandoNovedades = false;
      notifyListeners();
      return;
    }

    final int token = ++_tokenNovedades;
    _cargandoNovedades = true;
    notifyListeners();
    try {
      final DateTime fecha = desde ??
          DateTime.now().subtract(const Duration(days: 7));
      final List<Articulo> encontradas = await _repositorio.buscarNovedades(
        desde: fecha,
        categorias: categorias,
        excluirUid: _uidActual,
        limite: 8,
      );
      if (token != _tokenNovedades || _destruido) return;
      _novedades = encontradas;
    } catch (error) {
      if (token == _tokenNovedades && !_destruido) {
        _error = _mensajeDeError(error);
      }
    } finally {
      if (token == _tokenNovedades && !_destruido) {
        _cargandoNovedades = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Operaciones sobre los artículos (CRUD + favoritos)
  // ---------------------------------------------------------------------------

  /// Inserta un artículo nuevo y refresca las listas.
  Future<void> insertar(Articulo articulo) {
    return _ejecutar(() async {
      await _repositorio.insertar(articulo);
      await _recargarPagina();
      await _recargarMis();
    });
  }

  /// Actualiza un artículo existente y refresca las listas.
  Future<void> actualizar(Articulo articulo) {
    return _ejecutar(() async {
      await _repositorio.actualizar(articulo);
      _cacheDetalle[articulo.id] = articulo;
      _reemplazarEnListas(articulo);
      await _recargarPagina();
      await _recargarMis();
      await _recargarFavoritos();
    });
  }

  /// Marca una publicación como disponible o finalizada.
  Future<void> cambiarEstado(String id, EstadoPublicacion estado) {
    return _ejecutar(() async {
      final Articulo? actual = await _repositorio.obtenerPorId(id);
      if (actual == null) return;
      final Articulo actualizado = actual.copyWith(estado: estado);
      await _repositorio.actualizar(actualizado);
      _cacheDetalle[id] = actualizado;
      _reemplazarEnListas(actualizado);
      await _recargarPagina();
      await _recargarMis();
    });
  }

  /// Elimina un artículo por su id y refresca las listas.
  Future<void> eliminar(String id) {
    return _ejecutar(() async {
      await _repositorio.eliminar(id);
      _cacheDetalle.remove(id);
      _articulos = _sinArticulo(_articulos, id);
      _mis = _sinArticulo(_mis, id);
      _favoritos = _sinArticulo(_favoritos, id);
      await _recargarPagina();
      await _recargarMis();
      await _recargarFavoritos();
    });
  }

  /// Marca/desmarca un artículo como favorito y refresca las listas.
  Future<void> alternarFavorito(String id) {
    return _ejecutar(() async {
      await _repositorio.alternarFavorito(id);
      final Articulo? actual = await _repositorio.obtenerPorId(id);
      if (actual != null) {
        _cacheDetalle[id] = actual;
        _reemplazarEnListas(actual);
      }
      await _recargarPagina();
      await _recargarFavoritos();
    });
  }

  // ---------------------------------------------------------------------------
  // Métodos internos
  // ---------------------------------------------------------------------------

  /// Consulta que representa el estado actual de los filtros.
  ConsultaArticulos _consultaActual() => ConsultaArticulos(
        texto: _textoBusqueda,
        categoria: _categoriaSeleccionada,
        precioMinimo: _precioMinimo,
        precioMaximo: _precioMaximo,
        orden: _orden,
        limite: _tamanoPagina,
      );

  /// Invalida la página actual y cualquier respuesta que estuviera en camino.
  void _reiniciarPagina() {
    _tokenPagina++;
    _articulos = <Articulo>[];
    _cursor = null;
    _hayMas = false;
  }

  /// Invalida la página de "Mis artículos".
  void _reiniciarMis() {
    _tokenMis++;
    _mis = <Articulo>[];
    _cursorMis = null;
    _hayMasMis = false;
    _cargandoMis = false;
    _cargandoMasMis = false;
  }

  /// Invalida la página de favoritos.
  void _reiniciarFavoritos() {
    _tokenFavoritos++;
    _favoritos = <Articulo>[];
    _cursorFavoritos = null;
    _hayMasFavoritos = false;
    _cargandoFavoritos = false;
    _cargandoMasFavoritos = false;
  }

  /// Recarga la primera página de "Mis artículos"; no avisa a la UI.
  Future<void> _recargarMis() async {
    final String? uid = _uidActual;
    if (uid == null) {
      _reiniciarMis();
      return;
    }
    final int token = ++_tokenMis;
    final PaginaArticulos pagina = await _repositorio.buscarPagina(
      ConsultaArticulos(uidAutor: uid, limite: _tamanoPagina),
    );
    if (token != _tokenMis) return;
    _mis = pagina.articulos;
    _cursorMis = pagina.cursor;
    _hayMasMis = pagina.hayMas;
  }

  /// Recarga la primera página de favoritos; no avisa a la UI.
  Future<void> _recargarFavoritos() async {
    final int token = ++_tokenFavoritos;
    final PaginaArticulos pagina =
        await _repositorio.buscarPaginaFavoritos(limite: _tamanoPagina);
    if (token != _tokenFavoritos) return;
    _favoritos = pagina.articulos;
    _cursorFavoritos = pagina.cursor;
    _hayMasFavoritos = pagina.hayMas;
  }

  /// Reemplaza un artículo actualizado en todas las listas cargadas.
  void _reemplazarEnListas(Articulo articulo) {
    List<Articulo> reemplazar(List<Articulo> lista) => [
          for (final Articulo actual in lista)
            actual.id == articulo.id ? articulo : actual,
        ];
    _articulos = reemplazar(_articulos);
    _mis = reemplazar(_mis);
    if (articulo.esFavorito) {
      _favoritos = reemplazar(_favoritos);
    } else {
      _favoritos = _sinArticulo(_favoritos, articulo.id);
    }
  }

  /// Quita un artículo de una lista por id.
  List<Articulo> _sinArticulo(List<Articulo> lista, String id) =>
      lista.where((Articulo articulo) => articulo.id != id).toList();

  /// Recarga solo la primera página visible; no avisa a la UI.
  Future<void> _recargarPagina() async {
    final int token = ++_tokenPagina;
    final PaginaArticulos pagina = await _repositorio.buscarPagina(
      _consultaActual(),
    );
    if (token != _tokenPagina) return;
    _articulos = pagina.articulos;
    _cursor = pagina.cursor;
    _hayMas = pagina.hayMas;
  }

  /// Se suscribe a los cambios de la nube (si el repositorio los soporta) para
  /// que las pantallas se actualicen solas ante publicaciones de otros usuarios.
  void _escucharCambios() {
    if (!_repositorio.enTiempoReal) return;
    _suscripcion?.cancel();
    _suscripcion = _repositorio.observarTodos().listen(
      (_) {
        _error = null;
        if (_destruido) return;
        notifyListeners();
        unawaited(_refrescarPaginaEnVivo());
        unawaited(cargarMis());
        unawaited(cargarFavoritos());
      },
      onError: (Object error) {
        _error = _mensajeDeError(error);
        if (!_destruido) notifyListeners();
      },
    );
  }

  /// Refresca la página visible tras un cambio en tiempo real.
  Future<void> _refrescarPaginaEnVivo() async {
    final int token = ++_tokenPagina;
    try {
      final PaginaArticulos pagina = await _repositorio.buscarPagina(
        _consultaActual(),
      );
      if (token != _tokenPagina || _destruido) return;
      _articulos = pagina.articulos;
      _cursor = pagina.cursor;
      _hayMas = pagina.hayMas;
      notifyListeners();
    } catch (e) {
      if (token == _tokenPagina && !_destruido) {
        _error = _mensajeDeError(e);
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _destruido = true;
    _tokenPagina++;
    _tokenMis++;
    _tokenFavoritos++;
    _tokenNovedades++;
    _suscripcion?.cancel();
    super.dispose();
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
      _error = _mensajeDeError(e);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Traduce una excepción a un mensaje amigable en español.
  String _mensajeDeError(Object error) {
    if (error is FirebaseException) {
      debugPrint('Firestore ${error.code}: ${error.message}');
      return switch (error.code) {
        'network-request-failed' => 'Sin conexión a internet. Revisa tu red.',
        'permission-denied' =>
          'No tienes permiso para esta operación. Inicia sesión de nuevo.',
        'unavailable' => 'El servicio no responde. Intenta de nuevo en un momento.',
        'failed-precondition' =>
          'Falta un índice en Firestore. ${error.message ?? 'Revisa la consola.'}',
        _ => 'Error al acceder a la nube (${error.code}).',
      };
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Ocurrió un error al acceder a los datos: $error';
  }
}
