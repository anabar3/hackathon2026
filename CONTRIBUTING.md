# Guía de Contribución para BoardMee 

Gracias por tu interés en contribuir a BoardMee. Este proyecto busca conectar mentes a través de la proximidad física y tu ayuda es bienvenida.

## Requisitos de Desarrollo

Para trabajar en este proyecto, necesitarás:

- **Flutter SDK**: Versión estable más reciente.
- **Dart SDK**: Incluido con Flutter.
- **Android Studio** o **VS Code**.
- Un dispositivo Android físico (recomendado para probar el Bluetooth/BLE).

## Configuración del Entorno

1.  **Clona el repositorio:**
    ```bash
    git clone https://github.com/tu-usuario/hackathon2026.git
    cd hackathon2026
    ```
2.  **Instala las dependencias:**
    ```bash
    flutter pub get
    ```
3.  **Configura Supabase:**
    - Crea un proyecto en [Supabase](https://supabase.com/).
    - Copia el archivo `.env.example` a `.env` (si existe) y añade tu `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
4.  **Ejecuta la app:**
    ```bash
    flutter run
    ```

## Reglas del Proyecto

- **Estilo de Código:** Sigue las [guías oficiales de Dart](https://dart.dev/guides/language/effective-dart). Ejecuta `flutter format .` antes de subir cambios.
- **Ramas:** Crea una rama para cada funcionalidad o corrección: `feature/mi-funcionalidad` o `fix/nombre-del-error`.
- **Commits:** Usa mensajes claros y descriptivos en español (o inglés si prefieres).

## Cómo enviar tus cambios

1.  Haz un **Fork** del proyecto.
2.  Crea tu **Rama de funcionalidad** (`git checkout -b feature/NuevaMejora`).
3.  Haz **Commit** de tus cambios (`git commit -m 'Añadida nueva funcionalidad'`).
4.  Haz **Push** a la rama (`git push origin feature/NuevaMejora`).
5.  Abre un **Pull Request** detallando tus cambios y qué problemas resuelven.
