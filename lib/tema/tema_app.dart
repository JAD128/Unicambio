// =============================================================================
// ARCHIVO: lib/tema/tema_app.dart
// DESCRIPCIÓN: Define el tema visual (colores, tipografía, formas) de UniCambio.
//
// Centralizar el tema en un solo archivo hace que TODA la app se vea coherente:
// si mañana quieren cambiar el color principal, se cambia aquí una sola vez y
// todas las pantallas se actualizan. El lenguaje visual es iOS-inspired:
// fondos agrupados, superficies blancas, separadores finos y esquinas suaves.
// =============================================================================

import 'package:flutter/material.dart';

/// Clase contenedora del tema de la aplicación.
/// Se usa como `TemaApp.claro` desde `main.dart`.
class TemaApp {
  /// Constructor privado: esta clase no se instancia, solo agrupa utilidades.
  TemaApp._();

  /// Color base ("semilla") a partir del cual Material 3 genera la paleta
  /// completa de colores de la aplicación. Usamos un verde-azulado moderno.
  static const Color colorSemilla = Color(0xFF00897B);

  /// Color de fondo general de las pantallas (gris agrupado tipo iOS).
  static const Color colorFondo = Color(0xFFF2F2F7);

  /// Superficie de tarjetas, campos y barras.
  static const Color colorSuperficie = Colors.white;

  /// Texto principal, casi negro pero más suave que el negro puro.
  static const Color colorTexto = Color(0xFF1C1C1E);

  /// Texto secundario y ayudas.
  static const Color colorTextoSecundario = Color(0xFF6E6E73);

  /// Separadores finos entre filas agrupadas.
  static const Color colorSeparador = Color(0xFFE5E5EA);

  /// Radio de tarjetas y hojas.
  static const double radioTarjeta = 18;

  /// Radio de campos y botones.
  static const double radioControl = 14;

  /// Espaciado estándar entre bloques.
  static const double espacio = 16;

  /// Tema claro de UniCambio.
  static ThemeData get claro {
    final ColorScheme esquema = ColorScheme.fromSeed(
      seedColor: colorSemilla,
      brightness: Brightness.light,
    ).copyWith(
      surface: colorSuperficie,
      onSurface: colorTexto,
      onSurfaceVariant: colorTextoSecundario,
      surfaceContainerHighest: colorFondo,
      outlineVariant: colorSeparador,
    );

    final BorderSide bordeSuave = BorderSide(color: colorSeparador);
    final OutlineInputBorder campo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radioControl),
      borderSide: bordeSuave,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: colorFondo,
      fontFamily: null,
      textTheme: Typography.material2021().black.apply(
            bodyColor: colorTexto,
            displayColor: colorTexto,
            decorationColor: colorTexto,
          ),

      // ------------------------- Barra superior -------------------------
      appBarTheme: AppBarThemeData(
        backgroundColor: colorSuperficie,
        foregroundColor: colorTexto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: const TextStyle(
          color: colorTexto,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),

      // --------------------------- Tarjetas ------------------------------
      cardTheme: CardThemeData(
        color: colorSuperficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioTarjeta),
          side: bordeSuave,
        ),
      ),

      // ------------------- Campos de texto y búsqueda --------------------
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colorSuperficie,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(color: colorTextoSecundario),
        floatingLabelStyle: TextStyle(
          color: esquema.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: colorTextoSecundario),
        helperStyle: const TextStyle(
          color: colorTextoSecundario,
          fontSize: 12,
        ),
        counterStyle: const TextStyle(
          color: colorTextoSecundario,
          fontSize: 11,
        ),
        errorStyle: const TextStyle(color: Color(0xFFD70015), fontSize: 12),
        prefixIconColor: colorTextoSecundario,
        border: campo,
        enabledBorder: campo,
        focusedBorder: campo.copyWith(
          borderSide: BorderSide(color: esquema.primary, width: 1.6),
        ),
        errorBorder: campo.copyWith(
          borderSide: const BorderSide(color: Color(0xFFD70015)),
        ),
        focusedErrorBorder: campo.copyWith(
          borderSide: const BorderSide(color: Color(0xFFD70015), width: 1.6),
        ),
      ),

      // ------------------- Barra de navegación inferior ------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorSuperficie,
        surfaceTintColor: Colors.transparent,
        indicatorColor: esquema.primaryContainer,
        height: 70,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // --------------------------- Botones -------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radioControl),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: esquema.primary,
          side: bordeSuave,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radioControl),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: esquema.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(bordeSuave),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radioControl),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // --------------------- Botón flotante (Publicar) -------------------
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esquema.primary,
        foregroundColor: esquema.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioControl + 4),
        ),
      ),

      // ---------------------- Listas y diálogos --------------------------
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 36,
        iconColor: esquema.primary,
        titleTextStyle: const TextStyle(
          color: colorTexto,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: const TextStyle(
          color: colorTextoSecundario,
          fontSize: 13,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorSeparador,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        side: bordeSuave,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: TextStyle(color: colorTexto, fontWeight: FontWeight.w500),
        selectedColor: esquema.primaryContainer,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorSuperficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        titleTextStyle: const TextStyle(
          color: colorTexto,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: colorTextoSecundario,
          fontSize: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorTexto,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioControl),
        ),
      ),
    );
  }
}
