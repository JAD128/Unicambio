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

  /// Se llama al tocar el ícono de filtros.
  final VoidCallback? alFiltrar;

  const CampoBusqueda({
    super.key,
    this.alCambiar,
    this.textoInicial = '',
    this.alFiltrar,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: textoInicial,
      onChanged: alCambiar,
      decoration: InputDecoration(
        hintText: 'Buscar artículos...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: alFiltrar == null
            ? const Icon(Icons.tune)
            : IconButton(
                key: const Key('buscar-filtros'),
                icon: const Icon(Icons.tune),
                tooltip: 'Filtros y orden',
                onPressed: alFiltrar,
              ),
        // El tema ya define el relleno, bordes y colores; no repetimos aquí.
      ),
    );
  }
}
