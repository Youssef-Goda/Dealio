class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final String image;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.image,
    required this.rating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'].toString(),
      name: json['name'] ?? 'Unknown Product',
      description:
          json['description'] ?? 'No description available for this product.',
      price: double.parse((json['price'] ?? 0).toString()),
      oldPrice: json['oldPrice'] != null
          ? double.parse(json['oldPrice'].toString())
          : null,
      image: json['image'],
      rating: double.parse((json['rating'] ?? 0.0).toString()),
    );
  }
}

class BannerItem {
  final String id;
  final String imageUrl;

  BannerItem({required this.id, required this.imageUrl});

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['_id'] ?? json['id'].toString(),
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

class CategoryItem {
  final String id;
  final String name;
  final String icon;

  CategoryItem({required this.id, required this.name, required this.icon});

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['_id'] ?? json['id'].toString(),
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}
