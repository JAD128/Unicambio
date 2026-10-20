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
