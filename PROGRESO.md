# PROGRESO DEL PROYECTO — UniCambio

> Documento de contexto y bitácora. Léelo completo al retomar el trabajo para
> no perder el hilo. Actualízalo al cerrar cada avance.

Última actualización: **Avance 18** (formulario validado, estética iOS-inspired
adaptable, iconos/splash) junto con la corrección de índices de Firestore y el
diagnóstico de `failed-precondition`. Firebase/Google/ML Kit en iOS ya fueron
validados en el iPhone.

---

## 1. Qué es el proyecto

**UniCambio** es una app **Flutter** para estudiantes universitarios: permite
**vender, intercambiar o regalar** artículos entre compañeros.

- Directorio: `C:\Users\juand\Desktop\U\10mo\Desarrollo movil\Proyecto_Unicambio`
- Paquete Dart: `unicambio` · organización `com.unicambio`
- Plataformas habilitadas: `android`, `web`, `ios` (Firebase y Google Sign-In configurados)
- Flutter 3.47.6 · Dart SDK `^3.13.0`

---

## 2. Estado actual (resumen)

| Avance | Alcance | Estado |
|---|---|---|
| 1 — Interfaz visual | 5 pantallas, tema Material 3 | ✅ Hecho |
| 2 — Persistencia local | Modelo + SQLite (`sqflite`) + repositorio | ✅ Hecho |
| 3 — Estado global | `ArticulosProvider` (provider / ChangeNotifier) | ✅ Hecho |
| 4 — Conectar la UI | Pantallas leyendo/escribiendo por el provider | ✅ Hecho (reconectado) |
| 5 — Pruebas | Repositorio (ffi) + provider + widgets | ✅ Hecho |
| 6 — Autenticación | Firebase Auth (correo/contraseña + Google, sesión, reset) | ✅ Hecho |
| 7 — Backend/nube | Firestore (`ArticuloRepositorioNube` + favoritos por usuario) | ✅ Hecho |
| 8 — Fotos reales | Selector, Supabase Storage, URL y migración SQLite | ✅ Hecho (falta crear bucket y políticas) |
| 9 — Perfil y vendedor | `uidAutor`, perfil editable y nombre real | ✅ Hecho |
| 10 — Visión (ML Kit) | Etiquetado + OCR y sugerencias en el formulario | ✅ Hecho |
| 11 — Build iOS | Scaffold iOS, Firebase/Google, ML Kit y Codemagic | ✅ Hecho (IPA validado en iPhone) |
| 12 — Sugerencias LLM (proxy) | Worker REST Gemini + cliente Flutter | ✅ Hecho (58 pruebas) |
| 13 — Cierre iOS-ready | `.gitignore`, Gradle/AGP y docs del build | ✅ Hecho |
| 14 — Búsqueda avanzada | Filtros, orden, cursor y panel en Inicio | ✅ Hecho (67 pruebas) |
| 15 — Paginación total | Sin `todos`: Inicio, Mis artículos y favoritos por cursor | ✅ Hecho (71 pruebas) |
| 16 — Estados de publicación | `disponible`/`finalizado`, etiquetas y acciones | ✅ Hecho (73 pruebas) |
| 17 — WhatsApp + sugerencias | Contacto opcional, compartir texto y novedades in-app | ✅ Hecho (86 pruebas) |
| 18 — Formulario y estética | Validaciones, tema iOS-inspired adaptable e iconos/splash | ✅ Hecho (95 pruebas) |

> **Incidente del Avance 6**: al implementar la autenticación se reescribieron
> `main.dart` y las pantallas usando datos de ejemplo estáticos
> (`articulosEjemplo`), desconectando la UI del provider/SQLite. Se detectó
> analizando el código (no existía `ChangeNotifierProvider` en `lib/`) y se
> corrigió reconectando todo. Los archivos de datos/provider nunca se
> borraron; solo faltaba el cableado.

Verificación más reciente:

```bash
flutter analyze   # -> No issues found!
flutter test      # -> All tests passed!  (95 pruebas)
```

---

## 3. Funcionalidades actuales (todas funcionales)

- Ver artículos (Firestore; memoria como respaldo si Firebase no arranca).
- **Buscar** por título (búsqueda dinámica al escribir).
- **Filtrar** por categoría con chips.
- Ver **detalle** del artículo (foto real, precio, descripción, vendedor).
- **Marcar/desmarcar favoritos** (se refleja en toda la app).
- **Crear** publicación (con validación del formulario y foto opcional).
- **Editar** publicación.
- **Eliminar** publicación (con diálogo de confirmación).
- Navegación inferior: Inicio / Favoritos / Mis artículos.
- Botón flotante **Publicar**.
- **Sugerencias de la foto (Avance 10):** al elegir una foto en Android,
  ML Kit detecta etiquetas y texto, y el formulario ofrece categoría, título,
  descripción y líneas de OCR. Cada campo se aplica solo si el usuario toca
  "Usar"/"Reemplazar"; nada se rellena automáticamente.
- **WhatsApp opcional (Avance 17):** en Mi perfil se puede guardar un celular
  colombiano autodeclarado (sin verificación). El detalle muestra "Abrir
  WhatsApp" solo para publicaciones disponibles de otros usuarios; también se
  puede compartir el artículo como texto por `wa.me`, sin dominio ni deep link.
- **Sugerencias in-app (Avance 17):** interruptor apagado por defecto en Mi
  perfil; al activarlo se seleccionan todas las categorías y Inicio muestra una
  bandeja con publicaciones recientes. No hay FCM/APNs/push: solo se consulta
  con la app abierta y se marca `ultimaVista` al abrir la bandeja.

## 3.1 Funcionalidades de la autenticación (Avance 6)

- Crear cuenta, iniciar sesión, recuperar contraseña y cerrar sesión
  (Firebase Auth, correo/contraseña).
- **Continuar con Google**: en Android `google_sign_in` 7.x
  (`initialize()` en `main()`, luego `authenticate()` → `idToken` →
  `GoogleAuthProvider.credential` → `signInWithCredential`); en web
  `signInWithPopup(GoogleAuthProvider())` (el `authenticate()` de
  google_sign_in no existe en web). Configuración manual: `FIREBASE_SETUP.md`.
- La sesión persiste entre reinicios; `main.dart` abre Inicio si hay sesión.
- El registro guarda el nombre como `displayName` (se muestra en el saludo).
- Errores de Firebase traducidos a mensajes en español.

---

## 4. Arquitectura (patrón repositorio + estado global)

```
Pantallas (UI)
      │  context.watch / context.read
      ▼
ArticulosProvider (ChangeNotifier) — estado global
      │  usa el contrato
      ▼
ArticuloRepositorio  (interfaz abstracta)
      ├── ArticuloRepositorioNube     → Firestore (app real)
      ├── ArticuloRepositorioSqflite  → SQLite (histórico; solo sus pruebas)
      └── ArticuloRepositorioMemoria  → lista en RAM (pruebas / sin Firebase)
```

Reglas de oro:
- La UI **nunca** habla con SQLite directamente; siempre pasa por el provider.
- El provider **nunca** conoce detalles de SQL; solo la interfaz del repositorio.
- Para migrar a la nube: crear `ArticuloRepositorioNube` y cambiarlo en
  `main.dart`. **Las pantallas no se tocan.**
- Las pantallas usan `context.watch<ArticulosProvider>()` para reaccionar y
  `context.read<ArticulosProvider>()` para acciones.

---

## 5. Estructura de archivos

```
Proyecto_Unicambio/
├── lib/
│   ├── main.dart                          # Arranque: Firebase + repo (nube o memoria) + provider
│   ├── firebase_options.dart              # Opciones Firebase por plataforma (GENERADO; no editar a mano)
│   ├── config_supabase.dart               # URL + clave anon de Supabase (solo fotos)
│   ├── modelos/
│   │   ├── articulo.dart                  # Articulo + enum TipoPublicacion + vendedorPropio
│   │   ├── categoria.dart                 # enum Categoria + extensión UI (etiqueta, icono)
│   │   └── vision.dart                    # Etiquetas, resultado de ML Kit y sugerencias
│   ├── datos/
│   │   ├── base_datos.dart                # Singleton BaseDatos: abre unicambio.db y crea la tabla
│   │   ├── articulo_repositorio.dart      # Interfaz ArticuloRepositorio + ArticuloRepositorioSqflite
│   │   ├── articulo_repositorio_nube.dart # Implementación sobre Cloud Firestore (app real)
│   │   ├── articulo_repositorio_memoria.dart  # Implementación en RAM (pruebas / sin Firebase)
│   │   ├── almacenamiento_imagenes.dart   # Sube fotos a Supabase Storage (API REST) y devuelve la URL
│   │   ├── servicio_vision.dart           # Interfaz ServicioVision + implementación ML Kit
│   │   ├── sugeridor_publicacion.dart     # Etiquetas/OCR → categoría y título sugeridos
│   │   ├── generador_descripcion.dart     # Interfaz + plantillas locales de descripción
│   │   └── articulos_ejemplo.dart         # Lista articulosEjemplo (8) — solo para memoria en pruebas
│   ├── estado/
│   │   └── articulos_provider.dart        # Estado global (ChangeNotifier)
│   ├── tema/
│   │   └── tema_app.dart                  # Tema Material 3
│   ├── widgets/
│   │   ├── campo_busqueda.dart            # Barra de búsqueda (callback alCambiar)
│   │   ├── chip_categoria.dart            # Chip seleccionable (callback alSeleccionar)
│   │   ├── estado_placeholder.dart        # Mensaje centrado (vacío / error)
│   │   ├── panel_sugerencias.dart         # Sugerencias de la foto con "Usar" por campo
│   │   └── tarjeta_articulo.dart          # Tarjeta (imagen, insignia, favorito, precio)
│   └── pantallas/
│       ├── pantalla_autenticacion.dart    # Inicio, registro, reset y Google (Firebase)
│       ├── pantalla_inicio.dart           # Inicio: buscador + chips + cuadrícula + estados
│       ├── pantalla_favoritos.dart        # Favoritos (desde provider)
│       ├── pantalla_mis_articulos.dart    # Mis artículos: editar/estado/eliminar
│       ├── pantalla_detalle_articulo.dart # Detalle (favorito y estado conectados)
│       ├── pantalla_perfil.dart           # Perfil: nombre/foto editable y cerrar sesión
│       └── pantalla_publicar.dart         # Formulario crear/editar con foto (galería/cámara)
└── test/
    ├── widget_test.dart                   # 2 pruebas de humo (UI con provider en memoria)
    ├── articulos_provider_test.dart       # 17 pruebas del estado global
    ├── almacenamiento_imagenes_test.dart  # 5 pruebas de subida/borrado (MockClient)
    ├── articulo_repositorio_test.dart     # 18 pruebas de SQLite (con ffi)
    ├── panel_filtros_test.dart            # 3 pruebas del panel de búsqueda avanzada
    ├── sugeridor_publicacion_test.dart    # 9 pruebas de etiquetas/OCR
    ├── generador_descripcion_test.dart    # 5 pruebas de plantillas
    └── panel_sugerencias_test.dart        # 5 pruebas de widgets del panel
```

---

## 6. Modelo de datos y esquema SQLite

**Clase `Articulo`** (inmutable, `lib/modelos/articulo.dart`):

| Campo | Tipo Dart | Notas |
|---|---|---|
| `id` | `String` | PK. En creación: `'art_${DateTime.now().microsecondsSinceEpoch}'` |
| `titulo` | `String` | |
| `descripcion` | `String` | |
| `precio` | `double` | 0 si no aplica |
| `categoria` | `Categoria` | enum |
| `tipo` | `TipoPublicacion` | enum |
| `vendedor` | `String` | Nombre visible de la cuenta (o correo; respaldo `'Estudiante'`) |
| `esFavorito` | `bool` | |
| `imagenUrl` | `String?` | URL pública en Supabase Storage; null si no tiene foto |
| `uidAutor` | `String?` | `uid` de Firebase del autor; null en datos locales |
| `estado` | `EstadoPublicacion` | `disponible` (default) o `finalizado` |
| `creadoEn` | `DateTime?` | Fecha de publicación; `null` en artículos históricos |

- `TipoPublicacion`: `venta`, `intercambio`, `regalo` (con etiqueta/icono/color).
- `EstadoPublicacionUI.etiquetaPara(tipo)`: "Disponible" o, si finalizado,
  "Vendido"/"Intercambiado"/"Entregado" según el tipo.
- `Categoria`: `libros`, `apuntes`, `tecnologia`, `ropa`, `hogar`, `deportes`, `otros`.
- `precioTexto`: regalo → "Gratis"; 0 → "A convenir"; resto → "$ N".
- Serialización: enums como `.name`; `esFavorito` como 0/1 (SQLite no tiene bool);
  `imagenUrl`, `uidAutor` y `creadoEn` son opcionales (null si no aplican). Los
  documentos antiguos sin `estado` se leen como `disponible`; los que no tienen
  `creadoEn` no aparecen en sugerencias. `fechaPublicacion` usa el epoch como
  respaldo para comparar artículos históricos.

**Tabla `articulos`** (creada en `base_datos.dart`, versión de esquema `5`; las
migraciones agregan `imagenUrl` (v2), `uidAutor` (v3), `estado` (v4) y
`creadoEn` (v5)):

```sql
CREATE TABLE articulos (
  id          TEXT    PRIMARY KEY,
  titulo      TEXT    NOT NULL,
  descripcion TEXT    NOT NULL,
  precio      REAL    NOT NULL DEFAULT 0,
  categoria   TEXT    NOT NULL,
  tipo        TEXT    NOT NULL,
  vendedor    TEXT    NOT NULL,
  esFavorito  INTEGER NOT NULL DEFAULT 0,
  imagenUrl   TEXT,
  uidAutor    TEXT,
  estado      TEXT NOT NULL DEFAULT 'disponible',
  creadoEn    TEXT
)
```

Archivo de la BD: `unicambio.db` (vía `getDatabasesPath()`).

---

## 7. API de referencia (para no equivocarse)

**`ArticuloRepositorio`** (`lib/datos/articulo_repositorio.dart`):
`obtenerTodos()`, `obtenerFavoritos()`, `obtenerPorId(id)`, `insertar(a)`,
`actualizar(a)`, `eliminar(id)`, `alternarFavorito(id)`,
`buscarPagina(consulta, {cursor})` → `PaginaArticulos(articulos, cursor,
hayMas)`, `buscarPaginaFavoritos({limite, cursor})`,
`buscar(texto, {categoria})` (histórico),
`filtrarPorCategoria(categoria)`,
`buscarNovedades({desde, categorias, excluirUid, limite})`, `enTiempoReal`
(getter) y `observarTodos()`
(stream en tiempo real; solo la nube lo implementa). `ConsultaArticulos` lleva
texto, categoría, precio mínimo/máximo, orden, `uidAutor` y `limite` (12 en la
UI); `firma` incluye `uidAutor` para no mezclar cachés de cuentas.

**`AlmacenamientoImagenes`** (`lib/datos/almacenamiento_imagenes.dart`):
`subir({articuloId, bytes, nombreArchivo, tipoContenido})` → sube por REST a
Supabase (`/{uid}/{articuloId}/{hora}.{ext}` en el bucket `articulos`) y
devuelve la URL pública. Configuración: `lib/config_supabase.dart`
(`supabaseUrl`, `supabaseAnonKey`) o `--dart-define`. Ver `SUPABASE_SETUP.md`.

**Visión (Avance 10)**:
- `ServicioVision` (`lib/datos/servicio_vision.dart`): `analizar(ruta)` →
  `ResultadoVision(etiquetas, lineasTexto)` y `cerrar()`. La implementación
  `ServicioVisionMlKit` usa `ImageLabeler` + `TextRecognizer` (latín) on-device.
- `SugeridorPublicacion` (`lib/datos/sugeridor_publicacion.dart`):
  `sugerir(ResultadoVision)` → `SugerenciasPublicacion(categoria, titulo,
  lineasTexto)`. Lógica pura, sin Flutter ni ML Kit.
- `GeneradorDescripcion` (`lib/datos/generador_descripcion.dart`):
  `generar({titulo, categoria, tipo})`. Hoy `PlantillaGeneradorDescripcion`
  compone el texto localmente; se puede sustituir por un LLM sin tocar la UI.
- `PanelSugerencias` (`lib/widgets/panel_sugerencias.dart`): recibe las
  sugerencias y avisa con `alAplicarCategoria`, `alAplicarTitulo`,
  `alAplicarDescripcion` y `alDescartar`.

**`ArticulosProvider`** (`lib/estado/articulos_provider.dart`):
- Getters: `articulos` (página visible), `mios`, `favoritos`,
  `cargando`, `cargandoMas`, `cargandoMis`, `cargandoMasMis`,
  `cargandoFavoritos`, `cargandoMasFavoritos`, `error`, `textoBusqueda`,
  `categoriaSeleccionada`, `precioMinimo`, `precioMaximo`, `orden`, `hayMas`,
  `hayMasMis`, `hayMasFavoritos`, `novedades`, `hayNovedades`,
  `cargandoNovedades`, `listaVacia`, `articuloPorId(id)`, `uidActual`,
  `vendedorActual`. Ya no existe `todos`.

- Métodos: `iniciar()`, `actualizarBusqueda(texto)`,
  `seleccionarCategoria(categoria?)`,
  `actualizarFiltros({precioMinimo, precioMaximo, orden})`, `limpiarFiltros()`,
  `cargarMas()`, `cargarMis()`, `cargarMasMis()`, `cargarFavoritos()`,
  `cargarMasFavoritos()`, `cargarNovedades({activas, categorias, desde?})`,
  `refrescarArticulo(id)`, `insertar(a)`, `actualizar(a)`,
  `cambiarEstado(id, estado)`, `eliminar(id)`, `alternarFavorito(id)`,
  `configurarUsuario({uid, nombre?, correo?})`.

- Interno: `_recargarPagina()`, `_recargarMis()`, `_recargarFavoritos()` y
  `_ejecutar(...)` manejan `cargando`/`error`/`notifyListeners()`; tokens
  independientes descartan respuestas viejas al escribir rápido. `observarTodos()`
  solo invalida listas (deuda: aún lee la colección completa).

**Perfil (Avance 17)**:
- `PerfilRepositorio` (`lib/datos/perfil_repositorio.dart`): `obtener(uid)` y
  `guardar(perfil)`. Implementaciones: `PerfilRepositorioNube` (usa
  `usuarios/{uid}` con `set(merge: true)`) y `PerfilRepositorioMemoria`.
- `PerfilProvider` (`lib/estado/perfil_provider.dart`): getters `perfil`,
  `telefono`, `sugerenciasActivas`, `categoriasSugerencias`, `ultimaVista`,
  `cargando`, `error`; métodos `iniciar(uid)`, `guardarTelefono(texto)`,
  `actualizarPreferencias({activas, categorias})`, `marcarVisto()`,
  `telefonoDe(uid)` y `limpiar()`.
- `LanzadorWhatsapp` (`lib/datos/lanzador_whatsapp.dart`): `contactar` y
  `compartir` con `url_launcher`; `LanzadorWhatsappUrl` es la app real y se
  puede sustituir por un fake en pruebas. `normalizarTelefonoColombiano`
  acepta 10 dígitos o 12 con `57`.

**`BaseDatos`** (singleton): `BaseDatos.instancia.db`, `.cerrar()`, `.eliminar()`.

---

## 8. Cómo ejecutar y probar

```bash
flutter pub get
flutter run              # dispositivo/emulador Android (Firestore + Storage reales)
flutter run -d chrome    # navegador (rápido para ver la UI; en web sqflite no corre igual)
flutter analyze          # No issues found!
flutter test             # All tests passed!
```

Dependencias (`pubspec.yaml`): `cupertino_icons`, `firebase_core`,
`firebase_auth`, `cloud_firestore`, `google_sign_in`, `provider`,
`http`, `image_picker`, `sqflite`, `path`, `google_mlkit_image_labeling`,
`google_mlkit_text_recognition`; dev: `flutter_lints`, `sqflite_common_ffi`.

**Prueba manual sugerida:** buscar → filtrar por chip → abrir detalle → marcar
favorito → publicar artículo con foto (en Android, aplicar sugerencias de
categoría/título/descripción) → editar/eliminar en "Mis artículos". En este
equipo no hay emulador ni dispositivo Android conectado: se verificó el build
`flutter build apk --debug` y `flutter build web`, pero la prueba táctil de
ML Kit queda pendiente en un teléfono/emulador.

---

## 9. Pruebas (95 en total)

- `articulo_repositorio_test.dart` (20): usa `sqflite_common_ffi`
  (`sqfliteFfiInit()` + `databaseFactory = databaseFactoryFfi`) y prueba el
  repositorio REAL. Limpia la BD en `setUp` con `BaseDatos.instancia.eliminar()`.
- `articulos_provider_test.dart` (19): usa `ArticuloRepositorioMemoria` y un
  fake con `StreamController` para el tiempo real; incluye filtros, páginas,
  el filtro `mios` y las novedades.
- `perfil_provider_test.dart` (5): teléfono opcional normalizado, rechazo de
  números inválidos, preferencias por defecto, todas las categorías al activar,
  `ultimaVista` y caché del teléfono de otros vendedores.
- `lanzador_whatsapp_test.dart` (3): normalización de celulares colombianos y
  construcción de URIs `wa.me` sin abrir la app externa.
- `almacenamiento_imagenes_test.dart` (5): subida/borrado en Supabase con
  `MockClient` (URL, cabeceras, error HTTP, configuración faltante y enlaces
  ajenos).
- `sugeridor_publicacion_test.dart` (9): mapeo etiquetas→categoría, umbrales,
  títulos desde OCR, rechazo de precios/tallas, normalización y resultado vacío.
- `generador_descripcion_test.dart` (5): plantillas por tipo/categoría, texto
  sin precio y variante estable.
- `panel_sugerencias_test.dart` (5): "Usar"/"Reemplazar"/"Descartar", líneas
  de OCR tocables y panel oculto sin sugerencias.
- `panel_filtros_test.dart` (3): aplica orden/precio, rechaza rango invertido y
  avisa al limpiar.
- `cliente_sugerencias_llm_test.dart` (3): petición al Worker con token/foto,
  falta de token y error HTTP con `MockClient`.
- `cache_sugerencias_llm_test.dart` (2): misma imagen/tipo reutiliza entrada y
  fotos o tipos distintos no colisionan.
- `servicio_vision_con_llm_test.dart` (2): sugerencia agregada con caché y
  conservación del resultado ML Kit cuando el proxy falla.
- `sugeridor_publicacion_llm_test.dart` (2): prioridad del LLM y respaldo al
  sugeridor local.
- `widget_test.dart` (3): smoke tests de UI; envuelven pantallas con ambos
  providers en memoria y comprueban contacto/compartir por WhatsApp con un
  lanzador falso.
- `validadores_formulario_test.dart` (8): título 5-80, descripción 10-1000 y
  precio opcional ≤ 99,999,999 (incluye coma decimal y tipo distinto de venta).

> Nota: las pruebas de widgets usan el repositorio en memoria porque SQLite no
> corre en el entorno de test sin ffi.

---

## 10. Decisiones y notas importantes

- **Comentarios**: todo el código va comentado y documentado con `///` (el
  usuario está estudiando Flutter y pide código explicado). **No añadir
  comentarios innecesarios** en ediciones pequeñas, pero mantener el estilo.
- **Idioma**: el usuario habla español; responder en español, conciso y práctico.
- **Entrega por fases**: entregar cada fase completa (archivos + `flutter
  analyze` + `flutter test`), sin pedir confirmación en cada micro-paso.
- **Nube activa (Avance 7).** Los artículos se guardan en Cloud Firestore
  (`articulos/{id}`) y los favoritos en `usuarios/{uid}/favoritos/{id}`.
  La app **arranca vacía** (ya no hay semilla). Si Firebase no arranca
  (pruebas), `main.dart` usa `ArticuloRepositorioMemoria`.
- **"Mis artículos"** filtra por `uidAutor == provider.uidActual` (no por el
  nombre); las publicaciones usan el `displayName` real como `vendedor`.
- **Agregar dependencias** es válido si hace falta (ya se hizo con sqflite,
  provider, ffi), pero avisar/justificar.
- **Visión on-device (Avance 10).** ML Kit etiqueta y hace OCR, pero **no
  redacta** lenguaje natural. La descripción sale de
  `PlantillaGeneradorDescripcion`; `GeneradorDescripcion` queda como punto de
  extensión para un LLM futuro. No se usa Gemini Nano/AICore porque exige
  dispositivos compatibles, `minSdk 26` y APIs aún beta/alpha.
- **Nada se auto-aplica.** El panel muestra "Usar"/"Reemplazar" por campo y
  "Descartar"; si cambia la foto se ignoran resultados viejos con un token.
- **ML Kit solo corre en Android/iOS**, no en web. La pantalla usa `kIsWeb`
  para no invocar el plugin en Chrome; el build web sigue compilando.
- **No se sugiere precio** desde OCR: un número en la foto no garantiza que
  sea el precio. Las plantillas tampoco afirman estado, calidad ni ubicación.

### Problemas conocidos (no son del proyecto)
- `BLASTBufferQueue ... releaseBufferCallback without corresponding submitted
  buffer`: ruido de **Logcat del sistema Android** (SurfaceFlinger/BLAST). No es
  de Flutter ni causa lentitud.
- Desplazamiento lento en el dispositivo: usar `flutter run --profile`
  (o release), ajustes del dispositivo (equipos Transsion/Tecno con GPU Mali) y
  probar `flutter run --no-enable-impeller`.

### Git
- El repo está **inicializado**. Aviso `LF will be replaced by CRLF` es normal
  en Windows.
- **No hacer commit** salvo que el usuario lo pida explícitamente.

---

## 11. Hoja de ruta — lo que falta por implementar

> Estado: **NO iniciado** salvo que se indique lo contrario. Al empezar cada
> avance, acordar el alcance con el usuario y entregar por fases con
> `flutter analyze` + `flutter test` en verde.

### Avance 6 — Autenticación de usuarios ✅ HECHO
- Login y registro (correo/contraseña), recuperar contraseña, cerrar sesión.
- **Continuar con Google** (`google_sign_in` 7.2.0 en Android;
  `signInWithPopup` en web). Configuración completada y probada por la
  usuaria: proveedor Google activo, SHA-1 de depuración registrado y
  `google-services.json` con `oauth_client`. Ver `FIREBASE_SETUP.md`.
- Firebase Auth; sesión persistente; `displayName` en el saludo.
- Pantalla: `pantalla_autenticacion.dart`; puerta en `main.dart`
  (`_PuertaAutenticacion` con `authStateChanges()`).
- Configuración compilada: proyecto `unicambio-2f543`, apps Android/Web.
  Ver `FIREBASE_SETUP.md` y la sección de Firebase del `README.md`.

### Avance 7 — Backend / nube (sincronización) ✅ HECHO
- **`ArticuloRepositorioNube`** (`lib/datos/articulo_repositorio_nube.dart`)
  implementa `ArticuloRepositorio` sobre Cloud Firestore. `main.dart` lo elige
  cuando Firebase arrancó; la interfaz y las pantallas no cambiaron.
- **Estructura:** `articulos/{id}` (título, descripción, precio, categoría,
  tipo, vendedor, `uidAutor`) y `usuarios/{uid}/favoritos/{articuloId}`.
- **Favoritos por usuario:** `esFavorito` ya no se guarda en el artículo; el
  repositorio marca el flag en memoria al leer según los favoritos del uid.
- **Ids:** los asigna Firestore (se ignoran los ids con hora del modelo).
- **Semilla eliminada:** `semilla.dart` borrado; la app arranca vacía.
- **Sesión:** la puerta de autenticación recarga el provider cuando aparece
  un usuario (`iniciar()`), también al restaurar la sesión.
- **Errores de red** traducidos en el provider (`network-request-failed`,
  `permission-denied`, `unavailable`).
- **Reglas:** `firestore.rules` (leer con sesión, editar solo el dueño,
  favoritos propios). Despliegue en `FIREBASE_SETUP.md`.
- SQLite (`ArticuloRepositorioSqflite`) queda como código histórico y pruebas;
  la app ya no lo usa.
- Estado: ✅ Hecho.

### Avance 8 — Fotos reales de los artículos ✅ HECHO
- Selector con `image_picker` (galería o cámara), vista previa y opción de
  quitar la foto.
- Subida a **Supabase Storage** por REST (`http`), sin SDK ni login en
  Supabase; la URL pública se guarda en `imagenUrl` (Firestore y SQLite v4).
- Reemplaza la "imagen simulada" (degradado + ícono) por la foto real en la
  tarjeta y el detalle.
- Pendiente manual: crear el bucket público `articulos` y aplicar las
  políticas SQL (`SUPABASE_SETUP.md`).
- Estado: ✅ Implementado.

### Avance 9 — Perfil de usuario y vendedor real ✅ HECHO
- Publicar usa el `displayName` real (respaldo: correo / `'Estudiante'`) y
  guarda `uidAutor` en el modelo (Firestore y SQLite v3).
- "Mis artículos" filtra por `uidAutor == uid` de la sesión.
- Pantalla `pantalla_perfil.dart` (avatar en Inicio): editar nombre, cambiar o
  quitar foto (Supabase) y cerrar sesión; muestra publicaciones y favoritos.
- Estado: ✅ Hecho.

### Avance 10 — Visión por computadora con Google ML Kit ✅ HECHO
- **Etiquetado** (`google_mlkit_image_labeling`) y **OCR**
  (`google_mlkit_text_recognition`, script latino) on-device al elegir una foto
  nueva en Android. No se analizan URLs de fotos ya guardadas.
- `SugeridorPublicacion` traduce etiquetas inglesas a las 7 categorías, exige
  confianza mínima y margen sobre la segunda, y propone un título desde el OCR
  (rechaza precios, URLs, tallas y metadatos) o desde la mejor etiqueta.
- `PanelSugerencias` muestra categoría, título, descripción y texto OCR. El
  usuario aplica cada campo con "Usar"/"Reemplazar" o descarta todo; no hay
  auto-relleno. Las líneas de OCR también se pueden usar como título.
- La descripción se genera con `GeneradorDescripcion` (plantillas locales por
  tipo y categoría) y se recalcula si cambia el tipo, la categoría o el título.
  No se sugiere precio.
- Web: se evita el plugin con `kIsWeb`; en Chrome se muestra un aviso y el
  formulario sigue funcionando. El servicio se crea de forma perezosa y se
  cierra en `dispose`; un token descarta resultados de una foto anterior.
- Verificación: `flutter analyze` → `No issues found!`, `flutter test` →
  `All tests passed!` (58 en ese momento), `flutter build apk --debug` y
  `flutter build web`
  correctos. Prueba manual en Android pendiente (no hay emulador/dispositivo
  conectado en este equipo).
- Estado: ✅ Hecho.

### Build iOS / Codemagic ✅ HECHO
- Scaffold generado con `flutter create --org com.unicambio --platforms ios .`.
  Bundle ID: `com.unicambio.unicambio`; deployment target: iOS 15.0.
- `scripts/download_mlkit_bundles.sh` descarga los bundles que exigen los
  plugins ML Kit 1.0.3: `MLKitImageLabelingResources.bundle`,
  `MLKitObjectDetectionCommonResources.bundle` y `LatinOCRResources.bundle`
  desde la release `9.0.3` de `d-date/google-mlkit-swiftpm` en
  `ios/mlkit_bundles`. Descarga probada.
- `scripts/configure_ios_mlkit.rb` agrega `ios/Runner/GoogleService-Info.plist`
  con `SOURCE_ROOT` y fija `OTHER_LDFLAGS` (`-ObjC`, `-all_load`) e iOS 15.0.
  Ya no registra los bundles en Xcode: requiere la gema `xcodeproj` y se ejecuta
  en Codemagic (no hay Ruby/Xcode en este equipo).
- `codemagic.yaml` define el workflow `ios-unsigned`: `flutter pub get`,
  `flutter analyze`, `flutter test`, descarga de bundles, configuración Ruby,
  `flutter build ios --release --no-codesign`, copia de los `.bundle` desde
  `ios/mlkit_bundles` a `Runner.app`, verificación y empaquetado de
  `unicambio.ipa`.
- `ios/Runner/Info.plist` tiene `NSCameraUsageDescription`,
  `NSPhotoLibraryUsageDescription`, `GIDClientID` y `CFBundleURLTypes` con la
  URL scheme invertida. No lleva `GIDServerClientID` porque el plist no entregó
  `SERVER_CLIENT_ID`.
- Firebase CLI autorizado y FlutterFire ejecutado con Android/iOS/Web: el caso
  iOS ya está en `lib/firebase_options.dart` y la app iOS quedó registrada como
  `1:619158453000:ios:599f8dd2c8e9cdc9f3cabd`.
- **Intentos 1 a 3:** Codemagic descargó los bundles, pero Xcode falló al
  copiarlos: primero con un grupo anidado bajo `Runner`, luego con `SOURCE_ROOT`
  y finalmente con el patrón `wrapper.cbundle` del ejemplo oficial. En los tres
  casos Xcode no resolvió la ruta de los file refs.
- **Corrección:** los bundles ya no se registran en el proyecto. El workflow los
  descarga en `ios/mlkit_bundles`, compila sin esas referencias y luego los copia
  directamente en `build/ios/iphoneos/Runner.app` antes de empaquetar. Como
  Sideloadly vuelve a firmar el IPA, no hay problema de firma.
- **Validado:** `ios-unsigned` con `c79a166` generó `unicambio.ipa`, se instaló
  con Sideloadly y el usuario confirmó que arranca desde el home en el iPhone.
- **Sideloadly/AltStore:** sin Apple Developer Program no hay TestFlight; el IPA
  se reinstala con la cuenta gratuita (validez ~7 días). Si Sideloadly cambia el
  Bundle ID al firmar, hay que registrar ese id en Firebase u ocultar Google
  Sign-In en iOS.

### Avance 14 — Búsqueda avanzada con cursor real ✅ HECHO
- `ConsultaArticulos` y `PaginaArticulos` viajan entre provider y repositorio;
  el cursor es opaco (`Object?`) para que la UI no conozca Firestore.
- Firestore usa `where` de categoría/precio, `orderBy` y `limit`. El texto se
  sigue filtrando en Dart (título + descripción) porque no hay `LIKE`: se leen
  lotes hasta completar 12 coincidencias y se devuelve el último documento como
  cursor. SQLite y memoria implementan el mismo contrato.
- Con rango de precio, `ordenEfectivo` fuerza `precio ASC` (regla de Firestore);
  por eso el panel   ofrece solo título, precio ascendente y precio descendente.
- `firestore.indexes.json` contiene los índices compuestos de categoría con
  título/precio. Desplegados con `firebase deploy --only firestore:indexes`.
- Inicio tiene panel de filtros en el ícono `tune`, contador de resultados y
  botón "Cargar más". Los cambios de filtro reinician el cursor y un token
  descarta respuestas obsoletas.
- Verificación: `flutter analyze` limpio, `flutter test` (67), builds de APK y
  web correctos.

### Avance 15 — Paginación total ✅ HECHO
- El provider ya no expone `todos` ni llama a `obtenerTodos()`. Inicio,
  "Mis artículos" y favoritos reciben `PaginaArticulos` y siguen un cursor
  opaco con `cargarMas`, `cargarMasMis` y `cargarMasFavoritos`.
- `ConsultaArticulos` añade `uidAutor` (también en `firma`) y el repositorio
  añade `buscarPaginaFavoritos({limite, cursor})`. Firestore pagina favoritos
  por `FieldPath.documentId` y omite documentos huérfanos.
- `refrescarArticulo(id)` actualiza la caché del detalle cuando el widget se
  abre desde una tarjeta. Cada lista tiene tokens propios para descartar
  respuestas viejas.
- `observarTodos()` se mantiene solo como señal de invalidación en tiempo real;
  sigue leyendo la colección completa (deuda documentada abajo).
- `firestore.indexes.json` amplía los índices con `uidAutor` solo y combinado
  con categoría, para título y precio ASC/DESC. Desplegados con
  `firebase deploy --only firestore:indexes`.

### Avance 16 — Estados de publicación ✅ HECHO
- `Articulo.estado` usa `EstadoPublicacion.disponible|finalizado` con default
  `disponible`. SQLite sube a v4 (`estado TEXT NOT NULL DEFAULT 'disponible'`);
  documentos/registros antiguos se leen como disponibles.
- `EstadoPublicacionUI.etiquetaPara(tipo)` muestra `Vendido`,
  `Intercambiado` o `Entregado` cuando está finalizado. La tarjeta y el detalle
  muestran la etiqueta; el detalle desactiva "Contactar al vendedor".
- "Mis artículos" permite alternar el estado desde el menú y cuenta solo las
  publicaciones activas. `provider.cambiarEstado(id, estado)` es la única vía
  de cambio y actualiza caché, detalle y listas.
- `firestore.rules` valida que `estado` sea `disponible` o `finalizado` al
  crear/actualizar. No hay caducidad ni filtro por estado en Inicio.
- Verificación: `flutter analyze` limpio, `flutter test` (73).

### Avance 17 — WhatsApp opcional y sugerencias in-app ✅ HECHO
- `Articulo.creadoEn` (SQLite v5, `serverTimestamp()` en Firestore) permite
  consultar publicaciones recientes. `buscarNovedades({desde, categorias,
  excluirUid, limite})` filtra fecha en Firestore con un índice de un campo;
  categoría, estado y autor se filtran en Dart (sin índices compuestos nuevos).
- `usuarios/{uid}` guarda `telefono` (opcional y autodeclarado),
  `sugerenciasActivas` (default `false`), `categoriasSugerencias` (todas al
  activar por primera vez) y `ultimaVista`. Se escribe con `set(merge: true)`
  para no tocar la subcolección `favoritos`.
- `PerfilRepositorio`/`PerfilProvider` y `MultiProvider` en `main.dart`.
  El número se normaliza a `57...`; en Mi perfil se ve completo y se avisa que
  no está verificado. `firestore.rules` permite leer cualquier perfil con
  sesión y escribir solo el propio.
- El detalle abre `https://wa.me/<numero>?text=...` solo si la publicación está
  disponible y es de otro usuario; "Compartir" usa `https://wa.me/?text=...`.
  No hay dominio propio ni deep links. `LanzadorWhatsapp` abstrae
  `url_launcher` para pruebas.
- Inicio muestra una bandeja con las novedades; al abrirla se llama a
  `marcarVisto()`. No hay FCM/APNs/Cloud Functions: si la app está cerrada no
  hay aviso. La verificación SMS y las notificaciones push quedan para después.
- Verificación: `flutter analyze` limpio, `flutter test` (86), builds de APK y
  web y `git diff --check` correctos.

### Backlog de mejoras (prioridad por definir)
- **Chat propio / verificación SMS (Firebase Phone Auth)**: hoy se usa WhatsApp
  con un número autodeclarado; no hay OTP ni identidad verificada.
- **Notificaciones push**: ya hay bandeja dentro de la app, pero falta FCM/APNs
  (y configuración APNs en iOS) para avisar con la app cerrada.
- **Validaciones extra** en el formulario (longitud, precio máximo) y manejo de
  zonas seguras.
- **Accesibilidad** (semántica, contraste) e **internacionalización** (i18n).
- **Ícono de app y splash screen** propios.
- **CI** (GitHub Actions) que corra `analyze` + `test`.
- **Pruebas**: ampliar tests de widgets (interacción real: tocar chips, favorito,
  publicar) y tests de integración.
- **Seguridad**: reglas de acceso en la nube, no exponer claves.

### Deuda técnica / limitaciones conocidas
- Búsqueda por texto en Firestore se hace en memoria (no hay `LIKE`), aunque
  ahora solo sobre lotes paginados. `observarTodos()` sigue leyendo la colección
  completa como señal de invalidación; suscribirse por usuario/consulta queda
  para un avance futuro.
- `ArticuloRepositorioSqflite` ya no se usa en la app (solo en sus pruebas);
  se conserva como referencia. `ArticuloRepositorioMemoria` se usa en pruebas
  y si Firebase no arranca.
- Al reemplazar o quitar una foto, o al eliminar el artículo, la app borra el
  archivo anterior del bucket (mejor esfuerzo). La política `fotos_delete_anon`
  permite borrar con la clave `anon`; en producción conviene restringirla al
  dueño autenticando también en Supabase.
- Las cargas reales requieren crear el bucket `articulos` y sus políticas en
  Supabase (`SUPABASE_SETUP.md`). El bucket es público y permite `insert` con
  la clave `anon` (sin login en Supabase); aceptable para el proyecto, pero en
  producción habría que autenticar también allí.

Al empezar el próximo avance: revisar esta sección, acordar el alcance y volver
a entregar por fases con `analyze` + `test` en verde.

## Actualización — Avance 6: autenticación

Implementados registro e inicio de sesión con correo/contraseña mediante
Firebase Auth, envío de correo para restablecer contraseña, cierre de sesión y
puerta de navegación basada en `authStateChanges()`. Firebase Auth restaura la
sesión persistida por su SDK. El registro guarda también el nombre visible.

Se añadieron `firebase_core` y `firebase_auth`, la pantalla
`lib/pantallas/pantalla_autenticacion.dart` y la configuración compilada
`lib/firebase_config.dart`. Para conectar una instancia real hay que ejecutar
`flutterfire configure`, habilitar Email/Password en Firebase Console y pasar
las opciones como `--dart-define`; consultar `FIREBASE_SETUP.md`. Sin opciones
la app muestra instrucciones de configuración. La colección de artículos
continúa local en SQLite y todavía no se filtra por usuario.

Verificación pendiente: el entorno trae Dart 3.13.2 aunque el mínimo previo era
3.13.5. Se bajó el mínimo a 3.13.0 para permitir resolver dependencias, pero
`flutter analyze` quedó esperando sin salida y no se pudo confirmar el análisis
ni ejecutar pruebas en esta sesión.

Resultado de verificación posterior a la implementación: `flutter pub get`
resolvió las dependencias, `flutter analyze` terminó con `No issues found!` y
`flutter test` terminó con `All tests passed!` (2 pruebas presentes en el árbol
actual). El mínimo de Dart del `pubspec.yaml` se fijó en `^3.13.0` para coincidir
con el SDK instalado en este equipo.

La nota anterior sobre la verificación pendiente quedó superada al repetir los
comandos: análisis y pruebas terminaron correctamente.

Configuración Firebase completada por la usuaria: proyecto `unicambio-2f543`, apps Android/Web. FlutterFire generó `lib/firebase_options.dart`, `android/app/google-services.json` y aplicó el plugin de Google Services a Gradle. `main.dart` ahora inicializa desde `DefaultFirebaseOptions.currentPlatform`; ya no se requieren defines de compilación. Falta activar Email/Password en Firebase Console antes de usar registro/inicio. Guía actualizada en `FIREBASE_SETUP.md`.

## Actualización — Avance 7: Firestore

Los artículos y favoritos ahora viven en Cloud Firestore
(`ArticuloRepositorioNube`): `articulos/{id}` con `uidAutor` y
`usuarios/{uid}/favoritos/{articuloId}`. Los favoritos son por usuario
(`esFavorito` ya no se persiste en el artículo; se marca al leer), los ids los
asigna Firestore y la semilla se eliminó (la app arranca vacía). `main.dart`
elige el repo nube cuando Firebase inició y la puerta de sesión recarga el
provider al aparecer un usuario. `firestore.rules` restringe la escritura al
dueño y los favoritos al propio uid. Dependencia nueva: `cloud_firestore`
6.10.0. Verificación: `flutter analyze` → `No issues found!` y `flutter test`
→ `All tests passed!` (30).

## Actualización — Tiempo real con Firestore

La lista se actualiza sola cuando otro usuario publica, edita o elimina.
`ArticuloRepositorioNube.observarTodos()` usa `snapshots()` de Firestore (no
hace *polling*: el SDK mantiene la conexión y solo envía los documentos que
cambian). El provider se suscribe en `iniciar()` solo si
`repositorio.enTiempoReal` es `true` (nube), vuelve a filtrar en memoria con la
búsqueda/categoría activas, recalcula favoritos y cancela la suscripción en
`dispose()`. SQLite y memoria implementan `observarTodos()` con un stream vacío.
En facturación, cada documento entregado cuenta como 1 lectura; con este
tamaño de datos queda holgadamente dentro del plan gratuito. Nueva prueba:
`los cambios en tiempo real actualizan las listas` (fake con
`StreamController`). Verificación: `No issues found!` + `All tests passed!`
(30).

## Actualización — Avance 8: fotos reales de los artículos

El formulario permite elegir una imagen de la galería o tomarla con la cámara,
ver una vista previa, reemplazarla o quitarla. Al guardar, la imagen se carga a
Supabase Storage (API REST) en una ruta asociada al usuario de Firebase y al
artículo; la URL pública se persiste en `Articulo.imagenUrl` y SQLite. Las
tarjetas y el detalle muestran la imagen descargada. El esquema SQLite subió a
versión 2 con una migración que agrega la columna opcional `imagenUrl` a bases
existentes. No se usa Firebase Storage porque su plan Blaze no se pudo activar
(`OR_BACR2_59`); Supabase es gratis y sin tarjeta. Configuración en
`SUPABASE_SETUP.md` y `lib/config_supabase.dart`.

La imagen también se guarda en Firestore: `ArticuloRepositorioNube` escribe y
lee `imagenUrl` (null al quitarla). Al reemplazar/quitar la foto o eliminar el
artículo, `AlmacenamientoImagenes.eliminar` borra el archivo viejo del bucket
(mejor esfuerzo, no bloquea el guardado). `android/app/src/main/AndroidManifest.xml`
declara el permiso `INTERNET`, necesario en builds de release. Verificación:
`flutter analyze` → `No issues found!` y `flutter test` → `All tests passed!`
(30). Para cargas reales todavía hay que crear el bucket `articulos` y sus
políticas en Supabase; pasos en `SUPABASE_SETUP.md`. Si algún día se habilita
Blaze, `AlmacenamientoImagenes` es el único archivo a cambiar.

## Actualización — Avance 9: perfil y vendedor real

Las publicaciones nuevas usan el nombre visible de la cuenta (`displayName`;
respaldo: la parte antes de la `@` del correo o `'Estudiante'`) y guardan
`uidAutor`. El modelo `Articulo` incorpora `uidAutor` (SQLite sube a versión 3
con migración) y "Mis artículos" filtra por `uidAutor == uid` de la sesión, no
por el nombre. El provider expone `uidActual`, `vendedorActual` y `mios`, y
`main.dart` llama `configurarUsuario(...)` al restaurar/iniciar sesión.

Nueva pantalla `pantalla_perfil.dart`, accesible tocando el avatar de Inicio:
permite editar el nombre (`updateDisplayName`), cambiar la foto (se sube al
bucket `articulos` en `{uid}/perfil/...` y se guarda en `photoURL`), quitarla
(se borra del bucket) y cerrar sesión; también muestra cuántas publicaciones y
favoritos tienes. Verificación: `flutter analyze` → `No issues found!` y
`flutter test` → `All tests passed!` (30).

## Actualización — Avance 10: sugerencias con ML Kit

Al elegir una foto nueva en Android, `ServicioVisionMlKit` ejecuta etiquetado
de imágenes y OCR latino de ML Kit en el dispositivo. `SugeridorPublicacion`
convierte las etiquetas inglesas en una categoría (con umbral y margen) y
propone un título desde el OCR, descartando precios, URLs, tallas y líneas de
metadatos; si no hay texto útil, usa la etiqueta traducida. El panel muestra
esas sugerencias junto a una descripción generada con plantillas locales, y el
usuario decide campo por campo con "Usar"/"Reemplazar" o descarta todo. No se
auto-rellena nada y no se sugiere precio.

La descripción vive detrás de la interfaz `GeneradorDescripcion`; hoy
`PlantillaGeneradorDescripcion` compone el texto por tipo y categoría y se
recalcula si el usuario cambia venta/intercambio/regalo, categoría o título.
Esto deja la puerta abierta a un LLM futuro sin tocar la pantalla. En web se
evita ML Kit con `kIsWeb` (el build web compila y el formulario sigue
funcionando). El servicio se crea perezosamente, se cierra en `dispose` y un
token descarta resultados de una foto anterior.

Dependencias nuevas: `google_mlkit_image_labeling` y
`google_mlkit_text_recognition` (1.0.1). No se usa Gemini Nano/AICore porque
requiere dispositivos compatibles y `minSdk 26`. Verificación: `flutter
analyze` → `No issues found!`, `flutter test` → `All tests passed!` (58 en ese momento),
`flutter build apk --debug` y `flutter build web` correctos. La prueba manual
de las sugerencias en un teléfono/emulador Android queda pendiente porque este
equipo no tiene dispositivos conectados.

## Actualización — Build iOS en Codemagic

Se generó la carpeta `ios/` con el paquete `com.unicambio.unicambio` y el
deployment target 15.0. El build se hará en Codemagic porque aquí no hay macOS:
`codemagic.yaml` compila sin firma y empaqueta `unicambio.ipa` para instalarlo
desde Windows con Sideloadly/AltStore y un Apple ID gratuito.

Los plugins Flutter de ML Kit resueltos (`1.0.3`) usan SwiftPM
`d-date/google-mlkit-swiftpm` `9.0.3`, no `9.0.2`. Por eso el script de bundles
descarga esa versión y los tres recursos que exigen los plugins: etiquetado,
objetos comunes y OCR latino. El script Ruby agrega los bundles a Copy Bundle
Resources y las banderas del enlazador; la descarga se probó localmente, pero el
Ruby no está instalado en Windows y solo se podrá ejecutar en Codemagic.

Firebase iOS ya **no está pendiente**: `firebase login:list` muestra
`pauvan120@gmail.com` y FlutterFire registró el Bundle ID
`com.unicambio.unicambio`. Como FlutterFire en Windows no escribe el plist,
se descargó `ios/Runner/GoogleService-Info.plist` y se copiaron `CLIENT_ID` y
`REVERSED_CLIENT_ID` a `ios/Runner/Info.plist` (`GIDClientID` y
`CFBundleURLTypes`). No hay `SERVER_CLIENT_ID`, así que no se agregó
`GIDServerClientID`. El script Ruby incluye el plist en el IPA.

Tres builds de Codemagic llegaron a Xcode y fallaron con
`The file "...Resources.bundle" couldn't be opened because there is no such file`
para los tres bundles. Los archivos sí se descargaron; el problema era la
resolución de los file refs en `project.pbxproj`, incluso con el patrón
`wrapper.cbundle` del ejemplo oficial. Se descartó registrarlos en Xcode: el
workflow ahora compila sin esas referencias y copia los bundles desde
`ios/mlkit_bundles` directamente en `Runner.app` antes de generar el IPA. El
usuario confirmó que `ios-unsigned` con `c79a166` instala y abre la app en el
iPhone, así que esa deuda quedó cerrada.

## Actualización — Proxy REST para sugerencias LLM (Avance 12)

Se creó `proxy_gemini/` con un Cloudflare Worker que sirve `GET /health` y
`POST /sugerencias`. El endpoint recibe la foto en base64, etiquetas/OCR de ML
Kit y el tipo de publicación; verifica el ID token de Firebase, aplica un límite
de 10 peticiones por minuto por usuario/IP y llama a la **Interactions API** de
Gemini con el modelo `gemini-3.5-flash-lite`. La salida se valida antes de
devolver `categoria`, `titulo` y `descripcion`; cualquier fallo devuelve un JSON
de error para que Flutter mantenga el fallback local sin romper el formulario.

Archivos nuevos:

- `proxy_gemini/src/index.js`: lógica del Worker, prompt, CORS, validación y
  rate limit.
- `proxy_gemini/wrangler.jsonc`: variables públicas `FIREBASE_PROJECT_ID` y
  `MODELO`.
- `proxy_gemini/package.json`: dependencias `jose` y `wrangler`.
- `proxy_gemini/.dev.vars.example`: plantilla para el único secreto,
  `GEMINI_API_KEY`.
- `.gitignore`: ignora `node_modules/`, `.dev.vars*`, `.wrangler/`.

Verificación del Worker: `node --check src/index.js`, `npm install` (0
vulnerabilidades), `npx wrangler deploy --dry-run` y `GET /health` en la URL
desplegada, correctos. La key se guardó con `npx wrangler secret put
GEMINI_API_KEY` y el deploy quedó en
`https://unicambio-sugerencias.unicambiodm26.workers.dev`. La key no se escribe
en el repo ni se envía desde la app.

### Cableado en Flutter

- `lib/config_llm.dart` guarda solo la URL base; se puede cambiar con
  `--dart-define=UNICAMBIO_LLM_URL=...`.
- `ClienteSugerenciasLlm` (`lib/datos/cliente_sugerencias_llm.dart`) hace
  `POST /sugerencias` con la foto en base64, etiquetas/OCR de ML Kit y el ID
  token de `FirebaseAuth.instance.currentUser`. El token se inyecta en pruebas
  mediante `proveedorToken:`.
- `ServicioVisionConLlm` envuelve al servicio ML Kit, lee los bytes con
  `XFile.readAsBytes()` (sin `dart:io`, compatible con web), usa
  `CacheSugerenciasLlm` y devuelve la sugerencia dentro de `ResultadoVision`.
  Si falla red, token, cuota o JSON, devuelve el resultado local sin lanzar.
- `SugeridorPublicacionLlm` prefiere categoría y título del LLM; la
  descripción LLM se usa solo mientras el tipo de publicación no cambie. Si el
  usuario cambia venta/intercambio/regalo o edita título/categoría, se vuelve a
  la plantilla local.
- `ServiciosPublicacion` (`lib/datos/servicios_publicacion.dart`) concentra la
  fábrica; `PantallaPublicar` recibe `sugeridor:` opcional en pruebas y no se
  tocó `main.dart` ni `pantalla_mis_articulos.dart`.
- Pruebas nuevas: cliente HTTP con `MockClient`, caché por imagen/tipo,
  decorador con fallback y prioridad del sugeridor. Total: **58 pruebas en ese
  momento**.
  `flutter analyze` → `No issues found!`, `flutter test` → `All tests passed!`.

## Actualización — Avance 13: cierre iOS-ready

Para que el Worker, el cableado LLM y los ajustes de build salgan en un solo
commit se cerró esta deuda corta:

- `.gitignore` ahora ignores `proxy_gemini/node_modules/`, `.dev.vars`,
  `.dev.vars.*` y `.wrangler/`, pero permite versionar
  `proxy_gemini/.dev.vars.example` con `!`. Así la plantilla del secreto viaja
  con el repo y la key real nunca entra.
- Android: Gradle `9.3.1` → `9.5.0` y Android Gradle Plugin `9.1.0` → `9.1.1`.
- Documentación: el build iOS quedó marcado como validado, se eliminó el
  “pendiente” viejo y se agregó el checklist de prueba LLM en iOS al README.

Verificación previa al commit: `git check-ignore`, escaneo de secretos,
`flutter analyze`, `flutter test` (58), `flutter build apk --debug`,
`flutter build web` y `git diff --check`.

Checklist de prueba en iOS tras instalar el nuevo IPA:

1. Iniciar sesión (el ID token es obligatorio para el Worker).
2. Publicar → elegir foto de galería o cámara → esperar las sugerencias.
3. Confirmar que la descripción LLM aparece cuando el Worker responde.
4. Cambiar tipo/título y verificar que se vuelve a la plantilla local.
5. Desactivar red y repetir: no debe bloquearse la publicación.

## Actualización — Avance 14: búsqueda avanzada

Se cambió el contrato entre UI, provider y repositorio sin tocar Firestore desde
las pantallas:

- `ConsultaArticulos` (`lib/modelos/consulta_articulos.dart`) y
  `PaginaArticulos` (`lib/modelos/pagina_articulos.dart`) son los nuevos DTO.
  `ConsultaArticulos.ordenEfectivo` fuerza `precio ASC` cuando hay rango.
- `ArticuloRepositorio.buscarPagina(consulta, {cursor})` devuelve hasta 12
  artículos. El cursor es un `Object?`: en SQLite/memoria es un desplazamiento
  y en Firestore un `_CursorNube` con el último `DocumentSnapshot`.
- `ArticuloRepositorioNube` filtra categoría/precio en el servidor, pide lotes
  y aplica `texto` en Dart sobre título + descripción. `buscar()` sigue
  existiendo para código histórico.
- `ArticulosProvider` conserva `todos` para detalle/"Mis artículos"/favoritos y
  usa la página para Inicio. `cargarMas()` anexa resultados; un token interno
  descarta respuestas viejas al cambiar filtros rápido.
- `PanelFiltros` (`lib/widgets/panel_filtros.dart`) ofrece orden y rango de
  precio; Inicio muestra el botón "Cargar más" y el número de resultados.

Los índices de `firestore.indexes.json` se desplegaron con
`firebase deploy --only firestore:indexes --project unicambio-2f543`.
Verificación final: `flutter analyze` → `No issues found!`, `flutter test` →
`All tests passed!` (67), `flutter build apk --debug`, `flutter build web` y
`git diff --check` correctos.

## Actualización — Avances 15 y 16: paginación total y estados

- Se eliminó `ArticulosProvider.todos`. Inicio, "Mis artículos" y favoritos
  reciben `PaginaArticulos`; `cargarMis()`, `cargarFavoritos()` y sus variantes
  `cargarMas*` reinician/siguen cursores independientes. `refrescarArticulo(id)`
  actualiza el detalle sin volver a leer la colección completa.
- `ConsultaArticulos` incorpora `uidAutor` y el contrato incorpora
  `buscarPaginaFavoritos({limite, cursor})`. En Firestore, "Mis artículos" usa
  `where('uidAutor', isEqualTo: ...)` y los favoritos se paginan por id de
  documento. `observarTodos()` queda como señal de invalidación.
- `Articulo.estado` (`disponible`/`finalizado`) se persiste en Firestore y en
  SQLite v4; `EstadoPublicacionUI` da la etiqueta según el tipo. El paso de
  estado se hace con `provider.cambiarEstado(id, estado)`; la tarjeta, el
  detalle y "Mis artículos" reflejan el cambio y el contacto se deshabilita al
  finalizar.
- `firestore.rules` valida `estado`; `firestore.indexes.json` añade las
  combinaciones de `uidAutor` con categoría/título/precio. Despliegue con
  `firebase deploy --only firestore:rules,firestore:indexes --project unicambio-2f543`.
- Verificación: `flutter analyze` → `No issues found!`, `flutter test` →
  `All tests passed!` (73), builds de APK y web y `git diff --check` correctos.
  Este cierre agrupa los Avances 14, 15 y 16.

## Actualización — Avance 17: WhatsApp opcional y sugerencias in-app

- Se añadió `url_launcher` para abrir `wa.me` en Android, iOS y Chrome/web. La
  UI depende de `LanzadorWhatsapp`, así que las pruebas usan un fake.
- `creadoEn` llega a SQLite v5 y a Firestore con `FieldValue.serverTimestamp()`
  al crear. Al actualizar se conserva la fecha original. Las publicaciones
  históricas (sin fecha) quedan fuera de la bandeja de novedades.
- El perfil del usuario vive en `usuarios/{uid}` junto a sus favoritos. El
  teléfono es opcional, se guarda como `57...` y solo se muestra completo en Mi
  perfil; los demás usuarios lo leen para armar el enlace de WhatsApp.
- Las preferencias de sugerencias son locales a Firestore (por usuario), con
  todas las categorías activadas al encender el interruptor por primera vez.
  `ArticulosProvider.cargarNovedades` consulta la bandeja y `PerfilProvider`
  registra `ultimaVista` al abrirla.
- No se agregaron índices compuestos: la consulta de novedades filtra por fecha
  en Firestore y aplica el resto de los filtros en Dart sobre un lote acotado.
- Las reglas de `usuarios/{uid}` se desplegaron con
  `firebase deploy --only firestore:rules --project unicambio-2f543`.
- Verificación del avance: `flutter analyze` → `No issues found!`,
  `flutter test` → `All tests passed!` (86), builds de APK y web y
  `git diff --check` correctos.

## Corrección posterior — `failed-precondition` al probar en iOS

- El iPhone mostraba `Error al acceder a la nube (failed-precondition)`.
  En Firestore ese código significa que la consulta necesita un índice que el
  proyecto no tenía desplegado.
- `firebase.json` solo declaraba `firestore.rules`; ahora también declara
  `"indexes": "firestore.indexes.json"` para que el despliegue sea explícito.
- Se ejecutó `firebase deploy --only firestore:indexes --project unicambio-2f543`.
  `firebase firestore:indexes` pasó de `"indexes": []` a listar los 9 índices
  compuestos definidos localmente (categoria/titulo, categoria/precio,
  uidAutor/titulo, uidAutor/precio y uidAutor/categoria/*).
- `_mensajeDeError` en `ArticulosProvider` ahora muestra el mensaje completo de
  `FirebaseException` para `failed-precondition` y lo envía a `debugPrint`, de
  modo que si aparece otra consulta sin índice se sabe cuál crear.
- Nueva prueba: `failed-precondition explica el índice faltante`. Total: 87.
- Verificación: `flutter analyze` → `No issues found!`, `flutter test` →
  `All tests passed!` (87). Falta que la usuaria repita la prueba en el iPhone;
  si el error persiste, el nuevo mensaje permitirá crear el índice exacto.

## Avance 18 — Formulario validado y estética adaptable

- Este avance se entregó **junto** con la corrección de índices anterior: el
  mismo commit pendiente incluye `failed-precondition` y el trabajo visual.
- `lib/tema/tema_app.dart` centraliza el lenguaje iOS-inspired: fondo agrupado
  `0xFFF2F2F7`, superficies blancas, texto `0xFF1C1C1E`, separadores
  `0xFFE5E5EA`, radios 18/14, AppBar/Card/campos/botones/hojas coherentes.
- `lib/tema/adaptativo.dart` aporta `esIOS`, `iconoAdaptativo`,
  `anchoContenido`, `paddingConTeclado` y `mostrarHojaAdaptada` (Cupertino en
  iOS, Material con drag handle en Android/web). Las hojas de foto, novedades
  y filtros ya lo usan.
- `lib/utilidades/validadores_formulario.dart` concentra las reglas puras:
  título 5-80, descripción 10-1000, precio opcional ≤ 99,999,999 (acepta coma
  decimal y solo aplica a ventas). `PantallaPublicar` usa `GlobalKey` y
  `Scrollable.ensureVisible` para llevar el scroll al primer campo inválido;
  añade `maxLength`, ayudas, formato numérico, `SafeArea`, ancho máximo en web
  (760/640), `Semantics` y tooltips.
- Se alinearon los colores semánticos de "Mis artículos" y el detalle con
  `ColorScheme` en vez de `Colors.green/red/teal` sueltos.
- Branding: nuevas dependencias dev `flutter_launcher_icons 0.14.4` y
  `flutter_native_splash 2.4.8`; configuración en `flutter_launcher_icons.yaml`
  y `flutter_native_splash.yaml`. El logo actual es **provisional**: el
  definitivo debe reemplazar `assets/logo/unicambio.png` e
  `assets/logo/unicambio_foreground.png`, y luego ejecutar
  `dart run flutter_launcher_icons` y `dart run flutter_native_splash:create`.
  En iOS se usa `remove_alpha_ios: true` para cumplir con App Store.
- No se agregaron FCM/APNs, SMS ni chat: siguen fuera de alcance.
- Pruebas nuevas: `validadores_formulario_test.dart` (8). Total: 95.
- Verificación final: `flutter pub get`, `flutter analyze` → `No issues found!`,
  `flutter test` → `All tests passed!` (95), `flutter build apk --debug` y
  `flutter build web` correctos, `git diff --check` sin errores (solo avisos
  LF→CRLF de Windows). Falta regenerar el IPA con Codemagic cuando llegue el
  logo definitivo.
