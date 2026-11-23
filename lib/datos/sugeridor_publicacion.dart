// =============================================================================
// ARCHIVO: lib/datos/sugeridor_publicacion.dart
// DESCRIPCIÓN: Convierte el resultado crudo de ML Kit en sugerencias útiles
//              para el formulario: una categoría y un posible título.
//
// Es lógica PURA (no usa Flutter ni ML Kit), así que se puede probar sin
// cámara, sin emulador y sin modelos nativos. Las etiquetas de ML Kit vienen
// en inglés; aquí se traducen a las categorías y nombres de UniCambio.
// =============================================================================

import '../modelos/categoria.dart';
import '../modelos/vision.dart';

/// Calcula categoría y título sugeridos a partir de etiquetas y OCR.
class SugeridorPublicacion {
  const SugeridorPublicacion();

  /// Confianza mínima de la categoría ganadora.
  static const double _confianzaMinima = 0.5;

  /// Diferencia mínima entre la categoría ganadora y la segunda.
  static const double _margenMinimo = 0.12;

  /// Puntaje mínimo para aceptar una línea de OCR como título.
  static const int _puntajeMinimoTitulo = 4;

  /// Devuelve las sugerencias para [resultado].
  SugerenciasPublicacion sugerir(ResultadoVision resultado) {
    final List<EtiquetaImagen> etiquetas = resultado.etiquetas
        .where((EtiquetaImagen etiqueta) => etiqueta.etiqueta.trim().isNotEmpty)
        .toList();
    final List<String> lineas = _limpiarLineas(resultado.lineasTexto);
    final Categoria? categoria = _categoriaSugerida(etiquetas);
    final String? titulo = _tituloSugerido(
      lineas: lineas,
      etiquetas: etiquetas,
      categoria: categoria,
    );

    return SugerenciasPublicacion(
      categoria: categoria,
      titulo: titulo,
      lineasTexto: lineas,
    );
  }

  /// Elige la categoría con más confianza, si hay margen suficiente.
  Categoria? _categoriaSugerida(List<EtiquetaImagen> etiquetas) {
    if (etiquetas.isEmpty) return null;

    final Map<Categoria, double> puntajes = <Categoria, double>{
      for (final Categoria categoria in Categoria.values) categoria: 0,
    };

    for (final EtiquetaImagen etiqueta in etiquetas) {
      final String normalizada = _normalizar(etiqueta.etiqueta);
      if (normalizada.isEmpty || _etiquetasIgnoradas.contains(normalizada)) {
        continue;
      }
      final Set<String> palabras = normalizada.split(' ').toSet();

      for (final MapEntry<Categoria, Set<String>> grupo
          in _palabrasClave.entries) {
        final bool coincide = grupo.value.any(palabras.contains);
        if (coincide) {
          puntajes[grupo.key] = puntajes[grupo.key]! + etiqueta.confianza;
        }
      }
    }

    final List<MapEntry<Categoria, double>> ordenados =
        puntajes.entries
            .where((MapEntry<Categoria, double> entrada) => entrada.value > 0)
            .toList()
          ..sort(
            (MapEntry<Categoria, double> a, MapEntry<Categoria, double> b) =>
                b.value.compareTo(a.value),
          );
    if (ordenados.isEmpty) return null;

    final MapEntry<Categoria, double> mejor = ordenados.first;
    if (mejor.value < _confianzaMinima) return null;

    if (ordenados.length > 1) {
      final MapEntry<Categoria, double> segunda = ordenados[1];
      if (mejor.value - segunda.value < _margenMinimo) return null;
    }
    return mejor.key;
  }

  /// Busca un título en el OCR y, si no hay, usa la mejor etiqueta.
  String? _tituloSugerido({
    required List<String> lineas,
    required List<EtiquetaImagen> etiquetas,
    required Categoria? categoria,
  }) {
    String? mejorLinea;
    int mejorPuntaje = 0;

    for (int i = 0; i < lineas.length; i++) {
      final String linea = lineas[i];
      if (!_pareceTitulo(linea)) continue;
      final int puntaje = _puntajeTitulo(linea, i);
      if (puntaje > mejorPuntaje) {
        mejorPuntaje = puntaje;
        mejorLinea = linea;
      }
    }

    if (mejorLinea != null && mejorPuntaje >= _puntajeMinimoTitulo) {
      return _formatearTitulo(mejorLinea);
    }

    final List<EtiquetaImagen> porConfianza = List<EtiquetaImagen>.of(etiquetas)
      ..sort(
        (EtiquetaImagen a, EtiquetaImagen b) =>
            b.confianza.compareTo(a.confianza),
      );
    for (final EtiquetaImagen etiqueta in porConfianza) {
      final String? nombre = _nombreDeEtiqueta(etiqueta.etiqueta);
      if (nombre != null) return nombre;
    }

    switch (categoria) {
      case Categoria.libros:
        return 'Libro';
      case Categoria.apuntes:
        return 'Apuntes';
      case Categoria.tecnologia:
        return 'Artículo de tecnología';
      case Categoria.ropa:
        return 'Prenda de ropa';
      case Categoria.hogar:
        return 'Artículo de hogar';
      case Categoria.deportes:
        return 'Artículo deportivo';
      case Categoria.otros:
      case null:
        return null;
    }
  }

  /// Normaliza, quita vacías y evita líneas repetidas.
  List<String> _limpiarLineas(List<String> lineas) {
    final List<String> resultado = <String>[];
    final Set<String> vistas = <String>{};
    for (final String linea in lineas) {
      final String limpia = linea.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (limpia.isEmpty) continue;
      final String clave = _normalizar(limpia);
      if (clave.isEmpty || !vistas.add(clave)) continue;
      resultado.add(limpia);
      if (resultado.length >= 20) break;
    }
    return resultado;
  }

  /// Descarta texto que claramente no sirve como título.
  bool _pareceTitulo(String linea) {
    if (linea.length < 3 || linea.length > 60) return false;
    final String normalizada = _normalizar(linea);
    if (normalizada.isEmpty) return false;
    if (linea.toLowerCase().contains('http') ||
        linea.toLowerCase().contains('www.') ||
        linea.contains('@')) {
      return false;
    }
    if (RegExp(r'[\$€£]').hasMatch(linea)) return false;
    if (RegExp(r'\b\d{1,3}([.,]\d{3})+\b').hasMatch(linea)) return false;
    if (linea.endsWith(':')) return false;

    final List<String> palabras = normalizada.split(' ');
    if (palabras.isNotEmpty &&
        _palabrasNoTitulo.contains(palabras.first) &&
        palabras.length <= 2) {
      return false;
    }

    final int letras = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]')
        .allMatches(linea)
        .length;
    final int digitos = RegExp(r'\d').allMatches(linea).length;
    if (letras < 3 || digitos > letras) return false;

    return true;
  }

  /// Puntúa una línea según su "pinta" de título.
  int _puntajeTitulo(String linea, int indice) {
    int puntaje = 0;
    final int longitud = linea.length;
    final int palabras = linea.split(' ').length;

    if (longitud >= 8 && longitud <= 45) puntaje += 3;
    if (palabras >= 2 && palabras <= 6) puntaje += 2;
    if (palabras == 1 && longitud >= 4) puntaje += 1;
    if (indice < 3) puntaje += 1;

    final String primera = linea.substring(0, 1);
    if (primera == primera.toUpperCase() && linea != linea.toUpperCase()) {
      puntaje += 1;
    }

    final int letras = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]')
        .allMatches(linea)
        .length;
    if (letras >= 4) puntaje += 1;
    if (!RegExp(r'\d').hasMatch(linea)) puntaje += 1;

    return puntaje;
  }

  /// Convierte un título en mayúsculas a mayúsculas iniciales.
  String _formatearTitulo(String linea) {
    final String limpia = linea
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[|·•]+$'), '')
        .trim();
    if (limpia != limpia.toUpperCase()) return limpia;

    return limpia
        .split(' ')
        .map(
          (String palabra) => palabra.isEmpty
              ? palabra
              : palabra.substring(0, 1).toUpperCase() +
                    palabra.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  /// Traduce una etiqueta inglesa a un nombre en español.
  String? _nombreDeEtiqueta(String etiqueta) {
    final List<String> palabras = _normalizar(etiqueta).split(' ');
    for (final String palabra in palabras) {
      final String? nombre = _nombresEtiquetas[palabra];
      if (nombre != null) return nombre;
    }
    return null;
  }

  /// Minúsculas, sin acentos y con espacios simples.
  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  /// Etiquetas demasiado genéricas para decidir una categoría.
  static const Set<String> _etiquetasIgnoradas = <String>{
    'art',
    'black',
    'blue',
    'circle',
    'design',
    'floor',
    'font',
    'food',
    'graphic',
    'green',
    'hand',
    'human',
    'illustration',
    'indoor',
    'logo',
    'material',
    'metal',
    'outdoor',
    'paper',
    'pattern',
    'people',
    'person',
    'plastic',
    'product',
    'rectangle',
    'red',
    'room',
    'smile',
    'texture',
    'wall',
    'white',
    'wood',
    'yellow',
  };

  /// Palabras que suelen ser metadatos, no el nombre del artículo.
  static const Set<String> _palabrasNoTitulo = <String>{
    'codigo',
    'color',
    'condition',
    'estado',
    'isbn',
    'marca',
    'modelo',
    'model',
    'precio',
    'price',
    'size',
    'talla',
    'tel',
    'telefono',
    'whatsapp',
    'year',
  };

  /// Palabras clave (en inglés) que apuntan a cada categoría.
  static const Map<Categoria, Set<String>> _palabrasClave =
      <Categoria, Set<String>>{
        Categoria.libros: <String>{
          'book',
          'books',
          'comic',
          'dictionary',
          'encyclopedia',
          'literature',
          'magazine',
          'manga',
          'novel',
          'publication',
          'reading',
          'textbook',
        },
        Categoria.apuntes: <String>{
          'document',
          'eraser',
          'highlighter',
          'marker',
          'notebook',
          'notepad',
          'notes',
          'office',
          'pen',
          'pencil',
          'ruler',
          'school',
          'stationery',
        },
        Categoria.tecnologia: <String>{
          'cable',
          'calculator',
          'camera',
          'charger',
          'computer',
          'console',
          'drone',
          'earphones',
          'electronics',
          'flash',
          'hard',
          'headphone',
          'headphones',
          'keyboard',
          'laptop',
          'mobile',
          'monitor',
          'mouse',
          'notebook',
          'phone',
          'printer',
          'scanner',
          'screen',
          'smartwatch',
          'speaker',
          'tablet',
          'television',
          'tv',
          'usb',
          'video',
        },
        Categoria.ropa: <String>{
          'backpack',
          'bag',
          'belt',
          'boot',
          'boots',
          'cap',
          'clothes',
          'clothing',
          'coat',
          'dress',
          'glove',
          'gloves',
          'handbag',
          'hat',
          'hoodie',
          'jacket',
          'jeans',
          'jewelry',
          'pants',
          'scarf',
          'shirt',
          'shoe',
          'shoes',
          'shorts',
          'skirt',
          'sneaker',
          'sneakers',
          'sunglasses',
          'sweater',
          'trousers',
          'wallet',
          'watch',
        },
        Categoria.hogar: <String>{
          'appliance',
          'bed',
          'blanket',
          'bottle',
          'bowl',
          'cabinet',
          'carpet',
          'chair',
          'clock',
          'cup',
          'curtain',
          'desk',
          'drawer',
          'fan',
          'furniture',
          'glass',
          'heater',
          'kitchen',
          'lamp',
          'light',
          'microwave',
          'mirror',
          'mug',
          'oven',
          'pan',
          'pillow',
          'plant',
          'plate',
          'pot',
          'refrigerator',
          'rug',
          'shelf',
          'table',
          'vase',
        },
        Categoria.deportes: <String>{
          'ball',
          'basketball',
          'bat',
          'bicycle',
          'bike',
          'camping',
          'dumbbell',
          'fishing',
          'fitness',
          'football',
          'goggles',
          'gym',
          'helmet',
          'mat',
          'racket',
          'running',
          'skateboard',
          'soccer',
          'sport',
          'sports',
          'swimming',
          'tent',
          'tennis',
          'volleyball',
          'weights',
          'yoga',
        },
        Categoria.otros: <String>{
          'collectible',
          'craft',
          'game',
          'guitar',
          'instrument',
          'keychain',
          'piano',
          'puzzle',
          'souvenir',
          'tool',
          'toy',
          'ukulele',
          'umbrella',
          'violin',
        },
      };

  /// Nombres en español para las etiquetas más comunes.
  static const Map<String, String> _nombresEtiquetas = <String, String>{
    'backpack': 'Mochila',
    'bag': 'Bolso',
    'ball': 'Balón',
    'basketball': 'Balón de básquet',
    'bat': 'Bate',
    'bed': 'Cama',
    'belt': 'Cinturón',
    'bicycle': 'Bicicleta',
    'bike': 'Bicicleta',
    'blanket': 'Cobija',
    'book': 'Libro',
    'books': 'Libro',
    'boot': 'Botas',
    'boots': 'Botas',
    'bottle': 'Botella',
    'bowl': 'Tazón',
    'calculator': 'Calculadora',
    'camera': 'Cámara',
    'cap': 'Gorra',
    'chair': 'Silla',
    'charger': 'Cargador',
    'clock': 'Reloj',
    'coat': 'Abrigo',
    'comic': 'Cómic',
    'computer': 'Computadora',
    'cup': 'Taza',
    'desk': 'Escritorio',
    'dictionary': 'Diccionario',
    'dress': 'Vestido',
    'drone': 'Dron',
    'dumbbell': 'Mancuerna',
    'dumbbells': 'Mancuernas',
    'encyclopedia': 'Enciclopedia',
    'eraser': 'Borrador',
    'fan': 'Ventilador',
    'football': 'Balón de fútbol',
    'furniture': 'Mueble',
    'game': 'Juego',
    'glass': 'Vaso',
    'glove': 'Guante',
    'gloves': 'Guantes',
    'guitar': 'Guitarra',
    'hat': 'Sombrero',
    'headphone': 'Audífonos',
    'headphones': 'Audífonos',
    'helmet': 'Casco',
    'highlighter': 'Resaltador',
    'hoodie': 'Sudadera',
    'instrument': 'Instrumento',
    'jacket': 'Chaqueta',
    'jeans': 'Jeans',
    'keyboard': 'Teclado',
    'keychain': 'Llavero',
    'lamp': 'Lámpara',
    'laptop': 'Laptop',
    'magazine': 'Revista',
    'manga': 'Manga',
    'marker': 'Marcador',
    'mat': 'Mat',
    'microwave': 'Microondas',
    'mirror': 'Espejo',
    'mobile': 'Celular',
    'monitor': 'Monitor',
    'mouse': 'Mouse',
    'mug': 'Taza',
    'notebook': 'Cuaderno',
    'notepad': 'Bloc de notas',
    'novel': 'Novela',
    'oven': 'Horno',
    'pan': 'Sartén',
    'pants': 'Pantalón',
    'pen': 'Bolígrafo',
    'pencil': 'Lápiz',
    'phone': 'Celular',
    'piano': 'Piano',
    'pillow': 'Almohada',
    'plant': 'Planta',
    'plate': 'Plato',
    'pot': 'Olla',
    'printer': 'Impresora',
    'puzzle': 'Rompecabezas',
    'racket': 'Raqueta',
    'refrigerator': 'Refrigeradora',
    'rug': 'Alfombra',
    'ruler': 'Regla',
    'scanner': 'Escáner',
    'scarf': 'Bufanda',
    'shelf': 'Estantería',
    'shirt': 'Camisa',
    'shoe': 'Zapatos',
    'shoes': 'Zapatos',
    'shorts': 'Shorts',
    'skateboard': 'Patineta',
    'skirt': 'Falda',
    'smartwatch': 'Reloj inteligente',
    'sneaker': 'Zapatillas',
    'sneakers': 'Zapatillas',
    'soccer': 'Balón de fútbol',
    'speaker': 'Parlante',
    'sports': 'Artículo deportivo',
    'sunglasses': 'Gafas de sol',
    'sweater': 'Suéter',
    'table': 'Mesa',
    'tablet': 'Tablet',
    'television': 'Televisor',
    'tent': 'Carpa',
    'textbook': 'Libro de texto',
    'tool': 'Herramienta',
    'toy': 'Juguete',
    'trousers': 'Pantalón',
    'tv': 'Televisor',
    'ukulele': 'Ukelele',
    'umbrella': 'Paraguas',
    'vase': 'Florero',
    'violin': 'Violín',
    'wallet': 'Billetera',
    'watch': 'Reloj',
    'weights': 'Pesas',
    'yoga': 'Yoga',
  };
}
