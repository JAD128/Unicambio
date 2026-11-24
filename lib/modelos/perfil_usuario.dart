// =============================================================================
// ARCHIVO: lib/modelos/perfil_usuario.dart
// DESCRIPCIÓN: Preferencias del usuario que no viven en Firebase Auth: número
//              de WhatsApp opcional y configuración de sugerencias in-app.
// =============================================================================

import 'categoria.dart';

/// Datos de perfil guardados en `usuarios/{uid}` de Firestore.
class PerfilUsuario {
  /// Crea un perfil con valores seguros por defecto.
  const PerfilUsuario({
    required this.uid,
    this.telefono = '',
    this.sugerenciasActivas = false,
    this.categoriasSugerencias = const <Categoria>{},
    this.ultimaVista,
  });

  /// `uid` de Firebase del dueño del perfil.
  final String uid;

  /// Número ingresado por el usuario, normalizado con indicativo `57`.
  final String telefono;

  /// Si el usuario quiere ver sugerencias de artículos recientes.
  final bool sugerenciasActivas;

  /// Categorías que quiere ver en esas sugerencias.
  final Set<Categoria> categoriasSugerencias;

  /// Última vez que el usuario abrió la bandeja de sugerencias.
  final DateTime? ultimaVista;

  /// Perfil vacío para un usuario que aún no tiene documento en Firestore.
  factory PerfilUsuario.vacio(String uid) => PerfilUsuario(uid: uid);

  /// Crea una copia cambiando solo los campos indicados.
  PerfilUsuario copyWith({
    String? uid,
    String? telefono,
    bool? sugerenciasActivas,
    Set<Categoria>? categoriasSugerencias,
    DateTime? ultimaVista,
  }) {
    return PerfilUsuario(
      uid: uid ?? this.uid,
      telefono: telefono ?? this.telefono,
      sugerenciasActivas:
          sugerenciasActivas ?? this.sugerenciasActivas,
      categoriasSugerencias:
          categoriasSugerencias ?? this.categoriasSugerencias,
      ultimaVista: ultimaVista ?? this.ultimaVista,
    );
  }

  /// Convierte el perfil en un mapa simple (memoria y pruebas).
  Map<String, Object?> toMap() => <String, Object?>{
        'uid': uid,
        'telefono': telefono,
        'sugerenciasActivas': sugerenciasActivas,
        'categoriasSugerencias':
            categoriasSugerencias.map((Categoria c) => c.name).toList(),
        'ultimaVista': ultimaVista?.toIso8601String(),
      };

  /// Reconstruye un perfil desde un mapa simple.
  factory PerfilUsuario.fromMap(Map<String, Object?> mapa) {
    final Object? fecha = mapa['ultimaVista'];
    final DateTime? ultimaVista = fecha is DateTime
        ? fecha
        : fecha is String
            ? DateTime.tryParse(fecha)
            : null;

    final Object? categorias = mapa['categoriasSugerencias'];
    final Set<Categoria> seleccionadas = <Categoria>{};
    if (categorias is List) {
      for (final Object? valor in categorias) {
        if (valor is! String) continue;
        for (final Categoria categoria in Categoria.values) {
          if (categoria.name == valor) seleccionadas.add(categoria);
        }
      }
    }

    return PerfilUsuario(
      uid: mapa['uid'] as String? ?? '',
      telefono: mapa['telefono'] as String? ?? '',
      sugerenciasActivas: mapa['sugerenciasActivas'] as bool? ?? false,
      categoriasSugerencias: seleccionadas,
      ultimaVista: ultimaVista,
    );
  }
}
