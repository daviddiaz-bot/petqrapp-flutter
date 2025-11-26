import 'dart:io';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _currentUser;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (error) {
      print('Error signing in: $error');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  bool get isSignedIn => _currentUser != null;

  Future<String?> uploadPetData({
    required String petId,
    required String petName,
    required Map<String, dynamic> petData,
    File? photoFile,
  }) async {
    if (_currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final authHeaders = await _currentUser!.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Crear carpeta "PetQRApp" si no existe
      final folderQuery = "name='PetQRApp' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final folderList = await driveApi.files.list(q: folderQuery);
      
      String? folderId;
      if (folderList.files != null && folderList.files!.isNotEmpty) {
        folderId = folderList.files!.first.id;
      } else {
        final folder = drive.File()
          ..name = 'PetQRApp'
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await driveApi.files.create(folder);
        folderId = createdFolder.id;
      }

      // Subir la foto y obtener URL pública
      String? photoId;
      if (photoFile != null) {
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
        print('Photo uploaded: $photoId');
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

      // Subir HTML
      final htmlMetadata = drive.File()
        ..name = 'pet_${petName}_${petId}.html'
        ..parents = [folderId!]
        ..mimeType = 'text/html';
      
      final htmlBytes = utf8.encode(htmlContent);
      final htmlMedia = drive.Media(
        Stream.value(htmlBytes),
        htmlBytes.length,
      );

      final uploadedHtml = await driveApi.files.create(
        htmlMetadata,
        uploadMedia: htmlMedia,
      );

      // Hacer público el HTML
      await driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        uploadedHtml.id!,
      );

      // URL que renderiza el HTML directamente
      final webViewUrl = 'https://drive.google.com/uc?export=download&id=${uploadedHtml.id}';
      print('✅ Pet page created: $webViewUrl');
      
      return webViewUrl;
    } catch (e) {
      print('❌ Error uploading to Drive: $e');
      return null;
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
