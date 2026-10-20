# AGENTS.md — UniCambio (Flutter)

App Flutter (paquete `unicambio`) para que estudiantes vendan, intercambien o
regalen artículos. NO es el proyecto de MIT App Inventor del directorio padre.

## Antes de trabajar

Lee **`PROGRESO.md`**: estado, arquitectura, esquema SQLite, API de
repositorio/provider, problemas conocidos y hoja de ruta. Actualízalo al cerrar
cada avance.

## Comandos (deben quedar en verde)

```bash
flutter pub get   # tras tocar pubspec.yaml
flutter analyze   # -> No issues found!
flutter test      # -> All tests passed!  (23 pruebas)
```

No hay CI: `analyze` + `test` son la única verificación. Ejecutar ambos tras
cada cambio, en ese orden.

## Arquitectura

```
Pantallas --context.watch/read--> ArticulosProvider (ChangeNotifier)
        --> ArticuloRepositorio (interfaz)
              ├── ArticuloRepositorioSqflite  → SQLite `unicambio.db` (app real)
              └── ArticuloRepositorioMemoria  → RAM (solo pruebas)
```

- La UI **nunca** toca SQLite; el provider **nunca** ve SQL. Migrar a la nube =
  nueva implementación del repositorio + cambiarla en `main.dart`; las
  pantallas no se tocan.
- `main.dart` crea el repositorio, siembra datos de ejemplo (solo si la BD está
  vacía) y arranca la app con el provider.
- API y getters exactos: ver `PROGRESO.md` §7 antes de tocar provider o
  repositorio.

## Pruebas (peculiaridades)

- `test/articulo_repositorio_test.dart` prueba el repositorio real vía
  `sqflite_common_ffi`: requiere `sqfliteFfiInit()` +
  `databaseFactory = databaseFactoryFfi` en `setUpAll`, y borra la BD en cada
  `setUp` con `BaseDatos.instancia.eliminar()`.
- Tests de provider y widgets usan `ArticuloRepositorioMemoria` (SQLite no
  corre en el entorno de test sin ffi).
- Para un solo archivo: `flutter test test/articulos_provider_test.dart`.

## Convenciones del repo

- Código y comentarios **en español**, documentados con `///` (el usuario está
  estudiando Flutter). En ediciones pequeñas no añadir comentarios
  innecesarios, pero mantener el estilo existente.
- Responder en español, conciso.
- Entregar por fases completas (archivos + analyze + test en verde) sin pedir
  confirmación en cada micro-paso.
- Dependencias nuevas: permitidas si hacen falta, pero avisar/justificar.
- No hacer commit salvo petición explícita. En Windows el aviso
  `LF will be replaced by CRLF` es normal.

## Gotchas

- `sqflite` solo corre en Android/iOS. Para UI rápida: `flutter run -d chrome`
  (en web SQLite no funciona igual); para datos reales: emulador Android.
- Ruido de Logcat `BLASTBufferQueue ...` viene del sistema Android, no del
  proyecto.
- Pantalla lenta en equipos Transsion/Tecno (GPU Mali): probar
  `flutter run --profile` o `--no-enable-impeller`.
- Deuda técnica consciente: `esFavorito` es global (no por usuario) y los ids
  se generan con la hora; resolver al pasar a la nube (`PROGRESO.md` §11).
