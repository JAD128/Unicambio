// =============================================================================
// ARCHIVO: test/articulo_repositorio_test.dart
// DESCRIPCIÓN: Pruebas del repositorio REAL (el que usa SQLite).
//
// Como SQLite no funciona "tal cual" en la PC donde se ejecutan las pruebas,
// usamos `sqflite_common_ffi`, que permite ejecutar SQLite en el escritorio.
// Gracias al patrón repositorio, probamos EXACTAMENTE el mismo código que usa
// la app en el teléfono.
//
// Se ejecuta con:  flutter test
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:unicambio/datos/articulo_repositorio.dart';
import 'package:unicambio/datos/base_datos.dart';
import 'package:unicambio/modelos/articulo.dart';
import 'package:unicambio/modelos/categoria.dart';

/// Crea un artículo de prueba con valores por defecto fáciles de cambiar.
Articulo crearArticulo({
  String id = 'x1',
  String titulo = 'Artículo de prueba',
  Categoria categoria = Categoria.libros,
  TipoPublicacion tipo = TipoPublicacion.venta,
  double precio = 1000,
  bool esFavorito = false,
}) {
  return Articulo(
    id: id,
    titulo: titulo,
    descripcion: 'Descripción de prueba',
    precio: precio,
    categoria: categoria,
    tipo: tipo,
    vendedor: 'Estudiante de prueba',
    esFavorito: esFavorito,
  );
}

void main() {
  late ArticuloRepositorio repositorio;

  // Antes de TODAS las pruebas: activamos SQLite para escritorio.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Antes de CADA prueba: borramos la base para empezar desde cero.
  setUp(() async {
    await BaseDatos.instancia.eliminar();
    repositorio = ArticuloRepositorioSqflite();
  });

  // Después de CADA prueba: cerramos la conexión.
  tearDown(() async {
    await BaseDatos.instancia.cerrar();
  });

  test('insertar guarda un artículo y obtenerTodos lo devuelve', () async {
    await repositorio.insertar(crearArticulo(id: 'a1', titulo: 'Libro'));

    final List<Articulo> todos = await repositorio.obtenerTodos();

    expect(todos, hasLength(1));
    expect(todos.first.id, 'a1');
    expect(todos.first.titulo, 'Libro');
    expect(todos.first.categoria, Categoria.libros);
    expect(todos.first.tipo, TipoPublicacion.venta);
    expect(todos.first.esFavorito, isFalse);
  });

  test('obtenerTodos devuelve los artículos ordenados por título', () async {
    await repositorio.insertar(crearArticulo(id: 'b', titulo: 'Banana'));
    await repositorio.insertar(crearArticulo(id: 'a', titulo: 'Aguacate'));
    await repositorio.insertar(crearArticulo(id: 'c', titulo: 'Coco'));

    final List<Articulo> todos = await repositorio.obtenerTodos();

    expect(
      todos.map((Articulo a) => a.titulo).toList(),
      <String>['Aguacate', 'Banana', 'Coco'],
    );
  });

  test('obtenerPorId devuelve el artículo o null si no existe', () async {
    await repositorio.insertar(crearArticulo(id: 'a1'));

    expect(await repositorio.obtenerPorId('a1'), isNotNull);
    expect(await repositorio.obtenerPorId('no-existe'), isNull);
  });

  test('actualizar modifica los datos de un artículo existente', () async {
    await repositorio.insertar(crearArticulo(id: 'a1', titulo: 'Viejo'));

    await repositorio.actualizar(
      crearArticulo(id: 'a1', titulo: 'Nuevo', precio: 5000),
    );

    final Articulo? articulo = await repositorio.obtenerPorId('a1');
    expect(articulo!.titulo, 'Nuevo');
    expect(articulo.precio, 5000);
  });

  test('eliminar borra el artículo por su id', () async {
    await repositorio.insertar(crearArticulo(id: 'a1'));
    await repositorio.insertar(crearArticulo(id: 'a2', titulo: 'Otro'));

    await repositorio.eliminar('a1');

    final List<Articulo> todos = await repositorio.obtenerTodos();
    expect(todos, hasLength(1));
    expect(todos.first.id, 'a2');
  });

  test('alternarFavorito marca y desmarca, y obtenerFavoritos filtra',
      () async {
    await repositorio.insertar(crearArticulo(id: 'a1'));
    await repositorio.insertar(crearArticulo(id: 'a2', titulo: 'Otro'));

    // Marca como favorito.
    await repositorio.alternarFavorito('a1');
    expect(await repositorio.obtenerFavoritos(), hasLength(1));
    expect((await repositorio.obtenerPorId('a1'))!.esFavorito, isTrue);

    // Lo desmarca otra vez.
    await repositorio.alternarFavorito('a1');
    expect(await repositorio.obtenerFavoritos(), isEmpty);
    expect((await repositorio.obtenerPorId('a1'))!.esFavorito, isFalse);
  });

  test('buscar filtra por texto en el título', () async {
    await repositorio.insertar(crearArticulo(id: 'a1', titulo: 'Calculadora'));
    await repositorio.insertar(crearArticulo(id: 'a2', titulo: 'Libro'));

    final List<Articulo> resultado = await repositorio.buscar('calcula');

    expect(resultado, hasLength(1));
    expect(resultado.first.titulo, 'Calculadora');
  });

  test('buscar con categoría combina ambos filtros', () async {
    await repositorio.insertar(
      crearArticulo(id: 'a1', titulo: 'Libro A', categoria: Categoria.libros),
    );
    await repositorio.insertar(
      crearArticulo(
        id: 'a2',
        titulo: 'Libro B',
        categoria: Categoria.tecnologia,
      ),
    );

    final List<Articulo> resultado = await repositorio.buscar(
      'Libro',
      categoria: Categoria.libros,
    );

    expect(resultado, hasLength(1));
    expect(resultado.first.id, 'a1');
  });

  test('buscar sin filtros devuelve todos los artículos', () async {
    await repositorio.insertar(crearArticulo(id: 'a1'));
    await repositorio.insertar(crearArticulo(id: 'a2', titulo: 'Otro'));

    expect(await repositorio.buscar(''), hasLength(2));
  });

  test('filtrarPorCategoria devuelve solo los de esa categoría', () async {
    await repositorio.insertar(
      crearArticulo(id: 'a1', categoria: Categoria.libros),
    );
    await repositorio.insertar(
      crearArticulo(id: 'a2', categoria: Categoria.deportes),
    );

    final List<Articulo> resultado =
        await repositorio.filtrarPorCategoria(Categoria.deportes);

    expect(resultado, hasLength(1));
    expect(resultado.first.id, 'a2');
  });

  test('toMap/fromMap conservan todos los campos (ida y vuelta)', () {
    final Articulo original = crearArticulo(
      id: 'z9',
      titulo: 'Round trip',
      categoria: Categoria.apuntes,
      tipo: TipoPublicacion.regalo,
      precio: 0,
      esFavorito: true,
    );

    final Articulo copia = Articulo.fromMap(original.toMap());

    expect(copia.id, original.id);
    expect(copia.titulo, original.titulo);
    expect(copia.descripcion, original.descripcion);
    expect(copia.precio, original.precio);
    expect(copia.categoria, original.categoria);
    expect(copia.tipo, original.tipo);
    expect(copia.vendedor, original.vendedor);
    expect(copia.esFavorito, original.esFavorito);
  });
}
