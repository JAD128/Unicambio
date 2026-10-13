// =============================================================================
// ARCHIVO: lib/modelos/categoria.dart
// DESCRIPCIÓN: Define las categorías con las que se pueden clasificar los
//              artículos dentro de UniCambio.
//
// Es un archivo "de modelo": solo describe DATOS, no contiene pantallas ni
// lógica de la aplicación. En este primer avance únicamente sirve para que la
// interfaz muestre etiquetas, íconos y colores de cada categoría.
// =============================================================================

import 'package:flutter/material.dart';

/// Categorías disponibles para clasificar un artículo.
///
/// Se usa un `enum` porque las categorías son una lista fija y conocida.
/// Cada valor representa una categoría distinta del marketplace.
enum Categoria {
  libros,
  apuntes,
  tecnologia,
  ropa,
  hogar,
  deportes,
  otros,
}

/// Extensión con los datos de PRESENTACIÓN de cada [Categoria].
///
/// Una "extensión" permite agregar propiedades (como [etiqueta] o [icono]) a un
/// enum ya existente sin tener que modificar su definición.
extension CategoriaUI on Categoria {
  /// Texto legible que se muestra al usuario en la interfaz.
  String get etiqueta {
    switch (this) {
      case Categoria.libros:
        return 'Libros';
      case Categoria.apuntes:
        return 'Apuntes';
      case Categoria.tecnologia:
        return 'Tecnología';
      case Categoria.ropa:
        return 'Ropa';
      case Categoria.hogar:
        return 'Hogar';
      case Categoria.deportes:
        return 'Deportes';
      case Categoria.otros:
        return 'Otros';
    }
  }

  /// Ícono representativo que se dibuja en las tarjetas y en los filtros.
  IconData get icono {
    switch (this) {
      case Categoria.libros:
        return Icons.menu_book_outlined;
      case Categoria.apuntes:
        return Icons.edit_note_outlined;
      case Categoria.tecnologia:
        return Icons.devices_outlined;
      case Categoria.ropa:
        return Icons.checkroom_outlined;
      case Categoria.hogar:
        return Icons.chair_outlined;
      case Categoria.deportes:
        return Icons.sports_soccer_outlined;
      case Categoria.otros:
        return Icons.category_outlined;
    }
  }
}
