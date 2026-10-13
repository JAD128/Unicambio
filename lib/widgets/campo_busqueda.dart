// =============================================================================
// ARCHIVO: lib/widgets/campo_busqueda.dart
// DESCRIPCIÓN: Campo de texto para buscar artículos por nombre.
//
// NOTA (primer avance): es SOLO VISUAL. Todavía no filtra resultados; en la
// siguiente etapa se conectará con la lógica de búsqueda.
// =============================================================================

import 'package:flutter/material.dart';

/// Barra de búsqueda reutilizable que aparece en la pantalla de Inicio.
class CampoBusqueda extends StatelessWidget {
  const CampoBusqueda({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      // Sin lógica por ahora: la búsqueda real se implementará más adelante.
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Buscar artículos...',
        prefixIcon: const Icon(Icons.search),
        // Ícono de filtros a la derecha (también visual por ahora).
        suffixIcon: const Icon(Icons.tune),
        // El tema ya define el relleno, bordes y colores; no repetimos aquí.
      ),
    );
  }
}
