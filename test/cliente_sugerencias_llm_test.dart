// =============================================================================
// ARCHIVO: test/cliente_sugerencias_llm_test.dart
// DESCRIPCIÓN: Pruebas del cliente HTTP del proxy sin red real.
// =============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:unicambio/datos/cliente_sugerencias_llm.dart';
import 'package:unicambio/modelos/articulo.dart';
import 'package:unicambio/modelos/categoria.dart';
import 'package:unicambio/modelos/sugerencia_llm.dart';
import 'package:unicambio/modelos/vision.dart';

Uint8List _bytes() => Uint8List.fromList(<int>[1, 2, 3, 4]);

String _respuesta() => jsonEncode(<String, dynamic>{
  'categoria': 'libros',
  'titulo': 'Calculadora científica',
  'descripcion': 'Calculadora científica en buen estado para tus clases.',
});

void main() {
  test('envía token, foto y contexto al Worker', () async {
    late http.Request peticion;
    final MockClient cliente = MockClient((http.Request request) async {
      peticion = request;
      return http.Response(_respuesta(), 200);
    });
    final ClienteSugerenciasLlm servicio = ClienteSugerenciasLlm(
      cliente: cliente,
      proveedorToken: () async => 'token123',
      urlBase: 'https://worker.test',
    );

    final SugerenciaLlm sugerencia = await servicio.sugerir(
      bytes: _bytes(),
      mimeType: 'image/png',
      tipo: TipoPublicacion.regalo,
      etiquetas: <EtiquetaImagen>[
        const EtiquetaImagen(etiqueta: 'book', confianza: 0.9),
      ],
      lineasTexto: <String>['CÁLCULO'],
    );

    final Map<String, dynamic> cuerpo =
        jsonDecode(peticion.body) as Map<String, dynamic>;
    expect(peticion.method, 'POST');
    expect(peticion.url.toString(), 'https://worker.test/sugerencias');
    expect(peticion.headers['authorization'], 'Bearer token123');
    expect(cuerpo['imagenBase64'], base64Encode(_bytes()));
    expect(cuerpo['mimeType'], 'image/png');
    expect(cuerpo['tipoPublicacion'], 'regalo');
    expect(cuerpo['etiquetas'], isA<List<dynamic>>());
    expect(cuerpo['lineasTexto'], <dynamic>['CÁLCULO']);
    expect(sugerencia.categoria, Categoria.libros);
    expect(sugerencia.titulo, 'Calculadora científica');
    expect(sugerencia.tipoDescripcion, TipoPublicacion.regalo);
  });

  test('sin ID token lanza StateError', () async {
    final ClienteSugerenciasLlm servicio = ClienteSugerenciasLlm(
      cliente: MockClient((_) async => http.Response(_respuesta(), 200)),
      proveedorToken: () async => null,
    );

    expect(
      () => servicio.sugerir(
        bytes: _bytes(),
        mimeType: 'image/jpeg',
        tipo: TipoPublicacion.venta,
        etiquetas: const <EtiquetaImagen>[],
        lineasTexto: const <String>[],
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'mensaje',
          contains('Inicia sesión'),
        ),
      ),
    );
  });

  test('un error del Worker se convierte en StateError', () async {
    final ClienteSugerenciasLlm servicio = ClienteSugerenciasLlm(
      cliente: MockClient(
        (_) async => http.Response('{"error":"rate_limit"}', 429),
      ),
      proveedorToken: () async => 'token123',
    );

    expect(
      () => servicio.sugerir(
        bytes: _bytes(),
        mimeType: 'image/jpeg',
        tipo: TipoPublicacion.venta,
        etiquetas: const <EtiquetaImagen>[],
        lineasTexto: const <String>[],
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'mensaje',
          contains('429'),
        ),
      ),
    );
  });
}
