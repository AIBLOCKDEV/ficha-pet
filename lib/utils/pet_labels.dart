import 'package:flutter/material.dart';

/// Utilidades para mostrar los valores internos de una mascota en español.

IconData petTypeIcon(String type) =>
    type == 'cat' ? Icons.cruelty_free_rounded : Icons.pets_rounded;

String petTypeLabel(String type) {
  switch (type) {
    case 'dog':
      return 'Perro';
    case 'cat':
      return 'Gato';
    default:
      return 'Sin especificar';
  }
}

String petGenderLabel(String gender) {
  switch (gender) {
    case 'male':
      return 'Macho';
    case 'female':
      return 'Hembra';
    default:
      return 'Sin especificar';
  }
}

String petChipLabel(String chip) {
  switch (chip) {
    case 'yes':
      return 'Sí';
    case 'no':
      return 'No';
    default:
      return 'Sin especificar';
  }
}

/// Calcula la edad a partir de una fecha `yyyy-MM-dd`.
String petAgeLabel(String birthday) {
  if (birthday.isEmpty) return '';
  final birth = DateTime.tryParse(birthday);
  if (birth == null) return '';
  final now = DateTime.now();
  var years = now.year - birth.year;
  var months = now.month - birth.month;
  if (now.day < birth.day) months--;
  if (months < 0) {
    years--;
    months += 12;
  }
  if (years < 0) return '';
  if (years == 0) {
    return months == 1 ? '1 mes' : '$months meses';
  }
  return years == 1 ? '1 año' : '$years años';
}
