// =============================================================================
// ARCHIVO: lib/widgets/chip_categoria.dart
// DESCRIPCIÓN: "Chip" (etiqueta seleccionable) que representa una categoría.
//
// Se usa en la fila de filtros de la pantalla de Inicio. Es "tonto": solo
// avisa con [alSeleccionar]; quién filtra es el provider vía la pantalla.
// =============================================================================

import 'package:flutter/material.dart';

import '../modelos/categoria.dart';
import '../tema/adaptativo.dart';

/// Etiqueta seleccionable para una [Categoria].
class ChipCategoria extends StatelessWidget {
  /// Categoría que representa este chip (o `null` para el chip "Todos").
  final Categoria? categoria;

  /// Indica si el chip se muestra seleccionado (resaltado).
  final bool seleccionada;

  /// Se llama cuando el usuario toca el chip.
  final VoidCallback? alSeleccionar;

  const ChipCategoria({
    super.key,
    this.categoria,
    this.seleccionada = false,
    this.alSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay categoría, es el chip especial "Todos".
    final String texto = categoria?.etiqueta ?? 'Todos';
    final IconData icono = categoria?.icono ?? Icons.grid_view_rounded;

    final Key clave = ValueKey<String>('chip-$texto');

    return Padding(
      // Separación entre un chip y el siguiente.
      padding: const EdgeInsets.only(right: 8),
      child: botonCristalIos(
        context: context,
        key: clave,
        onPressed: alSeleccionar,
        destacado: seleccionada,
        alternativa: () => ChoiceChip(
          key: clave,
          label: Text(texto),
          avatar: Icon(icono, size: 18),
          selected: seleccionada,
          onSelected: (_) => alSeleccionar?.call(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icono, size: 18),
            const SizedBox(width: 6),
            Text(texto),
          ],
        ),
      ),
    );
  }
}
