// =============================================================================
// ARCHIVO: lib/widgets/chip_categoria.dart
// DESCRIPCIÓN: "Chip" (etiqueta seleccionable) que representa una categoría.
//
// Se usa en la fila de filtros de la pantalla de Inicio.
// NOTA (primer avance): es SOLO VISUAL. Al tocarlo aún no filtra artículos.
// =============================================================================

import 'package:flutter/material.dart';

import '../modelos/categoria.dart';

/// Etiqueta seleccionable para una [Categoria].
class ChipCategoria extends StatelessWidget {
  /// Categoría que representa este chip (o `null` para el chip "Todos").
  final Categoria? categoria;

  /// Indica si el chip se muestra seleccionado (resaltado).
  final bool seleccionada;

  const ChipCategoria({
    super.key,
    this.categoria,
    this.seleccionada = false,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay categoría, es el chip especial "Todos".
    final String texto = categoria?.etiqueta ?? 'Todos';
    final IconData icono = categoria?.icono ?? Icons.grid_view_rounded;

    return Padding(
      // Separación entre un chip y el siguiente.
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        avatar: Icon(icono, size: 18),
        selected: seleccionada,
        // Sin acción por ahora: el filtrado se agregará en otra etapa.
        onSelected: (_) {},
      ),
    );
  }
}
