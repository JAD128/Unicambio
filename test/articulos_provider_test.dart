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
import 'package:unicambio/modelos/consulta_articulos.dart';

/// Repositorio de prueba que simula los cambios en tiempo real de Firestore.
class RepositorioPruebaTiempoReal extends ArticuloRepositorioMemoria {
  final StreamController<List<Articulo>> _cambios =
      StreamController<List<Articulo>>.broadcast();

  @override
  bool get enTiempoReal => true;

  @override
  Stream<List<Articulo>> observarTodos() => _cambios.stream;

  /// Simula que otro usuario publicó/eliminó artículos.
  void emitir(List<Articulo> articulos) {
    for (final Articulo articulo in articulos) {
      insertar(articulo);
    }
    _cambios.add(articulos);
  }

  Future<void> cerrar() => _cambios.close();
}

/// Crea un artículo de prueba.
Articulo crearArticulo({
  required String id,
  required String titulo,
  String descripcion = 'desc',
  double precio = 1000,
  Categoria categoria = Categoria.libros,
  bool esFavorito = false,
  String? uidAutor,
  EstadoPublicacion estado = EstadoPublicacion.disponible,
}) {
  return Articulo(
    id: id,
    titulo: titulo,
    descripcion: descripcion,
    precio: precio,
    categoria: categoria,
    tipo: TipoPublicacion.venta,
    vendedor: 'Tester',
    esFavorito: esFavorito,
    uidAutor: uidAutor,
    estado: estado,
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

  test('mios filtra por el uid de la sesión', () async {
    final ArticulosProvider proveedor = ArticulosProvider(
      ArticuloRepositorioMemoria(
        iniciales: <Articulo>[
          crearArticulo(id: 'a', titulo: 'Mío', uidAutor: 'uid-1'),
          crearArticulo(id: 'b', titulo: 'Ajeno', uidAutor: 'uid-2'),
          crearArticulo(id: 'c', titulo: 'Sin dueño'),
        ],
      ),
    );
    await proveedor.iniciar();

    expect(proveedor.mios, isEmpty);

    proveedor.configurarUsuario(uid: 'uid-1', nombre: 'Ana');
    await proveedor.cargarMis();
    expect(proveedor.vendedorActual, 'Ana');
    expect(proveedor.mios.map((Articulo a) => a.id), <String>['a']);
  });

  test('insertar agrega un artículo nuevo', () async {
    await provider.iniciar();

    await provider.insertar(crearArticulo(id: '4', titulo: 'Nuevo'));

    expect(provider.articulos, hasLength(4));
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

    expect(provider.articulos, hasLength(2));
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

  test('actualizarFiltros aplica texto, precio y orden; limpiar restablece',
      () async {
    final ArticulosProvider filtrado = ArticulosProvider(
      ArticuloRepositorioMemoria(
        iniciales: <Articulo>[
          crearArticulo(
            id: '1',
            titulo: 'Libro',
            descripcion: 'cuaderno',
            precio: 100,
          ),
          crearArticulo(
            id: '2',
            titulo: 'Mochila',
            descripcion: 'cuaderno escolar',
            precio: 300,
          ),
          crearArticulo(
            id: '3',
            titulo: 'Otro',
            descripcion: 'sin filtro',
            precio: 200,
          ),
        ],
      ),
    );
    await filtrado.iniciar();

    await filtrado.actualizarFiltros(
      precioMinimo: 100,
      precioMaximo: 300,
      orden: OrdenArticulos.precioDesc,
    );
    expect(
      filtrado.articulos.map((Articulo a) => a.id).toList(),
      <String>['2', '3', '1'],
    );

    await filtrado.actualizarBusqueda('escolar');
    expect(filtrado.articulos.map((Articulo a) => a.id).toList(), <String>['2']);

    await filtrado.limpiarFiltros();
    expect(filtrado.textoBusqueda, isEmpty);
    expect(filtrado.precioMinimo, isNull);
    expect(filtrado.precioMaximo, isNull);
    expect(filtrado.orden, OrdenArticulos.titulo);
    expect(filtrado.articulos, hasLength(3));
  });

  test('cargarMas anexa la página siguiente y agota el cursor', () async {
    final List<Articulo> muchos = List<Articulo>.generate(
      14,
      (int i) => crearArticulo(
        id: '${i + 1}',
        titulo: 'Artículo ${14 - i}',
      ),
    );
    final ArticulosProvider paginado = ArticulosProvider(
      ArticuloRepositorioMemoria(iniciales: muchos),
    );
    await paginado.iniciar();

    expect(paginado.articulos, hasLength(12));
    expect(paginado.hayMas, isTrue);

    await paginado.cargarMas();

    expect(paginado.articulos, hasLength(14));
    expect(paginado.hayMas, isFalse);
    expect(paginado.cargandoMas, isFalse);
  });

  test('los cambios en tiempo real actualizan las listas', () async {
    final RepositorioPruebaTiempoReal repositorio =
        RepositorioPruebaTiempoReal();
    final ArticulosProvider enVivo = ArticulosProvider(repositorio);

    await enVivo.iniciar();
    expect(enVivo.articulos, isEmpty);

    repositorio.emitir(<Articulo>[
      crearArticulo(id: '9', titulo: 'Publicado en vivo'),
      crearArticulo(id: '10', titulo: 'Otro artículo'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(enVivo.articulos, hasLength(2));
    expect(enVivo.error, isNull);

    enVivo.dispose();
    await repositorio.cerrar();
  });

  test('cargarMis pagina y cargarMasMis agota el cursor', () async {
    final List<Articulo> mios = List<Articulo>.generate(
      14,
      (int i) => crearArticulo(
        id: 'm${i + 1}',
        titulo: 'Artículo ${14 - i}',
        uidAutor: 'uid-1',
      ),
    );
    final ArticulosProvider paginado = ArticulosProvider(
      ArticuloRepositorioMemoria(iniciales: mios),
    );
    paginado.configurarUsuario(uid: 'uid-1', nombre: 'Ana');
    await paginado.cargarMis();

    expect(paginado.mios, hasLength(12));
    expect(paginado.hayMasMis, isTrue);

    await paginado.cargarMasMis();

    expect(paginado.mios, hasLength(14));
    expect(paginado.hayMasMis, isFalse);
  });

  test('cargarFavoritos pagina y cargarMasFavoritos agota el cursor', () async {
    final List<Articulo> favoritos = List<Articulo>.generate(
      14,
      (int i) => crearArticulo(
        id: 'f${i + 1}',
        titulo: 'Favorito ${14 - i}',
        esFavorito: true,
      ),
    );
    final ArticulosProvider paginado = ArticulosProvider(
      ArticuloRepositorioMemoria(iniciales: favoritos),
    );
    await paginado.cargarFavoritos();

    expect(paginado.favoritos, hasLength(12));
    expect(paginado.hayMasFavoritos, isTrue);

    await paginado.cargarMasFavoritos();

    expect(paginado.favoritos, hasLength(14));
    expect(paginado.hayMasFavoritos, isFalse);
  });

  test('cambiarEstado actualiza la caché y las listas', () async {
    await provider.iniciar();

    await provider.cambiarEstado('1', EstadoPublicacion.finalizado);

    expect(provider.articuloPorId('1')!.estado, EstadoPublicacion.finalizado);
    expect(
      provider.articulos.firstWhere((Articulo a) => a.id == '1').estado,
      EstadoPublicacion.finalizado,
    );
  });
}
