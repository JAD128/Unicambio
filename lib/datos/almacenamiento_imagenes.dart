// =============================================================================
// ARCHIVO: lib/datos/almacenamiento_imagenes.dart
// DESCRIPCIÓN: Sube las fotos de las publicaciones a Supabase Storage.
//
// ¿Por qué Supabase y no Firebase Storage? Cloud Storage for Firebase exige el
// plan Blaze (tarjeta); Supabase tiene un nivel gratis sin tarjeta. Se usa solo
// para los archivos: los artículos y favoritos siguen en Firestore y la URL de
// la foto se guarda en `Articulo.imagenUrl`.
//
// Se usa la API REST con el paquete `http` (no hace falta inicializar el SDK de
// Supabase ni crear cuentas allí: las fotos van a un bucket público).
// =============================================================================

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config_supabase.dart';

/// Sube fotos a Supabase Storage y devuelve su URL pública.
class AlmacenamientoImagenes {
  AlmacenamientoImagenes({
    http.Client? cliente,
    String? Function()? uidActual,
    String? url,
    String? clave,
  })  : _cliente = cliente ?? http.Client(),
        _uidActual = uidActual ?? _uidDeFirebase,
        _url = url ?? supabaseUrl,
        _clave = clave ?? supabaseAnonKey;

  final http.Client _cliente;

  /// Devuelve el uid de Firebase del usuario actual (inyectable en pruebas).
  final String? Function() _uidActual;

  final String _url;
  final String _clave;

  /// Bucket público que hay que crear en Supabase (ver `SUPABASE_SETUP.md`).
  static const String bucket = 'articulos';

  /// Uid real del usuario autenticado en Firebase.
  static String? _uidDeFirebase() => FirebaseAuth.instance.currentUser?.uid;

  /// Sube [bytes] y devuelve la URL pública del archivo.
  ///
  /// La ruta incluye el uid para separar las fotos por usuario. No se usa
  /// `x-upsert`: cada archivo lleva la hora en el nombre, así que nunca choca.
  Future<String> subir({
    required String articuloId,
    required Uint8List bytes,
    required String nombreArchivo,
    required String tipoContenido,
  }) async {
    if (_url.isEmpty || _clave.isEmpty) {
      throw StateError(
        'Falta configurar Supabase. Pega la URL y la clave anon en '
        'lib/config_supabase.dart o usa --dart-define. Ver SUPABASE_SETUP.md.',
      );
    }
    final String? uid = _uidActual();
    if (uid == null) {
      throw StateError('Inicia sesión para subir la foto.');
    }

    final String extension = nombreArchivo.contains('.')
        ? nombreArchivo.split('.').last.toLowerCase()
        : 'jpg';
    final String ruta =
        '$uid/$articuloId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final Uri destino = Uri.parse(
      '${_sinBarraFinal(_url)}/storage/v1/object/$bucket/${_codificar(ruta)}',
    );

    final http.Response respuesta = await _cliente
        .post(
          destino,
          headers: <String, String>{
            'apikey': _clave,
            'Authorization': 'Bearer $_clave',
            'Content-Type': tipoContenido,
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 30));

    if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
      throw StateError(
        'No se pudo subir la foto (${respuesta.statusCode}): ${respuesta.body}',
      );
    }
    return urlPublica(ruta);
  }

  /// Borra la foto indicada por su URL pública.
  ///
  /// Es "mejor esfuerzo": si la URL no es de este bucket o no hay
  /// configuración, no hace nada. Solo lanza error si Supabase rechaza el
  /// borrado (por ejemplo, porque falta la política de `delete`).
  Future<void> eliminar(String? url) async {
    if (url == null || _url.isEmpty || _clave.isEmpty) return;
    final String? ruta = _rutaDesdeUrl(url);
    if (ruta == null) return;

    final Uri destino = Uri.parse(
      '${_sinBarraFinal(_url)}/storage/v1/object/$bucket/${_codificar(ruta)}',
    );
    final http.Response respuesta = await _cliente
        .delete(
          destino,
          headers: <String, String>{
            'apikey': _clave,
            'Authorization': 'Bearer $_clave',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (respuesta.statusCode != 200 && respuesta.statusCode != 204) {
      throw StateError(
        'No se pudo borrar la foto (${respuesta.statusCode}): ${respuesta.body}',
      );
    }
  }

  /// Extrae la ruta interna de una URL pública de este bucket.
  ///
  /// Devuelve `null` si la URL es de otro dominio o de otro bucket (así no se
  /// intenta borrar fotos ajenas o enlaces antiguos).
  String? _rutaDesdeUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host != Uri.tryParse(_url)?.host) return null;

    final String marcador = '/storage/v1/object/public/$bucket/';
    final int indice = uri.path.indexOf(marcador);
    if (indice < 0) return null;

    final String rutaCodificada = uri.path.substring(indice + marcador.length);
    if (rutaCodificada.isEmpty) return null;
    return rutaCodificada.split('/').map(Uri.decodeComponent).join('/');
  }

  /// URL pública de un archivo dentro del bucket.
  String urlPublica(String ruta) =>
      '${_sinBarraFinal(_url)}/storage/v1/object/public/$bucket/${_codificar(ruta)}';

  /// Codifica cada segmento de la ruta (conserva los `/`).
  String _codificar(String ruta) =>
      ruta.split('/').map(Uri.encodeComponent).join('/');

  /// Quita la barra final para no generar URLs con `//`.
  String _sinBarraFinal(String valor) =>
      valor.endsWith('/') ? valor.substring(0, valor.length - 1) : valor;
}
