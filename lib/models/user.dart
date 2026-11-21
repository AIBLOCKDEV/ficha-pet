class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'owner' | 'vet'
  final String clinicName;
  final String avatarBase64;
  final String createdAt;
  final int themeSeedIndex;
  final String themeMode; // 'light', 'dark', 'system'
  final bool pushEnabled;
  final int advanceDays; // Días de anticipación para recordatorios (ej. 14 o 30)

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'owner',
    this.clinicName = '',
    this.avatarBase64 = '',
    required this.createdAt,
    this.themeSeedIndex = 0,
    this.themeMode = 'light',
    this.pushEnabled = true,
    this.advanceDays = 14,
  });

  bool get isVet => role == 'vet';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() == 'vet' ? 'vet' : 'owner',
      clinicName: json['clinicName']?.toString() ?? '',
      avatarBase64: json['avatarBase64']?.toString() ?? '',
      createdAt:
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      themeSeedIndex: (json['themeSeedIndex'] as num?)?.toInt() ?? 0,
      themeMode: json['themeMode']?.toString() ?? 'light',
      pushEnabled: json['pushEnabled'] is bool ? json['pushEnabled'] : true,
      advanceDays: (json['advanceDays'] as num?)?.toInt() ?? 14,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'clinicName': clinicName,
      'avatarBase64': avatarBase64,
      'createdAt': createdAt,
      'themeSeedIndex': themeSeedIndex,
      'themeMode': themeMode,
      'pushEnabled': pushEnabled,
      'advanceDays': advanceDays,
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? clinicName,
    String? avatarBase64,
    String? createdAt,
    int? themeSeedIndex,
    String? themeMode,
    bool? pushEnabled,
    int? advanceDays,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      clinicName: clinicName ?? this.clinicName,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      createdAt: createdAt ?? this.createdAt,
      themeSeedIndex: themeSeedIndex ?? this.themeSeedIndex,
      themeMode: themeMode ?? this.themeMode,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      advanceDays: advanceDays ?? this.advanceDays,
    );
  }
}
