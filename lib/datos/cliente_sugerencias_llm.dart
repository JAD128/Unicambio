// =============================================================================
// ARCHIVO: lib/datos/cliente_sugerencias_llm.dart
// DESCRIPCIÓN: Cliente HTTP del proxy de sugerencias. La app nunca ve la API
//              key: solo envía el ID token de Firebase al Worker.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config_llm.dart';
import '../modelos/articulo.dart';
import '../modelos/sugerencia_llm.dart';
import '../modelos/vision.dart';

/// Función que entrega el ID token de Firebase del usuario actual.
typedef ProveedorTokenLlm = Future<String?> Function();

/// Cliente del endpoint `/sugerencias` del Worker.
class ClienteSugerenciasLlm {
  /// Crea un cliente inyectable (en pruebas se usa un `MockClient`).
  ClienteSugerenciasLlm({
    http.Client? cliente,
    ProveedorTokenLlm? proveedorToken,
    String urlBase = ConfiguracionLlm.urlBase,
  }) : _cliente = cliente ?? http.Client(),
       _proveedorToken = proveedorToken ?? _tokenDeFirebase,
       _url = Uri.parse(
         '${urlBase.replaceAll(RegExp(r'/+$'), '')}/sugerencias',
       );

  final http.Client _cliente;
  final ProveedorTokenLlm _proveedorToken;
  final Uri _url;

  static Future<String?> _tokenDeFirebase() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /// Pide una sugerencia para la foto y el contexto indicados.
  Future<SugerenciaLlm> sugerir({
    required List<int> bytes,
    required String mimeType,
    required TipoPublicacion tipo,
    required List<EtiquetaImagen> etiquetas,
    required List<String> lineasTexto,
  }) async {
    final String? token = await _proveedorToken();
    if (token == null || token.isEmpty) {
      throw StateError('Inicia sesión para usar las sugerencias inteligentes');
    }

    final Map<String, dynamic> cuerpo = <String, dynamic>{
      'imagenBase64': base64Encode(bytes),
      'mimeType': mimeType,
      'tipoPublicacion': tipo.name,
      'etiquetas': etiquetas
          .map(
            (EtiquetaImagen etiqueta) => <String, dynamic>{
              'etiqueta': etiqueta.etiqueta,
              'confianza': etiqueta.confianza,
            },
          )
          .toList(),
      'lineasTexto': lineasTexto,
    };

    final http.Response respuesta;
    try {
      respuesta = await _cliente
          .post(
            _url,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(cuerpo),
          )
          .timeout(ConfiguracionLlm.tiempoEspera);
    } on TimeoutException {
      throw StateError('El servicio de sugerencias tardó demasiado');
    } on Object {
      throw StateError('No se pudo conectar con el servicio de sugerencias');
    }

    if (respuesta.statusCode != 200) {
      throw StateError(
        'El servicio de sugerencias respondió ${respuesta.statusCode}',
      );
    }

    try {
      final Object? decodificado = jsonDecode(respuesta.body);
      if (decodificado is! Map<String, dynamic>) {
        throw const FormatException('Respuesta inesperada del Worker');
      }
      return SugerenciaLlm.fromJson(decodificado, tipo);
    } on FormatException catch (error) {
      throw StateError('Sugerencia no válida: ${error.message}');
    }
  }
}
