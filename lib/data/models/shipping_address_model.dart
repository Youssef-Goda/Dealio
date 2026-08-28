class ShippingAddress {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String governorate;
  final bool isDefault;
  final DateTime? createdAt;
  // ── GPS coordinates (optional — populated by "Detect My Location") ──────────
  final double? latitude;
  final double? longitude;

  const ShippingAddress({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.governorate,
    this.isDefault = false,
    this.createdAt,
    this.latitude,
    this.longitude,
  });

  // ────────────────── Serialisation ──────────────────────────
  factory ShippingAddress.fromJson(Map<String, dynamic> j) => ShippingAddress(
    id: j['id'] as String,
    userId: j['user_id'] as String,
    fullName: j['full_name'] as String,
    phone: j['phone'] as String,
    addressLine1: j['address_line1'] as String,
    addressLine2: j['address_line2'] as String?,
    city: j['city'] as String,
    governorate: j['governorate'] as String,
    isDefault: j['is_default'] as bool? ?? false,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
    latitude: j['latitude'] != null
        ? double.tryParse(j['latitude'].toString())
        : null,
    longitude: j['longitude'] != null
        ? double.tryParse(j['longitude'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'city': city,
    'governorate': governorate,
    'is_default': isDefault,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  // ────────────────── copyWith ────────────────────────────────
  ShippingAddress copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? governorate,
    bool? isDefault,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) => ShippingAddress(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    addressLine1: addressLine1 ?? this.addressLine1,
    addressLine2: addressLine2 ?? this.addressLine2,
    city: city ?? this.city,
    governorate: governorate ?? this.governorate,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
  );

  /// Compact single-line display string
  String get displayLine =>
      '$addressLine1${addressLine2 != null ? ', $addressLine2' : ''}, $city, $governorate';
}
