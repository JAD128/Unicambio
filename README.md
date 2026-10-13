# UniCambio

Aplicación móvil para estudiantes universitarios que permite **publicar artículos para vender, intercambiar o regalar** entre compañeros.

> **Estado del proyecto: Primer avance — Interfaz visual (UI).**
> Esta versión es un prototipo navegable. Los datos son de ejemplo y se manejan en memoria; todavía **no** hay base de datos, inicio de sesión ni lógica funcional.

---

## Funcionalidades de este avance

| Sección | Estado |
|---|---|
| Pantalla principal con artículos de ejemplo | Hecho (visual) |
| Barra de búsqueda | Visual (no filtra aún) |
| Filtros por categoría | Visual (no filtra aún) |
| Detalle del artículo | Hecho (navegación) |
| Favoritos (listar) | Visual (no agregar/quitar aún) |
| Formulario de publicación | Visual (no guarda aún) |
| Navegación Inicio / Favoritos / Mis artículos | Hecho |
| Tema visual moderno (Material 3) | Hecho |

**Pendiente para los siguientes avances:** búsqueda real, filtrado por categorías, agregar/quitar favoritos, crear/editar/eliminar publicaciones, validación del formulario y persistencia de datos (base de datos o backend).

---

## Tecnologías

- **Flutter** (probado con 3.47.6, canal stable)
- **Dart** (SDK `^3.13.5`)
- **Visual Studio Code** (editor recomendado)
- **Git / GitHub**

No requiere paquetes externos: solo `flutter` y `cupertino_icons`.

---

## Estructura del proyecto

```
Proyecto_Unicambio/
├── lib/
│   ├── main.dart                          # Arranque + navegación inferior (Inicio/Favoritos/Mis artículos)
│   ├── modelos/
│   │   ├── articulo.dart                  # Modelo Articulo + enum TipoPublicacion (Venta/Intercambio/Regalo)
│   │   └── categoria.dart                 # enum Categoria (etiqueta + ícono)
│   ├── datos/
│   │   └── articulos_ejemplo.dart         # Datos de ejemplo en memoria
│   ├── tema/
│   │   └── tema_app.dart                  # Tema visual (colores, tarjetas, inputs) Material 3
│   ├── widgets/
│   │   ├── campo_busqueda.dart            # Barra de búsqueda
│   │   ├── chip_categoria.dart            # Filtro de categoría
│   │   └── tarjeta_articulo.dart          # Tarjeta de artículo (imagen, insignia, favorito, precio)
│   └── pantallas/
│       ├── pantalla_inicio.dart           # Inicio: saludo + buscador + filtros + cuadrícula
│       ├── pantalla_favoritos.dart        # Favoritos
│       ├── pantalla_mis_articulos.dart    # Mis artículos (con menú Editar/Eliminar)
│       ├── pantalla_detalle_articulo.dart # Detalle completo del artículo
│       └── pantalla_publicar.dart         # Formulario de publicación
└── test/
    └── widget_test.dart                   # Pruebas de humo
```

---

## Requisitos previos

1. Instalar [Flutter](https://docs.flutter.dev/get-started/install).
2. Comprobar la instalación:

   ```bash
   flutter doctor
   ```

3. Instalar dependencias del proyecto:

   ```bash
   flutter pub get
   ```

---

## Cómo ejecutar

```bash
# En el navegador (rápido para revisar la UI)
flutter run -d chrome

# En un emulador o dispositivo Android conectado
flutter run
```

---

## Cómo probar

```bash
flutter analyze   # Revisa errores y advertencias  -> "No issues found!"
flutter test      # Ejecuta las pruebas            -> "All tests passed!"
```

**Prueba manual sugerida:**
1. Abre la app y observa la cuadrícula de artículos de ejemplo.
2. Toca una tarjeta para abrir el **detalle**.
3. Cambia entre las pestañas **Inicio**, **Favoritos** y **Mis artículos**.
4. Pulsa el botón flotante **Publicar** para ver el formulario.

---

## Subir a GitHub

```bash
git init
git add .
git commit -m "Primer avance UniCambio: interfaz visual en Flutter"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/unicambio.git
git push -u origin main
```

---

## Notas

- Los artículos mostrados provienen de `lib/datos/articulos_ejemplo.dart` (datos de ejemplo).
- El código está **comentado** y documentado con `///` para facilitar el estudio.
- El botón de favoritos, la búsqueda, los filtros y el formulario están marcados como pendientes (`TODO`) para el siguiente avance.
