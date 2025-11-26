import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';

class PetStorageService {
  static const String _keyPets = 'pets';

  Future<List<Pet>> getAllPets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? petsJson = prefs.getString(_keyPets);
    
    if (petsJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(petsJson);
    return decoded.map((json) => Pet.fromJson(json)).toList();
  }

  Future<void> savePet(Pet pet) async {
    final pets = await getAllPets();
    pets.add(pet);
    
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(pets.map((p) => p.toJson()).toList());
    await prefs.setString(_keyPets, encoded);
  }

  Future<void> deletePet(String petId) async {
    final pets = await getAllPets();
    pets.removeWhere((p) => p.id == petId);
    
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(pets.map((p) => p.toJson()).toList());
    await prefs.setString(_keyPets, encoded);
  }

  Future<Pet?> getPetById(String petId) async {
    final pets = await getAllPets();
    try {
      return pets.firstWhere((p) => p.id == petId);
    } catch (e) {
      return null;
    }
  }
}
