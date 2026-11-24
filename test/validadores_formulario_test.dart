// =============================================================================
// ARCHIVO: test/validadores_formulario_test.dart
// DESCRIPCIÓN: Pruebas de las reglas del formulario de publicación, sin widgets.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:unicambio/utilidades/validadores_formulario.dart';

void main() {
  group('validarTitulo', () {
    test('rechaza texto vacío y demasiado corto', () {
      expect(validarTitulo(null), 'Escribe un título');
      expect(validarTitulo('   '), 'Escribe un título');
      expect(
        validarTitulo('Libr'),
        'El título debe tener al menos $tituloMinimo caracteres',
      );
    });

    test('rechaza más de 80 caracteres', () {
      expect(
        validarTitulo('L' * (tituloMaximo + 1)),
        'El título no puede superar $tituloMaximo caracteres',
      );
    });

    test('acepta una longitud válida ignorando espacios extremos', () {
      expect(validarTitulo('  Calculadora científica  '), isNull);
    });
  });

  group('validarDescripcion', () {
    test('exige al menos 10 caracteres', () {
      expect(validarDescripcion(null), 'Escribe una descripción');
      expect(
        validarDescripcion('Muy corta'),
        'La descripción debe tener al menos $descripcionMinima caracteres',
      );
    });

    test('rechaza más de 1000 caracteres', () {
      expect(
        validarDescripcion('D' * (descripcionMaxima + 1)),
        'La descripción no puede superar $descripcionMaxima caracteres',
      );
    });
  });

  group('validarPrecio', () {
    test('es opcional y se ignora cuando no es venta', () {
      expect(validarPrecio(null, esVenta: true), isNull);
      expect(validarPrecio('', esVenta: true), isNull);
      expect(validarPrecio('abc', esVenta: false), isNull);
    });

    test('acepta coma decimal y rechaza valores negativos', () {
      expect(validarPrecio('12,5', esVenta: true), isNull);
      expect(validarPrecio('-1', esVenta: true), 'Precio no válido');
      expect(validarPrecio('abc', esVenta: true), 'Precio no válido');
    });

    test('rechaza valores por encima del máximo', () {
      expect(
        validarPrecio('100000000', esVenta: true),
        'El precio máximo es 99,999,999',
      );
    });
  });
}
