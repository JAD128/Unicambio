// =============================================================================
// ARCHIVO: lib/config_supabase.dart
// DESCRIPCIÓN: Credenciales de Supabase usadas SOLO para almacenar las fotos.
//
// Los artículos y favoritos siguen en Firestore; Supabase únicamente guarda
// los archivos de imagen y devuelve una URL pública que se copia al artículo.
//
// Cómo obtener los valores:
//   1. Crea un proyecto gratis en https://supabase.com
//   2. Ve a Project Settings → Data API / API Keys y copia:
//      - Project URL  → [supabaseUrl]
//      - anon public  → [supabaseAnonKey]
//   3. Pega los valores aquí (o pásalos con --dart-define, ver abajo).
//
// La clave `anon` es PÚBLICA por diseño (nunca uses la `service_role` en la
// app). Lo que puede hacer depende de las políticas del bucket; pasos en
// SUPABASE_SETUP.md.
//
// Alternativa sin editar el archivo:
//   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
//               --dart-define=SUPABASE_ANON_KEY=eyJ...
// =============================================================================

/// URL del proyecto Supabase (por ejemplo `https://abc.supabase.co`).
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://lujitvvdwfagqxjyunrn.supabase.co',
);

/// Clave `anon public` del proyecto Supabase.
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_fGeGwRkyxborNBE3VOR4kA_zlanOYiJ',
);
