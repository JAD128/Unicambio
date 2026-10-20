# Configurar Firebase Authentication

1. Instala e inicia sesión con Firebase CLI y FlutterFire CLI. En la raíz del
   proyecto ejecuta:

   ```powershell
   dart pub global run flutterfire_cli:flutterfire configure
   ```

2. Selecciona el proyecto Firebase y las plataformas **Android** y **Web**.
   FlutterFire genera `lib/firebase_options.dart` y configura Android. Ese
   archivo se usa directamente al iniciar Firebase; no hay que copiar valores
   ni añadir `--dart-define` al ejecutar.
3. En Firebase Console, abre **Authentication → Sign-in method** y habilita
   **Correo electrónico/contraseña**.
4. Inicia la app con `flutter run` para Android o `flutter run -d chrome` para
   Web.

El registro crea la cuenta en Firebase Auth. Firebase mantiene la sesión entre
reinicios; el botón **Cerrar sesión** de Inicio la termina. Las contraseñas
las gestiona Firebase y no se guardan en UniCambio.

## Habilitar "Continuar con Google"

La pantalla de acceso incluye un botón **Continuar con Google**. En móvil se
usa el paquete `google_sign_in` (devuelve un token que Firebase valida); en web
se usa `signInWithPopup` de `firebase_auth`. **Ya está configurado y probado**
(proveedor activo, SHA-1 registrado y `google-services.json` con
`oauth_client`). Los pasos quedan documentados por si se configura otro equipo
o se cambia la huella:

1. **Activa el proveedor**: en Firebase Console → **Authentication → Sign-in
   method** → **Google** → **Habilitar** → Guardar.

2. **Registra la huella SHA-1 de depuración** (sin ella, Android rechaza el
   inicio de sesión con Google). En PowerShell ejecuta:

   ```powershell
   keytool -list -v -keystore "$env:USERPROFILE\android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | Select-String "SHA1"
   ```

   Copia el valor (formato `AA:BB:CC:...`) y en **Project settings → Your
   apps → Android app** (`com.unicambio.unicambio`) pégalo en
   **SHA certificate fingerprints → Add fingerprint**.

3. **Vuelve a descargar `google-services.json`** desde Project settings y
   reemplaza `android/app/google-services.json`. Debe incluir un bloque
   `"oauth_client"` con el cliente Android (si está vacío, el plugin no puede
   pedir el token de Google).

4. Aplica el cambio con:

   ```powershell
   flutter clean
   flutter run
   ```

Web no necesita configuración extra: al habilitar el proveedor (paso 1) el
popup de Google funciona con el cliente web que ya tiene Firebase.

Si en Android aparece un error de cancelación tras elegir la cuenta o un
mensaje `clientConfigurationError`, revisa los pasos 1–3 (casi siempre es el
SHA-1 o un `google-services.json` desactualizado).

## Configurar Firestore (Avance 7)

Los artículos y favoritos se guardan en **Cloud Firestore** mediante
`ArticuloRepositorioNube` (colecciones `articulos` y
`usuarios/{uid}/favoritos`).

1. En Firebase Console, abre **Firestore Database → Create database**.
   Elige **Production mode** y la región más cercana (p. ej.
   `southamerica-east1`). Espera a que esté activa.
2. Publica las reglas de seguridad del proyecto (archivo `firestore.rules` en
   la raíz): los artículos solo los edita su autor y cada usuario gestiona
   sus propios favoritos. Desde la terminal, con la CLI de Firebase:

   ```powershell
   firebase deploy --only firestore:rules
   ```

   O manualmente: **Firestore → Rules**, pega el contenido de
   `firestore.rules` y pulsa **Publish**.
3. No hace falta crear colecciones a mano: `insertar` las crea al primer
   uso.
