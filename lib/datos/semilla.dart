// =============================================================================
// ARCHIVO: lib/datos/semilla.dart
// DESCRIPCIÓN: Inserta los artículos de ejemplo en la base de datos la PRIMERA
//              vez que se abre la aplicación.
//
// ¿Por qué? Porque una base de datos nueva está vacía. Para que el prototipo
// muestre contenido desde el inicio, "sembramos" los datos de ejemplo una sola
// vez. En las siguientes ejecuciones ya habrá datos y no se vuelve a sembrar.
// =============================================================================

import '../modelos/articulo.dart';
import 'articulo_repositorio.dart';
import 'articulos_ejemplo.dart';

/// Si la base de datos está vacía, inserta los artículos de ejemplo.
///
/// Se llama desde `main.dart` antes de mostrar la interfaz.
Future<void> sembrarDatosDeEjemplo(ArticuloRepositorio repositorio) async {
  final List<Articulo> existentes = await repositorio.obtenerTodos();

  // Si ya hay artículos (por ejemplo, el usuario ya creó los suyos), no hacemos nada.
  if (existentes.isNotEmpty) {
    return;
  }

  // Insertamos uno por uno los artículos de ejemplo.
  for (final Articulo articulo in articulosEjemplo) {
    await repositorio.insertar(articulo);
  }
}
