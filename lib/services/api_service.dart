import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/models/user.dart';

class ApiService {
  static const String _serverUrlKey = 'api_server_url';
  static const String _tokenKey = 'api_auth_token';
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api',
  );

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_serverUrlKey);
    return (custom != null && custom.trim().isNotEmpty)
        ? custom.trim()
        : defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url.trim());
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> checkServerHealth() async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<AppUser?> registerRemote({
    required String id,
    required String name,
    required String email,
    required String passwordHash,
    required String phone,
    String role = 'owner',
    String clinicName = '',
  }) async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'id': id,
              'name': name,
              'email': email,
              'passwordHash': passwordHash,
              'phone': phone,
              'role': role,
              'clinicName': clinicName,
            }),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        await setToken(body['token']?.toString());
        if (body['user'] is Map<String, dynamic>) {
          return AppUser.fromJson(body['user'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Offline register fallback: $e');
    }
    return null;
  }

  Future<AppUser?> loginRemote({
    required String email,
    required String passwordHash,
  }) async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'passwordHash': passwordHash,
            }),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        await setToken(body['token']?.toString());
        if (body['user'] is Map<String, dynamic>) {
          return AppUser.fromJson(body['user'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Offline login fallback: $e');
    }
    return null;
  }

  Future<List<Pet>?> fetchPetsRemote(String userId) async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .get(
            Uri.parse('$base/pets?userId=$userId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List<dynamic> list = body is Map<String, dynamic>
            ? (body['pets'] as List<dynamic>? ?? [])
            : (body as List<dynamic>);
        return list
            .whereType<Map<String, dynamic>>()
            .map(Pet.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('Offline fetchPets fallback: $e');
    }
    return null;
  }

  /// Vincula un paciente (mascota) a la cuenta del veterinario mediante QR o código.
  Future<Pet?> linkPetForVetRemote({
    required String vetId,
    int? petId,
    String shareCode = '',
  }) async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/vet/link'),
            headers: await _headers(),
            body: json.encode({
              'vetId': vetId,
              if (petId != null) 'petId': petId,
              if (shareCode.isNotEmpty) 'shareCode': shareCode,
            }),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        if (body['pet'] is Map<String, dynamic>) {
          return Pet.fromJson(body['pet'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Offline vet link fallback: $e');
    }
    return null;
  }

  /// Actualiza una mascota individualmente (sincronización bidireccional dueño <-> vet).
  Future<Pet?> updateSinglePetRemote(Pet pet) async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .put(
            Uri.parse('$base/pets/item'),
            headers: await _headers(),
            body: json.encode({'pet': pet.toJson()}),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        if (body['pet'] is Map<String, dynamic>) {
          return Pet.fromJson(body['pet'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Offline updateSinglePet fallback: $e');
    }
    return null;
  }

  Future<bool> syncPetsRemote(String ownerId, List<Pet> pets) async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .put(
            Uri.parse('$base/pets/sync'),
            headers: await _headers(),
            body: json.encode({
              'ownerId': ownerId,
              'pets': pets.map((p) => p.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Offline syncPets fallback: $e');
      return false;
    }
  }
}
