import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pet.dart';
import '../services/pet_storage_service.dart';
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
  
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _colorController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final pet = Pet(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      breed: _breedController.text.trim(),
      age: _ageController.text.trim(),
      color: _colorController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      ownerPhone: _ownerPhoneController.text.trim(),
      ownerAddress: _ownerAddressController.text.trim(),
      registeredAt: DateTime.now(),
    );

    await _storageService.savePet(pet);

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Navegar a la pantalla QR
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => QRScreen(pet: pet)),
    );
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Datos de la Mascota'),
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
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Generar Código QR'),
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
