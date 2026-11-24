// =============================================================================
// ARCHIVO: lib/modelos/consulta_articulos.dart
// DESCRIPCIÓN: Describe qué artículos quiere ver la pantalla de Inicio:
//              texto, categoría, rango de precio, orden y tamaño de página.
//
// Es un modelo sin dependencias de Firebase ni de SQLite: el provider lo crea
// y cada repositorio decide cómo traducirlo a su consulta real.
// =============================================================================

import 'categoria.dart';

/// Criterios de ordenación disponibles para la lista de artículos.
enum OrdenArticulos { titulo, precioAsc, precioDesc }

/// Extensión con la presentación y el campo real de Firestore/SQLite.
extension OrdenArticulosDatos on OrdenArticulos {
  /// Texto que se muestra en el panel de filtros.
  String get etiqueta {
    switch (this) {
      case OrdenArticulos.titulo:
        return 'Título A-Z';
      case OrdenArticulos.precioAsc:
        return 'Precio: menor a mayor';
      case OrdenArticulos.precioDesc:
        return 'Precio: mayor a menor';
    }
  }

  /// Nombre del campo por el que se ordena en la base de datos.
  String get campo {
    switch (this) {
      case OrdenArticulos.titulo:
        return 'titulo';
      case OrdenArticulos.precioAsc:
      case OrdenArticulos.precioDesc:
        return 'precio';
    }
  }

  /// `true` cuando el orden es descendente.
  bool get descendente => this == OrdenArticulos.precioDesc;
}

/// Consulta de artículos con filtros y paginación.
class ConsultaArticulos {
  /// Texto a buscar en título y descripción (vacío = sin filtro).
  final String texto;

  /// Categoría seleccionada (`null` = todas).
  final Categoria? categoria;

  /// Precio mínimo inclusive (`null` = sin límite inferior).
  final double? precioMinimo;

  /// Precio máximo inclusive (`null` = sin límite superior).
  final double? precioMaximo;

  /// Orden elegido por el usuario.
  final OrdenArticulos orden;

  /// Autor de las publicaciones (`null` = cualquier usuario). Lo usa
  /// "Mis artículos" para no leer la colección completa en el provider.
  final String? uidAutor;

  /// Cantidad de artículos por página (`null` = todos; lo usa `buscar`).
  final int? limite;

  /// Constructor de la consulta.
  const ConsultaArticulos({
    this.texto = '',
    this.categoria,
    this.precioMinimo,
    this.precioMaximo,
    this.orden = OrdenArticulos.titulo,
    this.uidAutor,
    this.limite = 12,
  });

  /// `true` si hay algún filtro de precio activo.
  bool get tienePrecio => precioMinimo != null || precioMaximo != null;

  /// Firestore exige ordenar por `precio` cuando se usa un filtro de rango.
  ///
  /// Si el usuario pidió "Título A-Z" con rango de precio, se cambia a
  /// "Precio: menor a mayor" para que la consulta sea válida.
  OrdenArticulos get ordenEfectivo {
    if (tienePrecio && orden == OrdenArticulos.titulo) {
      return OrdenArticulos.precioAsc;
    }
    return orden;
  }

  /// Firma estable del cursor: cambia si cambian los filtros o el orden.
  String get firma =>
      '${texto.trim().toLowerCase()}|${categoria?.name ?? '*'}|'
      '$precioMinimo|$precioMaximo|${ordenEfectivo.name}|${uidAutor ?? '*'}';
}
