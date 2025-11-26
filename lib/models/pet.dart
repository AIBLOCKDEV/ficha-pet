class Pet {
  int? id;
  String name;
  String type; // 'dog' or 'cat'
  String birthday;
  String weight;
  String gender; // 'male' or 'female'
  String breed;
  String chip; // 'yes' or 'no'
  String lastVaccineDate;
  String nextVaccineDate;
  String vaccineType;
  String lastDewormingDate;
  String nextDewormingDate;
  String dewormingProduct;
  List<MedicalHistoryEntry> medicalHistory;
  List<WeightHistoryEntry> weightHistory;
  PetFiles files;
  EmergencyContact emergencyContact;

  Pet({
    this.id,
    required this.name,
    required this.type,
    required this.birthday,
    required this.weight,
    required this.gender,
    required this.breed,
    required this.chip,
    required this.lastVaccineDate,
    required this.nextVaccineDate,
    required this.vaccineType,
    required this.lastDewormingDate,
    required this.nextDewormingDate,
    required this.dewormingProduct,
    required this.medicalHistory,
    required this.weightHistory,
    required this.files,
    required this.emergencyContact,
  });

  factory Pet.empty() {
    return Pet(
      name: '',
      type: '',
      birthday: '',
      weight: '',
      gender: '',
      breed: '',
      chip: '',
      lastVaccineDate: '',
      nextVaccineDate: '',
      vaccineType: '',
      lastDewormingDate: '',
      nextDewormingDate: '',
      dewormingProduct: '',
      medicalHistory: [],
      weightHistory: [],
      files: PetFiles.empty(),
      emergencyContact: EmergencyContact.empty(),
    );
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      birthday: json['birthday'] ?? '',
      weight: json['weight']?.toString() ?? '',
      gender: json['gender'] ?? '',
      breed: json['breed'] ?? '',
      chip: json['chip'] ?? '',
      lastVaccineDate: json['lastVaccineDate'] ?? '',
      nextVaccineDate: json['nextVaccineDate'] ?? '',
      vaccineType: json['vaccineType'] ?? '',
      lastDewormingDate: json['lastDewormingDate'] ?? '',
      nextDewormingDate: json['nextDewormingDate'] ?? '',
      dewormingProduct: json['dewormingProduct'] ?? '',
      medicalHistory: (json['medicalHistory'] as List<dynamic>?)
              ?.map((e) => MedicalHistoryEntry.fromJson(e))
              .toList() ??
          [],
      weightHistory: (json['weightHistory'] as List<dynamic>?)
              ?.map((e) => WeightHistoryEntry.fromJson(e))
              .toList() ??
          [],
      files: PetFiles.fromJson(json['files'] ?? {}),
      emergencyContact: EmergencyContact.fromJson(
          json['emergencyContact'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch,
      'name': name,
      'type': type,
      'birthday': birthday,
      'weight': weight,
      'gender': gender,
      'breed': breed,
      'chip': chip,
      'lastVaccineDate': lastVaccineDate,
      'nextVaccineDate': nextVaccineDate,
      'vaccineType': vaccineType,
      'lastDewormingDate': lastDewormingDate,
      'nextDewormingDate': nextDewormingDate,
      'dewormingProduct': dewormingProduct,
      'medicalHistory': medicalHistory.map((e) => e.toJson()).toList(),
      'weightHistory': weightHistory.map((e) => e.toJson()).toList(),
      'files': files.toJson(),
      'emergencyContact': emergencyContact.toJson(),
    };
  }

  Pet copyWith({
    int? id,
    String? name,
    String? type,
    String? birthday,
    String? weight,
    String? gender,
    String? breed,
    String? chip,
    String? lastVaccineDate,
    String? nextVaccineDate,
    String? vaccineType,
    String? lastDewormingDate,
    String? nextDewormingDate,
    String? dewormingProduct,
    List<MedicalHistoryEntry>? medicalHistory,
    List<WeightHistoryEntry>? weightHistory,
    PetFiles? files,
    EmergencyContact? emergencyContact,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      birthday: birthday ?? this.birthday,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      breed: breed ?? this.breed,
      chip: chip ?? this.chip,
      lastVaccineDate: lastVaccineDate ?? this.lastVaccineDate,
      nextVaccineDate: nextVaccineDate ?? this.nextVaccineDate,
      vaccineType: vaccineType ?? this.vaccineType,
      lastDewormingDate: lastDewormingDate ?? this.lastDewormingDate,
      nextDewormingDate: nextDewormingDate ?? this.nextDewormingDate,
      dewormingProduct: dewormingProduct ?? this.dewormingProduct,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      weightHistory: weightHistory ?? this.weightHistory,
      files: files ?? this.files,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}

class MedicalHistoryEntry {
  String date;
  String text;

  MedicalHistoryEntry({
    required this.date,
    required this.text,
  });

  factory MedicalHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MedicalHistoryEntry(
      date: json['date'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'text': text,
    };
  }
}

class WeightHistoryEntry {
  String date;
  double weight;

  WeightHistoryEntry({
    required this.date,
    required this.weight,
  });

  factory WeightHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WeightHistoryEntry(
      date: json['date'] ?? '',
      weight: (json['weight'] is num) ? json['weight'].toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'weight': weight,
    };
  }
}

class PetFiles {
  String petImage;
  String vaccineCard;
  List<ExamFile> exams;

  PetFiles({
    required this.petImage,
    required this.vaccineCard,
    required this.exams,
  });

  factory PetFiles.empty() {
    return PetFiles(
      petImage: '',
      vaccineCard: '',
      exams: [],
    );
  }

  factory PetFiles.fromJson(Map<String, dynamic> json) {
    return PetFiles(
      petImage: json['petImage'] ?? '',
      vaccineCard: json['vaccineCard'] ?? '',
      exams: (json['exams'] as List<dynamic>?)
              ?.map((e) => ExamFile.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'petImage': petImage,
      'vaccineCard': vaccineCard,
      'exams': exams.map((e) => e.toJson()).toList(),
    };
  }
}

class ExamFile {
  String name;
  String type;
  String data;

  ExamFile({
    required this.name,
    required this.type,
    required this.data,
  });

  factory ExamFile.fromJson(Map<String, dynamic> json) {
    return ExamFile(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      data: json['data'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'data': data,
    };
  }
}

class EmergencyContact {
  String name;
  String phone;
  String address;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.address,
  });

  factory EmergencyContact.empty() {
    return EmergencyContact(
      name: '',
      phone: '',
      address: '',
    );
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}

