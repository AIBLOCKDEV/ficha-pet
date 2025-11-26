# Ficha Pet - Aplicación Flutter

Aplicación móvil para gestión de salud de mascotas, convertida desde HTML a Flutter para generar APK.

## Características

- ✅ Dashboard con lista de mascotas
- ✅ Formulario de edición/creación de mascotas
- ✅ Visualización detallada de cada mascota
- ✅ Recordatorios de vacunas y desparasitación
- ✅ Historial médico
- ✅ Gráficos de evolución de peso
- ✅ Exportación a PDF
- ✅ Generación de códigos QR
- ✅ Almacenamiento local de datos
- ✅ Subida de imágenes (foto de mascota, carnet de vacunación)

## Requisitos

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio o VS Code con extensiones de Flutter
- Android SDK para generar APK

## Instalación

1. Asegúrate de tener Flutter instalado:
```bash
flutter --version
```

2. Navega a la carpeta del proyecto:
```bash
cd app
```

3. Instala las dependencias:
```bash
flutter pub get
```

## Ejecutar la aplicación

Para ejecutar en modo desarrollo:
```bash
flutter run
```

## Generar APK

Para generar un APK de release:

```bash
flutter build apk --release
```

El APK se generará en: `build/app/outputs/flutter-apk/app-release.apk`

Para generar un APK dividido por arquitectura (recomendado para reducir tamaño):
```bash
flutter build apk --split-per-abi
```

Esto generará APKs separados para:
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

## Generar App Bundle (AAB) para Google Play

Para subir a Google Play Store, genera un App Bundle:
```bash
flutter build appbundle --release
```

El archivo se generará en: `build/app/outputs/bundle/release/app-release.aab`

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── models/
│   └── pet.dart              # Modelos de datos
├── providers/
│   └── pet_provider.dart     # Gestión de estado
├── screens/
│   ├── dashboard_screen.dart  # Pantalla principal
│   ├── edit_pet_screen.dart  # Formulario de edición
│   └── view_pet_screen.dart  # Vista detallada
├── services/
│   ├── storage_service.dart  # Almacenamiento local
│   ├── file_service.dart     # Manejo de archivos
│   ├── pdf_service.dart      # Exportación PDF
│   └── qr_service.dart       # Generación QR
├── widgets/
│   ├── pet_card.dart         # Tarjeta de mascota
│   ├── reminder_card.dart    # Tarjeta de recordatorio
│   ├── weight_chart.dart     # Gráfico de peso
│   └── medical_history_widget.dart # Widget de historial
└── utils/
    ├── app_theme.dart        # Tema de la aplicación
    └── date_utils.dart       # Utilidades de fecha
```

## Permisos necesarios

La aplicación requiere los siguientes permisos en Android (ya configurados en `android/app/src/main/AndroidManifest.xml`):

- `android.permission.INTERNET` - Para cargar imágenes
- `android.permission.CAMERA` - Para tomar fotos
- `android.permission.READ_EXTERNAL_STORAGE` - Para seleccionar imágenes
- `android.permission.WRITE_EXTERNAL_STORAGE` - Para guardar PDFs

## Notas

- Los datos se almacenan localmente usando SharedPreferences
- Las imágenes se guardan en formato base64
- Los PDFs se generan y se pueden compartir
- Los códigos QR contienen información básica de la mascota en formato JSON

## Desarrollo

Para ejecutar en modo debug con hot reload:
```bash
flutter run
```

Para ejecutar en modo release:
```bash
flutter run --release
```

## Solución de Problemas

Si encuentras errores al ejecutar `flutter pub get`, asegúrate de tener:
- Flutter actualizado: `flutter upgrade`
- Dart actualizado: `dart --version`

Si hay problemas con las imágenes base64, verifica que las imágenes se estén codificando correctamente.

