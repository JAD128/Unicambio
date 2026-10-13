// =============================================================================
// ARCHIVO: lib/datos/articulos_ejemplo.dart
// DESCRIPCIÓN: Datos de ejemplo ("mock data") que se usan para llenar la
//              interfaz durante este primer avance.
//
// En lugar de una base de datos, usamos listas en memoria. Cuando se implemente
// el almacenamiento real, estas listas se reemplazarán por consultas a la BD o
// al servicio en la nube, pero las pantallas no tendrán que cambiar mucho.
// =============================================================================

import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Lista principal de artículos publicados por estudiantes (datos de ejemplo).
///
/// Se declara como `final` (no `const`) porque más adelante podría necesitar
/// inicializarse de forma dinámica.
final List<Articulo> articulosEjemplo = <Articulo>[
  const Articulo(
    id: 'a1',
    titulo: 'Cálculo de una variable - Stewart',
    descripcion:
        'Libro de Cálculo de una variable (James Stewart, 8a edición). '
        'Buen estado, con algunas anotaciones a lápiz. Ideal para Cálculo I.',
    precio: 45000,
    categoria: Categoria.libros,
    tipo: TipoPublicacion.venta,
    vendedor: 'Ana Gómez',
    esFavorito: true,
  ),
  const Articulo(
    id: 'a2',
    titulo: 'Calculadora científica Casio fx-991',
    descripcion:
        'Calculadora Casio fx-991LA Plus. Funciona perfectamente, incluye '
        'estuche. Muy útil para ingeniería y física.',
    precio: 80000,
    categoria: Categoria.tecnologia,
    tipo: TipoPublicacion.venta,
    vendedor: 'Carlos Ruiz',
  ),
  const Articulo(
    id: 'a3',
    titulo: 'Apuntes de Física I completos',
    descripcion:
        'Apuntes de todo el semestre de Física I, con ejercicios resueltos y '
        'parciales anteriores. Se regalan a quien los necesite.',
    precio: 0,
    categoria: Categoria.apuntes,
    tipo: TipoPublicacion.regalo,
    vendedor: 'María Pérez',
    esFavorito: true,
  ),
  const Articulo(
    id: 'a4',
    titulo: 'Chaqueta universitaria talla M',
    descripcion:
        'Chaqueta de la universidad, talla M. La cambio por una talla L o por '
        'una sudadera en buen estado.',
    precio: 0,
    categoria: Categoria.ropa,
    tipo: TipoPublicacion.intercambio,
    vendedor: 'Juan Torres',
  ),
  const Articulo(
    id: 'a5',
    titulo: 'Lámpara de escritorio LED',
    descripcion:
        'Lámpara LED con brazo flexible y 3 niveles de intensidad. Perfecta '
        'para estudiar de noche.',
    precio: 35000,
    categoria: Categoria.hogar,
    tipo: TipoPublicacion.venta,
    vendedor: 'Sofía Díaz',
  ),
  const Articulo(
    id: 'a6',
    titulo: 'Balón de fútbol profesional',
    descripcion:
        'Balón número 5, poco uso. Lo cambio por raquetas de tenis o por un '
        'balón de baloncesto.',
    precio: 0,
    categoria: Categoria.deportes,
    tipo: TipoPublicacion.intercambio,
    vendedor: 'Diego López',
  ),
  const Articulo(
    id: 'a7',
    titulo: 'Libro: Introducción a los Algoritmos',
    descripcion:
        'El clásico "CLRS" de algoritmos. Edición en español, en excelente '
        'estado. Base para Algoritmos y Estructuras de Datos.',
    precio: 120000,
    categoria: Categoria.libros,
    tipo: TipoPublicacion.venta,
    vendedor: 'Laura Martín',
    esFavorito: true,
  ),
  const Articulo(
    id: 'a8',
    titulo: 'Audífonos Bluetooth',
    descripcion:
        'Audífonos inalámbricos con estuche de carga. Los cambio por un mouse '
        'inalámbrico o por un teclado mecánico.',
    precio: 0,
    categoria: Categoria.tecnologia,
    tipo: TipoPublicacion.intercambio,
    vendedor: 'Andrés Vega',
  ),
];

/// Subconjunto que representa los favoritos del usuario (datos de ejemplo).
/// En la pantalla de Favoritos se muestran solo estos artículos.
final List<Articulo> favoritosEjemplo = <Articulo>[
  articulosEjemplo[0],
  articulosEjemplo[2],
  articulosEjemplo[6],
];

/// Subconjunto que representa los artículos publicados por el propio usuario.
/// En la pantalla "Mis artículos" se muestran estos.
final List<Articulo> misArticulosEjemplo = <Articulo>[
  articulosEjemplo[1],
  articulosEjemplo[4],
];
