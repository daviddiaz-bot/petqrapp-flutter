import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegraphService {
  // Usar GitHub Gist como hosting HTML - 100% confiable y gratuito
  static const String gistApiUrl = 'https://api.github.com/gists';
  
  Future<String?> uploadPetPage({
    required String petId,
    required String petName,
    required Map<String, dynamic> petData,
    File? photoFile,
  }) async {
    try {
      print('📤 Creando página HTML...');
      
      // Convertir foto a base64
      String photoBase64 = '';
      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        photoBase64 = base64Encode(bytes);
        print('📸 Foto convertida a base64 (${bytes.length} bytes)');
      }
      
      // Crear HTML completo con foto embebida
      final htmlContent = _buildFullHtmlPage(petData, photoBase64);
      
      // Subir a GitHub Gist (anónimo, sin autenticación)
      print('🌐 Subiendo a GitHub Gist...');
      final gistUrl = await _createGist(
        filename: 'pet_${petName.replaceAll(' ', '_')}.html',
        content: htmlContent,
        description: '🐾 ${petData['name']} - PetQRApp',
      );
      
      if (gistUrl != null) {
        print('✅ Página creada: $gistUrl');
        return gistUrl;
      }
      
      return null;
      
    } catch (e) {
      print('❌ Error: $e');
      return null;
    }
  }
  
  Future<String?> _createGist({
    required String filename,
    required String content,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(gistApiUrl),
        headers: {
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'description': description,
          'public': true,
          'files': {
            filename: {
              'content': content,
            }
          }
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final gistId = data['id'];
        final htmlFilename = data['files'].keys.first;
        
        // URL directa al HTML raw
        final rawUrl = 'https://gist.githubusercontent.com/anonymous/$gistId/raw/$htmlFilename';
        
        // Usar htmlpreview para renderizar
        return 'https://htmlpreview.github.io/?$rawUrl';
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
      
      return null;
    } catch (e) {
      print('Error creating gist: $e');
      return null;
    }
  }
  
  String _buildFullHtmlPage(Map<String, dynamic> petData, String photoBase64) {
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
        .photo-container {
            width: 100%;
            background: #f5f5f5;
            ${photoBase64.isNotEmpty ? '' : 'display: none;'}
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
        .info { padding: 30px 20px; }
        .section { margin-bottom: 25px; }
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
        
        ${photoBase64.isNotEmpty ? '''
        <div class="photo-container">
            <img class="photo" src="data:image/jpeg;base64,$photoBase64" alt="${petData['name']}">
        </div>
        ''' : '''
        <div class="photo-placeholder">📷</div>
        '''}
        
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
            🐾 Generado con PetQRApp
        </div>
    </div>
</body>
</html>
''';
  }
}
