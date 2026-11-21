import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ficha_pet/models/user.dart';
import 'package:ficha_pet/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  static const String _usersKey = 'registered_users_v2';
  static const String _passwordsKey = 'registered_passwords_v2';
  static const String _activeUserIdKey = 'active_user_id_v2';

  final ApiService _apiService;
  AppUser? _currentUser;
  bool _isInitialized = false;
  bool _isBusy = false;
  bool _isServerConnected = false;

  AuthProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isBusy => _isBusy;
  bool get isServerConnected => _isServerConnected;

  ThemeMode get themeMode {
    switch (_currentUser?.themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  int get themeSeedIndex => _currentUser?.themeSeedIndex ?? 0;

  static String _hashPassword(String password) {
    final bytes = utf8.encode('fichapet_salt_${password.trim()}');
    return sha256.convert(bytes).toString();
  }

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString(_activeUserIdKey);
      final users = await _loadAllUsers(prefs);

      if (activeId != null && activeId.isNotEmpty) {
        for (final u in users) {
          if (u.id == activeId) {
            _currentUser = u;
            break;
          }
        }
      }
      _isServerConnected = await _apiService.checkServerHealth();
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<List<AppUser>> _loadAllUsers(SharedPreferences prefs) async {
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(AppUser.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAllUsers(
      SharedPreferences prefs, List<AppUser> users) async {
    final encoded = json.encode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, encoded);
  }

  Future<Map<String, String>> _loadPasswords(SharedPreferences prefs) async {
    final raw = prefs.getString(_passwordsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _savePasswords(
      SharedPreferences prefs, Map<String, String> passwords) async {
    await prefs.setString(_passwordsKey, json.encode(passwords));
  }

  /// Registra un nuevo usuario (Dueño o Veterinario) y abre su sesión automáticamente.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String role = 'owner',
    String clinicName = '',
  }) async {
    _isBusy = true;
    notifyListeners();
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = name.trim();
      final prefs = await SharedPreferences.getInstance();
      final users = await _loadAllUsers(prefs);

      if (users.any((u) => u.email.toLowerCase() == cleanEmail)) {
        throw StateError('Ya existe una cuenta registrada con este correo');
      }

      final id = 'usr_${DateTime.now().millisecondsSinceEpoch}';
      final passwordHash = _hashPassword(password);

      // Intenta registrar también en el servidor backend si está activo
      final remoteUser = await _apiService.registerRemote(
        id: id,
        name: cleanName,
        email: cleanEmail,
        passwordHash: passwordHash,
        phone: phone.trim(),
        role: role,
        clinicName: clinicName.trim(),
      );
      _isServerConnected = remoteUser != null;

      final user = remoteUser ??
          AppUser(
            id: id,
            name: cleanName,
            email: cleanEmail,
            phone: phone.trim(),
            role: role == 'vet' ? 'vet' : 'owner',
            clinicName: clinicName.trim(),
            createdAt: DateTime.now().toIso8601String(),
          );

      users.add(user);
      await _saveAllUsers(prefs, users);

      final passwords = await _loadPasswords(prefs);
      passwords[user.id] = passwordHash;
      await _savePasswords(prefs, passwords);

      await prefs.setString(_activeUserIdKey, user.id);
      _currentUser = user;
      return user;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Inicia sesión con correo y contraseña.
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    _isBusy = true;
    notifyListeners();
    try {
      final cleanEmail = email.trim().toLowerCase();
      final passwordHash = _hashPassword(password);
      final prefs = await SharedPreferences.getInstance();
      final users = await _loadAllUsers(prefs);
      final passwords = await _loadPasswords(prefs);

      // Primero intentamos con el servidor remoto si está activo
      final remoteUser = await _apiService.loginRemote(
        email: cleanEmail,
        passwordHash: passwordHash,
      );
      if (remoteUser != null) {
        _isServerConnected = true;
        final existingIdx = users.indexWhere((u) => u.id == remoteUser.id);
        if (existingIdx == -1) {
          users.add(remoteUser);
        } else {
          users[existingIdx] = remoteUser;
        }
        passwords[remoteUser.id] = passwordHash;
        await _saveAllUsers(prefs, users);
        await _savePasswords(prefs, passwords);
        await prefs.setString(_activeUserIdKey, remoteUser.id);
        _currentUser = remoteUser;
        return remoteUser;
      }

      AppUser? found;
      for (final u in users) {
        if (u.email.toLowerCase() == cleanEmail) {
          found = u;
          break;
        }
      }

      if (found == null) {
        throw StateError('No encontramos una cuenta con ese correo');
      }

      final storedHash = passwords[found.id];
      if (storedHash != null && storedHash != passwordHash) {
        throw StateError('Contraseña incorrecta');
      }

      await prefs.setString(_activeUserIdKey, found.id);
      _currentUser = found;
      return found;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Ingreso rápido con cuenta de demostración.
  Future<AppUser> loginDemo() async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadAllUsers(prefs);
    const demoEmail = 'demo@fichapet.app';

    for (final u in users) {
      if (u.email.toLowerCase() == demoEmail) {
        await prefs.setString(_activeUserIdKey, u.id);
        _currentUser = u;
        notifyListeners();
        return u;
      }
    }

    return register(
      name: 'Usuario Demo',
      email: demoEmail,
      password: 'demo1234',
      phone: '+56 9 5551 2345',
      role: 'owner',
    );
  }

  /// Ingreso rápido con cuenta de Veterinario de demostración.
  Future<AppUser> loginDemoVet() async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadAllUsers(prefs);
    const vetEmail = 'vet@fichapet.app';

    for (final u in users) {
      if (u.email.toLowerCase() == vetEmail) {
        await prefs.setString(_activeUserIdKey, u.id);
        _currentUser = u;
        notifyListeners();
        return u;
      }
    }

    return register(
      name: 'Dra. Sofía Vet',
      email: vetEmail,
      password: 'vet1234',
      phone: '+56 9 8880 1122',
      role: 'vet',
      clinicName: 'Clínica Veterinaria Ficha Pet',
    );
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? clinicName,
    String? avatarBase64,
    int? themeSeedIndex,
    String? themeMode,
    bool? pushEnabled,
    int? advanceDays,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    final updated = user.copyWith(
      name: name ?? user.name,
      phone: phone ?? user.phone,
      clinicName: clinicName ?? user.clinicName,
      avatarBase64: avatarBase64 ?? user.avatarBase64,
      themeSeedIndex: themeSeedIndex ?? user.themeSeedIndex,
      themeMode: themeMode ?? user.themeMode,
      pushEnabled: pushEnabled ?? user.pushEnabled,
      advanceDays: advanceDays ?? user.advanceDays,
    );

    final prefs = await SharedPreferences.getInstance();
    final users = await _loadAllUsers(prefs);
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      users[idx] = updated;
    } else {
      users.add(updated);
    }
    await _saveAllUsers(prefs, users);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeUserIdKey);
    await _apiService.setToken(null);
    _currentUser = null;
    notifyListeners();
  }
}
