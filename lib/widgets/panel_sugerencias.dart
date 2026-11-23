// =============================================================================
// ARCHIVO: lib/widgets/panel_sugerencias.dart
// DESCRIPCIÓN: Panel que muestra lo que ML Kit detectó en la foto y permite
//              aplicar cada sugerencia por separado.
//
// Es "tonto": no analiza nada ni modifica el formulario. Solo avisa con sus
// callbacks cuando el usuario toca "Usar", "Reemplazar" o "Descartar". Nada se
// aplica automáticamente.
// =============================================================================

import 'package:flutter/material.dart';

import '../modelos/categoria.dart';
import '../modelos/vision.dart';

/// Panel de sugerencias de categoría, título, descripción y texto OCR.
class PanelSugerencias extends StatelessWidget {
  /// Sugerencias calculadas a partir de la foto.
  final SugerenciasPublicacion sugerencias;

  /// Descripción generada con el tipo y la categoría actuales del formulario.
  final String descripcion;

  /// Texto actual del campo de título.
  final String tituloActual;

  /// Texto actual del campo de descripción.
  final String descripcionActual;

  /// Categoría seleccionada actualmente en el formulario.
  final Categoria categoriaActual;

  /// Se llama al tocar "Usar"/"Reemplazar" en la categoría.
  final ValueChanged<Categoria> alAplicarCategoria;

  /// Se llama al tocar "Usar"/"Reemplazar" en el título.
  final ValueChanged<String> alAplicarTitulo;

  /// Se llama al tocar "Usar"/"Reemplazar" en la descripción.
  final ValueChanged<String> alAplicarDescripcion;

  /// Se llama al tocar "Descartar".
  final VoidCallback alDescartar;

  const PanelSugerencias({
    super.key,
    required this.sugerencias,
    required this.descripcion,
    required this.tituloActual,
    required this.descripcionActual,
    required this.categoriaActual,
    required this.alAplicarCategoria,
    required this.alAplicarTitulo,
    required this.alAplicarDescripcion,
    required this.alDescartar,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final Categoria? categoria = sugerencias.categoria;
    final String? titulo = sugerencias.titulo;
    final String descripcionSugerida = descripcion.trim();
    final List<String> lineas = sugerencias.lineasTexto;

    final bool mostrarCategoria =
        categoria != null && categoria != categoriaActual;
    final bool mostrarTitulo =
        titulo != null &&
        titulo.trim().isNotEmpty &&
        titulo.trim() != tituloActual.trim();
    final bool mostrarDescripcion =
        descripcionSugerida.isNotEmpty &&
        descripcionSugerida != descripcionActual.trim();

    if (!mostrarCategoria &&
        !mostrarTitulo &&
        !mostrarDescripcion &&
        lineas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.auto_awesome, color: tema.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sugerencias de la foto',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('sugerencia-descartar'),
                  onPressed: alDescartar,
                  child: const Text('Descartar'),
                ),
              ],
            ),
            Text(
              'Aplica solo lo que te sirva; nada se cambia solo.',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (mostrarCategoria)
              _FilaSugerencia(
                etiqueta: 'Categoría',
                valor: categoria.etiqueta,
                icono: categoria.icono,
                textoBoton: 'Usar',
                claveBoton: const Key('sugerencia-categoria-usar'),
                alAplicar: () => alAplicarCategoria(categoria),
              ),
            if (mostrarTitulo)
              _FilaSugerencia(
                etiqueta: 'Título',
                valor: titulo.trim(),
                icono: Icons.title,
                textoBoton: tituloActual.trim().isEmpty ? 'Usar' : 'Reemplazar',
                claveBoton: const Key('sugerencia-titulo-usar'),
                alAplicar: () => alAplicarTitulo(titulo.trim()),
              ),
            if (mostrarDescripcion)
              _FilaSugerencia(
                etiqueta: 'Descripción',
                valor: descripcionSugerida,
                icono: Icons.description_outlined,
                textoBoton: descripcionActual.trim().isEmpty
                    ? 'Usar'
                    : 'Reemplazar',
                claveBoton: const Key('sugerencia-descripcion-usar'),
                alAplicar: () => alAplicarDescripcion(descripcionSugerida),
              ),
            if (lineas.isNotEmpty)
              _TextoDetectado(
                lineas: lineas,
                tituloActual: tituloActual,
                alUsarLinea: alAplicarTitulo,
              ),
          ],
        ),
      ),
    );
  }
}

/// Una fila con etiqueta, valor sugerido y botón para aplicarlo.
class _FilaSugerencia extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData icono;
  final String textoBoton;
  final Key claveBoton;
  final VoidCallback alAplicar;

  const _FilaSugerencia({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.textoBoton,
    required this.claveBoton,
    required this.alAplicar,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icono, size: 20, color: tema.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  etiqueta,
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  valor,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: claveBoton,
            onPressed: alAplicar,
            child: Text(textoBoton),
          ),
        ],
      ),
    );
  }
}

/// Desplegable con las líneas de texto que detectó el OCR.
class _TextoDetectado extends StatelessWidget {
  final List<String> lineas;
  final String tituloActual;
  final ValueChanged<String> alUsarLinea;

  const _TextoDetectado({
    required this.lineas,
    required this.tituloActual,
    required this.alUsarLinea,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Theme(
      data: tema.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        leading: const Icon(Icons.text_fields, size: 20),
        title: Text(
          'Texto detectado (${lineas.length})',
          style: tema.textTheme.bodyMedium,
        ),
        children: <Widget>[
          for (int i = 0; i < lineas.length; i++)
            ListTile(
              key: Key('sugerencia-linea-$i'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                lineas[i],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: lineas[i].trim() == tituloActual.trim()
                  ? Icon(
                      Icons.check_circle,
                      size: 18,
                      color: tema.colorScheme.primary,
                    )
                  : TextButton(
                      onPressed: () => alUsarLinea(lineas[i]),
                      child: const Text('Usar'),
                    ),
            ),
        ],
      ),
    );
  }
}
