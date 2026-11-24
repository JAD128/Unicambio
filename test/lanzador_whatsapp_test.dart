// =============================================================================
// ARCHIVO: test/lanzador_whatsapp_test.dart
// DESCRIPCIÓN: Pruebas de normalización y construcción de URLs de WhatsApp.
//              No abren la app externa.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/datos/lanzador_whatsapp.dart';

void main() {
  test('normalizarTelefonoColombiano acepta 10 y 12 dígitos', () {
    expect(normalizarTelefonoColombiano('300 123 4567'), '573001234567');
    expect(normalizarTelefonoColombiano('+57 311 222 33 44'), '573112223344');
  });

  test('normalizarTelefonoColombiano rechaza números inválidos', () {
    expect(normalizarTelefonoColombiano('123'), isNull);
    expect(normalizarTelefonoColombiano('2001234567'), isNull);
    expect(normalizarTelefonoColombiano(''), isNull);
  });

  test('las URIs usan wa.me y dejan el mensaje en el parámetro text', () {
    final Uri contacto = uriContactoWhatsapp(
      telefono: '573001234567',
      mensaje: 'Hola, ¿sigue disponible?',
    );
    final Uri compartir = uriCompartirWhatsapp('Mira este libro');

    expect(contacto.host, 'wa.me');
    expect(contacto.path, '/573001234567');
    expect(
      contacto.queryParameters['text'],
      'Hola, ¿sigue disponible?',
    );
    expect(compartir.path, '/');
    expect(compartir.queryParameters['text'], 'Mira este libro');
  });
}
