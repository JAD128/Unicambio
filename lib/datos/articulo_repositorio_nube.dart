// =============================================================================
// ARCHIVO: lib/datos/articulo_repositorio_nube.dart
// DESCRIPCIÓN: Implementación de [ArticuloRepositorio] usando Cloud Firestore.
//
// Es la contraparte de [ArticuloRepositorioSqflite]: la app cambia de una a
// otra en `main.dart` sin tocar pantallas ni provider (patrón repositorio).
//
// Estructura en Firestore:
//   articulos/{idArticulo}                → datos públicos del artículo
//   usuarios/{uid}/favoritos/{idArticulo} → favoritos de cada usuario
//
// Detalles importantes:
// - El id lo asigna Firestore (no usamos los ids con hora del modelo).
// - El artículo guarda en silencio el `uidAutor` del que lo publicó; las
//   reglas de seguridad lo usan para permitir editar solo al dueño.
// - `esFavorito` NO se guarda en la nube: cada usuario tiene su propia
//   subcolección de favoritos y el flag se marca en memoria al leer.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelos/articulo.dart';
import '../modelos/categoria.dart';
import '../modelos/consulta_articulos.dart';
import '../modelos/pagina_articulos.dart';
import 'articulo_repositorio.dart';

/// Implementación de [ArticuloRepositorio] sobre Cloud Firestore.
class ArticuloRepositorioNube implements ArticuloRepositorio {
  /// Acceso a Firestore y a la sesión (inyectables para pruebas).
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ArticuloRepositorioNube({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Colección compartida con todos los artículos publicados.
  CollectionReference<Map<String, dynamic>> get _articulos =>
      _db.collection('articulos');

  /// Devuelve la subcolección de favoritos del usuario actual.
  ///
  /// Lanza [StateError] si no hay sesión (las reglas de Firestore también
  /// lo impedirían, pero avisamos antes y con un mensaje claro).
  CollectionReference<Map<String, dynamic>> _favoritos() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Debes iniciar sesión para ver o marcar favoritos.');
    }
    return _db.collection('usuarios').doc(uid).collection('favoritos');
  }

  @override
  Future<List<Articulo>> obtenerTodos() async {
    final QuerySnapshot<Map<String, dynamic>> datos =
        await _articulos.orderBy('titulo').get();
    return _marcarFavoritos(_desdeSnapshots(datos));
  }

  @override
  bool get enTiempoReal => true;

  /// Escucha la colección: Firestore mantiene una conexión abierta y envía
  /// solo los documentos que cambian (no hace *polling*), así que la lista se
  /// actualiza sola cuando otro usuario publica, edita o elimina.
  @override
  Stream<List<Articulo>> observarTodos() {
    return _articulos.orderBy('titulo').snapshots().asyncMap((datos) async {
      final List<Articulo> articulos = _desdeSnapshots(datos);
      if (_auth.currentUser == null) return articulos;
      return _marcarFavoritos(articulos);
    });
  }

  @override
  Future<List<Articulo>> obtenerFavoritos() async {
    final QuerySnapshot<Map<String, dynamic>> datos = await _favoritos().get();
    final List<String> ids = datos.docs.map((doc) => doc.id).toList();
    if (ids.isEmpty) return <Articulo>[];

    // Pedimos los artículos de cada favorito; si un favorito apunta a un
    // artículo ya eliminado, simplemente lo ignoramos.
    final List<DocumentSnapshot<Map<String, dynamic>>> documentos =
        await Future.wait(ids.map((id) => _articulos.doc(id).get()));
    final List<Articulo> articulos = documentos
        .where((doc) => doc.exists)
        .map((doc) => _desdeSnapshot(doc))
        .toList()
      ..sort((a, b) => a.titulo.compareTo(b.titulo));
    return articulos.map((a) => a.copyWith(esFavorito: true)).toList();
  }

  @override
  Future<Articulo?> obtenerPorId(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> datos =
        await _articulos.doc(id).get();
    if (!datos.exists) return null;
    final List<Articulo> marcados =
        await _marcarFavoritos(<Articulo>[_desdeSnapshot(datos)]);
    return marcados.first;
  }

  @override
  Future<void> insertar(Articulo articulo) async {
    // El id del modelo (con hora) se ignora: Firestore asigna uno propio.
    await _articulos.add(_aMapa(articulo));
  }

  @override
  Future<void> actualizar(Articulo articulo) async {
    // Actualiza los datos; el id del documento ya coincide con articulo.id
    // porque al leer lo construimos con el id real de Firestore.
    await _articulos.doc(articulo.id).update(_aMapa(articulo));
  }

  @override
  Future<void> eliminar(String id) async {
    // Borra el artículo y, si el usuario actual lo tenía favorito, su marca.
    final WriteBatch lote = _db.batch();
    lote.delete(_articulos.doc(id));
    lote.delete(_favoritos().doc(id));
    await lote.commit();
  }

  @override
  Future<void> alternarFavorito(String id) async {
    final DocumentReference<Map<String, dynamic>> marca = _favoritos().doc(id);
    final DocumentSnapshot<Map<String, dynamic>> actual = await marca.get();
    if (actual.exists) {
      await marca.delete();
    } else {
      await marca.set(<String, Object>{'creado': FieldValue.serverTimestamp()});
    }
  }

  @override
  Future<List<Articulo>> buscar(String texto, {Categoria? categoria}) async {
    final PaginaArticulos pagina = await buscarPagina(
      ConsultaArticulos(texto: texto, categoria: categoria, limite: null),
    );
    return pagina.articulos;
  }

  @override
  Future<PaginaArticulos> buscarPagina(
    ConsultaArticulos consulta, {
    Object? cursor,
  }) async {
    final String firma = consulta.firma;
    Query<Map<String, dynamic>> query = _articulos;
    if (consulta.categoria != null) {
      query = query.where('categoria', isEqualTo: consulta.categoria!.name);
    }
    if (consulta.precioMinimo != null) {
      query = query.where(
        'precio',
        isGreaterThanOrEqualTo: consulta.precioMinimo,
      );
    }
    if (consulta.precioMaximo != null) {
      query = query.where('precio', isLessThanOrEqualTo: consulta.precioMaximo);
    }
    if (consulta.uidAutor != null) {
      query = query.where('uidAutor', isEqualTo: consulta.uidAutor);
    }

    // Con un rango de precio, Firestore exige ordenar primero por `precio`.
    final OrdenArticulos orden = consulta.ordenEfectivo;
    query = query.orderBy(orden.campo, descending: orden.descendente);

    DocumentSnapshot<Map<String, dynamic>>? documentoInicial;
    if (cursor != null) {
      if (cursor is! _CursorNube || cursor.firma != firma) {
        throw StateError('El paginador cambió. Vuelve a aplicar los filtros.');
      }
      documentoInicial = cursor.documento;
      query = query.startAfterDocument(documentoInicial);
    }

    final String texto = consulta.texto.trim().toLowerCase();
    bool coincideTexto(DocumentSnapshot<Map<String, dynamic>> doc) {
      if (texto.isEmpty) return true;
      final Map<String, dynamic>? datos = doc.data();
      final String titulo = (datos?['titulo'] as String? ?? '').toLowerCase();
      final String descripcion =
          (datos?['descripcion'] as String? ?? '').toLowerCase();
      return titulo.contains(texto) || descripcion.contains(texto);
    }

    final int? limite = consulta.limite;
    if (limite == null) {
      final QuerySnapshot<Map<String, dynamic>> datos = await query.get();
      final List<_ParDocumento> pares = datos.docs
          .where(coincideTexto)
          .map((DocumentSnapshot<Map<String, dynamic>> doc) => _ParDocumento(
                _desdeSnapshot(doc),
                doc,
              ))
          .toList();
      final List<Articulo> marcados =
          await _marcarFavoritos(pares.map((p) => p.articulo).toList());
      return PaginaArticulos(
        articulos: marcados,
        cursor: pares.isEmpty ? null : pares.last.documento,
      );
    }

    // Firestore no busca substrings: leemos lotes hasta llenar la página con
    // coincidencias reales. El cursor final es el último artículo devuelto.
    final int objetivo = limite + 1;
    final List<_ParDocumento> acumulados = <_ParDocumento>[];
    DocumentSnapshot<Map<String, dynamic>>? ultimoLeido;
    while (acumulados.length < objetivo) {
      final int pedido = objetivo - acumulados.length;
      Query<Map<String, dynamic>> lote = query;
      if (ultimoLeido != null) {
        lote = lote.startAfterDocument(ultimoLeido);
      }
      final QuerySnapshot<Map<String, dynamic>> datos =
          await lote.limit(pedido).get();
      if (datos.docs.isEmpty) break;
      for (final DocumentSnapshot<Map<String, dynamic>> doc in datos.docs) {
        if (coincideTexto(doc)) {
          acumulados.add(_ParDocumento(_desdeSnapshot(doc), doc));
        }
      }
      ultimoLeido = datos.docs.last;
      if (datos.docs.length < pedido) break;
    }

    final List<Articulo> marcados =
        await _marcarFavoritos(acumulados.map((p) => p.articulo).toList());
    final List<_ParDocumento> resultado = <_ParDocumento>[
      for (int i = 0; i < acumulados.length; i++)
        _ParDocumento(marcados[i], acumulados[i].documento),
    ];
    final List<_ParDocumento> visibles = resultado.take(limite).toList();
    return PaginaArticulos(
      articulos: visibles.map((p) => p.articulo).toList(),
      cursor: visibles.isEmpty
          ? null
          : _CursorNube(visibles.last.documento, firma),
      hayMas: resultado.length > limite,
    );
  }

  @override
  Future<PaginaArticulos> buscarPaginaFavoritos({
    required int limite,
    Object? cursor,
  }) async {
    Query<Map<String, dynamic>> query =
        _favoritos().orderBy(FieldPath.documentId);
    if (cursor != null) {
      if (cursor is! _CursorFavoritos) {
        throw StateError(
          'El paginador de favoritos cambió. Vuelve a abrir la lista.',
        );
      }
      query = query.startAfterDocument(cursor.documento);
    }

    final QuerySnapshot<Map<String, dynamic>> datos =
        await query.limit(limite + 1).get();
    final bool hayMas = datos.docs.length > limite;
    final List<DocumentSnapshot<Map<String, dynamic>>> visibles =
        datos.docs.take(limite).toList();
    final List<DocumentSnapshot<Map<String, dynamic>>> documentos =
        await Future.wait(
      visibles.map((favorito) => _articulos.doc(favorito.id).get()),
    );
    final List<Articulo> articulos = <Articulo>[];
    for (final DocumentSnapshot<Map<String, dynamic>> doc in documentos) {
      if (!doc.exists || doc.data() == null) continue;
      articulos.add(_desdeSnapshot(doc).copyWith(esFavorito: true));
    }

    return PaginaArticulos(
      articulos: articulos,
      cursor: visibles.isEmpty ? null : _CursorFavoritos(visibles.last),
      hayMas: hayMas,
    );
  }

  @override
  Future<List<Articulo>> filtrarPorCategoria(Categoria categoria) =>
      buscar('', categoria: categoria);

  // ---------------------------------------------------------------------------
  // Métodos auxiliares privados
  // ---------------------------------------------------------------------------

  /// Convierte los documentos de Firestore en artículos del modelo.
  List<Articulo> _desdeSnapshots(QuerySnapshot<Map<String, dynamic>> datos) =>
      datos.docs.map(_desdeSnapshot).toList();

  /// Convierte un documento en un [Articulo], usando el id real de Firestore.
  Articulo _desdeSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> datos = doc.data()!;
    return Articulo(
      id: doc.id,
      titulo: datos['titulo'] as String,
      descripcion: datos['descripcion'] as String,
      precio: (datos['precio'] as num).toDouble(),
      categoria: Categoria.values.byName(datos['categoria'] as String),
      tipo: TipoPublicacion.values.byName(datos['tipo'] as String),
      vendedor: datos['vendedor'] as String,
      imagenUrl: datos['imagenUrl'] as String?,
      uidAutor: datos['uidAutor'] as String?,
      estado: EstadoPublicacion.values.firstWhere(
        (EstadoPublicacion valor) =>
            valor.name == (datos['estado'] as String? ?? 'disponible'),
        orElse: () => EstadoPublicacion.disponible,
      ),
    );
  }

  /// Convierte el modelo en el mapa que se guarda en Firestore.
  ///
  /// No guardamos `esFavorito` (es por usuario) ni el id (lo asigna Firestore).
  /// `imagenUrl` se guarda como null al quitar la foto, para borrar el campo.
  Map<String, Object?> _aMapa(Articulo articulo) => <String, Object?>{
        'titulo': articulo.titulo,
        'descripcion': articulo.descripcion,
        'precio': articulo.precio,
        'categoria': articulo.categoria.name,
        'tipo': articulo.tipo.name,
        'vendedor': articulo.vendedor,
        'imagenUrl': articulo.imagenUrl,
        'uidAutor': _auth.currentUser?.uid ?? '',
        'estado': articulo.estado.name,
      };

  /// Devuelve los ids marcados como favorito por el usuario actual.
  Future<Set<String>> _idsFavoritos() async {
    final QuerySnapshot<Map<String, dynamic>> datos =
        await _favoritos().get();
    return datos.docs.map((doc) => doc.id).toSet();
  }

  /// Marca (en memoria) cuáles artículos son favoritos del usuario actual.
  Future<List<Articulo>> _marcarFavoritos(List<Articulo> articulos) async {
    final Set<String> favoritos = await _idsFavoritos();
    return articulos
        .map((articulo) =>
            articulo.copyWith(esFavorito: favoritos.contains(articulo.id)))
        .toList();
  }
}

/// Par internally usado para no perder el documento de Firestore al marcar
/// favoritos: el documento es necesario para `startAfterDocument`.
class _ParDocumento {
  final Articulo articulo;
  final DocumentSnapshot<Map<String, dynamic>> documento;

  const _ParDocumento(this.articulo, this.documento);
}

/// Cursor opaco de Firestore; la firma evita reutilizarlo con otra consulta.
class _CursorNube {
  final DocumentSnapshot<Map<String, dynamic>> documento;
  final String firma;

  const _CursorNube(this.documento, this.firma);
}

/// Cursor opaco de la página de favoritos (último documento de la subcolección).
class _CursorFavoritos {
  final DocumentSnapshot<Map<String, dynamic>> documento;

  const _CursorFavoritos(this.documento);
}
