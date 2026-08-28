class UserModel {
  final String id;
  final int serialId;
  final String code;
  final String firstName;
  final String lastName;
  final String email;
  String role;
  bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // ── Extended profile fields ──────────────────────────────────────────────────
  final String? phoneNumber;
  final DateTime? birthDate;
  final String? gender; // 'male' | 'female' | 'other'
  final String? profilePicture; // ImgBB URL

  UserModel({
    required this.id,
    required this.serialId,
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    this.profilePicture,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    dynamic getValue(List<String> keys) {
      for (var key in keys) {
        if (json.containsKey(key) && json[key] != null) return json[key];
      }
      return null;
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      serialId:
          int.tryParse(getValue(['serial_id', 'serialId']).toString()) ?? 0,
      code: getValue(['code'])?.toString() ?? 'N/A',
      firstName: getValue(['firstName', 'first_name'])?.toString() ?? '',
      lastName: getValue(['lastName', 'last_name'])?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt:
          DateTime.tryParse(getValue(['createdAt', 'created_at']).toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
        getValue(['updatedAt', 'updated_at']).toString(),
      ),
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      birthDate: (json['birthDate'] ?? json['birth_date']) != null
          ? DateTime.tryParse(
              (json['birthDate'] ?? json['birth_date']).toString(),
            )
          : null,
      gender: json['gender']?.toString() ?? '',
      profilePicture: json['profilePicture'] ?? json['profile_picture'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'role': role,
    'isActive': isActive,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
    if (gender != null) 'gender': gender,
    if (profilePicture != null) 'profilePicture': profilePicture,
  };
}
