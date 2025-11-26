import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegraphService {
  // Servicio gratuito de hosting HTML - NO requiere autenticación
  static const String telegraphApiUrl = 'https://api.telegra.ph';
  
  // ImgBB API key gratuita (pública para demos)
  static const String imgbbApiKey = '8b3a0c8c5f8f7c8c5f8f7c8c5f8f7c8c';
  
  Future<String?> uploadPetPage({
    required String petId,
    required String petName,
    required Map<String, dynamic> petData,
    File? photoFile,
  }) async {
    try {
      print('📤 Iniciando upload a Telegraph...');
      
      // 1. Subir foto a ImgBB si existe
      String? photoUrl;
      if (photoFile != null) {
        print('📸 Subiendo foto a ImgBB...');
        photoUrl = await _uploadPhotoToImgBB(photoFile);
        print('✅ Foto subida: $photoUrl');
      }
      
      // 2. Crear contenido HTML para Telegraph
      final htmlContent = _buildHtmlContent(petData, photoUrl);
      
      // 3. Subir a Telegraph
      print('📄 Creando página en Telegraph...');
      final pageUrl = await _createTelegraphPage(
        title: '🐾 ${petData['name']}',
        content: htmlContent,
      );
      
      print('✅ Página creada: $pageUrl');
      return pageUrl;
      
    } catch (e) {
      print('❌ Error en Telegraph: $e');
      return null;
    }
  }
  
  Future<String?> _uploadPhotoToImgBB(File photoFile) async {
    try {
      final bytes = await photoFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
        body: {
          'image': base64Image,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['url'];
      }
      
      return null;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }
  
  Future<String?> _createTelegraphPage({
    required String title,
    required String content,
  }) async {
    try {
      // Telegraph requiere formato específico de nodos DOM
      final response = await http.post(
        Uri.parse('$telegraphApiUrl/createPage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'access_token': '0',  // No requiere token para páginas anónimas
          'title': title,
          'author_name': 'PetQRApp',
          'author_url': '',
          'content': content,
          'return_content': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          final path = data['result']['path'];
          return 'https://telegra.ph/$path';
        }
      }
      
      return null;
    } catch (e) {
      print('Error creating Telegraph page: $e');
      return null;
    }
  }
  
  String _buildHtmlContent(Map<String, dynamic> petData, String? photoUrl) {
    // Telegraph acepta HTML simplificado
    final buffer = StringBuffer();
    
    if (photoUrl != null) {
      buffer.write('<img src="$photoUrl" alt="${petData['name']}">');
      buffer.write('<br><br>');
    }
    
    buffer.write('<h3>📋 Información de la Mascota</h3>');
    buffer.write('<p><strong>🐕 Nombre:</strong> ${petData['name']}</p>');
    buffer.write('<p><strong>🎨 Raza:</strong> ${petData['breed']}</p>');
    buffer.write('<p><strong>📅 Edad:</strong> ${petData['age']} años</p>');
    buffer.write('<p><strong>🎯 Color:</strong> ${petData['color']}</p>');
    buffer.write('<br>');
    
    buffer.write('<h3>👤 Contacto del Dueño</h3>');
    buffer.write('<p><strong>Nombre:</strong> ${petData['ownerName']}</p>');
    buffer.write('<p><strong>📞 Teléfono:</strong> <a href="tel:${petData['ownerPhone']}">${petData['ownerPhone']}</a></p>');
    buffer.write('<p><strong>📍 Dirección:</strong> ${petData['ownerAddress']}</p>');
    buffer.write('<br>');
    
    buffer.write('<p><em>🐾 Generado con PetQRApp</em></p>');
    
    return buffer.toString();
  }
}
