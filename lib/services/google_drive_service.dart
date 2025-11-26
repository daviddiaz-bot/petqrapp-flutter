import 'dart:io';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  GoogleSignInAccount? _currentUser;
  String? _userEmail;

  Future<bool> signIn() async {
    try {
      print('🔵 [Drive] Intentando login con Google...');
      _currentUser = await _googleSignIn.signIn();

      if (_currentUser != null) {
        _userEmail = _currentUser!.email;
        print('🟢 [Drive] Login exitoso: $_userEmail');
        return true;
      }

      print('🔴 [Drive] Login cancelado por el usuario');
      return false;
    } catch (error) {
      print('🔴 [Drive] Error en login: $error');
      print('🔴 [Drive] Tipo de error: ${error.runtimeType}');
      if (error is Exception) {
        final msg = error.toString();
        if (msg.contains('DEVELOPER_ERROR')) {
          print('⚠️ [Drive] DEVELOPER_ERROR: Falta configurar SHA-1 y google-services.json en Firebase/Google Cloud.');
        } else if (msg.contains('API_NOT_CONNECTED')) {
          print('⚠️ [Drive] API_NOT_CONNECTED: Revisa conexión o permisos de Drive API habilitados.');
        }
      }
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _userEmail = null;
  }

  bool get isSignedIn => _currentUser != null;
  String? get userEmail => _userEmail;

  Future<String?> uploadPetData({
    required String petId,
    required String petName,
    required Map<String, dynamic> petData,
    File? photoFile,
  }) async {
    if (_currentUser == null) {
      print('🔴 [Drive] ERROR: Usuario no autenticado antes de uploadPetData');
      throw Exception('Usuario no autenticado. Inicia sesión en Google primero.');
    }

    try {
      print('🔵 [Drive] Iniciando upload a Drive...');
      print('🔵 [Drive] Usuario: $_userEmail');
      
      final authHeaders = await _currentUser!.authHeaders;
      print('🔵 [Drive] Headers obtenidos: ${authHeaders.keys.join(', ')}');
      
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Crear carpeta "PetQRApp" en el Drive del usuario
      print('🔵 [Drive] Buscando carpeta PetQRApp...');
      final folderQuery = "name='PetQRApp' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final folderList = await driveApi.files.list(q: folderQuery);
      
      String? folderId;
      if (folderList.files != null && folderList.files!.isNotEmpty) {
        folderId = folderList.files!.first.id;
        print('🟢 [Drive] Carpeta encontrada: $folderId');
      } else {
        print('🔵 [Drive] Creando carpeta PetQRApp...');
        final folder = drive.File()
          ..name = 'PetQRApp'
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await driveApi.files.create(folder);
        folderId = createdFolder.id;
        print('🟢 [Drive] Carpeta creada: $folderId');
      }

      // Subir la foto y obtener URL pública
      String? photoId;
      if (photoFile != null) {
        print('🔵 [Drive] Subiendo foto...');
        final photoMetadata = drive.File()
          ..name = 'photo_${petId}.jpg'
          ..parents = [folderId!];
        
        final photoMedia = drive.Media(
          photoFile.openRead(),
          photoFile.lengthSync(),
        );
        
        final uploadedPhoto = await driveApi.files.create(
          photoMetadata,
          uploadMedia: photoMedia,
        );

        // Hacer público
        await driveApi.permissions.create(
          drive.Permission()
            ..type = 'anyone'
            ..role = 'reader',
          uploadedPhoto.id!,
        );
        
        photoId = uploadedPhoto.id;
        print('🟢 [Drive] Foto subida ID: $photoId');
      }

      // Convertir foto a base64 para respaldo
      String photoBase64 = '';
      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        photoBase64 = base64Encode(bytes);
      }

      // Crear HTML con MÚLTIPLES URLs de foto para máxima compatibilidad
      final photoUrl1 = photoId != null ? 'https://drive.google.com/uc?export=view&id=$photoId' : '';
      final photoUrl2 = photoId != null ? 'https://drive.usercontent.google.com/download?id=$photoId&export=view' : '';
      final photoUrl3 = photoId != null ? 'https://lh3.googleusercontent.com/d/$photoId' : '';
      
      final htmlContent = '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>🐾 ${petData['name']}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 500px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .header {
            background: linear-gradient(135deg, #4A90E2, #7B68EE);
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        .header h1 { font-size: 32px; margin-bottom: 5px; }
        .header p { opacity: 0.9; font-size: 16px; }
        .photo-container {
            width: 100%;
            background: #f5f5f5;
            position: relative;
            overflow: hidden;
        }
        .photo {
            width: 100%;
            height: auto;
            max-height: 400px;
            object-fit: cover;
            display: block;
        }
        .photo-placeholder {
            width: 100%;
            height: 250px;
            background: linear-gradient(135deg, #f0f0f0 0%, #e0e0e0 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 64px;
        }
        .info {
            padding: 30px 20px;
        }
        .section {
            margin-bottom: 25px;
        }
        .section-title {
            font-size: 14px;
            color: #7B68EE;
            font-weight: 600;
            margin-bottom: 15px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .field {
            margin-bottom: 15px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 10px;
        }
        .field-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
        }
        .field-value {
            font-size: 18px;
            color: #333;
            font-weight: 500;
        }
        .icon { margin-right: 8px; }
        .contact-btn {
            display: block;
            background: #4CAF50;
            color: white;
            padding: 18px;
            border-radius: 30px;
            text-decoration: none;
            text-align: center;
            margin: 20px 0;
            font-weight: 600;
            font-size: 18px;
            box-shadow: 0 4px 15px rgba(76,175,80,0.3);
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #999;
            font-size: 12px;
            border-top: 1px solid #eee;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🐾 ${petData['name']}</h1>
            <p>Información de Mascota Registrada</p>
        </div>
        
        <div class="photo-container">
            ${photoBase64.isNotEmpty ? '''
            <img 
                id="petPhoto" 
                class="photo" 
                src="data:image/jpeg;base64,$photoBase64"
                alt="${petData['name']}"
                onerror="this.style.display='none'; document.getElementById('photoPlaceholder').style.display='flex';"
            >
            <div id="photoPlaceholder" class="photo-placeholder" style="display:none;">
                📷
            </div>
            ''' : '''
            <div class="photo-placeholder">📷</div>
            '''}
        </div>
        
        <div class="info">
            <div class="section">
                <div class="section-title">📋 Información de la Mascota</div>
                <div class="field">
                    <div class="field-label">Nombre</div>
                    <div class="field-value"><span class="icon">🐕</span>${petData['name']}</div>
                </div>
                <div class="field">
                    <div class="field-label">Raza</div>
                    <div class="field-value"><span class="icon">🎨</span>${petData['breed']}</div>
                </div>
                <div class="field">
                    <div class="field-label">Edad</div>
                    <div class="field-value"><span class="icon">📅</span>${petData['age']} años</div>
                </div>
                <div class="field">
                    <div class="field-label">Color</div>
                    <div class="field-value"><span class="icon">🎯</span>${petData['color']}</div>
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">👤 Contacto del Dueño</div>
                <div class="field">
                    <div class="field-label">Nombre del Dueño</div>
                    <div class="field-value"><span class="icon">👤</span>${petData['ownerName']}</div>
                </div>
                <div class="field">
                    <div class="field-label">Teléfono</div>
                    <div class="field-value"><span class="icon">📞</span>${petData['ownerPhone']}</div>
                </div>
                <div class="field">
                    <div class="field-label">Dirección</div>
                    <div class="field-value"><span class="icon">📍</span>${petData['ownerAddress']}</div>
                </div>
            </div>
            
            <a href="tel:${petData['ownerPhone']}" class="contact-btn">
                📞 Llamar al Dueño Ahora
            </a>
        </div>
        
        <div class="footer">
            🐾 Generado con PetQRApp<br>
            Información almacenada en Google Drive
        </div>
    </div>
    
    <script>
        // Intentar cargar foto desde múltiples URLs si base64 falla
        const photo = document.getElementById('petPhoto');
        if (photo && !photo.complete) {
            const urls = [
                '$photoUrl1',
                '$photoUrl2',
                '$photoUrl3'
            ].filter(url => url);
            
            let urlIndex = 0;
            photo.onerror = function() {
                urlIndex++;
                if (urlIndex < urls.length) {
                    this.src = urls[urlIndex];
                } else {
                    this.style.display = 'none';
                    document.getElementById('photoPlaceholder').style.display = 'flex';
                }
            };
        }
    </script>
</body>
</html>
''';

      // Subir HTML a Drive
      final htmlMetadata = drive.File()
        ..name = 'pet_${petName}_${petId}.html'
        ..parents = [folderId!]
        ..mimeType = 'text/html'
        ..description = 'PetQRApp - Información de $petName';
      
      final htmlBytes = utf8.encode(htmlContent);
      final htmlMedia = drive.Media(
        Stream.value(htmlBytes),
        htmlBytes.length,
      );

      final uploadedHtml = await driveApi.files.create(
        htmlMetadata,
        uploadMedia: htmlMedia,
      );

      // Hacer público el HTML con permisos de lectura para cualquiera
      await driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader'
          ..allowFileDiscovery = false,
        uploadedHtml.id!,
      );

      // SOLUCIÓN: Usar htmlpreview.github.io para renderizar HTML de Drive
      // Esta URL abre el HTML en un visor que soporta renderizado completo
      final googleDriveRawUrl = 'https://drive.google.com/uc?export=download&id=${uploadedHtml.id}';
      final webViewUrl = 'https://htmlpreview.github.io/?$googleDriveRawUrl';
      
      print('✅ [Drive] Página HTML creada:');
      print('   ➤ Drive ID: ${uploadedHtml.id}');
      print('   ➤ Raw URL: $googleDriveRawUrl');
      print('   ➤ Preview URL (QR): $webViewUrl');
      
      return webViewUrl;
    } catch (e) {
      print('❌ [Drive] Error subiendo a Drive: $e');
      if (e.toString().contains('403')) {
        print('⚠️ [Drive] 403 Forbidden: Verifica que Drive API esté habilitada y los scopes estén en la pantalla de consentimiento.');
      }
      if (e.toString().contains('401')) {
        print('⚠️ [Drive] 401 Unauthorized: Revisa configuración de OAuth y google-services.json.');
      }
      return null;
    }
  }

    // Eliminar archivo HTML alojado en Drive a partir de la URL almacenada
    Future<bool> deleteFile(String driveUrl) async {
      try {
        // Extraer ID del archivo desde la URL (puede venir con htmlpreview)
        // Formatos posibles contienen id=FILE_ID
        String? fileId;
        if (driveUrl.contains('id=')) {
          final idIndex = driveUrl.indexOf('id=') + 3;
          final ampIndex = driveUrl.indexOf('&', idIndex);
          fileId = ampIndex == -1 ? driveUrl.substring(idIndex) : driveUrl.substring(idIndex, ampIndex);
        }
        if (fileId == null || fileId.isEmpty) {
          print('⚠️ No se pudo extraer el ID de la URL para deleteFile');
          return false;
        }
        print('🔵 Eliminando archivo Drive ID: $fileId');

        // Asegurar sesión
        if (_currentUser == null) {
          await _googleSignIn.signInSilently();
          _currentUser = _googleSignIn.currentUser;
        }
        if (_currentUser == null) {
          print('⚠️ Usuario no autenticado, no se elimina de Drive');
          return false;
        }

        final authHeaders = await _currentUser!.authHeaders;
        final client = GoogleAuthClient(authHeaders);
        final api = drive.DriveApi(client);
        await api.files.delete(fileId);
        print('🟢 Archivo eliminado correctamente de Drive');
        return true;
      } catch (e) {
        print('❌ Error eliminando archivo de Drive: $e');
        return false;
      }
    }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
