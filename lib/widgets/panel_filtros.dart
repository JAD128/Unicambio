// =============================================================================
// ARCHIVO: lib/widgets/panel_filtros.dart
// DESCRIPCIÓN: Bottom sheet con el orden y el rango de precio de la búsqueda.
//
// El panel no habla con el repositorio: solo reúne los valores y se los devuelve
// a la pantalla de Inicio, que es la que llama al provider.
// =============================================================================

import 'package:flutter/material.dart';

import '../modelos/consulta_articulos.dart';

/// Valores que devuelve el panel cuando el usuario toca "Aplicar".
class ValoresFiltros {
  /// Orden elegido para los resultados.
  final OrdenArticulos orden;

  /// Precio mínimo (null si el campo quedó vacío).
  final double? precioMinimo;

  /// Precio máximo (null si el campo quedó vacío).
  final double? precioMaximo;

  /// Constructor de los valores del panel.
  const ValoresFiltros({
    required this.orden,
    this.precioMinimo,
    this.precioMaximo,
  });
}

/// Panel modal para ordenar y filtrar por precio.
class PanelFiltros extends StatefulWidget {
  /// Orden actual, para marcar el segmento activo.
  final OrdenArticulos orden;

  /// Precio mínimo actual.
  final double? precioMinimo;

  /// Precio máximo actual.
  final double? precioMaximo;

  /// Se llama al tocar "Aplicar".
  final ValueChanged<ValoresFiltros> alAplicar;

  /// Se llama al tocar "Limpiar" (el panel se cierra solo).
  final VoidCallback alLimpiar;

  /// Constructor del panel de filtros.
  const PanelFiltros({
    super.key,
    required this.orden,
    this.precioMinimo,
    this.precioMaximo,
    required this.alAplicar,
    required this.alLimpiar,
  });

  @override
  State<PanelFiltros> createState() => _PanelFiltrosState();
}

class _PanelFiltrosState extends State<PanelFiltros> {
  late final TextEditingController _controlMinimo;
  late final TextEditingController _controlMaximo;
  late OrdenArticulos _orden;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controlMinimo = TextEditingController(
      text: widget.precioMinimo?.toStringAsFixed(0) ?? '',
    );
    _controlMaximo = TextEditingController(
      text: widget.precioMaximo?.toStringAsFixed(0) ?? '',
    );
    _orden = widget.orden;
  }

  @override
  void dispose() {
    _controlMinimo.dispose();
    _controlMaximo.dispose();
    super.dispose();
  }

  /// Acepta punto o coma decimal y devuelve null si el campo está vacío.
  double? _parsear(String texto) {
    final String limpio = texto.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;
    return double.tryParse(limpio);
  }

  void _aplicar() {
    final double? minimo = _parsear(_controlMinimo.text);
    final double? maximo = _parsear(_controlMaximo.text);
    if (minimo != null && maximo != null && minimo > maximo) {
      setState(() {
        _error = 'El precio mínimo no puede ser mayor que el máximo.';
      });
      return;
    }
    final ValoresFiltros valores = ValoresFiltros(
      orden: _orden,
      precioMinimo: minimo,
      precioMaximo: maximo,
    );
    FocusScope.of(context).unfocus();
    widget.alAplicar(valores);
    Navigator.of(context).pop(valores);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Wrap(
          runSpacing: 16,
          children: <Widget>[
            Text(
              'Filtrar resultados',
              style: tema.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Ordenar por', style: tema.textTheme.labelLarge),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<OrdenArticulos>(
                key: const Key('filtro-orden'),
                segments: OrdenArticulos.values
                    .map(
                      (OrdenArticulos orden) => ButtonSegment<OrdenArticulos>(
                        value: orden,
                        label: Text(orden.etiqueta.replaceFirst('Precio: ', '')),
                        icon: Icon(
                          orden == OrdenArticulos.titulo
                              ? Icons.sort_by_alpha
                              : Icons.swap_vert,
                        ),
                      ),
                    )
                    .toList(),
                selected: <OrdenArticulos>{_orden},
                onSelectionChanged: (Set<OrdenArticulos> seleccion) {
                  if (seleccion.isEmpty) return;
                  setState(() => _orden = seleccion.first);
                },
              ),
            ),
            Text('Rango de precio', style: tema.textTheme.labelLarge),
            TextField(
              key: const Key('filtro-precio-min'),
              controller: _controlMinimo,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio mínimo',
                prefixText: '\$ ',
              ),
            ),
            TextField(
              key: const Key('filtro-precio-max'),
              controller: _controlMaximo,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Precio máximo',
                prefixText: '\$ ',
                errorText: _error,
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('filtro-limpiar'),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      widget.alLimpiar();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('filtro-aplicar'),
                    onPressed: _aplicar,
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
