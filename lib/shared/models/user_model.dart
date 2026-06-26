class UserModel {
  final String id;
  final String name;
  final String phone;
  final String language;
  final DateTime createdAt;
  final bool profileSetupComplete;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.language,
    required this.createdAt,
    this.profileSetupComplete = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? language,
    DateTime? createdAt,
    bool? profileSetupComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      profileSetupComplete: profileSetupComplete ?? this.profileSetupComplete,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'language': language,
    'createdAt': createdAt.toIso8601String(),
    'profileSetupComplete': profileSetupComplete,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    language: json['language'] as String? ?? 'en',
    createdAt: DateTime.parse(json['createdAt'] as String),
    profileSetupComplete: json['profileSetupComplete'] as bool? ?? false,
  );

  static UserModel get defaultUser => UserModel(
    id: 'user_001',
    name: 'Ramesh Kumar',
    phone: '9876543210',
    language: 'en',
    createdAt: DateTime(2024, 1, 15),
    profileSetupComplete: true,
  );
}
