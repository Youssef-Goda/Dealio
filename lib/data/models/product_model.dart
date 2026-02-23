class Product {
  final String id;
  final int serialId;
  final String code;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final List<String> imageUrls;
  final double rating;
  final int countInStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.serialId,
    required this.code,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.imageUrls,
    required this.rating,
    required this.countInStock,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    dynamic getValue(List<String> keys) {
      for (var key in keys) {
        if (json.containsKey(key) && json[key] != null) return json[key];
      }
      return null;
    }

    List<String> parseImages() {
      var data = json['imageUrls'] ?? json['imageUrl'];

      if (data != null) {
        if (data is List) {
          return List<String>.from(data);
        } else if (data is String && data.isNotEmpty) {
          return data.contains(',') ? data.split(',') : [data];
        }
      }
      return [];
    }

    return Product(
      id: json['id']?.toString() ?? '',
      serialId:
          int.tryParse(getValue(['serial_id', 'serialId']).toString()) ?? 0,
      code: getValue(['code', 'productCode'])?.toString() ?? 'P-000',
      name: json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      oldPrice: json['oldPrice'] != null
          ? double.tryParse(json['oldPrice'].toString())
          : null,
      imageUrls: parseImages(),
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      countInStock: int.tryParse(json['countInStock']?.toString() ?? '0') ?? 0,
      createdAt:
          DateTime.tryParse(getValue(['createdAt', 'created_at']).toString()) ??
          DateTime.now(),
      updatedAt: json.containsKey('updatedAt') || json.containsKey('updated_at')
          ? DateTime.tryParse(getValue(['updatedAt', 'updated_at']).toString())
          : null,
    );
  }
}

class BannerItem {
  final String id;
  final String imageUrl;
  BannerItem({required this.id, required this.imageUrl});
  factory BannerItem.fromJson(Map<String, dynamic> json) =>
      BannerItem(id: json['id'].toString(), imageUrl: json['imageUrl'] ?? '');
}

class CategoryItem {
  final String id;
  final String name;
  final String icon;
  CategoryItem({required this.id, required this.name, required this.icon});
  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    icon: json['icon'] ?? '',
  );
}
