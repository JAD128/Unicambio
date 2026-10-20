// =============================================================================
// ARCHIVO: lib/widgets/campo_busqueda.dart
// DESCRIPCIÓN: Campo de texto para buscar artículos por nombre.
//
// Es "tonto" (stateless): solo avisa con [alCambiar] lo que escribe el usuario.
// Quien decide qué hacer con el texto es la pantalla que lo usa (Inicio), que
// se lo pasa al provider.
// =============================================================================

import 'package:flutter/material.dart';

/// Barra de búsqueda reutilizable que aparece en la pantalla de Inicio.
class CampoBusqueda extends StatelessWidget {
  /// Se llama con el texto escrito en cada cambio del campo.
  final ValueChanged<String>? alCambiar;

  /// Texto que aparece al abrir la pantalla (el que quedó en el provider).
  final String textoInicial;

  const CampoBusqueda({
    super.key,
    this.alCambiar,
    this.textoInicial = '',
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: textoInicial,
      onChanged: alCambiar,
      decoration: InputDecoration(
        hintText: 'Buscar artículos...',
        prefixIcon: const Icon(Icons.search),
        // Ícono de filtros a la derecha (decorativo por ahora).
        suffixIcon: const Icon(Icons.tune),
        // El tema ya define el relleno, bordes y colores; no repetimos aquí.
      ),
    );
  }
}
