JULIO ANDRÉS DIAZ MAIGUAL
PAULA VANESSA LEÓN ERAZO


Documentación en README


# UniCambio

Aplicación Flutter para estudiantes universitarios que permite publicar
artículos para vender, intercambiar o regalar. El proyecto tiene una interfaz
de artículos, datos en la nube con Cloud Firestore y autenticación con Firebase
Auth.

## Estado actual

- **Autenticación:** crear cuenta, iniciar sesión, recuperar contraseña y
  cerrar sesión con Firebase Authentication (correo y contraseña), más
  **Continuar con Google** (en Android vía `google_sign_in`; en web con el
  popup de Firebase Auth).
- **Sesión:** Firebase conserva la sesión entre reinicios y la app abre Inicio
  cuando detecta un usuario autenticado.
- **Artículos:** publicaciones y favoritos se guardan en Cloud Firestore
  (`ArticuloRepositorioNube`) a través de `ArticulosProvider`. La app arranca
  **vacía** (sin datos de ejemplo) y los favoritos son **por usuario**.
  Firestore sirve su caché local cuando no hay conexión y las publicaciones de
  otros usuarios aparecen **en vivo** (`snapshots`).
- **Fotos:** cada publicación puede llevar una foto de galería o cámara
  (comprimida); se sube a **Supabase Storage** y la URL pública se guarda en el
  artículo. Firestore sigue siendo la base de datos. Configuración en
  `SUPABASE_SETUP.md`.
- **Perfil:** cada cuenta publica con su nombre real; "Mis artículos" se
  filtra por `uidAutor`. Desde el avatar de Inicio se puede editar el nombre,
  cambiar o quitar la foto de perfil y cerrar sesión.
- **Sugerencias con ML Kit (Android):** al elegir una foto, la app etiqueta la
  imagen y hace OCR **en el dispositivo**. El formulario propone categoría,
  título, descripción y líneas de texto; cada campo se aplica solo si tocas
  "Usar"/"Reemplazar". No se sugiere precio ni se rellena nada solo. En web
  esta función se omite y el formulario sigue funcionando.
- **Pruebas:** 49 pruebas (repositorio con ffi, provider, almacenamiento,
  lógica de visión y widgets).
- **iOS (en preparación):** scaffold generado y workflow de Codemagic para
  producir un IPA sin firma e instalarlo con Sideloadly. Firebase/Google en iOS
  siguen pendientes de configuración.

## Cómo funciona la autenticación

El recorrido principal está en `lib/main.dart`:

1. `main()` prepara Flutter con `WidgetsFlutterBinding.ensureInitialized()`.
2. `Firebase.initializeApp()` inicia Firebase usando las opciones generadas
   para la plataforma actual.
3. Si la inicialización falla, se muestra una pantalla con el error. Si se
   inicia correctamente, `UniCambioApp` abre `_PuertaAutenticacion`.
4. `_PuertaAutenticacion` escucha `FirebaseAuth.instance.authStateChanges()`:
   - Mientras Firebase restaura la sesión, muestra un indicador de carga.
   - Si no hay usuario, muestra `PantallaAutenticacion`.
   - Si hay usuario, muestra `PantallaPrincipal`.

Firebase Auth guarda y restaura la sesión en el dispositivo. No se guarda la
contraseña en la app.

### Registro e inicio de sesión

`lib/pantallas/pantalla_autenticacion.dart` contiene los formularios y las
acciones de autenticación. La misma pantalla alterna entre inicio y registro:

- El registro valida nombre, formato básico del correo y una contraseña de al
  menos 6 caracteres. Llama a
  `createUserWithEmailAndPassword()` y guarda el nombre como `displayName`.
- El inicio llama a `signInWithEmailAndPassword()`.
- Los errores comunes de Firebase se convierten en mensajes en español, por
  ejemplo correo inválido, cuenta existente o contraseña débil.
- **¿Olvidaste tu contraseña?** envía el enlace de restablecimiento con
  `sendPasswordResetEmail()` al correo escrito.

Al iniciar sesión, `lib/pantallas/pantalla_inicio.dart` muestra el nombre de
Firebase si existe. Su botón de salida llama a `FirebaseAuth.instance.signOut()`;
el cambio de sesión hace que `_PuertaAutenticacion` vuelva a mostrar el acceso.

## Configuración de Firebase

La app está vinculada al proyecto Firebase **UniCambio** (`unicambio-2f543`),
con aplicaciones registradas para Android y Web (iOS pendiente). Para que el acceso funcione,
el proveedor **Correo electrónico/contraseña** debe estar habilitado en Firebase
Console:

1. Abre Firebase Console y selecciona el proyecto **UniCambio**.
2. Ve a **Authentication → Sign-in method** (o **Proveedores de acceso**).
3. Activa **Correo electrónico/contraseña** y guarda.

### Archivos de configuración

`flutterfire configure` generó los archivos y ajustes de plataforma:

| Archivo | Para qué sirve |
|---|---|
| `lib/firebase_options.dart` | Opciones Dart por plataforma (Android y Web). `main.dart` lee `DefaultFirebaseOptions.currentPlatform`. No editarlo a mano; vuelve a generar si agregas plataformas o cambias de proyecto. |
| `android/app/google-services.json` | Identifica la app Android ante Firebase y es leído por el plugin de Google Services. |
| `firebase.json` | Metadatos de configuración usados por las herramientas Firebase. |
| `android/settings.gradle.kts` | Declara la versión del plugin Gradle de Google Services. |
| `android/app/build.gradle.kts` | Aplica el plugin de Google Services a la app Android. |

Las dependencias `firebase_core` y `firebase_auth` están declaradas en
`pubspec.yaml`. `firebase_core` inicializa Firebase; `firebase_auth` permite
crear cuentas, iniciar sesión, restablecer la contraseña y cerrar sesión.

### Almacenamiento de fotos (Supabase)

Las fotos se suben a **Supabase Storage**; los artículos y favoritos siguen en
Firestore. `lib/config_supabase.dart` guarda `supabaseUrl` y
`supabaseAnonKey`, y `AlmacenamientoImagenes` usa la API REST con `http` (sin
SDK de Supabase). Pasos completos —crear el proyecto, el bucket público
`articulos` y las políticas SQL— en **`SUPABASE_SETUP.md`**.

### Si se configura otra instalación o plataforma

Desde la raíz del proyecto, con Firebase CLI y FlutterFire CLI instalados e
iniciados con sesión, ejecuta:

```powershell
dart pub global run flutterfire_cli:flutterfire configure
```

Elige el proyecto Firebase y las plataformas que se usarán. La CLI actualiza
`lib/firebase_options.dart` y los ajustes de Android cuando corresponde. No es
necesario copiar claves ni pasar `--dart-define` al ejecutar.

Si PowerShell no reconoce `firebase`, pero Firebase CLI ya está instalado en
Windows, agrega su carpeta al `PATH` de la ventana actual y verifica la versión:

```powershell
$env:Path += ";$env:APPDATA\npm"
firebase --version
```

Si la cuenta conectada muestra cero proyectos, confirma que `firebase login`
usó la misma cuenta de Google con la que creaste el proyecto en Firebase
Console.

## Ejecutar la aplicación

Desde la raíz del proyecto:

```powershell
flutter pub get
flutter run
```

Para abrirla en Chrome:

```powershell
flutter run -d chrome
```

La autenticación web utiliza las opciones Web de `lib/firebase_options.dart`.
Para ejecutar en Android, conecta un dispositivo o inicia un emulador.

### Probar las funciones

1. Abre la pantalla de acceso y selecciona **Crear cuenta**.
2. Ingresa nombre, correo y contraseña de 6 caracteres o más. Firebase creará
   la cuenta y la app abrirá Inicio (vacío hasta que publiques algo).
3. Pulsa el ícono **Cerrar sesión** en la barra superior.
4. Inicia sesión con el mismo correo y contraseña.
5. Cierra y vuelve a abrir la app para comprobar que Firebase restaura la
   sesión. Para detener `flutter run`, escribe `q` en la terminal.
6. En la pantalla de acceso, prueba **¿Olvidaste tu contraseña?** y revisa el
   correo para encontrar el enlace de restablecimiento.
7. Pulsa **Continuar con Google** (ya configurado y probado; los pasos quedan
   en `FIREBASE_SETUP.md`).
8. Publica un artículo con el botón **Publicar**: aparecerá también en la
   cuenta de otro usuario (Firestore) y sin reiniciar la app (tiempo real).
   Adjunta una foto desde la galería o cámara y comprueba que se ve en la
   tarjeta y en el detalle.
9. Marca favoritos en una cuenta y comprueba que no aparecen en la otra.
10. En Android, al adjuntar una foto espera el análisis (ML Kit). Prueba
    "Usar" en categoría/título/descripción, una línea de OCR y "Descartar".
    Verifica que cambiar la foto reemplaza las sugerencias y que en Chrome no
    se intenta analizar.

Las cuentas creadas se ven en Firebase Console, en **Authentication → Users**.

## Build iOS con Codemagic (en preparación)

La plataforma iOS ya está generada con Bundle ID `com.unicambio.unicambio` y
deployment target 15.0. No hace falta Mac: el workflow `ios-unsigned` de
`codemagic.yaml` instala dependencias, corre `analyze` y `test`, descarga los
bundles de ML Kit `9.0.3`, configura el proyecto Xcode, compila con
`flutter build ios --release --no-codesign` y deja el artefacto `unicambio.ipa`.

Para usarlo:

1. Sube el repo a GitHub y crea el workflow `ios-unsigned` en Codemagic.
2. Antes de esperar login en iOS, completa la configuración pendiente:
   ejecuta `firebase login` y
   `dart pub global run flutterfire_cli:flutterfire configure --platforms ios`.
   FlutterFire debe registrar `com.unicambio.unicambio`, generar
   `ios/Runner/GoogleService-Info.plist` y agregar el caso iOS a
   `lib/firebase_options.dart`.
3. Copia de `GoogleService-Info.plist` a `ios/Runner/Info.plist` los valores
   `CLIENT_ID` (`GIDClientID`), `SERVER_CLIENT_ID` (`GIDServerClientID`) y
   `REVERSED_CLIENT_ID` (URL scheme de `CFBundleURLTypes`). Los permisos de
   cámara y galería ya están agregados. Sin estos pasos, el IPA compila pero la
   app no inicia Firebase/Google en iOS.
4. Descarga `unicambio.ipa` e instálalo desde Windows con Sideloadly o AltStore
   conectando el iPhone por USB. Sin Apple Developer Program no hay TestFlight.

Con un Apple ID gratuito la firma suele durar unos 7 días y hay que reinstalar.
Además, Sideloadly puede cambiar el Bundle ID al firmar; si ocurre, registra ese
nuevo id en Firebase o desactiva Google Sign-In en iOS.

## Verificación del proyecto

```powershell
flutter analyze
flutter test
```

Al actualizar este README, las verificaciones reportaron **No issues
found!** y **All tests passed!** (49 pruebas). También compilan
`flutter build apk --debug` y `flutter build web`.

## Estructura relevante

```text
lib/
├── main.dart                         # Inicialización Firebase y puerta de sesión
├── firebase_options.dart             # Opciones de Firebase por plataforma (generado)
├── pantallas/
│   ├── pantalla_autenticacion.dart   # Inicio, registro, reset y Google
│   ├── pantalla_inicio.dart         # Inicio y acción de cerrar sesión
│   ├── pantalla_favoritos.dart
│   ├── pantalla_mis_articulos.dart
│   └── pantalla_publicar.dart
├── datos/                            # Repositorios, Supabase y visión (ML Kit)
├── estado/                           # Estado de artículos
└── tema/                             # Tema visual Material 3
test/
├── widget_test.dart                  # Pruebas de widgets
├── sugeridor_publicacion_test.dart   # Etiquetas/OCR → sugerencias
├── generador_descripcion_test.dart   # Plantillas de descripción
└── panel_sugerencias_test.dart       # Panel de sugerencias
```

## Tecnologías

- Flutter y Dart (`pubspec.yaml` requiere Dart `^3.13.0`).
- Firebase Authentication para cuentas por correo y contraseña y con Google.
- `firebase_core` para inicializar Firebase y `firebase_auth` para autenticación.
- `google_sign_in` para obtener el token de Google en Android (en web se usa
  `signInWithPopup` de `firebase_auth`).
- Cloud Firestore (`cloud_firestore`) para los artículos y favoritos en la nube.
- Supabase Storage (API REST con `http`) para las fotos de artículos y perfil.
- `image_picker` para elegir la foto de la galería o tomarla con la cámara.
- Google ML Kit (`google_mlkit_image_labeling` y
  `google_mlkit_text_recognition`) para etiquetado y OCR on-device en Android.
- SQLite (`sqflite`) se conserva como implementación histórica y para sus
  pruebas; la app usa Firestore.
- Provider para el estado de artículos.

## Alcance pendiente

- Verificación de correo.
- Prueba manual de las sugerencias de ML Kit en un dispositivo/emulador
  Android (el build APK ya compila).
- Chat con el vendedor, notificaciones y búsqueda avanzada.
