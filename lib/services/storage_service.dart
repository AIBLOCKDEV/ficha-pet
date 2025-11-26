import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ficha_pet/models/pet.dart';

class StorageService {
  static const String _petsKey = 'allPetsData';

  Future<List<Pet>> loadPets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petsJson = prefs.getString(_petsKey);

      if (petsJson == null || petsJson.isEmpty) {
        return [];
      }

      final Map<String, dynamic> data = json.decode(petsJson);
      final List<dynamic> petsList = data['allPets'] ?? [];

      return petsList.map((json) => Pet.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> savePets(List<Pet> pets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {
        'allPets': pets.map((pet) => pet.toJson()).toList(),
      };
      final petsJson = json.encode(data);
      await prefs.setString(_petsKey, petsJson);
    } catch (e) {
      rethrow;
    }
  }
}

