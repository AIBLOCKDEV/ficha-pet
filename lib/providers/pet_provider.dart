import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/models/user.dart';
import 'package:ficha_pet/services/api_service.dart';
import 'package:ficha_pet/services/notification_service.dart';
import 'package:ficha_pet/services/qr_service.dart';
import 'package:ficha_pet/services/storage_service.dart';
import 'package:ficha_pet/utils/date_utils.dart';

class PetProvider with ChangeNotifier {
  final StorageService _storageService;
  final NotificationService _notificationService;
  final ApiService _apiService;

  List<Pet> _allPets = [];
  String _activeUserId = '';
  bool _isActiveUserVet = false;
  int _advanceDays = 14;
  bool _pushEnabled = true;
  bool _isLoading = false;

  List<PushNotificationItem> _pushInbox = [];
  List<PushNotificationItem> _latestTriggered = [];

  PetProvider({
    StorageService? storageService,
    NotificationService? notificationService,
    ApiService? apiService,
  })  : _storageService = storageService ?? StorageService(),
        _notificationService = notificationService ?? NotificationService(),
        _apiService = apiService ?? ApiService();

  /// Mascotas del usuario autenticado (propias o vinculadas como paciente veterinario).
  List<Pet> get pets => List.unmodifiable(
        _allPets.where((p) =>
            p.ownerId == _activeUserId ||
            (_activeUserId.isNotEmpty && p.linkedVetIds.contains(_activeUserId))),
      );

  bool get isLoading => _isLoading;
  String get activeUserId => _activeUserId;
  bool get isActiveUserVet => _isActiveUserVet;
  int get advanceDays => _advanceDays;
  bool get pushEnabled => _pushEnabled;

  /// Mascotas disponibles en el dispositivo para prueba rápida de escaneo QR en rol Veterinario.
  List<Pet> get unlinkedPetsInDevice => List.unmodifiable(
        _allPets.where((p) =>
            p.ownerId != _activeUserId && !p.linkedVetIds.contains(_activeUserId)),
      );

  List<PushNotificationItem> get pushInbox => List.unmodifiable(_pushInbox);
  List<PushNotificationItem> get latestTriggered =>
      List.unmodifiable(_latestTriggered);
  int get unreadPushCount => _pushInbox.where((n) => !n.isRead).length;

  List<PushNotificationItem> get schedulePreview =>
      _notificationService.buildSchedulePreview(
        pets: pets,
        advanceDays: _advanceDays,
      );

  void consumeLatestTriggered() {
    _latestTriggered = [];
  }

  /// Vincula el provider con el usuario autenticado y carga sus mascotas
  /// y notificaciones push.
  Future<void> setActiveUser(AppUser? user) async {
    final newId = user?.id ?? '';
    final newIsVet = user?.isVet ?? false;
    final newAdvance = user?.advanceDays ?? 14;
    final newPush = user?.pushEnabled ?? true;

    final userChanged = _activeUserId != newId || _isActiveUserVet != newIsVet;
    _activeUserId = newId;
    _isActiveUserVet = newIsVet;
    _advanceDays = newAdvance;
    _pushEnabled = newPush;

    if (userChanged) {
      await loadPets();
    } else {
      await _refreshNotifications();
      notifyListeners();
    }
  }

  Pet? getPetById(int? id) {
    if (id == null) return null;
    for (final pet in pets) {
      if (pet.id == id) return pet;
    }
    return null;
  }

  Future<void> loadPets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allPets = await _storageService.loadPets();
      var changed = false;
      var nextId = DateTime.now().millisecondsSinceEpoch;
      for (final pet in _allPets) {
        if (pet.id == null) {
          pet.id = nextId++;
          changed = true;
        }
        // Si había mascotas previas sin ownerId y el usuario activo es dueño,
        // se adoptan automáticamente en su cuenta.
        if (pet.ownerId.isEmpty &&
            _activeUserId.isNotEmpty &&
            !_isActiveUserVet) {
          pet.ownerId = _activeUserId;
          changed = true;
        }
      }

      // Intentar sincronizar desde el servidor remoto (bidireccional dueño <-> vet)
      if (_activeUserId.isNotEmpty) {
        final remotePets = await _apiService.fetchPetsRemote(_activeUserId);
        if (remotePets != null && remotePets.isNotEmpty) {
          for (final remote in remotePets) {
            final idx = _allPets.indexWhere((p) => p.id == remote.id);
            if (idx == -1) {
              _allPets.add(remote);
            } else {
              _allPets[idx] = remote;
            }
          }
          changed = true;
        }
      }

      if (changed) await _storageService.savePets(_allPets);
      await _refreshNotifications();
    } catch (e) {
      debugPrint('Error loading pets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshNotifications({bool forceDispatchAll = false}) async {
    final userKey = _activeUserId.isEmpty ? 'default' : _activeUserId;
    final triggered = await _notificationService.evaluateAndDispatch(
      userId: userKey,
      pets: pets,
      advanceDays: _advanceDays,
      pushEnabled: _pushEnabled,
      forceDispatchAll: forceDispatchAll,
    );
    if (triggered.isNotEmpty) {
      _latestTriggered = triggered;
    }
    _pushInbox = await _notificationService.loadInbox(userKey);
  }

  /// Dispara manualmente una verificación y envío de notificaciones push
  /// (útil para probar alertas anticipadas y vencidas cada 2 días).
  Future<int> triggerPushCheckNow() async {
    await _notificationService.requestPermission();
    await _refreshNotifications(forceDispatchAll: true);
    notifyListeners();
    return _latestTriggered.length;
  }

  Future<void> markAllNotificationsRead() async {
    final userKey = _activeUserId.isEmpty ? 'default' : _activeUserId;
    await _notificationService.markAllAsRead(userKey);
    _pushInbox = await _notificationService.loadInbox(userKey);
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    final userKey = _activeUserId.isEmpty ? 'default' : _activeUserId;
    await _notificationService.clearInbox(userKey);
    _pushInbox = [];
    notifyListeners();
  }

  Future<void> addPet(Pet pet) async {
    pet.id = DateTime.now().millisecondsSinceEpoch;
    pet.ownerId = _activeUserId;
    _recordWeight(pet, null);
    final previous = List<Pet>.from(_allPets);
    _allPets.add(pet);
    await _persist(previous);
  }

  /// Vincula una mascota al perfil del veterinario escaneando su QR clínico
  /// o ingresando su código `FP-XXXXXX`. Sincronización bidireccional activa.
  Future<Pet> linkPetByQR(String qrData) async {
    if (_activeUserId.isEmpty) {
      throw StateError('Debes iniciar sesión como veterinario');
    }
    final parsed = QRService.parseQRPayload(qrData);
    if (parsed == null) {
      throw StateError('Código QR o código clínico no válido');
    }

    // 1. Intentar vincular directamente contra el servidor remoto
    final remoteLinked = await _apiService.linkPetForVetRemote(
      vetId: _activeUserId,
      petId: parsed.petId,
      shareCode: parsed.shareCode,
    );

    if (remoteLinked != null) {
      final idx = _allPets.indexWhere((p) => p.id == remoteLinked.id);
      if (idx == -1) {
        _allPets.add(remoteLinked);
      } else {
        _allPets[idx] = remoteLinked;
      }
      await _storageService.savePets(_allPets);
      await _refreshNotifications();
      notifyListeners();
      return remoteLinked;
    }

    // 2. Búsqueda y vinculación local (si el servidor no está disponible)
    final localIdx = _allPets.indexWhere((p) {
      if (parsed.petId != null && p.id == parsed.petId) return true;
      if (parsed.shareCode.isNotEmpty && p.shareCode == parsed.shareCode) {
        return true;
      }
      return false;
    });

    if (localIdx == -1) {
      throw StateError(
          'No encontramos ninguna mascota con ese código QR (${parsed.shareCode.isNotEmpty ? parsed.shareCode : parsed.petId})');
    }

    final existing = _allPets[localIdx];
    final vets = List<String>.from(existing.linkedVetIds);
    if (!vets.contains(_activeUserId)) {
      vets.add(_activeUserId);
    }
    final updated = existing.copyWith(linkedVetIds: vets);
    _allPets[localIdx] = updated;
    await _storageService.savePets(_allPets);
    await _refreshNotifications();
    notifyListeners();
    return updated;
  }

  /// Desvincula un paciente de la lista del veterinario sin borrar la mascota del dueño.
  Future<void> unlinkVetPatient(int petId) async {
    final idx = _allPets.indexWhere((p) => p.id == petId);
    if (idx == -1) return;
    final existing = _allPets[idx];
    final vets = List<String>.from(existing.linkedVetIds)
      ..remove(_activeUserId);
    final updated = existing.copyWith(linkedVetIds: vets);
    final previous = List<Pet>.from(_allPets);
    _allPets[idx] = updated;
    await _persist(previous, updatedPet: updated);
  }

  Future<void> updatePet(Pet pet) async {
    final index = _allPets.indexWhere((p) => p.id == pet.id);
    if (index == -1) {
      throw StateError('Mascota no encontrada');
    }
    final existing = _allPets[index];
    // Preservar siempre el dueño original y los veterinarios vinculados
    // para que las actualizaciones del veterinario se reflejen en el dueño y viceversa.
    pet.ownerId = existing.ownerId.isNotEmpty ? existing.ownerId : _activeUserId;
    pet.linkedVetIds = List<String>.from(
      {...existing.linkedVetIds, ...pet.linkedVetIds},
    );
    _recordWeight(pet, existing);
    final previous = List<Pet>.from(_allPets);
    _allPets[index] = pet;
    await _persist(previous, updatedPet: pet);
  }

  Future<void> deletePet(int id) async {
    final idx = _allPets.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    // Si es un veterinario y no es el dueño, sólo desvincula el paciente
    if (_isActiveUserVet && _allPets[idx].ownerId != _activeUserId) {
      await unlinkVetPatient(id);
      return;
    }
    final previous = List<Pet>.from(_allPets);
    _allPets.removeWhere((p) => p.id == id && p.ownerId == _activeUserId);
    await _persist(previous);
  }

  /// Guarda localmente, sincroniza con el servidor y actualiza notificaciones.
  Future<void> _persist(List<Pet> previous, {Pet? updatedPet}) async {
    try {
      await _storageService.savePets(_allPets);
      if (_activeUserId.isNotEmpty) {
        if (updatedPet != null) {
          await _apiService.updateSinglePetRemote(updatedPet);
        } else {
          await _apiService.syncPetsRemote(_activeUserId, pets);
        }
      }
      await _refreshNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving pets: $e');
      _allPets = previous;
      notifyListeners();
      rethrow;
    }
  }

  /// Registra el peso en el historial cuando es nuevo o cambió.
  void _recordWeight(Pet pet, Pet? previous) {
    final weight = double.tryParse(pet.weight.replaceAll(',', '.'));
    if (weight == null || weight <= 0) return;
    final previousWeight =
        double.tryParse((previous?.weight ?? '').replaceAll(',', '.'));
    final hasHistory = pet.weightHistory.isNotEmpty;
    if (hasHistory && previousWeight == weight) return;

    final today = DateTime.now();
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final history = List<WeightHistoryEntry>.from(pet.weightHistory)
      ..removeWhere((e) => e.date.startsWith(todayKey));
    history.add(WeightHistoryEntry(date: todayKey, weight: weight));
    pet.weightHistory = history;
  }

  /// Recordatorios de vacunas/desparasitaciones vencidas o dentro de la
  /// ventana de anticipación (mínimo 30 días).
  List<Reminder> getReminders() {
    final reminders = <Reminder>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowDays = _advanceDays > 30 ? _advanceDays : 30;
    final limit = today.add(Duration(days: windowDays));

    void check(Pet pet, String dateString, String type) {
      if (dateString.isEmpty) return;
      final date = DateTime.tryParse(dateString);
      if (date == null) return;
      final day = DateTime(date.year, date.month, date.day);
      if (!day.isAfter(limit)) {
        reminders.add(Reminder(pet: pet, type: type, date: day));
      }
    }

    for (final pet in pets) {
      check(pet, pet.nextVaccineDate, 'Vacuna');
      check(pet, pet.nextDewormingDate, 'Desparasitación');
    }

    reminders.sort((a, b) => a.date.compareTo(b.date));
    return reminders;
  }

  /// Exporta las mascotas del usuario actual en formato JSON.
  String exportBackupJson() {
    final data = {
      'allPets': pets.map((p) => p.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Importa mascotas desde un JSON y las asocia al usuario actual.
  Future<int> importBackupJson(String rawJson) async {
    final decoded = json.decode(rawJson);
    final List<dynamic> list;
    if (decoded is Map<String, dynamic> && decoded['allPets'] is List) {
      list = decoded['allPets'] as List<dynamic>;
    } else if (decoded is List) {
      list = decoded;
    } else {
      throw const FormatException('Formato JSON no reconocido');
    }

    final imported = list
        .whereType<Map<String, dynamic>>()
        .map(Pet.fromJson)
        .toList();
    if (imported.isEmpty) return 0;

    final previous = List<Pet>.from(_allPets);
    var nextId = DateTime.now().millisecondsSinceEpoch;
    for (final pet in imported) {
      pet.ownerId = _activeUserId;
      final exists = pet.id != null && _allPets.any((p) => p.id == pet.id);
      if (pet.id == null || exists) {
        pet.id = nextId++;
      }
      _allPets.add(pet);
    }
    await _persist(previous);
    return imported.length;
  }

  /// Crea la mascota de demostración "Rocky" con una vacuna vencida (para ver
  /// el ciclo de notificación push cada 2 días) y una desparasitación próxima
  /// (con anticipación).
  Future<void> addSamplePet() async {
    final now = DateTime.now();
    final sample = Pet(
      id: now.millisecondsSinceEpoch,
      ownerId: _activeUserId,
      name: 'Rocky',
      type: 'dog',
      birthday: formatDateForInput(DateTime(now.year - 3, 5, 15)),
      weight: '12.5',
      gender: 'male',
      breed: 'Beagle',
      chip: 'yes',
      lastVaccineDate:
          formatDateForInput(now.subtract(const Duration(days: 369))),
      nextVaccineDate:
          formatDateForInput(now.subtract(const Duration(days: 4))),
      vaccineType: 'Polivalente Anual',
      lastDewormingDate:
          formatDateForInput(now.subtract(const Duration(days: 173))),
      nextDewormingDate: formatDateForInput(now.add(const Duration(days: 7))),
      dewormingProduct: 'Pastilla Masticable',
      medicalHistory: [
        MedicalHistoryEntry(
          date: now.subtract(const Duration(days: 120)).toIso8601String(),
          text: 'Limpieza dental de rutina y control general.',
        ),
        MedicalHistoryEntry(
          date: now.subtract(const Duration(days: 30)).toIso8601String(),
          text:
              'Consulta por alergia leve en la piel. Se indicó champú hipoalergénico.',
        ),
      ],
      weightHistory: [
        WeightHistoryEntry(
          date: formatDateForInput(now.subtract(const Duration(days: 180))),
          weight: 11.8,
        ),
        WeightHistoryEntry(
          date: formatDateForInput(now.subtract(const Duration(days: 90))),
          weight: 12.1,
        ),
        WeightHistoryEntry(
          date: formatDateForInput(now),
          weight: 12.5,
        ),
      ],
      files: PetFiles.empty(),
      emergencyContact: EmergencyContact(
        name: 'Juan Pérez',
        phone: '+56 9 5551 2345',
        address: 'Av. Principal 123',
      ),
    );
    final previous = List<Pet>.from(_allPets);
    _allPets.add(sample);
    await _persist(previous);
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

  /// Días restantes (negativo si está vencido).
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
  }

  bool get isOverdue => daysLeft < 0;

  /// Describe la cadencia de notificaciones push para este recordatorio.
  String get pushCadenceBadge {
    if (isOverdue) {
      return 'Push cada 2 días (Vencida)';
    }
    if (daysLeft == 0) {
      return 'Push hoy';
    }
    return 'Push anticipado ($daysLeft d)';
  }
}
