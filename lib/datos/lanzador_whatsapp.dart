// =============================================================================
// ARCHIVO: lib/datos/lanzador_whatsapp.dart
// DESCRIPCIÓN: Abre WhatsApp con `url_launcher`. Se define una interfaz para
//              poder simular el lanzamiento en pruebas sin salir de Flutter.
//
// No usamos deep links propios ni dominio: solo se comparte texto.
// =============================================================================

import 'package:url_launcher/url_launcher.dart';

/// Normaliza un número colombiano a formato internacional sin `+`.
///
/// Acepta 10 dígitos que empiezan por `3` y 12 dígitos que ya empiezan por `57`.
/// Devuelve `null` cuando el texto no es un número móvil colombiano válido.
String? normalizarTelefonoColombiano(String entrada) {
  final String digitos = entrada.replaceAll(RegExp(r'\D'), '');
  if (digitos.length == 10 && digitos.startsWith('3')) return '57$digitos';
  if (digitos.length == 12 && digitos.startsWith('57')) return digitos;
  return null;
}

/// URI usada para escribir a un número concreto.
Uri uriContactoWhatsapp({required String telefono, required String mensaje}) =>
    Uri.https('wa.me', '/$telefono', <String, String>{'text': mensaje});

/// URI usada para elegir chat y compartir solo texto.
Uri uriCompartirWhatsapp(String mensaje) =>
    Uri.https('wa.me', '/', <String, String>{'text': mensaje});

/// Operaciones de WhatsApp que la UI necesita.
abstract class LanzadorWhatsapp {
  /// Abre un chat con [telefono] y deja [mensaje] escrito.
  Future<bool> contactar({
    required String telefono,
    required String mensaje,
  });

  /// Abre WhatsApp para compartir [mensaje].
  Future<bool> compartir(String mensaje);
}

/// Implementación real basada en `url_launcher`.
class LanzadorWhatsappUrl implements LanzadorWhatsapp {
  const LanzadorWhatsappUrl();

  @override
  Future<bool> contactar({
    required String telefono,
    required String mensaje,
  }) {
    final String? normalizado = normalizarTelefonoColombiano(telefono);
    if (normalizado == null) return Future<bool>.value(false);
    return _abrir(
      uriContactoWhatsapp(telefono: normalizado, mensaje: mensaje),
    );
  }

  @override
  Future<bool> compartir(String mensaje) =>
      _abrir(uriCompartirWhatsapp(mensaje));

  Future<bool> _abrir(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
