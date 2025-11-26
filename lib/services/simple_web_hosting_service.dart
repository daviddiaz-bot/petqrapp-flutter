import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio simple de hosting HTML usando GitHub Gist
/// NO requiere autenticación OAuth - solo email del usuario
class SimpleWebHostingService {
  
  /// Crea página HTML pública con información de la mascota
  /// Retorna URL pública que se puede usar en el QR
  Future<String?> createPetPage({
    required String ownerEmail,
    required String petId,
    required String petName,
    required Map<String, dynamic> petData,
    File? photoFile,
  }) async {
    try {
      print('🌐 [Web] Creando página web para $petName...');
      print('📧 [Web] Email del dueño: $ownerEmail');
      
      // Convertir foto a base64
      String photoBase64 = '';
      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        photoBase64 = base64Encode(bytes);
        print('📸 [Web] Foto convertida: ${bytes.length} bytes');
      }
      
      // Generar HTML completo
      final htmlContent = _generateHTML(petData, photoBase64, ownerEmail);
      
      // Subir a GitHub Gist (público, anónimo)
      final gistUrl = await _uploadToGist(
        filename: '${petName.replaceAll(' ', '_')}_$petId.html',
        content: htmlContent,
        description: '🐾 $petName - PetQRApp',
      );
      
      if (gistUrl != null) {
        print('✅ [Web] Página creada: $gistUrl');
        return gistUrl;
      }
      
      print('⚠️ [Web] No se pudo crear la página');
      return null;
      
    } catch (e) {
      print('❌ [Web] Error: $e');
      return null;
    }
  }
  
  Future<String?> _uploadToGist({
    required String filename,
    required String content,
    required String description,
  }) async {
    try {
      print('📤 [Gist] Subiendo archivo: $filename');
      print('📤 [Gist] Tamaño contenido: ${content.length} chars');
      
      final response = await http.post(
        Uri.parse('https://api.github.com/gists'),
        headers: {
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'description': description,
          'public': true,
          'files': {
            filename: {'content': content}
          }
        }),
      );
      
      print('📥 [Gist] Status code: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        // final gistId = data['id']; // No usado
        final files = data['files'] as Map<String, dynamic>;
        final firstFile = files.keys.first;
        final rawUrl = files[firstFile]['raw_url'];
        
        final finalUrl = 'https://htmlpreview.github.io/?$rawUrl';
        print('✅ [Gist] URL generada: $finalUrl');
        
        // Usar servicio de rendering HTML
        return finalUrl;
      }
      
      print('⚠️ [Gist] Error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e, stackTrace) {
      print('❌ [Gist] Excepción: $e');
      print('❌ [Gist] Stack: $stackTrace');
      return null;
    }
  }
  
  String _generateHTML(Map<String, dynamic> petData, String photoBase64, String ownerEmail) {
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
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            max-width: 500px;
            width: 100%;
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
        .header h1 {
            font-size: 32px;
            margin-bottom: 8px;
            font-weight: 700;
        }
        .header p {
            opacity: 0.95;
            font-size: 16px;
        }
        .photo-section {
            width: 100%;
            ${photoBase64.isEmpty ? 'display: none;' : ''}
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
            font-size: 80px;
        }
        .content {
            padding: 30px 20px;
        }
        .section {
            margin-bottom: 30px;
        }
        .section-title {
            font-size: 13px;
            color: #7B68EE;
            font-weight: 700;
            margin-bottom: 16px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
        }
        .field {
            margin-bottom: 16px;
            padding: 16px;
            background: #f8f9fa;
            border-radius: 12px;
            border-left: 4px solid #7B68EE;
        }
        .field-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 6px;
            font-weight: 600;
        }
        .field-value {
            font-size: 18px;
            color: #333;
            font-weight: 500;
            display: flex;
            align-items: center;
        }
        .icon {
            margin-right: 10px;
            font-size: 20px;
        }
        .contact-btn {
            display: block;
            background: linear-gradient(135deg, #4CAF50, #45a049);
            color: white;
            padding: 18px;
            border-radius: 30px;
            text-decoration: none;
            text-align: center;
            margin: 25px 0;
            font-weight: 600;
            font-size: 18px;
            box-shadow: 0 4px 15px rgba(76,175,80,0.4);
            transition: transform 0.2s;
        }
        .contact-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(76,175,80,0.5);
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #999;
            font-size: 13px;
            border-top: 1px solid #eee;
            background: #fafafa;
        }
        .footer small {
            display: block;
            margin-top: 8px;
            font-size: 11px;
            color: #bbb;
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
        <div class="photo-section">
            <img class="photo" src="data:image/jpeg;base64,$photoBase64" alt="${petData['name']}">
        </div>
        ''' : '''
        <div class="photo-placeholder">📷</div>
        '''}
        
        <div class="content">
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
            <small>Registrado por: $ownerEmail</small>
        </div>
    </div>
</body>
</html>
''';
  }
}
