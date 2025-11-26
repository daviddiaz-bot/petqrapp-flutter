import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/pet_storage_service.dart';
import '../models/pet.dart';
import 'form_screen.dart';
import 'qr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PetStorageService _storageService = PetStorageService();
  List<Pet> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    final pets = await _storageService.getAllPets();
    setState(() {
      _pets = pets;
      _isLoading = false;
    });
  }

  void _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormScreen()),
    );
    if (result == true) {
      _loadPets();
    }
  }

  void _navigateToQR(Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScreen(pet: pet)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🐾 ', style: TextStyle(fontSize: 24)),
            Text('PetQRApp'),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? _buildEmptyState()
              : _buildPetList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToForm,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Mascota'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No hay mascotas registradas',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToForm,
            icon: const Icon(Icons.add),
            label: const Text('Registrar Primera Mascota'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetList() {
    return RefreshIndicator(
      onRefresh: _loadPets,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary,
                radius: 30,
                child: Text(
                  pet.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(
                pet.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('🎨 ${pet.breed}'),
                  Text('📅 ${pet.age} años'),
                  Text('👤 ${pet.ownerName}'),
                ],
              ),
              trailing: const Icon(Icons.qr_code_2, size: 32, color: AppColors.primary),
              onTap: () => _navigateToQR(pet),
            ),
          );
        },
      ),
    );
  }
}
