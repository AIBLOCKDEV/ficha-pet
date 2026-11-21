# Guía de Despliegue en Servidor y Publicación en Tiendas (Google Play & App Store)

## 1. Base de Datos y Servidor Backend (`server/`)

El proyecto incluye en [`server/`](file:///c:/Users/renny/Desktop/generado%20por%20IA/Ficha%20Pet/app/server) el esquema SQL relacional, el servidor API REST y el motor de notificaciones push.

### Archivos incluidos
- [`server/schema.sql`](file:///c:/Users/renny/Desktop/generado%20por%20IA/Ficha%20Pet/app/server/schema.sql): Tablas `users`, `pets`, `push_devices` y `push_dispatch_log` (compatible con PostgreSQL y SQLite).
- [`server/server.js`](file:///c:/Users/renny/Desktop/generado%20por%20IA/Ficha%20Pet/app/server/server.js): API REST (`/api/health`, `/api/auth/register`, `/api/auth/login`, `/api/pets`, `/api/pets/sync`, `/api/notifications/pending`) con evaluación de recordatorios anticipados y repetición cada 2 días para vacunas vencidas.
- [`server/Dockerfile`](file:///c:/Users/renny/Desktop/generado%20por%20IA/Ficha%20Pet/app/server/Dockerfile) y [`server/docker-compose.yml`](file:///c:/Users/renny/Desktop/generado%20por%20IA/Ficha%20Pet/app/server/docker-compose.yml): Contenedor listo para producción.

### Cómo montar el servidor
```bash
# Opción A: Directo con Node.js (>= 18)
cd app/server
node server.js

# Opción B: Con Docker Compose en tu VPS / servidor cloud
cd app/server
docker compose up -d --build
```

Una vez desplegado en tu dominio (por ejemplo `https://api.fichapet.com/api`), puedes configurarlo en la app desde **Mi Perfil → Configurar servidor y base de datos** o cambiar `defaultBaseUrl` en [`lib/services/api_service.dart`](file:///c:/Users/renny/Desktop/generado%20por%20IA/Ficha%20Pet/app/lib/services/api_service.dart).

---

## 2. Publicación en Google Play Store (Android)

El `applicationId` ya está configurado para producción como `com.fichapet.app` en [`android/app/build.gradle.kts`](file:///c:/Users/renny/Desktop/generado%20por%20IA/Ficha%20Pet/app/android/app/build.gradle.kts) (no usa `com.example`), con íconos generados desde el logo oficial de **Ficha + Pet** y permisos de notificaciones (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`).

1. **Generar tu Keystore de firma**:
   ```bash
   keytool -genkey -v -keystore app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **Crear `app/android/key.properties`** (puedes copiar [`android/key.properties.example`](file:///c:/Users/renny/Desktop/generado%20por%20IA/Ficha%20Pet/app/android/key.properties.example)).
3. **Compilar el Android App Bundle (`.aab`) para Google Play Console**:
   ```bash
   cd app
   flutter build appbundle --release --dart-define=API_BASE_URL=https://api.tudominio.com/api
   ```
   El archivo listo para subir a Google Play Console estará en:
   `app/build/app/outputs/bundle/release/app-release.aab`

---

## 3. Publicación en Apple App Store (iOS)

En un equipo macOS con Xcode instalado:

1. **Generar/actualizar carpeta `ios/` con el Bundle ID de producción**:
   ```bash
   cd app
   flutter create --platforms=ios --org com.fichapet .
   ```
2. **Permisos en `ios/Runner/Info.plist`**:
   Agrega las descripciones requeridas por App Store Review:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Ficha Pet necesita acceso a la cámara para fotografiar a tu mascota y su carnet de vacunación.</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>Ficha Pet necesita acceso a tu galería para adjuntar fotos de tu mascota, carnet de vacunas y exámenes médicos.</string>
   ```
3. **Compilar el archivo IPA para App Store Connect / TestFlight**:
   ```bash
   flutter build ipa --release --dart-define=API_BASE_URL=https://api.tudominio.com/api
   ```
