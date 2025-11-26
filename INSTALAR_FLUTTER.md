# Instalación de Flutter para Windows

## Pasos para Instalar Flutter

### 1. Descargar Flutter SDK

1. Ve a: https://docs.flutter.dev/get-started/install/windows
2. Descarga el SDK de Flutter (ZIP)
3. Extrae el archivo ZIP a una ubicación como `C:\src\flutter` (evita usar rutas con espacios o caracteres especiales)

### 2. Agregar Flutter al PATH

1. Abre el Panel de Control
2. Busca "Variables de entorno"
3. En "Variables del sistema", selecciona "Path" y haz clic en "Editar"
4. Haz clic en "Nuevo" y agrega la ruta completa a `flutter\bin` (ejemplo: `C:\src\flutter\bin`)
5. Haz clic en "Aceptar" en todas las ventanas

### 3. Verificar la Instalación

Abre una nueva terminal (PowerShell o CMD) y ejecuta:

```bash
flutter doctor
```

Este comando verificará que todo esté instalado correctamente.

### 4. Instalar Android Studio (Recomendado)

1. Descarga Android Studio desde: https://developer.android.com/studio
2. Instala Android Studio
3. Durante la instalación, asegúrate de instalar:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)

### 5. Configurar Android SDK

1. Abre Android Studio
2. Ve a Tools > SDK Manager
3. En la pestaña "SDK Platforms", instala:
   - Android 13.0 (Tiramisu) o superior
4. En la pestaña "SDK Tools", asegúrate de tener instalado:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android SDK Platform-Tools

### 6. Aceptar Licencias de Android

Ejecuta en la terminal:

```bash
flutter doctor --android-licenses
```

Acepta todas las licencias escribiendo `y` cuando se solicite.

### 7. Verificar Instalación Completa

Ejecuta nuevamente:

```bash
flutter doctor
```

Deberías ver una salida similar a:

```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x, on Microsoft Windows ...)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Visual Studio - develop for Windows
[✓] Android Studio (version 2023.x)
[✓] VS Code (version x.x.x)
[✓] Connected device
[✓] Network resources
```

### 8. Una Vez Instalado Flutter

Navega a la carpeta del proyecto y ejecuta:

```bash
cd app
flutter pub get
flutter run
```

## Alternativa: Usar Visual Studio Code

Si prefieres VS Code:

1. Instala VS Code desde: https://code.visualstudio.com/
2. Instala la extensión "Flutter" en VS Code
3. Abre la carpeta `app` en VS Code
4. Presiona F5 o haz clic en "Run > Start Debugging"

## Notas Importantes

- **Flutter debe estar en el PATH** para que funcione desde cualquier terminal
- **Necesitas una terminal nueva** después de agregar Flutter al PATH para que los cambios surtan efecto
- **Android Studio** es recomendado pero no obligatorio; puedes usar VS Code con Flutter
- **Para generar APK**, necesitas Android SDK instalado

## Solución de Problemas Comunes

### Flutter no se reconoce
- Verifica que Flutter esté en el PATH
- Abre una nueva terminal después de agregar Flutter al PATH
- Reinicia tu computadora si es necesario

### Android SDK no encontrado
- Instala Android Studio
- Ejecuta `flutter doctor` para ver qué falta
- Sigue las sugerencias que muestra `flutter doctor`

### Licencias de Android no aceptadas
- Ejecuta `flutter doctor --android-licenses`
- Acepta todas las licencias

