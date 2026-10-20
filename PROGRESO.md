# PROGRESO DEL PROYECTO — UniCambio

> Documento de contexto y bitácora. Léelo completo al retomar el trabajo para
> no perder el hilo. Actualízalo al cerrar cada avance.

Última actualización: cierre del **avance de persistencia local (SQLite) + lógica funcional**.

---

## 1. Qué es el proyecto

**UniCambio** es una app **Flutter** para estudiantes universitarios: permite
**vender, intercambiar o regalar** artículos entre compañeros.

- Directorio: `C:\Users\juand\Desktop\U\10mo\Desarrollo movil\Proyecto_Unicambio`
- Paquete Dart: `unicambio` · organización `com.unicambio`
- Plataformas habilitadas: `android`, `web`
- Flutter 3.47.6 · Dart SDK `^3.13.5`

El proyecto tiene dos avances previos de interfaz ya cerrados y ahora una
capa de datos local. **Todavía no hay login ni backend en la nube.**

---

## 2. Estado actual (resumen)

| Avance | Alcance | Estado |
|---|---|---|
| 1 — Interfaz visual | 5 pantallas, tema Material 3, datos de ejemplo en memoria | ✅ Hecho |
| 2 — Persistencia local | Modelo + SQLite (`sqflite`) + repositorio | ✅ Hecho |
| 3 — Estado global | `ArticulosProvider` (provider / ChangeNotifier) | ✅ Hecho |
| 4 — Conectar la UI | Pantallas leyendo/escribiendo por el provider | ✅ Hecho |
| 5 — Pruebas | Repositorio (ffi) + provider + widgets | ✅ Hecho |
| 6 — Pendiente | Login y/o nube (Firebase/Supabase) | ⛔ No iniciado |

Verificación más reciente:

```bash
flutter analyze   # -> No issues found!
flutter test      # -> All tests passed!  (23 pruebas)
```

---

## 3. Funcionalidades actuales (todas funcionales)

- Ver artículos (desde la base de datos SQLite).
- **Buscar** por título (búsqueda dinámica al escribir).
- **Filtrar** por categoría con chips.
- Ver **detalle** del artículo (imagen simulada, precio, descripción, vendedor).
- **Marcar/desmarcar favoritos** (se refleja en toda la app).
- **Crear** publicación (con validación del formulario).
- **Editar** publicación.
- **Eliminar** publicación (con diálogo de confirmación).
- Navegación inferior: Inicio / Favoritos / Mis artículos.
- Botón flotante **Publicar**.

Pendiente para el siguiente avance: autenticación, nube, fotos reales.

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
      ├── ArticuloRepositorioSqflite   → SQLite (app real)
      └── ArticuloRepositorioMemoria   → lista en RAM (pruebas)
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
│   ├── main.dart                          # Arranque: ffi/sqflite + semilla + provider + navegación
│   ├── modelos/
│   │   ├── articulo.dart                  # Articulo + enum TipoPublicacion (+ copyWith/toMap/fromMap/precioTexto)
│   │   └── categoria.dart                 # enum Categoria + extensión UI (etiqueta, icono)
│   ├── datos/
│   │   ├── base_datos.dart                # Singleton BaseDatos: abre unicambio.db y crea la tabla
│   │   ├── articulo_repositorio.dart      # Interfaz ArticuloRepositorio + ArticuloRepositorioSqflite
│   │   ├── articulo_repositorio_memoria.dart  # Implementación en RAM (pruebas)
│   │   ├── semilla.dart                   # sembrarDatosDeEjemplo(): siembra solo si la BD está vacía
│   │   └── articulos_ejemplo.dart         # Lista articulosEjemplo (8) — solo para la semilla
│   ├── estado/
│   │   └── articulos_provider.dart        # Estado global (ChangeNotifier)
│   ├── tema/
│   │   └── tema_app.dart                  # Tema Material 3
│   ├── widgets/
│   │   ├── campo_busqueda.dart            # Barra de búsqueda (onChanged -> buscar)
│   │   ├── chip_categoria.dart            # Chip seleccionable de categoría
│   │   ├── estado_placeholder.dart        # Mensaje centrado (vacío / error)
│   │   └── tarjeta_articulo.dart          # Tarjeta (imagen, insignia, favorito, precio)
│   └── pantallas/
│       ├── pantalla_inicio.dart           # Inicio: buscador + chips + cuadrícula + estados
│       ├── pantalla_favoritos.dart        # Favoritos
│       ├── pantalla_mis_articulos.dart    # Mis artículos (Editar/Eliminar con confirmación)
│       ├── pantalla_detalle_articulo.dart # Detalle (favorito + contacto vía SnackBar)
│       └── pantalla_publicar.dart         # Formulario crear/editar (StatefulWidget)
└── test/
    ├── widget_test.dart                   # 2 pruebas de humo (UI)
    ├── articulos_provider_test.dart       # 10 pruebas del estado global
    └── articulo_repositorio_test.dart     # 11 pruebas de SQLite (con ffi)
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
| `vendedor` | `String` | Nuevos: `'Tú (estudiante)'` |
| `esFavorito` | `bool` | |

- `TipoPublicacion`: `venta`, `intercambio`, `regalo` (con etiqueta/icono/color).
- `Categoria`: `libros`, `apuntes`, `tecnologia`, `ropa`, `hogar`, `deportes`, `otros`.
- `precioTexto`: regalo → "Gratis"; 0 → "A convenir"; resto → "$ N".
- Serialización: enums como `.name`; `esFavorito` como 0/1 (SQLite no tiene bool).

**Tabla `articulos`** (creada en `base_datos.dart`, versión de esquema `1`):

```sql
CREATE TABLE articulos (
  id          TEXT    PRIMARY KEY,
  titulo      TEXT    NOT NULL,
  descripcion TEXT    NOT NULL,
  precio      REAL    NOT NULL DEFAULT 0,
  categoria   TEXT    NOT NULL,
  tipo        TEXT    NOT NULL,
  vendedor    TEXT    NOT NULL,
  esFavorito  INTEGER NOT NULL DEFAULT 0
)
```

Archivo de la BD: `unicambio.db` (vía `getDatabasesPath()`).

---

## 7. API de referencia (para no equivocarse)

**`ArticuloRepositorio`** (`lib/datos/articulo_repositorio.dart`):
`obtenerTodos()`, `obtenerFavoritos()`, `obtenerPorId(id)`, `insertar(a)`,
`actualizar(a)`, `eliminar(id)`, `alternarFavorito(id)`,
`buscar(texto, {categoria})`, `filtrarPorCategoria(categoria)`.

**`ArticulosProvider`** (`lib/estado/articulos_provider.dart`):
- Getters: `todos`, `articulos` (filtrados), `favoritos`, `cargando`, `error`,
  `textoBusqueda`, `categoriaSeleccionada`, `listaVacia`, `articuloPorId(id)`.
- Métodos: `iniciar()`, `actualizarBusqueda(texto)`,
  `seleccionarCategoria(categoria?)`, `insertar(a)`, `actualizar(a)`,
  `eliminar(id)`, `alternarFavorito(id)`.
- Interno: `_ejecutar(...)` maneja `cargando` + `error` + `notifyListeners()`.

**`BaseDatos`** (singleton): `BaseDatos.instancia.db`, `.cerrar()`, `.eliminar()`.

---

## 8. Cómo ejecutar y probar

```bash
flutter pub get
flutter run              # dispositivo/emulador Android (recomendado: SQLite real)
flutter run -d chrome    # navegador (rápido para ver la UI; en web sqflite no corre igual)
flutter analyze          # No issues found!
flutter test             # All tests passed!
```

Dependencias (`pubspec.yaml`): `cupertino_icons`, `sqflite ^2.4.4+1`,
`path ^1.9.1`, `provider ^6.1.5+1`; dev: `flutter_lints ^6.0.0`,
`sqflite_common_ffi ^2.4.3`.

**Prueba manual sugerida:** buscar → filtrar por chip → abrir detalle → marcar
favorito → publicar artículo → editar/eliminar en "Mis artículos".

---

## 9. Pruebas (23 en total)

- `articulo_repositorio_test.dart` (11): usa `sqflite_common_ffi`
  (`sqfliteFfiInit()` + `databaseFactory = databaseFactoryFfi`) y prueba el
  repositorio REAL. Limpia la BD en `setUp` con `BaseDatos.instancia.eliminar()`.
- `articulos_provider_test.dart` (10): usa `ArticuloRepositorioMemoria`.
- `widget_test.dart` (2): smoke tests de UI; envuelven pantallas con el provider
  y el repositorio en memoria.

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
- **Sin login ni nube todavía.** Datos de ejemplo (8 artículos, ids `a1`–`a8`)
  se siembran **solo la primera vez** (si la tabla está vacía).
- **Agregar dependencias** es válido si hace falta (ya se hizo con sqflite,
  provider, ffi), pero avisar/justificar.

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

### Avance 6 — Autenticación de usuarios
- Login y registro (correo/contraseña), recuperar contraseña, cerrar sesión.
- Paquete sugerido: **Firebase Auth**.
- Pantallas nuevas: `login`, `registro`, `recuperar_password`, `perfil`.
- `main.dart` decide qué mostrar: si hay sesión → app; si no → login.
- Guardar la sesión entre reinicios (persistencia del token).
- Estado: ⛔ No iniciado.

### Avance 7 — Backend / nube (sincronización)
- Crear **`ArticuloRepositorioNube`** implementando `ArticuloRepositorio`
  (Firestore o Supabase). Cambiarlo en `main.dart` sin tocar pantallas.
- Migrar `esFavorito` a una relación por usuario (hoy es un campo global del
  artículo; con varios usuarios debe ser "favoritos por usuario").
- Quitar/condicionar la **semilla** (`semilla.dart`) para que no se ejecute en
  producción.
- Manejo de conexión/offline y errores de red.
- Estado: ⛔ No iniciado.

### Avance 8 — Fotos reales de los artículos
- Botón "Agregar foto" (hoy es solo visual) con `image_picker`.
- Subir a almacenamiento (Firebase Storage / Supabase Storage) y guardar la URL
  en el artículo (nuevo campo `imagenUrl` + migración de esquema, subir `version`).
- Reemplazar la "imagen simulada" (degradado + ícono) por la foto real.
- Estado: ⛔ No iniciado.

### Avance 9 — Perfil de usuario y vendedor real
- Hoy los artículos nuevos usan vendedor `'Tú (estudiante)'` (placeholder).
- Tomar el nombre del usuario autenticado.
- Pantalla de perfil (nombre, foto, datos), "Mis artículos" por usuario.
- Estado: ⛔ No iniciado.

### Avance 10 — Visión por computadora con Google ML Kit
- Integrar **Google ML Kit** (paquete `google_mlkit_*` de Flutter) para análisis
  de imágenes **on-device**, enfocado en las APIs de **ML Kit Vision**.
- Casos candidatos: reconocimiento de texto (**OCR**, `text_recognition`) para
  leer etiquetas o precios, etiquetado de imágenes (`image_labeling`) para
  autocompletar la categoría, y detección de objetos (`object_detection`).
- Encaja tras el Avance 8 (fotos reales): la foto capturada se procesa con ML
  Kit para sugerir categoría/título o extraer texto.
- Considerar rendimiento en equipos de gama baja y permisos de cámara.
- Estado: ⛔ No iniciado.

### Backlog de mejoras (prioridad por definir)
- **Chat / contacto al vendedor**: el botón hoy solo muestra un SnackBar.
- **Notificaciones**: la campana es decorativa.
- **Búsqueda avanzada**: filtrar también por descripción; filtrar por rango de
  precio; ordenar (recientes, precio, relevancia).
- **Paginación / carga incremental** de artículos.
- **Estados de publicación**: vendido/disponible, caducidad.
- **Validaciones extra** en el formulario (longitud, precio máximo) y manejo de
  zonas seguras.
- **Accesibilidad** (semántica, contraste) e **internacionalización** (i18n).
- **Ícono de app y splash screen** propios.
- **CI** (GitHub Actions) que corra `analyze` + `test`.
- **Pruebas**: ampliar tests de widgets (interacción real: tocar chips, favorito,
  publicar) y tests de integración.
- **Seguridad**: reglas de acceso en la nube, no exponer claves.

### Deuda técnica / limitaciones conocidas
- `esFavorito` es global (no por usuario) → resolver en Avance 7.
- Los "ids" se generan con la hora (`art_<microsegundos>`); en la nube conviene
  dejar que el backend asigne el id.
- No hay manejo de estado de conexión (offline) todavía.
- `ArticuloRepositorioMemoria` se usa solo en pruebas (no en la app).

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
