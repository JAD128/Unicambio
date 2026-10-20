// =============================================================================
// ARCHIVO: test/articulos_provider_test.dart
// DESCRIPCIÓN: Pruebas del estado global [ArticulosProvider].
//
// Usamos el repositorio EN MEMORIA (rápido y sin base de datos) para comprobar
// que la lógica de búsqueda, filtros, favoritos y CRUD funciona bien.
//
// Se ejecuta con:  flutter test
// =============================================================================

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/datos/articulo_repositorio_memoria.dart';
import 'package:unicambio/estado/articulos_provider.dart';
import 'package:unicambio/modelos/articulo.dart';
import 'package:unicambio/modelos/categoria.dart';

/// Repositorio de prueba que simula los cambios en tiempo real de Firestore.
class RepositorioPruebaTiempoReal extends ArticuloRepositorioMemoria {
  final StreamController<List<Articulo>> _cambios =
      StreamController<List<Articulo>>.broadcast();

  @override
  bool get enTiempoReal => true;

  @override
  Stream<List<Articulo>> observarTodos() => _cambios.stream;

  /// Simula que otro usuario publicó/eliminó artículos.
  void emitir(List<Articulo> articulos) => _cambios.add(articulos);

  Future<void> cerrar() => _cambios.close();
}

/// Crea un artículo de prueba.
Articulo crearArticulo({
  required String id,
  required String titulo,
  Categoria categoria = Categoria.libros,
  bool esFavorito = false,
}) {
  return Articulo(
    id: id,
    titulo: titulo,
    descripcion: 'desc',
    precio: 1000,
    categoria: categoria,
    tipo: TipoPublicacion.venta,
    vendedor: 'Tester',
    esFavorito: esFavorito,
  );
}

void main() {
  late ArticulosProvider provider;

  setUp(() {
    provider = ArticulosProvider(
      ArticuloRepositorioMemoria(
        iniciales: <Articulo>[
          crearArticulo(id: '1', titulo: 'Libro de Cálculo'),
          crearArticulo(
            id: '2',
            titulo: 'Calculadora científica',
            categoria: Categoria.tecnologia,
          ),
          crearArticulo(
            id: '3',
            titulo: 'Apuntes de Física',
            categoria: Categoria.apuntes,
          ),
        ],
      ),
    );
  });

  test('iniciar carga todos los artículos', () async {
    await provider.iniciar();

    expect(provider.todos, hasLength(3));
    expect(provider.articulos, hasLength(3));
    expect(provider.listaVacia, isFalse);
    expect(provider.error, isNull);
  });

  test('actualizarBusqueda filtra por título', () async {
    await provider.iniciar();

    await provider.actualizarBusqueda('calcula');

    expect(provider.articulos, hasLength(1));
    expect(provider.articulos.first.titulo, contains('Calculadora'));
  });

  test('actualizarBusqueda con texto sin coincidencias deja la lista vacía',
      () async {
    await provider.iniciar();

    await provider.actualizarBusqueda('zzzz');

    expect(provider.listaVacia, isTrue);
  });

  test('seleccionarCategoria filtra por categoría', () async {
    await provider.iniciar();

    await provider.seleccionarCategoria(Categoria.apuntes);

    expect(provider.articulos, hasLength(1));
    expect(provider.articulos.first.id, '3');
  });

  test('seleccionarCategoria null muestra todos', () async {
    await provider.iniciar();

    await provider.seleccionarCategoria(Categoria.apuntes);
    await provider.seleccionarCategoria(null);

    expect(provider.articulos, hasLength(3));
  });

  test('insertar agrega un artículo nuevo', () async {
    await provider.iniciar();

    await provider.insertar(crearArticulo(id: '4', titulo: 'Nuevo'));

    expect(provider.todos, hasLength(4));
    expect(provider.articuloPorId('4'), isNotNull);
  });

  test('actualizar modifica un artículo existente', () async {
    await provider.iniciar();

    await provider.actualizar(crearArticulo(id: '1', titulo: 'Cambiado'));

    expect(provider.articuloPorId('1')!.titulo, 'Cambiado');
  });

  test('eliminar quita un artículo', () async {
    await provider.iniciar();

    await provider.eliminar('1');

    expect(provider.todos, hasLength(2));
    expect(provider.articuloPorId('1'), isNull);
  });

  test('alternarFavorito marca y desmarca', () async {
    await provider.iniciar();

    await provider.alternarFavorito('1');
    expect(provider.favoritos, hasLength(1));
    expect(provider.articuloPorId('1')!.esFavorito, isTrue);

    await provider.alternarFavorito('1');
    expect(provider.favoritos, isEmpty);
    expect(provider.articuloPorId('1')!.esFavorito, isFalse);
  });

  test('articuloPorId devuelve null si no existe', () async {
    await provider.iniciar();

    expect(provider.articuloPorId('no-existe'), isNull);
  });

  test('los cambios en tiempo real actualizan las listas', () async {
    final RepositorioPruebaTiempoReal repositorio =
        RepositorioPruebaTiempoReal();
    final ArticulosProvider enVivo = ArticulosProvider(repositorio);

    await enVivo.iniciar();
    expect(enVivo.todos, isEmpty);

    repositorio.emitir(<Articulo>[
      crearArticulo(id: '9', titulo: 'Publicado en vivo'),
      crearArticulo(id: '10', titulo: 'Otro artículo'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(enVivo.todos, hasLength(2));
    expect(enVivo.articulos, hasLength(2));
    expect(enVivo.error, isNull);

    enVivo.dispose();
    await repositorio.cerrar();
  });
}
