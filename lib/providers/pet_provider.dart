import 'package:flutter/foundation.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/services/storage_service.dart';

class PetProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Pet> _pets = [];
  bool _isLoading = false;

  List<Pet> get pets => _pets;
  bool get isLoading => _isLoading;

  Future<void> loadPets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pets = await _storageService.loadPets();
    } catch (e) {
      debugPrint('Error loading pets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPet(Pet pet) async {
    try {
      pet.id = DateTime.now().millisecondsSinceEpoch;
      _pets.add(pet);
      await _storageService.savePets(_pets);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding pet: $e');
      rethrow;
    }
  }

  Future<void> updatePet(int index, Pet pet) async {
    try {
      _pets[index] = pet;
      await _storageService.savePets(_pets);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating pet: $e');
      rethrow;
    }
  }

  Future<void> deletePet(int index) async {
    try {
      _pets.removeAt(index);
      await _storageService.savePets(_pets);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      rethrow;
    }
  }

  List<Reminder> getReminders() {
    final reminders = <Reminder>[];
    final today = DateTime.now();
    final thirtyDaysFromNow = today.add(const Duration(days: 30));

    for (final pet in _pets) {
      if (pet.nextVaccineDate.isNotEmpty) {
        try {
          final nextVaccine = DateTime.parse(pet.nextVaccineDate);
          if (nextVaccine.isAfter(today) && nextVaccine.isBefore(thirtyDaysFromNow)) {
            reminders.add(Reminder(
              pet: pet,
              type: 'Vacuna',
              date: nextVaccine,
            ));
          }
        } catch (e) {
          debugPrint('Error parsing vaccine date: $e');
        }
      }

      if (pet.nextDewormingDate.isNotEmpty) {
        try {
          final nextDeworming = DateTime.parse(pet.nextDewormingDate);
          if (nextDeworming.isAfter(today) && nextDeworming.isBefore(thirtyDaysFromNow)) {
            reminders.add(Reminder(
              pet: pet,
              type: 'Desparasitación',
              date: nextDeworming,
            ));
          }
        } catch (e) {
          debugPrint('Error parsing deworming date: $e');
        }
      }
    }

    reminders.sort((a, b) => a.date.compareTo(b.date));
    return reminders;
  }
}

class Reminder {
  final Pet pet;
  final String type;
  final DateTime date;

  Reminder({
    required this.pet,
    required this.type,
    required this.date,
  });
}

