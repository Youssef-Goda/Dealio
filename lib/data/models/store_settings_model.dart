class StoreSettings {
  final bool isBannerEnabled;
  final String? updatedAt;

  StoreSettings({
    this.isBannerEnabled = true,
    this.updatedAt,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      isBannerEnabled: json['is_banner_enabled'] ?? json['isBannerEnabled'] ?? true,
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_banner_enabled': isBannerEnabled,
      'updated_at': updatedAt,
    };
  }

  StoreSettings copyWith({
    bool? isBannerEnabled,
    String? updatedAt,
  }) {
    return StoreSettings(
      isBannerEnabled: isBannerEnabled ?? this.isBannerEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
