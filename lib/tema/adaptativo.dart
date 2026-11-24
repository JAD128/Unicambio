// =============================================================================
// ARCHIVO: lib/tema/adaptativo.dart
// DESCRIPCIÓN: Pequeños helpers para adaptar la misma estética iOS-inspired a
//              Android, iOS y web sin duplicar pantallas ni dependencias.
// =============================================================================

import 'package:flutter/cupertino.dart' show showCupertinoModalPopup;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import 'tema_app.dart';

/// `true` cuando la app corre en iOS (no en la web).
bool get esIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// `true` cuando la app corre en Android (no en la web).
bool get esAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Icono Cupertino en iOS y Material en Android/web.
IconData iconoAdaptativo({
  required IconData material,
  required IconData cupertino,
}) => esIOS ? cupertino : material;

/// Ancho máximo del contenido para que el formulario no se estire en web.
double anchoContenido(double anchoDisponible) {
  if (kIsWeb && anchoDisponible >= 900) return 760;
  if (anchoDisponible >= 700) return 640;
  return anchoDisponible;
}

/// Padding inferior que respeta el teclado y la barra de gestos.
EdgeInsets paddingConTeclado(BuildContext context) => EdgeInsets.fromLTRB(
      16,
      16,
      16,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    );

/// Muestra una hoja inferior: Cupertino en iOS, Material en Android/web.
Future<T?> mostrarHojaAdaptada<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  if (esIOS) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext contexto) =>
          HojaAdaptativaIos(child: builder(contexto)),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: builder,
  );
}

/// Superficie opaca con asa para las hojas modales de iOS.
class HojaAdaptativaIos extends StatelessWidget {
  /// Contenido de la hoja.
  final Widget child;

  /// Constructor de la superficie.
  const HojaAdaptativaIos({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('hoja-adaptativa-ios'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: TemaApp.colorSuperficie,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TemaApp.radioTarjeta),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: TemaApp.colorSeparador,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(child: child),
        ],
      ),
    );
  }
}
