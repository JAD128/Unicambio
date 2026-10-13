// =============================================================================
// ARCHIVO: lib/tema/tema_app.dart
// DESCRIPCIÓN: Define el tema visual (colores, tipografía, formas) de UniCambio.
//
// Centralizar el tema en un solo archivo hace que TODA la app se vea coherente:
// si mañana quieren cambiar el color principal, se cambia aquí una sola vez y
// todas las pantallas se actualizan.
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

  /// Color de fondo general de las pantallas (un gris muy claro).
  static const Color colorFondo = Color(0xFFF4F6F8);

  /// Tema claro de UniCambio.
  static ThemeData get claro {
    // Generamos el esquema de colores de Material 3 a partir del color semilla.
    final ColorScheme esquema = ColorScheme.fromSeed(
      seedColor: colorSemilla,
      brightness: Brightness.light,
    );

    return ThemeData(
      // Material 3 es el diseño moderno recomendado por Google.
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: colorFondo,
      // Fuente por defecto del sistema (no se incluyen fuentes personalizadas).
      fontFamily: null,

      // ------------------------- Barra superior -------------------------
      appBarTheme: AppBarThemeData(
        backgroundColor: esquema.surface,
        foregroundColor: esquema.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: esquema.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      // --------------------------- Tarjetas ------------------------------
      cardTheme: CardThemeData(
        color: esquema.surface,
        elevation: 1.5,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      // ------------------- Campos de texto y búsqueda --------------------
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: esquema.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: esquema.onSurfaceVariant),
        prefixIconColor: esquema.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: esquema.primary, width: 1.6),
        ),
      ),

      // ------------------- Barra de navegación inferior ------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: esquema.surface,
        indicatorColor: esquema.primaryContainer,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ---------------------- Botón principal (Filled) -------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // --------------------- Botón flotante (Publicar) -------------------
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esquema.primary,
        foregroundColor: esquema.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
