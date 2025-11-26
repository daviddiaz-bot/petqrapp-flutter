import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet.dart';
import '../services/pet_storage_service.dart';
import '../services/google_drive_service.dart';
import '../utils/validators.dart';
import '../utils/app_colors.dart';
import 'qr_screen.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = PetStorageService();
  final _driveService = GoogleDriveService();
  final _imagePicker = ImagePicker();
  
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _colorController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _colorController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final petId = const Uuid().v4();
      String? driveUrl;

      // Subir a Google Drive del usuario
      try {
        print('🔵 Iniciando sesión en Google Drive...');
        
        // Mostrar diálogo de loading
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Conectando con tu Google Drive...'),
                SizedBox(height: 8),
                Text(
                  'Por favor acepta los permisos',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
        
        final signedIn = await _driveService.signIn();
        
        // Cerrar diálogo
        if (!mounted) return;
        Navigator.pop(context);
        
        if (signedIn) {
          print('🟢 Login exitoso: ${_driveService.userEmail}');
          
          // Mostrar progreso de subida
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Subiendo a tu Drive...'),
                  SizedBox(height: 8),
                  Text(
                    'Creando página web de ${_nameController.text}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
          
          driveUrl = await _driveService.uploadPetData(
            petId: petId,
            petName: _nameController.text.trim(),
            petData: {
              'name': _nameController.text.trim(),
              'breed': _breedController.text.trim(),
              'age': _ageController.text.trim(),
              'color': _colorController.text.trim(),
              'ownerName': _ownerNameController.text.trim(),
              'ownerPhone': _ownerPhoneController.text.trim(),
              'ownerAddress': _ownerAddressController.text.trim(),
            },
            photoFile: _selectedImage,
          );
          
          // Cerrar diálogo de progreso
          if (!mounted) return;
          Navigator.pop(context);
          
          if (driveUrl != null && driveUrl.isNotEmpty) {
            print('🟢 URL de Drive obtenida: $driveUrl');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Guardado en tu Google Drive'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('🔴 Login cancelado o falló');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ No se pudo conectar con Google Drive'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (error) {
        print('🔴 Error en Drive: $error');
        // Cerrar cualquier diálogo abierto
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error: ${error.toString()}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }

      // Crear mascota con URL de Google Drive
      print('🔵 Creando mascota con driveUrl: $driveUrl');
      final pet = Pet(
        id: petId,
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        age: _ageController.text.trim(),
        color: _colorController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        ownerAddress: _ownerAddressController.text.trim(),
        photoPath: _selectedImage?.path,
        driveUrl: driveUrl,  // URL del HTML en Google Drive del usuario
        registeredAt: DateTime.now(),
      );

      print('🔵 Guardando mascota en storage local...');
      await _storageService.savePet(pet);
      print('🟢 Mascota guardada exitosamente');
      print('🔵 Pet object: ${pet.toJson()}');

      setState(() => _isLoading = false);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => QRScreen(pet: pet)),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar Mascota'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text('Subiendo a Google Drive...'),
                  const SizedBox(height: 10),
                  Text(
                    'Esto puede tardar unos segundos',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Datos de la Mascota'),
                    _buildImagePicker(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nombre de la mascota',
                      icon: Icons.pets,
                      validator: (v) => Validators.validateRequired(v, 'El nombre'),
                    ),
                    _buildTextField(
                      controller: _breedController,
                      label: 'Raza',
                      icon: Icons.category,
                      validator: (v) => Validators.validateRequired(v, 'La raza'),
                    ),
                    _buildTextField(
                      controller: _ageController,
                      label: 'Edad (años)',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAge,
                    ),
                    _buildTextField(
                      controller: _colorController,
                      label: 'Color',
                      icon: Icons.palette,
                      validator: (v) => Validators.validateRequired(v, 'El color'),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Datos del Dueño'),
                    _buildTextField(
                      controller: _ownerNameController,
                      label: 'Nombre completo',
                      icon: Icons.person,
                      validator: (v) => Validators.validateRequired(v, 'El nombre'),
                    ),
                    _buildTextField(
                      controller: _ownerPhoneController,
                      label: 'Teléfono (10 dígitos)',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                    _buildTextField(
                      controller: _ownerAddressController,
                      label: 'Dirección',
                      icon: Icons.home,
                      maxLines: 2,
                      validator: (v) => Validators.validateRequired(v, 'La dirección'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Subir a Drive y Generar QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ℹ️ Los datos se guardarán en tu Google Drive',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Toca para agregar foto de la mascota',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
