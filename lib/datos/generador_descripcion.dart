// =============================================================================
// ARCHIVO: lib/datos/generador_descripcion.dart
// DESCRIPCIÓN: Genera una descripción para la publicación a partir del título,
//              la categoría y el tipo (venta, intercambio o regalo).
//
// Hoy se usan plantillas locales: son gratis, funcionan sin internet y no
// inventan estado, precio ni ubicación. La interfaz [GeneradorDescripcion]
// permite cambiar estas plantillas por un LLM en el futuro sin tocar la
// pantalla de publicación.
// =============================================================================

import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Contrato de cualquier generador de descripciones.
abstract class GeneradorDescripcion {
  /// Devuelve la descripción sugerida para el formulario.
  String generar({
    required String? titulo,
    required Categoria categoria,
    required TipoPublicacion tipo,
  });
}

/// Generador local basado en plantillas por tipo y categoría.
class PlantillaGeneradorDescripcion implements GeneradorDescripcion {
  const PlantillaGeneradorDescripcion();

  @override
  String generar({
    required String? titulo,
    required Categoria categoria,
    required TipoPublicacion tipo,
  }) {
    final String nombre = _nombre(titulo, categoria);
    final String beneficio = _beneficio(categoria);
    final int variante = _variante(nombre);

    switch (tipo) {
      case TipoPublicacion.venta:
        return variante == 0
            ? 'Vendo $nombre, una opción práctica para $beneficio. '
                  'Si te interesa, escríbeme y coordinamos la entrega.'
            : 'Pongo a la venta $nombre, ideal para $beneficio. '
                  'Escríbeme y con gusto coordinamos la entrega.';
      case TipoPublicacion.intercambio:
        return variante == 0
            ? 'Cambio $nombre por algo que me sirva. '
                  'Si te interesa, escríbeme y vemos qué podemos acordar.'
            : 'Busco intercambiar $nombre por otro artículo útil. '
                  'Cuéntame qué tienes y coordinamos.';
      case TipoPublicacion.regalo:
        return variante == 0
            ? 'Regalo $nombre a quien le pueda servir. '
                  'Escríbeme si te interesa y coordinamos la entrega.'
            : 'Doy $nombre en regalo; solo busca un nuevo dueño que lo '
                  'aproveche. Escríbeme para coordinarlo.';
    }
  }

  /// Nombre natural para empezar la descripción.
  String _nombre(String? titulo, Categoria categoria) {
    final String limpio = (titulo ?? '').trim();
    if (limpio.isNotEmpty) return limpio;

    switch (categoria) {
      case Categoria.libros:
        return 'este libro';
      case Categoria.apuntes:
        return 'estos apuntes';
      case Categoria.tecnologia:
        return 'este artículo de tecnología';
      case Categoria.ropa:
        return 'esta prenda';
      case Categoria.hogar:
        return 'este artículo de hogar';
      case Categoria.deportes:
        return 'este artículo deportivo';
      case Categoria.otros:
        return 'este artículo';
    }
  }

  /// Beneficio suave según la categoría (sin afirmar estado ni calidad).
  String _beneficio(Categoria categoria) {
    switch (categoria) {
      case Categoria.libros:
        return 'tus clases y lecturas';
      case Categoria.apuntes:
        return 'repasar tus materias';
      case Categoria.tecnologia:
        return 'tus clases y trabajos';
      case Categoria.ropa:
        return 'renovar tu look';
      case Categoria.hogar:
        return 'tu cuarto o apartamento';
      case Categoria.deportes:
        return 'mantenerte activo';
      case Categoria.otros:
        return 'lo que necesitas';
    }
  }

  /// Elige una variante estable para no repetir siempre la misma frase.
  int _variante(String nombre) {
    final int suma = nombre.codeUnits.fold<int>(
      0,
      (int total, int codigo) => total + codigo,
    );
    return suma % 2;
  }
}
