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
flutter test      # -> All tests passed!  (24 pruebas)
```

No hay CI: `analyze` + `test` son la única verificación. Ejecutar ambos tras
cada cambio, en ese orden.

## Arquitectura

```
Pantallas --context.watch/read--> ArticulosProvider (ChangeNotifier)
        --> ArticuloRepositorio (interfaz)
              ├── ArticuloRepositorioNube     → Firestore (app real)
              ├── ArticuloRepositorioSqflite  → SQLite (histórico, solo pruebas)
              └── ArticuloRepositorioMemoria  → RAM (pruebas / sin Firebase)
```

- La UI **nunca** toca la base de datos; el provider **nunca** ve SQL ni
  Firestore. Cambiar de backend = nueva implementación del repositorio +
  cambiarla en `main.dart`; las pantallas no se tocan.
- `main.dart` crea el repositorio (`ArticuloRepositorioNube` si Firebase
  inició; `ArticuloRepositorioMemoria` como respaldo), lanza
  `provider.iniciar()` sin bloquear el arranque y monta la app con
  `ChangeNotifierProvider`. La puerta de sesión recarga el provider cuando
  aparece un usuario. Con Firestore, `iniciar()` también se suscribe a
  `observarTodos()` (`snapshots`) para que las publicaciones de otros usuarios
  aparezcan en vivo; la suscripción se cancela en `dispose()`.
- **No hay semilla**: la app arranca vacía; `articulosEjemplo` solo alimenta
  la implementación en memoria de las pruebas.
- **Al editar pantallas: mantener el provider como única fuente de datos.**
  En el Avance 6 se reescribieron pantallas usando `articulosEjemplo` directo
  y se desconectó la UI sin que analyze/test lo delataran; verificar tras
  cambios grandes que `ChangeNotifierProvider` siga en `main.dart` y las
  pantallas usen `context.watch/read<ArticulosProvider>()`.
- "Mis artículos" filtra por `vendedorPropio` ('Tú (estudiante)'), no por la
  sesión de Firebase (Avance 9).
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

- Firestore es la fuente real (`unicambio-2f543`). Las reglas viven en
  `firestore.rules` (desplegar con `firebase deploy --only firestore:rules` o
  pegarlas en la consola). Sin sesión, leer/escribir falla por diseño.
- `sqflite` solo corre en Android/iOS y ya no se usa en la app (solo en sus
  pruebas, con `sqflite_common_ffi`). Para UI rápida sigue sirviendo
  `flutter run -d chrome`; para datos reales, emulador Android.
- Ruido de Logcat `BLASTBufferQueue ...` viene del sistema Android, no del
  proyecto.
- Pantalla lenta en equipos Transsion/Tecno (GPU Mali): probar
  `flutter run --profile` o `--no-enable-impeller`.
- Deuda técnica consciente: "Mis artículos" aún filtra por `vendedorPropio` y
  la búsqueda en Firestore es en memoria (no hay `LIKE`); resolver en
  Avance 9 (`PROGRESO.md` §11).
