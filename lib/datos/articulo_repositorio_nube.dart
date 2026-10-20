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
    // Firestore no busca substrings en texto: filtramos en memoria.
    final List<Articulo> todos = await obtenerTodos();
    final String consulta = texto.trim().toLowerCase();
    return todos.where((Articulo articulo) {
      final coincideTexto =
          consulta.isEmpty || articulo.titulo.toLowerCase().contains(consulta);
      final coincideCategoria =
          categoria == null || articulo.categoria == categoria;
      return coincideTexto && coincideCategoria;
    }).toList();
  }

  @override
  Future<List<Articulo>> filtrarPorCategoria(Categoria categoria) async {
    final QuerySnapshot<Map<String, dynamic>> datos = await _articulos
        .where('categoria', isEqualTo: categoria.name)
        .orderBy('titulo')
        .get();
    return _marcarFavoritos(_desdeSnapshots(datos));
  }

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
    );
  }

  /// Convierte el modelo en el mapa que se guarda en Firestore.
  ///
  /// No guardamos `esFavorito` (es por usuario) ni el id (lo asigna Firestore).
  Map<String, Object> _aMapa(Articulo articulo) => <String, Object>{
        'titulo': articulo.titulo,
        'descripcion': articulo.descripcion,
        'precio': articulo.precio,
        'categoria': articulo.categoria.name,
        'tipo': articulo.tipo.name,
        'vendedor': articulo.vendedor,
        'uidAutor': _auth.currentUser?.uid ?? '',
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
