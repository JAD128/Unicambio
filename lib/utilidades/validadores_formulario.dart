// =============================================================================
// ARCHIVO: lib/utilidades/validadores_formulario.dart
// DESCRIPCIÓN: Reglas puras del formulario de publicación. Al estar separadas
//              de la UI se pueden probar sin construir widgets.
// =============================================================================

/// Longitudes permitidas para el título.
const int tituloMinimo = 5;
const int tituloMaximo = 80;

/// Longitudes permitidas para la descripción.
const int descripcionMinima = 10;
const int descripcionMaxima = 1000;

/// Precio máximo aceptado para una venta.
const double precioMaximo = 99999999;

/// Valida el nombre del artículo.
String? validarTitulo(String? valor) {
  final String texto = valor?.trim() ?? '';
  if (texto.isEmpty) return 'Escribe un título';
  if (texto.length < tituloMinimo) {
    return 'El título debe tener al menos $tituloMinimo caracteres';
  }
  if (texto.length > tituloMaximo) {
    return 'El título no puede superar $tituloMaximo caracteres';
  }
  return null;
}

/// Valida la descripción del artículo.
String? validarDescripcion(String? valor) {
  final String texto = valor?.trim() ?? '';
  if (texto.isEmpty) return 'Escribe una descripción';
  if (texto.length < descripcionMinima) {
    return 'La descripción debe tener al menos $descripcionMinima caracteres';
  }
  if (texto.length > descripcionMaxima) {
    return 'La descripción no puede superar $descripcionMaxima caracteres';
  }
  return null;
}

/// Valida el precio solo cuando el tipo de publicación es venta.
String? validarPrecio(String? valor, {required bool esVenta}) {
  if (!esVenta) return null;
  final String texto = valor?.trim() ?? '';
  if (texto.isEmpty) return null;

  final double? numero = double.tryParse(texto.replaceAll(',', '.'));
  if (numero == null || numero < 0) return 'Precio no válido';
  if (numero > precioMaximo) return 'El precio máximo es 99,999,999';
  return null;
}
