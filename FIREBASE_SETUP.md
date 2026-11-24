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
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | Select-String "SHA1"
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
    la raíz): los artículos solo los edita su autor, cada usuario gestiona
    sus propios favoritos y `estado` solo puede ser `disponible` o
    `finalizado`. Desde la terminal, con la CLI de Firebase:

   ```powershell
   firebase deploy --only firestore:rules
   ```

   O manualmente: **Firestore → Rules**, pega el contenido de
   `firestore.rules` y pulsa **Publish**.
 3. Publica los índices compuestos (categoría y `uidAutor` con título/precio en
    ambos sentidos, además de las combinaciones de tres campos):

   ```powershell
   firebase deploy --only firestore:indexes
   ```

   También puedes crearlos a mano desde **Firestore → Indexes** usando
   `firestore.indexes.json` como guía. Sin estos índices, los filtros combinados
   fallan con un enlace "Create index" en la consola.
4. No hace falta crear colecciones a mano: `insertar` las crea al primer
   uso.

## Fotos de artículos (Avance 8)

Las fotos **no** se guardan en Firebase Storage: Cloud Storage for Firebase
exige el plan Blaze (tarjeta) y en este proyecto la activación falló con
`OR_BACR2_59`. Se usa **Supabase Storage** (gratis, sin tarjeta) y en Firestore
solo se guarda la URL pública en `Articulo.imagenUrl`.

La configuración completa está en **`SUPABASE_SETUP.md`**. Resumen: crear el
bucket público `articulos`, aplicar las políticas SQL para subir/leer y pegar
la URL y la clave `anon` en `lib/config_supabase.dart`.

`firestore.rules` no cambia. Si en el futuro se habilita Blaze, solo hay que
reescribir `AlmacenamientoImagenes` para usar Firebase Storage; la UI y
Firestore no se tocan.

## iOS

Firebase y Google Sign-In en iOS **ya están configurados** para
`com.unicambio.unicambio`. La sesión de Firebase CLI quedó autorizada con
`pauvan120@gmail.com` y FlutterFire registró la app iOS
(`1:619158453000:ios:599f8dd2c8e9cdc9f3cabd`).

Para reproducirlo:

1. Autoriza la CLI y ejecuta FlutterFire con las tres plataformas (correr solo
   `--platforms ios` regeneraría `lib/firebase_options.dart` sin Android/Web):

   ```powershell
   firebase login
   dart pub global run flutterfire_cli:flutterfire configure -p unicambio-2f543 --platforms android,ios,web --ios-bundle-id com.unicambio.unicambio --android-package-name com.unicambio.unicambio --overwrite-firebase-options
   ```

   En Windows FlutterFire **no** genera ni registra el plist de iOS: solo crea
   el caso iOS en `lib/firebase_options.dart`. Hay que descargar
   `GoogleService-Info.plist` desde Firebase Console → Project settings → Your
   apps y guardarlo en `ios/Runner/GoogleService-Info.plist`.

2. Copia los valores del plist a `ios/Runner/Info.plist`:
   - `CLIENT_ID` → `GIDClientID`.
   - `REVERSED_CLIENT_ID` → URL scheme dentro de `CFBundleURLTypes`.
   - `SERVER_CLIENT_ID` → `GIDServerClientID` solo si el proveedor lo entrega.
      En esta app no aparece y por eso no se agregó: el `idToken` se valida
      contra Firebase; el proxy de sugerencias también lo verifica.

3. `scripts/configure_ios_mlkit.rb` agrega `GoogleService-Info.plist` a Copy
   Bundle Resources del target `Runner` en Codemagic. Los bundles de ML Kit no
   se registran en Xcode: `codemagic.yaml` los copia en `Runner.app` después del
   build. Sin el plist, Firebase no arranca en iOS.

4. En Firebase Console → **Authentication → Sign-in method**, mantén Google
   habilitado. Los permisos de cámara y galería ya están en `Info.plist`.

Verificación: `DefaultFirebaseOptions.currentPlatform` devuelve el caso iOS y el
IPA de Codemagic incluye el plist y la URL scheme.

## Proxy de sugerencias con Gemini (Cloudflare Worker)

`proxy_gemini/` es el backend del Avance 12. Mantiene la API key fuera de Flutter
y del IPA. El Worker verifica el ID token de Firebase, por lo que solo usuarios
autenticados pueden pedir sugerencias.

1. Crea la key en **Google AI Studio → Get API key → Create API key**, selecciona
   el proyecto de Google Cloud vinculado a `unicambio-2f543` y cópiala. Si la key
   aparece sin restricciones, edítala y activa **Restrict key → Gemini API**.
   No pegues la key en el chat ni en `lib/`.
2. En la carpeta `proxy_gemini/`, copia `.dev.vars.example` a `.dev.vars` y pega
   la key solo ahí para probar en local. `.dev.vars` ya está ignorado por Git.
3. Instala y prueba el Worker:

   ```powershell
   npm install
   npm run dev
   ```

   Debe responder `GET http://localhost:8787/health` con un JSON `"ok": true`.

4. Entra a Cloudflare y sube el secreto. El comando te pedirá la key; no la
   escribas como argumento:

   ```powershell
   npx wrangler login
   npm run secret
   npm run deploy
   ```

5. Wrangler imprimió la URL pública definitiva:
   `https://unicambio-sugerencias.unicambiodm26.workers.dev`. No hace falta
   tocar `wrangler.jsonc`: ya tiene `FIREBASE_PROJECT_ID=unicambio-2f543` y
   `MODELO=gemini-3.5-flash-lite`. Para verificar, abre
   `https://unicambio-sugerencias.unicambiodm26.workers.dev/health`; debe
   devolver `"ok": true`.

Contrato del endpoint:

- `POST /sugerencias`
- Header: `Authorization: Bearer <idToken de Firebase>`
- Body: `{ "imagenBase64": "...", "mimeType": "image/jpeg", "tipoPublicacion": "venta", "etiquetas": [], "lineasTexto": [] }`
- Respuesta correcta: `{ "categoria": "libros", "titulo": "...", "descripcion": "..." }`
- Respuesta de error: `{ "error": "codigo", "mensaje": "..." }`

Si el Worker no está desplegado o falla, la app sigue con ML Kit + plantillas
locales: no se bloquea la publicación.

### Conexión desde Flutter

La app ya apunta al Worker desplegado. `lib/config_llm.dart` contiene solo la
URL base (sin secretos) y se puede sobrescribir al compilar:

```bash
flutter run --dart-define=UNICAMBIO_LLM_URL=https://unicambio-sugerencias.unicambiodm26.workers.dev
```

`ClienteSugerenciasLlm` obtiene el ID token con
`FirebaseAuth.instance.currentUser.getIdToken()` y lo envía como
`Authorization: Bearer ...`. Por eso la pantalla de publicación requiere sesión
iniciada; si no hay token, el cliente lanza un `StateError` y el decorador
`ServicioVisionConLlm` conserva las sugerencias locales de ML Kit.

`ServiciosPublicacion` crea el servicio compuesto y el sugeridor; la pantalla
sigue usando `context.read<ArticulosProvider>()` para guardar. No hay cambios en
`main.dart` ni en las demás pantallas. La descripción del LLM se muestra solo
mientras el tipo de publicación no cambie; si cambia, se recalcula con
`PlantillaGeneradorDescripcion`.
