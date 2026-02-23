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
  });

  String get fullName => "$firstName $lastName";

  factory UserModel.fromJson(Map<String, dynamic> json) {
    dynamic getValue(List<String> keys) {
      for (var key in keys) {
        if (json.containsKey(key) && json[key] != null) return json[key];
      }
      return null;
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      serialId: int.tryParse(getValue(['serial_id']).toString()) ?? 0,
      code: getValue(['code'])?.toString() ?? 'N/A',

      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isActive: json['isActive'] ?? json['is_active'] ?? true,

      createdAt:
          DateTime.tryParse(getValue(['createdAt']).toString()) ??
          DateTime.now(),

      updatedAt: json.containsKey('updatedAt')
          ? DateTime.tryParse(getValue(['updatedAt']).toString())
          : null,
    );
  }
}
