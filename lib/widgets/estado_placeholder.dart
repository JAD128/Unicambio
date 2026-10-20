// =============================================================================
// ARCHIVO: lib/widgets/estado_placeholder.dart
// DESCRIPCIÓN: Widget reutilizable para mostrar un mensaje centrado con ícono.
//              Se usa en los estados "vacío" y "error" de las listas.
// =============================================================================

import 'package:flutter/material.dart';

/// Mensaje centrado con un ícono, un título y un subtítulo opcional.
class EstadoPlaceholder extends StatelessWidget {
  /// Ícono grande que se dibuja arriba del texto.
  final IconData icono;

  /// Título principal del mensaje.
  final String titulo;

  /// Texto secundario (opcional).
  final String? subtitulo;

  const EstadoPlaceholder({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icono, size: 64, color: tema.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium,
            ),
            if (subtitulo != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitulo!,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
