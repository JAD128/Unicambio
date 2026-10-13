// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_publicar.dart
// DESCRIPCIÓN: Formulario para publicar un artículo nuevo. Permite ingresar
//              nombre, descripción, precio, tipo de publicación (venta,
//              intercambio o regalo), categoría y una foto.
//
// NOTA (primer avance): es SOLO VISUAL. Los campos no validan ni guardan datos
// todavía; el botón "Publicar" no realiza ninguna acción.
// =============================================================================

import 'package:flutter/material.dart';

import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Pantalla del formulario de publicación.
class PantallaPublicar extends StatelessWidget {
  const PantallaPublicar({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar artículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ---------------------- Nombre del artículo -------------------
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nombre del artículo',
                hintText: 'Ej: Calculadora científica',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 14),

            // ------------------------- Descripción -----------------------
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Describe el estado y los detalles del artículo',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // --------------------- Tipo de publicación -------------------
            _TituloSeccion(texto: 'Tipo de publicación', tema: tema),
            const SizedBox(height: 8),
            SegmentedButton<TipoPublicacion>(
              segments: TipoPublicacion.values
                  .map(
                    (TipoPublicacion tipo) => ButtonSegment<TipoPublicacion>(
                      value: tipo,
                      label: Text(tipo.etiqueta),
                    ),
                  )
                  .toList(),
              selected: const <TipoPublicacion>{TipoPublicacion.venta},
              onSelectionChanged: (_) {},
              showSelectedIcon: false,
            ),
            const SizedBox(height: 20),

            // --------------------------- Precio --------------------------
            _TituloSeccion(texto: 'Precio', tema: tema),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 20),

            // -------------------------- Categoría ------------------------
            _TituloSeccion(texto: 'Categoría', tema: tema),
            const SizedBox(height: 8),
            DropdownButtonFormField<Categoria>(
              initialValue: Categoria.libros,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: Categoria.values
                  .map(
                    (Categoria categoria) => DropdownMenuItem<Categoria>(
                      value: categoria,
                      child: Text(categoria.etiqueta),
                    ),
                  )
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),

            // ---------------------------- Foto ---------------------------
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Agregar foto'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // -------------------------- Publicar -------------------------
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check),
              label: const Text('Publicar artículo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título pequeño que separa las secciones del formulario.
class _TituloSeccion extends StatelessWidget {
  final String texto;
  final ThemeData tema;

  const _TituloSeccion({required this.texto, required this.tema});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
