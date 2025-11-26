# Instrucciones para Generar APK

## Pasos para Compilar y Generar el APK

### 1. Verificar Instalación de Flutter

Asegúrate de tener Flutter instalado y configurado:
```bash
flutter doctor
```

Este comando verificará que todo esté correctamente instalado.

### 2. Navegar a la Carpeta del Proyecto

```bash
cd app
```

### 3. Instalar Dependencias

```bash
flutter pub get
```

### 4. Verificar que el Proyecto Compila

```bash
flutter analyze
```

### 5. Generar APK de Release

Para generar un APK optimizado para producción:

```bash
flutter build apk --release
```

El APK se encontrará en:
```
app/build/app/outputs/flutter-apk/app-release.apk
```

### 6. Generar APK Dividido por Arquitectura (Recomendado)

Para reducir el tamaño del APK, genera versiones separadas por arquitectura:

```bash
flutter build apk --split-per-abi --release
```

Esto generará:
- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit)
- `app-x86_64-release.apk` (para emuladores)

### 7. Generar App Bundle para Google Play

Si planeas publicar en Google Play Store:

```bash
flutter build appbundle --release
```

El archivo `.aab` se encontrará en:
```
app/build/app/outputs/bundle/release/app-release.aab
```

## Requisitos Previos

- Flutter SDK >= 3.0.0
- Android SDK instalado
- Java JDK 8 o superior
- Android Studio (recomendado) o VS Code con extensiones de Flutter

## Solución de Problemas Comunes

### Error: "Flutter SDK not found"
- Asegúrate de tener Flutter instalado y en el PATH
- Ejecuta `flutter doctor` para verificar la instalación

### Error: "Gradle sync failed"
- Abre Android Studio y sincroniza el proyecto
- Verifica que tengas Android SDK instalado

### Error al compilar
- Ejecuta `flutter clean`
- Luego `flutter pub get`
- Intenta compilar nuevamente

### Error con permisos de Android
- Verifica que `AndroidManifest.xml` tenga los permisos necesarios
- Ya están configurados en el proyecto

## Notas Importantes

- El APK de release está firmado con una clave de debug por defecto
- Para producción, deberás configurar una clave de firma propia
- El tamaño del APK puede variar según las dependencias incluidas
- Los APKs divididos por arquitectura son más pequeños y recomendados

## Estructura del APK Generado

El APK incluirá:
- ✅ Todas las dependencias necesarias
- ✅ Assets y recursos de la aplicación
- ✅ Código Dart compilado a código nativo
- ✅ Permisos configurados para cámara, almacenamiento, etc.

