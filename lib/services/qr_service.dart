import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ficha_pet/models/pet.dart';
import 'dart:convert';

class QRService {
  static Widget generateQRCode(Pet pet) {
    // Crear un JSON con la información básica de la mascota
    final petData = {
      'id': pet.id,
      'name': pet.name,
      'type': pet.type,
      'breed': pet.breed,
      'birthday': pet.birthday,
      'owner': pet.emergencyContact.name,
      'phone': pet.emergencyContact.phone,
    };

    final jsonString = json.encode(petData);

    return QrImageView(
      data: jsonString,
      version: QrVersions.auto,
      size: 200.0,
      backgroundColor: Colors.white,
    );
  }
}

