# Configurar Supabase Storage para las fotos

La app guarda **solo las fotos** en Supabase Storage (los artículos y
favoritos siguen en Firestore). Supabase tiene un nivel gratuito que **no pide
tarjeta**, a diferencia de Firebase Storage (plan Blaze).

## 1. Crear el proyecto

1. Entra a [supabase.com](https://supabase.com) y crea una cuenta.
2. **New project**: elige nombre (por ejemplo `unicambio`), contraseña de base
   de datos y la región más cercana. Espera a que termine de crearse.

## 2. Crear el bucket de fotos

1. En el menú lateral, abre **Storage**.
2. **New bucket**:
   - Nombre: `articulos` (debe coincidir con `AlmacenamientoImagenes.bucket`).
   - Activa **Public bucket** (las fotos se muestran con URL pública).
3. Guarda.

## 3. Permitir la subida (políticas)

La app no inicia sesión en Supabase: usa la clave `anon` incluida en el
proyecto. Por eso el bucket necesita políticas que permitan **insertar** a
`anon`. Para un proyecto de clase es aceptable; en producción habría que
autenticar también en Supabase.

En **SQL Editor → New query**, pega y ejecuta:

```sql
-- Subir fotos nuevas (la app no sobrescribe: cada nombre lleva la hora).
create policy "fotos_insert_anon"
on storage.objects for insert
to anon, authenticated
with check (bucket_id = 'articulos');

-- Leer las fotos (lectura pública del bucket).
create policy "fotos_select_publico"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'articulos');

-- Borrar fotos viejas al reemplazarlas o eliminar el artículo.
create policy "fotos_delete_anon"
on storage.objects for delete
to anon, authenticated
using (bucket_id = 'articulos');
```

No se crea política de `update`: la app nunca sobrescribe un archivo, sube uno
nuevo y borra el anterior.

> **Aviso de seguridad:** al no haber login en Supabase, la política de
> `delete` permite que cualquiera con la clave `anon` (incluida en la app)
> borre fotos del bucket. Para un proyecto de clase es aceptable; en
> producción habría que autenticar en Supabase (por ejemplo, con
> *Third-Party Auth* de Firebase) y limitar el borrado a la carpeta del dueño
> con `(storage.foldername(name))[1] = auth.uid()::text`.

## 4. Copiar las credenciales

En **Project Settings → API** copia:

- **Project URL** → `supabaseUrl`
- **anon public** (no uses `service_role`) → `supabaseAnonKey`

Pégalas en `lib/config_supabase.dart`:

```dart
const String supabaseUrl = 'https://TU-PROYECTO.supabase.co';
const String supabaseAnonKey = 'TU_CLAVE_ANON';
```

O pásalas sin editar el archivo:

```powershell
flutter run --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co `
            --dart-define=SUPABASE_ANON_KEY=TU_CLAVE_ANON
```

> La clave `anon` es pública por diseño. Nunca pongas la `service_role` en una
> app: esa clave se salta todas las políticas.

## 5. Probar

1. Ejecuta `flutter pub get` y luego `flutter run`.
2. Publica un artículo con foto de galería o cámara.
3. La foto debe verse en la tarjeta y en el detalle.
4. En **Storage → articulos** verás la carpeta con tu uid de Firebase.

## Problemas comunes

- **Error 403 / `new row violates row-level security policy`**: faltan las
  políticas del paso 3 o el bucket no es público.
- **`Falta configurar Supabase`**: no pegaste la URL/clave o ejecutaste sin los
  `--dart-define`.
- **Error 413 / demasiado grande**: las fotos se comprimen antes de subir
  (1600 px, calidad 82); si el bucket tiene un límite menor, ajústalo en
  **Storage → Settings**.
- **La URL abre 400/404**: revisa que la ruta no tenga `//` y que el bucket se
  llame exactamente `articulos`.

Los límites del plan gratuito (almacenamiento y tráfico) se consultan en
**Project Settings → Billing**; con fotos comprimidas de unos cientos de KB
alcanza de sobra para el proyecto.
