// =============================================================================
// ARCHIVO: test/almacenamiento_imagenes_test.dart
// DESCRIPCIÓN: Pruebas de la subida de fotos a Supabase Storage usando un
//              cliente HTTP falso (sin red y sin Firebase).
// =============================================================================

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:unicambio/datos/almacenamiento_imagenes.dart';

/// Bytes de una imagen simulada.
Uint8List bytesEjemplo() => Uint8List.fromList(<int>[1, 2, 3, 4]);

void main() {
  test('subir envía la foto y devuelve la URL pública', () async {
    late http.Request peticion;
    final MockClient cliente = MockClient((http.Request request) async {
      peticion = request;
      return http.Response('{"Key":"ok"}', 200);
    });
    final AlmacenamientoImagenes almacenamiento = AlmacenamientoImagenes(
      cliente: cliente,
      uidActual: () => 'uid123',
      url: 'https://proyecto.supabase.co/',
      clave: 'anon-key',
    );

    final String url = await almacenamiento.subir(
      articuloId: 'art1',
      bytes: bytesEjemplo(),
      nombreArchivo: 'foto.PNG',
      tipoContenido: 'image/png',
    );

    expect(peticion.method, 'POST');
    expect(peticion.url.host, 'proyecto.supabase.co');
    expect(
      peticion.url.path,
      startsWith('/storage/v1/object/articulos/uid123/art1/'),
    );
    expect(peticion.url.path, endsWith('.png'));
    expect(peticion.headers['authorization'], 'Bearer anon-key');
    expect(peticion.headers['apikey'], 'anon-key');
    expect(peticion.headers['content-type'], 'image/png');
    expect(peticion.bodyBytes, bytesEjemplo());
    expect(
      url,
      startsWith(
        'https://proyecto.supabase.co/storage/v1/object/public/articulos/uid123/art1/',
      ),
    );
    expect(url, endsWith('.png'));
  });

  test('subir sin configuración lanza StateError con instrucciones', () async {
    final AlmacenamientoImagenes almacenamiento = AlmacenamientoImagenes(
      cliente: MockClient((_) async => http.Response('', 200)),
      uidActual: () => 'uid123',
      url: '',
      clave: '',
    );

    expect(
      () => almacenamiento.subir(
        articuloId: 'art1',
        bytes: bytesEjemplo(),
        nombreArchivo: 'foto.jpg',
        tipoContenido: 'image/jpeg',
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'mensaje',
          contains('configurar Supabase'),
        ),
      ),
    );
  });

  test('un error HTTP lanza StateError con el código', () async {
    final AlmacenamientoImagenes almacenamiento = AlmacenamientoImagenes(
      cliente: MockClient(
        (_) async => http.Response('new row violates row-level security', 403),
      ),
      uidActual: () => 'uid123',
      url: 'https://proyecto.supabase.co',
      clave: 'anon-key',
    );

    expect(
      () => almacenamiento.subir(
        articuloId: 'art1',
        bytes: bytesEjemplo(),
        nombreArchivo: 'foto.jpg',
        tipoContenido: 'image/jpeg',
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'mensaje',
          contains('403'),
        ),
      ),
    );
  });

  test('eliminar borra el archivo indicado por su URL pública', () async {
    late http.Request peticion;
    final MockClient cliente = MockClient((http.Request request) async {
      peticion = request;
      return http.Response('', 200);
    });
    final AlmacenamientoImagenes almacenamiento = AlmacenamientoImagenes(
      cliente: cliente,
      uidActual: () => 'uid123',
      url: 'https://proyecto.supabase.co/',
      clave: 'anon-key',
    );

    await almacenamiento.eliminar(
      'https://proyecto.supabase.co/storage/v1/object/public/'
      'articulos/uid123/art1/foto.png',
    );

    expect(peticion.method, 'DELETE');
    expect(
      peticion.url.path,
      '/storage/v1/object/articulos/uid123/art1/foto.png',
    );
    expect(peticion.headers['authorization'], 'Bearer anon-key');
    expect(peticion.headers['apikey'], 'anon-key');
  });

  test('eliminar ignora enlaces que no son de este bucket', () async {
    bool seHizoPeticion = false;
    final MockClient cliente = MockClient((_) async {
      seHizoPeticion = true;
      return http.Response('', 200);
    });
    final AlmacenamientoImagenes almacenamiento = AlmacenamientoImagenes(
      cliente: cliente,
      uidActual: () => 'uid123',
      url: 'https://proyecto.supabase.co',
      clave: 'anon-key',
    );

    await almacenamiento.eliminar(
      'https://firebasestorage.googleapis.com/v0/b/otro/o/foto.png',
    );
    await almacenamiento.eliminar(null);

    expect(seHizoPeticion, isFalse);
  });
}
