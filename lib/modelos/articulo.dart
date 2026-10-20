// =============================================================================
// ARCHIVO: lib/modelos/articulo.dart
// DESCRIPCIÓN: Define el modelo de datos "Articulo", que representa cada
//              publicación que un estudiante hace en UniCambio.
//
// IMPORTANTE (primer avance): este modelo SOLO describe la información que
// necesita la interfaz para dibujarse. Todavía no hay base de datos, ni inicio
// de sesión, ni operaciones para crear/editar/eliminar. Eso se agregará después.
// =============================================================================

import 'package:flutter/material.dart';

import 'categoria.dart';

/// Nombre del vendedor que se asigna a las publicaciones creadas en este
/// dispositivo. Es un marcador provisional: en el Avance 9 se reemplazará por
/// el nombre real del usuario autenticado.
const String vendedorPropio = 'Tú (estudiante)';

/// Tipos de publicación que ofrece UniCambio.
///
/// - [venta]: el artículo se ofrece por un precio en dinero.
/// - [intercambio]: el artículo se cambia por otro artículo.
/// - [regalo]: el artículo se entrega sin costo.
enum TipoPublicacion { venta, intercambio, regalo }

/// Extensión con los datos de PRESENTACIÓN de cada [TipoPublicacion].
/// Sirve para mostrar la etiqueta, el ícono y el color en la interfaz.
extension TipoPublicacionUI on TipoPublicacion {
  /// Texto legible que verá el usuario.
  String get etiqueta {
    switch (this) {
      case TipoPublicacion.venta:
        return 'Venta';
      case TipoPublicacion.intercambio:
        return 'Intercambio';
      case TipoPublicacion.regalo:
        return 'Regalo';
    }
  }

  /// Ícono representativo del tipo de publicación.
  IconData get icono {
    switch (this) {
      case TipoPublicacion.venta:
        return Icons.sell_outlined;
      case TipoPublicacion.intercambio:
        return Icons.swap_horiz_rounded;
      case TipoPublicacion.regalo:
        return Icons.card_giftcard_outlined;
    }
  }

  /// Color con el que se resalta cada tipo de publicación.
  Color get color {
    switch (this) {
      case TipoPublicacion.venta:
        return const Color(0xFF2E7D32); // verde
      case TipoPublicacion.intercambio:
        return const Color(0xFF1565C0); // azul
      case TipoPublicacion.regalo:
        return const Color(0xFFAD1457); // rosa
    }
  }
}

/// Representa un artículo publicado por un estudiante.
///
/// La clase es "inmutable" (`final` en todos sus campos) porque en este avance
/// solo mostramos información en pantalla; aún no se modifica desde código.
class Articulo {
  /// Identificador único del artículo (en el futuro vendrá de la base de datos).
  final String id;

  /// Nombre del artículo que se muestra en la tarjeta.
  final String titulo;

  /// Descripción larga que se muestra en la pantalla de detalle.
  final String descripcion;

  /// Precio en pesos. Es `0` cuando el artículo es un regalo o a convenir.
  final double precio;

  /// Categoría a la que pertenece el artículo.
  final Categoria categoria;

  /// Tipo de publicación: venta, intercambio o regalo.
  final TipoPublicacion tipo;

  /// Nombre del estudiante que publicó el artículo.
  final String vendedor;

  /// Indica si el artículo está marcado como favorito (dato de ejemplo).
  final bool esFavorito;

  /// Constructor constante: permite crear artículos de ejemplo sin costo extra.
  const Articulo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.tipo,
    required this.vendedor,
    this.esFavorito = false,
  });

  /// Crea una copia del artículo cambiando solo los campos que se indiquen.
  ///
  /// Es útil para actualizar un artículo sin modificar el original, por ejemplo
  /// al marcar/desmarcar favorito:
  /// `articulo.copyWith(esFavorito: !articulo.esFavorito)`.
  Articulo copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    double? precio,
    Categoria? categoria,
    TipoPublicacion? tipo,
    String? vendedor,
    bool? esFavorito,
  }) {
    return Articulo(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      categoria: categoria ?? this.categoria,
      tipo: tipo ?? this.tipo,
      vendedor: vendedor ?? this.vendedor,
      esFavorito: esFavorito ?? this.esFavorito,
    );
  }

  /// Convierte el artículo en un `Map` para guardarlo en SQLite (sqflite).
  ///
  /// sqflite no entiende objetos Dart ni `enum`, así que:
  /// - Los enums (`categoria`, `tipo`) se guardan como texto con `.name`.
  /// - Los booleanos no existen en SQLite; `esFavorito` se guarda como 0 o 1.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
      'categoria': categoria.name,
      'tipo': tipo.name,
      'vendedor': vendedor,
      'esFavorito': esFavorito ? 1 : 0,
    };
  }

  /// Construye un [Articulo] a partir de una fila de la base de datos.
  ///
  /// Es la operación inversa de [toMap]: convierte los textos de los enums de
  /// vuelta a sus valores y el entero 0/1 de vuelta a un `bool`.
  factory Articulo.fromMap(Map<String, Object?> map) {
    return Articulo(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      // SQLite puede devolver `int` o `double` para un campo REAL.
      precio: (map['precio'] as num).toDouble(),
      categoria: Categoria.values.byName(map['categoria'] as String),
      tipo: TipoPublicacion.values.byName(map['tipo'] as String),
      vendedor: map['vendedor'] as String,
      esFavorito: (map['esFavorito'] as int) == 1,
    );
  }

  /// Devuelve el texto de precio listo para mostrar en pantalla.
  ///
  /// Reglas de presentación (solo visuales):
  /// - Si es un REGALO, se muestra "Gratis".
  /// - Si no tiene precio (0) y no es regalo, se muestra "A convenir".
  /// - En cualquier otro caso, se muestra el precio con el símbolo "$".
  String get precioTexto {
    if (tipo == TipoPublicacion.regalo) {
      return 'Gratis';
    }
    if (precio <= 0) {
      return 'A convenir';
    }
    return '\$ ${precio.toStringAsFixed(0)}';
  }
}
