import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ficha_pet/models/pet.dart';

class ParsedClinicalQR {
  final int? petId;
  final String shareCode;

  const ParsedClinicalQR({
    this.petId,
    this.shareCode = '',
  });
}

class QRService {
  /// Genera el payload clínico oficial de Ficha Pet para que un veterinario
  /// pueda escanearlo desde la app y vincular la ficha con sincronización bidireccional.
  static String buildQRPayload(Pet pet) {
    final data = {
      'app': 'ficha_pet',
      'v': 2,
      'petId': pet.id,
      'ownerId': pet.ownerId,
      'shareCode': pet.shareCode,
      'name': pet.name,
      'type': pet.type,
      'breed': pet.breed,
    };
    return json.encode(data);
  }

  /// Interpreta tanto el JSON completo del QR escaneado como el código corto `FP-XXXXXX`
  /// o el ID numérico de la mascota.
  static ParsedClinicalQR? parseQRPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('{')) {
      try {
        final map = json.decode(trimmed) as Map<String, dynamic>;
        final petId = (map['petId'] as num?)?.toInt() ?? (map['id'] as num?)?.toInt();
        final shareCode = map['shareCode']?.toString().trim().toUpperCase() ?? '';
        if (petId != null || shareCode.isNotEmpty) {
          return ParsedClinicalQR(petId: petId, shareCode: shareCode);
        }
      } catch (_) {
        return null;
      }
    }

    final upper = trimmed.toUpperCase();
    if (upper.startsWith('FP-')) {
      return ParsedClinicalQR(shareCode: upper);
    }

    final asInt = int.tryParse(trimmed);
    if (asInt != null) {
      return ParsedClinicalQR(petId: asInt);
    }

    return ParsedClinicalQR(shareCode: 'FP-$upper');
  }

  static Widget generateQRCode(Pet pet, {double size = 210}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: QrImageView(
        data: buildQRPayload(pet),
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF141824),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF141824),
        ),
      ),
    );
  }
}
