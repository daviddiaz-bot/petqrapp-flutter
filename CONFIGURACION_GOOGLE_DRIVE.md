# 🔧 Configuración de Google Drive para PetQRApp

## 📋 Pasos para Habilitar Google Drive

### 1. Crear Proyecto en Google Cloud Console

1. Ve a: https://console.cloud.google.com/
2. Clic en **"Crear proyecto"**
3. Nombre: `PetQRApp`
4. Clic en **"Crear"**

### 2. Habilitar Google Drive API

1. En el menú lateral: **APIs y servicios** → **Biblioteca**
2. Busca: `Google Drive API`
3. Clic en **"Habilitar"**

### 3. Configurar Pantalla de Consentimiento OAuth

1. Ve a: **APIs y servicios** → **Pantalla de consentimiento de OAuth**
2. Selecciona: **Externo**
3. Completa:
   - Nombre de la aplicación: `PetQRApp`
   - Correo de asistencia: tu email
   - Correo de contacto del desarrollador: tu email
4. Clic en **"Guardar y continuar"**
5. En **"Ámbitos"**: Clic en **"Añadir o quitar ámbitos"**
   - Busca y selecciona: `https://www.googleapis.com/auth/drive.file`
   - Busca y selecciona: `https://www.googleapis.com/auth/drive.appdata`
6. Clic en **"Guardar y continuar"**
7. En **"Usuarios de prueba"**: Añade tu email de Gmail
8. Clic en **"Guardar y continuar"**

### 4. Crear Credenciales OAuth 2.0

1. Ve a: **APIs y servicios** → **Credenciales**
2. Clic en **"+ CREAR CREDENCIALES"** → **ID de cliente de OAuth 2.0**
3. Tipo de aplicación: **Android**
4. Nombre: `PetQRApp Android`

### 5. Obtener SHA-1 del Certificado de Debug

Necesitamos el SHA-1 del certificado que usa GitHub Actions. 

**Opción A - Generar nuevo keystore:**

Ejecuta en PowerShell:
```powershell
cd C:\Users\david\Documents\petqrapp_flutter\android\app
keytool -genkey -v -keystore petqrapp-release.keystore -alias petqrapp -keyalg RSA -keysize 2048 -validity 10000
```

Cuando te pregunte la contraseña, usa: `petqrapp2025`

Luego obtén el SHA-1:
```powershell
keytool -list -v -keystore petqrapp-release.keystore -alias petqrapp
```

**Opción B - Usar el debug keystore de Android:**
```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### 6. Configurar OAuth con SHA-1

1. Copia el **SHA-1** que obtuviste
2. En Google Cloud Console → Credenciales → Tu ID de cliente OAuth Android
3. Pega el SHA-1 en **"Huella digital de certificado SHA-1"**
4. Nombre del paquete: `com.petqrapp.flutter`
5. Clic en **"Crear"**

### 7. Descargar google-services.json

1. Ve a: https://console.firebase.google.com/
2. Clic en **"Agregar proyecto"**
3. Selecciona el proyecto `PetQRApp` que creaste
4. Clic en el ícono de Android (</>) para agregar app Android
5. Nombre del paquete: `com.petqrapp.flutter`
6. Apodo de la app: `PetQRApp`
7. **Descarga** el archivo `google-services.json`
8. Colócalo en: `android/app/google-services.json`

### 8. Configurar build.gradle

Ya está configurado en el código, pero verifica que tengas:

**android/build.gradle:**
```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:7.3.0'
    classpath 'com.google.gms:google-services:4.3.15'  // ← Agregar esta línea
}
```

**android/app/build.gradle:**
```gradle
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'  // ← Agregar esta línea
```

### 9. Probar la Aplicación

1. Descarga el nuevo APK de GitHub Actions
2. Instala en tu teléfono
3. Registra una mascota
4. Deberás ver:
   - ✅ Pantalla de login de Google
   - ✅ "Conectando con tu Google Drive..."
   - ✅ Solicitud de permisos de Drive
   - ✅ "Subiendo a tu Drive..."
   - ✅ "✅ Guardado en tu Google Drive"

## ✅ Verificación

Para verificar que funcionó:

1. Abre tu Google Drive en el navegador
2. Deberías ver una carpeta llamada **"PetQRApp"**
3. Dentro estará el archivo HTML con la información de la mascota
4. El QR contiene la URL de ese archivo

## 🔒 Privacidad y Seguridad

- ✅ Los datos están en el Drive del USUARIO, no en un servidor externo
- ✅ Solo el usuario puede eliminar sus datos
- ✅ Si elimina la mascota en la app, también se borra de Drive
- ✅ El archivo HTML es público (anyone with link) para que el QR funcione
- ✅ Nadie puede editar, solo ver con el link del QR

## 🆘 Solución de Problemas

**Si el login falla:**
- Verifica que el SHA-1 esté correcto
- Verifica que el package name sea: `com.petqrapp.flutter`
- Asegúrate de estar en "Usuarios de prueba" en OAuth

**Si no sube a Drive:**
- Verifica que Google Drive API esté habilitada
- Verifica que los scopes incluyan `drive.file`
- Revisa los logs de la app

## 📞 Contacto

Si tienes problemas con la configuración, avísame y te ayudo paso a paso.
