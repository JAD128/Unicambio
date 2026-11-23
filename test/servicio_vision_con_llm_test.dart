// =============================================================================
// ARCHIVO: test/servicio_vision_con_llm_test.dart
// DESCRIPCIÓN: Pruebas del decorador ML Kit + proxy con cliente falso.
// =============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:unicambio/datos/cliente_sugerencias_llm.dart';
import 'package:unicambio/datos/servicio_vision.dart';
import 'package:unicambio/datos/servicio_vision_con_llm.dart';
import 'package:unicambio/modelos/articulo.dart';
import 'package:unicambio/modelos/vision.dart';

Uint8List _bytes() => Uint8List.fromList(<int>[9, 8, 7]);

String _respuesta() => jsonEncode(<String, dynamic>{
  'categoria': 'tecnologia',
  'titulo': 'Calculadora científica',
  'descripcion': 'Calculadora científica útil para tus clases y trabajos.',
});

class _VisionFalsa implements ServicioVision {
  @override
  Future<ResultadoVision> analizar(String ruta) async {
    return const ResultadoVision(
      etiquetas: <EtiquetaImagen>[
        EtiquetaImagen(etiqueta: 'calculator', confianza: 0.9),
      ],
      lineasTexto: <String>['CÁLCULO'],
    );
  }

  @override
  Future<void> cerrar() async {}
}

void main() {
  test('agrega la sugerencia y reutiliza la caché en la misma foto', () async {
    int llamadas = 0;
    final ClienteSugerenciasLlm cliente = ClienteSugerenciasLlm(
      cliente: MockClient((http.Request request) async {
        llamadas++;
        return http.Response(_respuesta(), 200);
      }),
      proveedorToken: () async => 'token123',
    );
    final ServicioVisionConLlm servicio = ServicioVisionConLlm(
      vision: _VisionFalsa(),
      cliente: cliente,
      tipoActual: () => TipoPublicacion.venta,
      lector: (String ruta) async => _bytes(),
    );

    final ResultadoVision primera = await servicio.analizar('foto.jpg');
    final ResultadoVision segunda = await servicio.analizar('foto.jpg');

    expect(llamadas, 1);
    expect(primera.etiquetas, isNotEmpty);
    expect(primera.lineasTexto, <String>['CÁLCULO']);
    expect(primera.sugerencia?.titulo, 'Calculadora científica');
    expect(segunda.sugerencia?.titulo, 'Calculadora científica');
    await servicio.cerrar();
  });

  test('si el proxy falla, conserva el resultado de ML Kit', () async {
    final ClienteSugerenciasLlm cliente = ClienteSugerenciasLlm(
      cliente: MockClient((_) async => throw StateError('sin red')),
      proveedorToken: () async => 'token123',
    );
    final ServicioVisionConLlm servicio = ServicioVisionConLlm(
      vision: _VisionFalsa(),
      cliente: cliente,
      tipoActual: () => TipoPublicacion.venta,
      lector: (String ruta) async => _bytes(),
    );

    final ResultadoVision resultado = await servicio.analizar('foto.png');

    expect(resultado.sugerencia, isNull);
    expect(resultado.etiquetas, isNotEmpty);
    expect(resultado.lineasTexto, <String>['CÁLCULO']);
  });
}
