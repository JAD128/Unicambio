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
flutter test      # -> All tests passed!  (95 pruebas)
```

No hay CI de pruebas: `analyze` + `test` son la única verificación local.
Ejecutar ambos tras cada cambio, en ese orden. `codemagic.yaml` solo genera el
IPA de iOS; no sustituye esta verificación.

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
- "Mis artículos" filtra por `uidAutor == provider.uidActual`; al publicar se
  usa `provider.vendedorActual` (displayName real). `main.dart` llama
  `configurarUsuario(...)` al restaurar/iniciar sesión.
- **Búsqueda avanzada (Avance 14):** la UI solo llama a
  `provider.actualizarBusqueda/seleccionarCategoria/actualizarFiltros/cargarMas`.
  El provider envía `ConsultaArticulos` al repositorio y recibe
  `PaginaArticulos(articulos, cursor, hayMas)`; el cursor es opaco. `texto` se
  filtra en Dart (título + descripción) porque Firestore no tiene `LIKE`; el
  orden por título se fuerza a precio cuando hay rango.
- **Paginación total (Avance 15):** el provider ya no expone `todos` ni llama a
  `obtenerTodos()`. Inicio, "Mis artículos" y favoritos usan
  `PaginaArticulos`; `cargarMis/cargarFavoritos` reinician la página,
  `cargarMasMis/cargarMasFavoritos` siguen el cursor y `refrescarArticulo(id)
  actualiza el detalle por id. `observarTodos()` sigue vivo como señal de
  invalidación en tiempo real (deuda conocida: aún lee la colección completa).
- **Estados de publicación (Avance 16):** `Articulo.estado` usa
   `EstadoPublicacion.disponible|finalizado` (SQLite v5, valor por defecto

  `disponible`). La etiqueta depende del tipo: `Disponible`, `Vendido`,
  `Intercambiado` o `Entregado`. `provider.cambiarEstado(id, estado)` es la
  única vía de cambio; "Mis artículos" tiene la acción y el detalle desactiva
   "Contactar al vendedor" cuando está finalizado. No hay caducidad ni filtro
   por estado en Inicio.
- **WhatsApp + sugerencias in-app (Avance 17):** `url_launcher` abre `wa.me`;
   el número es opcional, autodeclarado, se guarda en `usuarios/{uid}` y solo
   se muestra completo en Mi perfil. El detalle contacta/Comparte solo texto
   (sin dominio ni deep link) y solo si está disponible y no es propio.
   `PerfilProvider` + `ArticulosProvider.cargarNovedades` gestionan la bandeja;
   toggle apagado por defecto y todas las categorías al activar. No hay
      FCM/APNs/push ni verificación SMS; eso queda para otro avance.
 Elaborado con
   `LanzadorWhatsapp` inyectable y SQLite v5 (`creadoEn`).

- Las fotos viven en **Supabase Storage** (`AlmacenamientoImagenes`, API REST
  con `http`) y la URL en `Articulo.imagenUrl` (Firestore y SQLite, esquema
  v5; `uidAutor` desde v3). Las credenciales van en `lib/config_supabase.dart` (o `--dart-define`);
  el bucket público `articulos` y sus políticas se configuran según
  `SUPABASE_SETUP.md`. Firebase Storage no se usa (Blaze no se pudo activar).
  El build de release necesita el permiso `INTERNET` en
  `android/app/src/main/AndroidManifest.xml`.
- **Visión + LLM (Avance 12):** `ServicioVision` ML Kit devuelve etiquetas + OCR
  y `ServicioVisionConLlm` (`lib/datos/servicio_vision_con_llm.dart`) decora ese
  resultado con una sugerencia del Worker. `ClienteSugerenciasLlm` envía la
  imagen en base64 junto al **ID token de Firebase** a
  `https://unicambio-sugerencias.unicambiodm26.workers.dev/sugerencias`; la API
  key solo existe como secreto `GEMINI_API_KEY` en Cloudflare. Si falla el
  Worker, `ResultadoVision` conserva ML Kit y `SugeridorPublicacionLlm` usa el
  respaldo local. `PlantillaGeneradorDescripcion` sigue vigente para cambios de
  tipo/categoría/título y cuando no hay respuesta del LLM.
- **Formulario y estética (Avance 18):** `lib/tema/tema_app.dart` concentra el
  tema iOS-inspired (fondo agrupado, superficies blancas, esquinas suaves);
  `lib/tema/adaptativo.dart` da hojas Cupertino en iOS y Material en
  Android/web, iconos por plataforma y ancho máximo en web.
  `lib/utilidades/validadores_formulario.dart` contiene las reglas puras del
  formulario (título 5-80, descripción 10-1000, precio ≤ 99,999,999) y
  `PantallaPublicar` usa keys para llevar el scroll al primer campo inválido.
- API y getters exactos: ver `PROGRESO.md` §7 antes de tocar provider o
  repositorio.

## Pruebas (peculiaridades)

- `test/articulo_repositorio_test.dart` prueba el repositorio real vía
  `sqflite_common_ffi`: requiere `sqfliteFfiInit()` +
  `databaseFactory = databaseFactoryFfi` en `setUpAll`, y borra la BD en cada
  `setUp` con `BaseDatos.instancia.eliminar()`.
- Tests de provider y widgets usan `ArticuloRepositorioMemoria` (SQLite no
  corre en el entorno de test sin ffi) y `PerfilRepositorioMemoria`.
- `PantallaDetalleArticulo` acepta `lanzador:`; las pruebas usan un
  `LanzadorWhatsapp` falso. Las URLs puras se prueban en
  `test/lanzador_whatsapp_test.dart`.
- La lógica de visión se prueba sin ML Kit:
  `sugeridor_publicacion_test.dart`, `generador_descripcion_test.dart` y
  `panel_sugerencias_test.dart`. La parte LLM se prueba con `MockClient` en
  `cliente_sugerencias_llm_test.dart`, `cache_sugerencias_llm_test.dart`,
  `servicio_vision_con_llm_test.dart` y `sugeridor_publicacion_llm_test.dart`.
  Para inyectar dependencias en pruebas, `PantallaPublicar` acepta
  `servicioVision:`, `generadorDescripcion:` y `sugeridor:`.
- Las reglas del formulario se prueban sin widgets en
  `test/validadores_formulario_test.dart`.
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
  pegarlas en la consola). Sin sesión, leer/escribir falla por diseño. Los
  índices compuestos de filtros viven en `firestore.indexes.json`; desplegar con
  `firebase deploy --only firestore:indexes`.
- `sqflite` solo corre en Android/iOS y ya no se usa en la app (solo en sus
  pruebas, con `sqflite_common_ffi`). Para UI rápida sigue sirviendo
  `flutter run -d chrome`; para datos reales, emulador Android.
- Ruido de Logcat `BLASTBufferQueue ...` viene del sistema Android, no del
  proyecto.
- Pantalla lenta en equipos Transsion/Tecno (GPU Mali): probar
  `flutter run --profile` o `--no-enable-impeller`.
- ML Kit Vision solo corre en Android/iOS: en Chrome no se analiza la foto
  (la UI lo evita con `kIsWeb`). El análisis es on-device y no necesita API
  key. Las etiquetas llegan en inglés; el mapeo a categorías está en
  `sugeridor_publicacion.dart`.
- El proxy ya está desplegado en
  `https://unicambio-sugerencias.unicambiodm26.workers.dev` y se puede cambiar
  con `--dart-define=UNICAMBIO_LLM_URL=...` (`lib/config_llm.dart`). Nunca
  escribas la key de Gemini en Flutter: solo el Worker la conoce. Si el Worker
  no responde, la publicación sigue funcionando con las plantillas locales. En
  `proxy_gemini/` solo se versiona `.dev.vars.example`; `.dev.vars`,
  `node_modules/` y `.wrangler/` están ignorados.
- iOS tiene scaffold (`ios/`, Bundle ID `com.unicambio.unicambio`, target 15.0),
  Firebase/Google Sign-In configurados y un workflow `ios-unsigned` en
  `codemagic.yaml` que produce `unicambio.ipa` sin firma para Sideloadly. Los
  plugins ML Kit 1.0.3 exigen SwiftPM `9.0.3`;
  `scripts/download_mlkit_bundles.sh` baja los 3 bundles a `ios/mlkit_bundles`,
  `codemagic.yaml` los copia en `Runner.app` después del build y
  `scripts/configure_ios_mlkit.rb` registra `GoogleService-Info.plist` con
   `xcodeproj`.
- El logo definitivo debe reemplazar `assets/logo/unicambio.png` y
  `assets/logo/unicambio_foreground.png`; luego ejecutar
  `dart run flutter_launcher_icons` y `dart run flutter_native_splash:create`.
- Deuda técnica consciente: la búsqueda en Firestore es en memoria (no hay

  `LIKE`); resolver en un avance futuro (`PROGRESO.md` §11). La paginación ya es
  real, pero `todos` sigue leyendo la colección completa.
