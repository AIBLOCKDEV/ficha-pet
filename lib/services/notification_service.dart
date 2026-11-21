import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:ficha_pet/utils/date_utils.dart';

import 'notification_bridge_stub.dart'
    if (dart.library.js_interop) 'notification_bridge_web.dart';

class PushNotificationItem {
  final String id;
  final int? petId;
  final String petName;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime dueDate;
  final int daysLeft;
  final bool isOverdue;
  final String cadenceLabel; // Ej.: 'Cada 2 días (Vencida)' o 'Anticipación (14 días)'
  bool isRead;

  PushNotificationItem({
    required this.id,
    required this.petId,
    required this.petName,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.dueDate,
    required this.daysLeft,
    required this.isOverdue,
    required this.cadenceLabel,
    this.isRead = false,
  });

  factory PushNotificationItem.fromJson(Map<String, dynamic> json) {
    return PushNotificationItem(
      id: json['id']?.toString() ?? '',
      petId: (json['petId'] as num?)?.toInt(),
      petName: json['petName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      dueDate:
          DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      daysLeft: (json['daysLeft'] as num?)?.toInt() ?? 0,
      isOverdue: json['isOverdue'] == true,
      cadenceLabel: json['cadenceLabel']?.toString() ?? '',
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'petId': petId,
        'petName': petName,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'daysLeft': daysLeft,
        'isOverdue': isOverdue,
        'cadenceLabel': cadenceLabel,
        'isRead': isRead,
      };
}

class NotificationService {
  static const String _inboxPrefix = 'push_inbox_';
  static const String _lastSentPrefix = 'push_last_sent_';

  /// Solicita permiso de notificaciones push en el navegador / sistema.
  Future<bool> requestPermission() => requestPlatformNotificationPermission();

  /// Evalúa todas las mascotas del usuario y dispara notificaciones push:
  /// - Con anticipación (dentro de [advanceDays], ej. 30, 14, 7, 3, 1, 0 días).
  /// - Si ya están vencidas (daysLeft < 0), sigue enviando cada 2 días
  ///   hasta que se actualice la fecha de vacunación o desparasitación.
  Future<List<PushNotificationItem>> evaluateAndDispatch({
    required String userId,
    required List<Pet> pets,
    required int advanceDays,
    required bool pushEnabled,
    bool forceDispatchAll = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final inbox = await loadInbox(userId);
    final newlyTriggered = <PushNotificationItem>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Future<void> checkEvent({
      required Pet pet,
      required String rawDate,
      required String eventType,
      required String detail,
    }) async {
      if (rawDate.isEmpty) return;
      final parsed = DateTime.tryParse(rawDate);
      if (parsed == null) return;
      final dueDay = DateTime(parsed.year, parsed.month, parsed.day);
      final daysLeft = dueDay.difference(today).inDays;

      // Fuera de la ventana de anticipación
      if (daysLeft > advanceDays) return;

      final isOverdue = daysLeft < 0;
      final key =
          '$_lastSentPrefix${userId}_${pet.id ?? pet.name}_${eventType}_$rawDate';
      final lastSentStr = prefs.getString(key);
      final lastSent =
          lastSentStr != null ? DateTime.tryParse(lastSentStr) : null;
      final lastSentDay = lastSent != null
          ? DateTime(lastSent.year, lastSent.month, lastSent.day)
          : null;

      bool shouldSend = forceDispatchAll;
      if (!shouldSend) {
        if (lastSentDay == null) {
          shouldSend = true;
        } else {
          final daysSinceLastSent = today.difference(lastSentDay).inDays;
          if (isOverdue) {
            // REGLA CLAVE: Si la vacuna/desparasitación está vencida,
            // seguir enviando notificación push cada 2 días.
            shouldSend = daysSinceLastSent >= 2;
          } else {
            // Con anticipación: enviar en hitos (30, 14, 7, 3, 2, 1, 0 días)
            // si aún no se envió hoy.
            const milestones = {30, 21, 14, 7, 3, 2, 1, 0};
            shouldSend =
                daysSinceLastSent >= 1 && milestones.contains(daysLeft);
          }
        }
      }

      if (!shouldSend) return;

      final petName = pet.name.isNotEmpty ? pet.name : 'tu mascota';
      final detailSuffix = detail.isNotEmpty ? ' ($detail)' : '';
      final String title;
      final String body;
      final String cadenceLabel;

      if (isOverdue) {
        final overdueDays = -daysLeft;
        final nextRepeatDate =
            formatDate(formatDateForInput(today.add(const Duration(days: 2))));
        title = '¡$eventType vencida! · $petName';
        body =
            '$eventType$detailSuffix venció el ${formatDate(rawDate)} (hace $overdueDays ${overdueDays == 1 ? "día" : "días"}). '
            'Se seguirá recordando cada 2 días (próximo aviso: $nextRepeatDate).';
        cadenceLabel = 'Repetición cada 2 días (Vencida)';
      } else if (daysLeft == 0) {
        title = '¡Hoy toca $eventType para $petName!';
        body =
            'Hoy (${formatDate(rawDate)}) está programada la $eventType$detailSuffix de $petName.';
        cadenceLabel = 'Día del evento';
      } else {
        title = 'Recordatorio anticipado · $eventType ($petName)';
        body =
            'Faltan $daysLeft ${daysLeft == 1 ? "día" : "días"} para la $eventType$detailSuffix de $petName (${formatDate(rawDate)}).';
        cadenceLabel = 'Anticipación ($daysLeft días antes)';
      }

      final item = PushNotificationItem(
        id: '${pet.id}_${eventType}_${now.millisecondsSinceEpoch}',
        petId: pet.id,
        petName: petName,
        title: title,
        body: body,
        createdAt: now,
        dueDate: dueDay,
        daysLeft: daysLeft,
        isOverdue: isOverdue,
        cadenceLabel: cadenceLabel,
      );

      await prefs.setString(key, today.toIso8601String());
      inbox.insert(0, item);
      newlyTriggered.add(item);

      if (pushEnabled) {
        await showPlatformNotification(title: title, body: body);
      }
    }

    for (final pet in pets) {
      await checkEvent(
        pet: pet,
        rawDate: pet.nextVaccineDate,
        eventType: 'Vacuna',
        detail: pet.vaccineType,
      );
      await checkEvent(
        pet: pet,
        rawDate: pet.nextDewormingDate,
        eventType: 'Desparasitación',
        detail: pet.dewormingProduct,
      );
    }

    if (newlyTriggered.isNotEmpty) {
      // Conservar máximo 50 notificaciones en bandeja
      final trimmed = inbox.take(50).toList();
      await saveInbox(userId, trimmed);
    }

    return newlyTriggered;
  }

  /// Construye la programación futura de notificaciones (incluyendo el ciclo
  /// cada 2 días para vacunas vencidas) para mostrarla en el Centro Push.
  List<PushNotificationItem> buildSchedulePreview({
    required List<Pet> pets,
    required int advanceDays,
  }) {
    final preview = <PushNotificationItem>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    void addPreview(Pet pet, String rawDate, String eventType, String detail) {
      if (rawDate.isEmpty) return;
      final parsed = DateTime.tryParse(rawDate);
      if (parsed == null) return;
      final dueDay = DateTime(parsed.year, parsed.month, parsed.day);
      final daysLeft = dueDay.difference(today).inDays;
      if (daysLeft > advanceDays) return;

      final petName = pet.name.isNotEmpty ? pet.name : 'Mascota';
      final isOverdue = daysLeft < 0;
      final detailSuffix = detail.isNotEmpty ? ' · $detail' : '';

      final String cadence;
      final String title;
      final String body;
      if (isOverdue) {
        final abs = -daysLeft;
        cadence = 'Activa cada 2 días · Vencida hace $abs d';
        title = '$eventType vencida — $petName';
        body =
            'Fecha límite: ${formatDate(rawDate)}$detailSuffix. Alerta push activa cada 48 horas.';
      } else if (daysLeft == 0) {
        cadence = 'Vence hoy';
        title = '$eventType hoy — $petName';
        body = 'Programada para hoy (${formatDate(rawDate)})$detailSuffix.';
      } else {
        cadence = 'Anticipación ($daysLeft d restantes)';
        title = '$eventType próxima — $petName';
        body =
            'Programada para el ${formatDate(rawDate)}$detailSuffix (en $daysLeft días).';
      }

      preview.add(
        PushNotificationItem(
          id: 'preview_${pet.id}_$eventType',
          petId: pet.id,
          petName: petName,
          title: title,
          body: body,
          createdAt: today,
          dueDate: dueDay,
          daysLeft: daysLeft,
          isOverdue: isOverdue,
          cadenceLabel: cadence,
        ),
      );
    }

    for (final pet in pets) {
      addPreview(pet, pet.nextVaccineDate, 'Vacuna', pet.vaccineType);
      addPreview(
          pet, pet.nextDewormingDate, 'Desparasitación', pet.dewormingProduct);
    }

    preview.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return preview;
  }

  Future<List<PushNotificationItem>> loadInbox(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_inboxPrefix$userId');
      if (raw == null || raw.isEmpty) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(PushNotificationItem.fromJson)
          .toList();
    } catch (e) {
      debugPrint('Error loading push inbox: $e');
      return [];
    }
  }

  Future<void> saveInbox(
      String userId, List<PushNotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString('$_inboxPrefix$userId', encoded);
  }

  Future<void> markAllAsRead(String userId) async {
    final items = await loadInbox(userId);
    for (final item in items) {
      item.isRead = true;
    }
    await saveInbox(userId, items);
  }

  Future<void> clearInbox(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_inboxPrefix$userId');
  }
}
