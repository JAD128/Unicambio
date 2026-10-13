// =============================================================================
// ARCHIVO: lib/datos/base_datos.dart
// DESCRIPCIÓN: Se encarga de crear y abrir la base de datos local SQLite usando
//              el paquete `sqflite`, y de crear la tabla donde se guardan los
//              artículos.
//
// Esta clase es la ÚNICA que conoce cómo se abre la base de datos. El
// repositorio (Fase 2) la usará para leer y escribir; las pantallas nunca la
// usan directamente.
//
// IMPORTANTE: `sqflite` funciona en Android e iOS. En escritorio/web se
// necesita `sqflite_common_ffi` (solo para pruebas), por eso la app se prueba
// en un dispositivo o emulador Android.
// =============================================================================

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Acceso centralizado a la base de datos de UniCambio.
///
/// Se implementa como "singleton" ([BaseDatos.instancia]) para que toda la app
/// comparta la misma conexión en lugar de abrir varias.
class BaseDatos {
  /// Constructor privado: obliga a usar [BaseDatos.instancia].
  BaseDatos._();

  /// Única instancia de la clase.
  static final BaseDatos instancia = BaseDatos._();

  /// Nombre del archivo de la base de datos dentro del dispositivo.
  static const String nombreArchivo = 'unicambio.db';

  /// Versión del esquema. Se sube cada vez que cambie la estructura de tablas
  /// y se maneja en [openDatabase] con `onUpgrade`.
  static const int version = 1;

  /// Nombre de la tabla de artículos (la usan los repositorios).
  static const String tablaArticulos = 'articulos';

  /// Conexión abierta, se guarda en caché para no reabrirla cada vez.
  Database? _db;

  /// Devuelve la base de datos, abriéndola la primera vez que se solicita.
  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await _abrir();
    return _db!;
  }

  /// Abre (o crea) el archivo de base de datos y configura la creación de tablas.
  Future<Database> _abrir() async {
    // Ruta de la carpeta de bases de datos del sistema (Android/iOS).
    final String carpeta = await getDatabasesPath();
    final String ruta = p.join(carpeta, nombreArchivo);

    return openDatabase(
      ruta,
      version: version,
      // onCreate se ejecuta solo la primera vez (cuando el archivo no existe).
      onCreate: _crearTablas,
      // onUpgrade se ejecutará cuando subamos `version` en el futuro.
      onUpgrade: _actualizarTablas,
    );
  }

  /// Crea las tablas en la primera apertura de la base de datos.
  Future<void> _crearTablas(Database db, int versionNueva) async {
    await db.execute('''
      CREATE TABLE $tablaArticulos (
        id          TEXT    PRIMARY KEY,
        titulo      TEXT    NOT NULL,
        descripcion TEXT    NOT NULL,
        precio      REAL    NOT NULL DEFAULT 0,
        categoria   TEXT    NOT NULL,
        tipo        TEXT    NOT NULL,
        vendedor    TEXT    NOT NULL,
        esFavorito  INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Migraciones futuras cuando cambie la estructura de la base de datos.
  ///
  /// Por ahora no hay cambios de versión, así que queda preparado pero vacío.
  Future<void> _actualizarTablas(
    Database db,
    int versionAnterior,
    int versionNueva,
  ) async {
    // Ejemplo para más adelante:
    // if (versionAnterior < 2) {
    //   await db.execute('ALTER TABLE $tablaArticulos ADD COLUMN ubicacion TEXT');
    // }
  }

  /// Cierra la conexión (útil al hacer logout o en pruebas).
  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
  }

  /// Elimina por completo el archivo de la base de datos.
  /// Se usa principalmente en pruebas para empezar desde cero.
  Future<void> eliminar() async {
    await cerrar();
    final String carpeta = await getDatabasesPath();
    final String ruta = p.join(carpeta, nombreArchivo);
    await deleteDatabase(ruta);
  }
}
