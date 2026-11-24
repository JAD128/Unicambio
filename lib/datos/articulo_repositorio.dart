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
import '../modelos/consulta_articulos.dart';
import '../modelos/pagina_articulos.dart';
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

  /// Busca artículos aplicando todos los filtros de [consulta], devolviendo
  /// una página y un [PaginaArticulos.cursor] opaco para continuar.
  Future<PaginaArticulos> buscarPagina(
    ConsultaArticulos consulta, {
    Object? cursor,
  });

  /// Devuelve una página de favoritos del usuario actual.
  ///
  /// En Firestore los favoritos viven en `usuarios/{uid}/favoritos`, por lo que
  /// no puede expresarse como un filtro de [buscarPagina]. El cursor es opaco.
  Future<PaginaArticulos> buscarPaginaFavoritos({
    required int limite,
    Object? cursor,
  });

  /// Busca todos los artículos que coinciden con [texto] y [categoria].
  ///
  /// Se conserva para el código histórico y las pruebas; la app usa
  /// [buscarPagina] para que la lista de Inicio no lea toda la colección.
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
    final PaginaArticulos pagina = await buscarPagina(
      ConsultaArticulos(texto: texto, categoria: categoria, limite: null),
    );
    return pagina.articulos;
  }

  /// Traduce el orden de la consulta a un `ORDER BY` de SQLite.
  String _ordenSql(ConsultaArticulos consulta) {
    final OrdenArticulos orden = consulta.ordenEfectivo;
    if (orden == OrdenArticulos.titulo) return 'titulo ASC, id ASC';
    final String sentido = orden.descendente ? 'DESC' : 'ASC';
    return 'precio $sentido, titulo ASC, id ASC';
  }

  @override
  Future<PaginaArticulos> buscarPagina(
    ConsultaArticulos consulta, {
    Object? cursor,
  }) async {
    final Database db = await _db;
    final List<String> condiciones = <String>[];
    final List<Object?> argumentos = <Object?>[];

    final String textoLimpio = consulta.texto.trim();
    if (textoLimpio.isNotEmpty) {
      condiciones.add('(titulo LIKE ? OR descripcion LIKE ?)');
      argumentos.addAll(<Object?>['%$textoLimpio%', '%$textoLimpio%']);
    }
    if (consulta.categoria != null) {
      condiciones.add('categoria = ?');
      argumentos.add(consulta.categoria!.name);
    }
    if (consulta.precioMinimo != null) {
      condiciones.add('precio >= ?');
      argumentos.add(consulta.precioMinimo);
    }
    if (consulta.precioMaximo != null) {
      condiciones.add('precio <= ?');
      argumentos.add(consulta.precioMaximo);
    }
    if (consulta.uidAutor != null) {
      condiciones.add('uidAutor = ?');
      argumentos.add(consulta.uidAutor);
    }

    final int? limite = consulta.limite;
    final int desplazamiento =
        cursor is int && cursor >= 0 ? cursor : 0;
    final List<Map<String, Object?>> filas = await db.query(
      BaseDatos.tablaArticulos,
      where: condiciones.isEmpty ? null : condiciones.join(' AND '),
      whereArgs: argumentos.isEmpty ? null : argumentos,
      orderBy: _ordenSql(consulta),
      limit: limite == null ? null : limite + 1,
      offset: limite == null ? null : desplazamiento,
    );

    if (limite == null) {
      return PaginaArticulos(
        articulos: filas.map(Articulo.fromMap).toList(),
      );
    }

    final bool hayMas = filas.length > limite;
    final List<Map<String, Object?>> visibles =
        filas.take(limite).toList();
    return PaginaArticulos(
      articulos: visibles.map(Articulo.fromMap).toList(),
      cursor: desplazamiento + visibles.length,
      hayMas: hayMas,
    );
  }

  @override
  Future<PaginaArticulos> buscarPaginaFavoritos({
    required int limite,
    Object? cursor,
  }) async {
    final Database db = await _db;
    final int desplazamiento = cursor is int && cursor >= 0 ? cursor : 0;
    final List<Map<String, Object?>> filas = await db.query(
      BaseDatos.tablaArticulos,
      where: 'esFavorito = 1',
      orderBy: _ordenSql(const ConsultaArticulos()),
      limit: limite + 1,
      offset: desplazamiento,
    );

    final bool hayMas = filas.length > limite;
    final List<Map<String, Object?>> visibles = filas.take(limite).toList();
    return PaginaArticulos(
      articulos: visibles.map(Articulo.fromMap).toList(),
      cursor: desplazamiento + visibles.length,
      hayMas: hayMas,
    );
  }

  @override
  Future<List<Articulo>> filtrarPorCategoria(Categoria categoria) =>
      buscar('', categoria: categoria);
}
