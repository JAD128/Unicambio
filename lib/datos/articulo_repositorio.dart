// =============================================================================
// ARCHIVO: lib/datos/articulo_repositorio.dart
// DESCRIPCIÓN: Define QUÉ operaciones se pueden hacer con los artículos (la
//              interfaz) y CÓMO se hacen con SQLite (la implementación).
//
// Patrón repositorio: la interfaz [ArticuloRepositorio] es el "contrato" que
// usará la app (pantallas y estado). La clase [ArticuloRepositorioSqflite] es
// una implementación concreta que guarda en la base de datos local.
//
// Gracias a esto, si mañana cambiamos a la nube (Firebase/Supabase), solo
// creamos otra implementación (ej. `ArticuloRepositorioNube`) y la cambiamos en
// `main.dart`. Las pantallas NO se enteran ni se modifican.
// =============================================================================

import 'package:sqflite/sqflite.dart';

import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import 'base_datos.dart';

/// Contrato con todas las operaciones disponibles sobre los artículos.
///
/// Todo es asíncrono (`Future`) porque la base de datos (local o en la nube)
/// responde de forma asíncrona.
abstract class ArticuloRepositorio {
  /// Devuelve todos los artículos guardados.
  Future<List<Articulo>> obtenerTodos();

  /// Devuelve solo los artículos marcados como favoritos.
  Future<List<Articulo>> obtenerFavoritos();

  /// Devuelve un artículo por su [id], o `null` si no existe.
  Future<Articulo?> obtenerPorId(String id);

  /// Guarda un artículo nuevo.
  Future<void> insertar(Articulo articulo);

  /// Actualiza un artículo existente (se identifica por su `id`).
  Future<void> actualizar(Articulo articulo);

  /// Elimina el artículo con ese [id].
  Future<void> eliminar(String id);

  /// Cambia el estado de favorito del artículo con ese [id] (marca/desmarca).
  Future<void> alternarFavorito(String id);

  /// Busca artículos cuyo título contenga [texto] y, opcionalmente, que
  /// pertenezcan a una [categoria].
  Future<List<Articulo>> buscar(String texto, {Categoria? categoria});

  /// Devuelve los artículos de una [categoria].
  Future<List<Articulo>> filtrarPorCategoria(Categoria categoria);

  /// `true` si el repositorio puede avisar en tiempo real de los cambios que
  /// hacen otros usuarios (Firestore sí; SQLite y memoria no).
  ///
  /// El provider solo escucha [observarTodos] cuando esto es `true`, porque los
  /// repositorios locales no cambian "por fuera" de la app.
  bool get enTiempoReal => false;

  /// Emite la lista completa de artículos cada vez que cambia en la nube.
  ///
  /// Por defecto no emite nada: solo lo implementan los repositorios con
  /// [enTiempoReal] (ver `ArticuloRepositorioNube`).
  Stream<List<Articulo>> observarTodos() =>
      const Stream<List<Articulo>>.empty();
}

/// Implementación de [ArticuloRepositorio] usando SQLite (paquete `sqflite`).
class ArticuloRepositorioSqflite implements ArticuloRepositorio {
  /// Acceso a la base de datos. Se inyecta para poder usar otra instancia en
  /// las pruebas; por defecto usa el singleton [BaseDatos.instancia].
  final BaseDatos _baseDatos;

  ArticuloRepositorioSqflite({BaseDatos? baseDatos})
      : _baseDatos = baseDatos ?? BaseDatos.instancia;

  /// Atajo para obtener la conexión a la base de datos.
  Future<Database> get _db => _baseDatos.db;

  /// Columna por la que se ordenan los resultados.
  static const String _orden = 'titulo ASC';

  @override
  Future<List<Articulo>> obtenerTodos() async {
    final Database db = await _db;
    final List<Map<String, Object?>> filas = await db.query(
      BaseDatos.tablaArticulos,
      orderBy: _orden,
    );
    return filas.map(Articulo.fromMap).toList();
  }

  @override
  bool get enTiempoReal => false;

  /// Solo hay datos locales: no hay cambios externos que escuchar.
  @override
  Stream<List<Articulo>> observarTodos() =>
      const Stream<List<Articulo>>.empty();

  @override
  Future<List<Articulo>> obtenerFavoritos() async {
    final Database db = await _db;
    final List<Map<String, Object?>> filas = await db.query(
      BaseDatos.tablaArticulos,
      where: 'esFavorito = ?',
      whereArgs: <Object?>[1],
      orderBy: _orden,
    );
    return filas.map(Articulo.fromMap).toList();
  }

  @override
  Future<Articulo?> obtenerPorId(String id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> filas = await db.query(
      BaseDatos.tablaArticulos,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (filas.isEmpty) {
      return null;
    }
    return Articulo.fromMap(filas.first);
  }

  @override
  Future<void> insertar(Articulo articulo) async {
    final Database db = await _db;
    // `ConflictAlgorithm.replace` evita errores si el id ya existiera.
    await db.insert(
      BaseDatos.tablaArticulos,
      articulo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> actualizar(Articulo articulo) async {
    final Database db = await _db;
    await db.update(
      BaseDatos.tablaArticulos,
      articulo.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[articulo.id],
    );
  }

  @override
  Future<void> eliminar(String id) async {
    final Database db = await _db;
    await db.delete(
      BaseDatos.tablaArticulos,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> alternarFavorito(String id) async {
    final Database db = await _db;
    // Como `esFavorito` guarda 0 o 1, `1 - esFavorito` lo invierte en la propia
    // base de datos (no hace falta leerlo antes en Dart).
    await db.rawUpdate(
      'UPDATE ${BaseDatos.tablaArticulos} SET esFavorito = 1 - esFavorito WHERE id = ?',
      <Object?>[id],
    );
  }

  @override
  Future<List<Articulo>> buscar(String texto, {Categoria? categoria}) async {
    final Database db = await _db;

    // Construimos la condición WHERE dinámicamente solo con los filtros activos.
    final List<String> condiciones = <String>[];
    final List<Object?> argumentos = <Object?>[];

    final String textoLimpio = texto.trim();
    if (textoLimpio.isNotEmpty) {
      // `LIKE %texto%` busca coincidencias parciales en el título.
      condiciones.add('titulo LIKE ?');
      argumentos.add('%$textoLimpio%');
    }
    if (categoria != null) {
      condiciones.add('categoria = ?');
      argumentos.add(categoria.name);
    }

    final List<Map<String, Object?>> filas = await db.query(
      BaseDatos.tablaArticulos,
      where: condiciones.isEmpty ? null : condiciones.join(' AND '),
      whereArgs: argumentos.isEmpty ? null : argumentos,
      orderBy: _orden,
    );
    return filas.map(Articulo.fromMap).toList();
  }

  @override
  Future<List<Articulo>> filtrarPorCategoria(Categoria categoria) async {
    final Database db = await _db;
    final List<Map<String, Object?>> filas = await db.query(
      BaseDatos.tablaArticulos,
      where: 'categoria = ?',
      whereArgs: <Object?>[categoria.name],
      orderBy: _orden,
    );
    return filas.map(Articulo.fromMap).toList();
  }
}
