# 🐾 PetQRApp - Flutter

Generador de códigos QR para mascotas con almacenamiento en Google Drive.

## 📱 Características

- Registro de mascotas con foto
- Generación de código QR
- Almacenamiento seguro en Google Drive del dueño
- Página web automática con info de la mascota
- Compartir QR por WhatsApp/Email

## 🚀 Instalación

1. Descargar APK desde GitHub Actions
2. Instalar en Android
3. Iniciar sesión con Google al registrar primera mascota

## 📦 Estructura

```
petqrapp_flutter/
├── android/          # Proyecto Android nativo
├── lib/              # Código fuente Flutter
│   ├── models/       # Modelos de datos
│   ├── screens/      # Pantallas de la app
│   ├── services/     # Servicios (Drive, Storage)
│   └── utils/        # Utilidades y validadores
├── .github/          # GitHub Actions workflows
└── pubspec.yaml      # Dependencias del proyecto
```

## 🔧 Desarrollo

```bash
flutter pub get
flutter run
```

## 📥 APK

Descarga desde: https://github.com/daviddiaz-bot/petqrapp-flutter/actions
