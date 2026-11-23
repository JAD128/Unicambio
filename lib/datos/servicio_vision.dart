// =============================================================================
// ARCHIVO: lib/datos/servicio_vision.dart
// DESCRIPCIÓN: Analiza una foto con Google ML Kit (etiquetado + OCR) y
//              devuelve un resultado simple para la aplicación.
//
// La pantalla NO importa ML Kit: solo usa la interfaz [ServicioVision]. Eso
// permite inyectar un servicio falso en las pruebas y cambiar de tecnología
// sin tocar el formulario. Todo el procesamiento es on-device (sin internet).
// =============================================================================

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../modelos/vision.dart';

/// Servicio que extrae etiquetas y texto de una imagen.
abstract class ServicioVision {
  /// Analiza la imagen ubicada en [ruta] (archivo local del dispositivo).
  Future<ResultadoVision> analizar(String ruta);

  /// Libera los modelos nativos. Se llama al cerrar la pantalla.
  Future<void> cerrar();
}

/// Implementación real con los modelos de Google ML Kit.
class ServicioVisionMlKit implements ServicioVision {
  ServicioVisionMlKit({ImageLabeler? etiquetador, TextRecognizer? reconocedor})
    : _etiquetador =
          etiquetador ??
          ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.45)),
      _reconocedor =
          reconocedor ?? TextRecognizer(script: TextRecognitionScript.latin);

  final ImageLabeler _etiquetador;
  final TextRecognizer _reconocedor;
  bool _cerrado = false;

  @override
  Future<ResultadoVision> analizar(String ruta) async {
    final InputImage imagen = InputImage.fromFilePath(ruta);

    // Cada detector falla por separado: si el OCR no encuentra texto o el
    // etiquetado falla, igual se devuelve lo que sí se pudo obtener.
    final List<EtiquetaImagen> etiquetas = await _etiquetas(imagen);
    final List<String> lineas = await _texto(imagen);

    return ResultadoVision(etiquetas: etiquetas, lineasTexto: lineas);
  }

  Future<List<EtiquetaImagen>> _etiquetas(InputImage imagen) async {
    try {
      final List<ImageLabel> etiquetas = await _etiquetador.processImage(
        imagen,
      );
      return etiquetas
          .map(
            (ImageLabel etiqueta) => EtiquetaImagen(
              etiqueta: etiqueta.label,
              confianza: etiqueta.confidence,
            ),
          )
          .toList();
    } catch (_) {
      return const <EtiquetaImagen>[];
    }
  }

  Future<List<String>> _texto(InputImage imagen) async {
    try {
      final RecognizedText reconocido = await _reconocedor.processImage(imagen);
      return reconocido.blocks
          .expand((TextBlock bloque) => bloque.lines)
          .map((TextLine linea) => linea.text)
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  Future<void> cerrar() async {
    if (_cerrado) return;
    _cerrado = true;
    try {
      await Future.wait<void>(<Future<void>>[
        _etiquetador.close(),
        _reconocedor.close(),
      ]);
    } catch (_) {
      // Si el sistema ya liberó los modelos, no hay nada más que hacer.
    }
  }
}
