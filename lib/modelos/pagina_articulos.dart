// =============================================================================
// ARCHIVO: lib/modelos/pagina_articulos.dart
// DESCRIPCIÓN: Resultado de una búsqueda paginada.
//
// `cursor` es opaco: el provider solo lo guarda y se lo devuelve al repositorio
// en "Cargar más". Así la UI no sabe si es un offset de SQLite o un documento de
// Firestore.
// =============================================================================

import 'articulo.dart';

/// Una página de artículos y la información para pedir la siguiente.
class PaginaArticulos {
  /// Artículos de esta página.
  final List<Articulo> articulos;

  /// Marcador opaco para continuar; `null` si no hay más páginas.
  final Object? cursor;

  /// `true` si todavía quedan artículos por cargar.
  final bool hayMas;

  /// Constructor de la página.
  const PaginaArticulos({
    required this.articulos,
    this.cursor,
    this.hayMas = false,
  });
}
