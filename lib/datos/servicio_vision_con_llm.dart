// =============================================================================
// ARCHIVO: lib/datos/servicio_vision_con_llm.dart
// DESCRIPCIÓN: Decorador de ServicioVision. Primero analiza con ML Kit y
//              después pide una sugerencia al proxy; si falla, devuelve el
//              resultado local sin interrumpir el formulario.
// =============================================================================

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../modelos/articulo.dart';
import '../modelos/sugerencia_llm.dart';
import '../modelos/vision.dart';
import 'cache_sugerencias_llm.dart';
import 'cliente_sugerencias_llm.dart';
import 'servicio_vision.dart';

/// Devuelve el tipo de publicación vigente al analizar la foto.
typedef TipoPublicacionActual = TipoPublicacion Function();

/// Lee los bytes de la imagen indicada.
typedef LectorImagenLlm = Future<Uint8List> Function(String ruta);

/// Servicio de visión que suma sugerencias del LLM al resultado de ML Kit.
class ServicioVisionConLlm implements ServicioVision {
  /// Crea el decorador sobre el servicio de visión local.
  ServicioVisionConLlm({
    required this.vision,
    required this.tipoActual,
    ClienteSugerenciasLlm? cliente,
    CacheSugerenciasLlm? cache,
    LectorImagenLlm? lector,
  }) : _cliente = cliente ?? ClienteSugerenciasLlm(),
       _cache = cache ?? CacheSugerenciasLlm(),
       _lector = lector ?? _leerImagen;

  /// Servicio base (ML Kit en la app).
  final ServicioVision vision;

  /// Tipo elegido en el formulario en el momento del análisis.
  final TipoPublicacionActual tipoActual;

  final ClienteSugerenciasLlm _cliente;
  final CacheSugerenciasLlm _cache;
  final LectorImagenLlm _lector;

  static Future<Uint8List> _leerImagen(String ruta) =>
      XFile(ruta).readAsBytes();

  @override
  Future<ResultadoVision> analizar(String ruta) async {
    final ResultadoVision resultado = await vision.analizar(ruta);
    try {
      final Uint8List bytes = await _lector(ruta);
      final TipoPublicacion tipo = tipoActual();
      SugerenciaLlm? sugerencia = _cache.leer(bytes: bytes, tipo: tipo);
      sugerencia ??= await _cliente.sugerir(
        bytes: bytes,
        mimeType: _mimeDe(ruta),
        tipo: tipo,
        etiquetas: resultado.etiquetas,
        lineasTexto: resultado.lineasTexto,
      );
      _cache.guardar(bytes: bytes, tipo: tipo, sugerencia: sugerencia);
      return ResultadoVision(
        etiquetas: resultado.etiquetas,
        lineasTexto: resultado.lineasTexto,
        sugerencia: sugerencia,
      );
    } catch (_) {
      return resultado;
    }
  }

  @override
  Future<void> cerrar() => vision.cerrar();

  String _mimeDe(String ruta) {
    final String nombre = ruta.toLowerCase();
    if (nombre.endsWith('.png')) return 'image/png';
    if (nombre.endsWith('.webp')) return 'image/webp';
    if (nombre.endsWith('.heic') || nombre.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }
}
