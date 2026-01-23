class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final String image;
  final double rating;

const  Product({
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



final List<Product> dummyProducts = [
  Product(
    id: '1',
    name: 'Oppo Reno 6 4G',
    description: 'Normal samrt phone',
    price: 1200,
    oldPrice: 1500,
    image: 'https://i.ibb.co/NgJQZ5np/0c6f11cd330187c260f3c9060eb50fab-1.webp' ,
    rating: 4.5,
  ),
  Product(
    id: '2',
    name: 'iPhone 15 Pro Max',
    description: 'Titanium design with A17 Pro chip.',
    price: 55000,
    oldPrice: 60000,
    image: 'https://i.ibb.co/NgJQZ5np/0c6f11cd330187c260f3c9060eb50fab-1.webp',
    rating: 4.9,
  ),
  Product(
    id: '3',
    name: 'Sony WH-1000XM5',
    description: 'Industry-leading noise canceling headphones.',
    price: 15000,
    image: 'https://i.ibb.co/NgJQZ5np/0c6f11cd330187c260f3c9060eb50fab-1.webp',
    rating: 4.8,
  ),
  Product(
    id: '4',
    name: 'MacBook M3 Air',
    description: 'Powerfully thin and amazingly fast.',
    price: 72000,
    oldPrice: 75000,
    image: 'https://picsum.photos/id/1/200/300',
    rating: 4.7,
  ),
    Product(
    id: '5',
    name: 'Nike Air Max 2024',
    description: 'The best running shoes with air cushion technology.',
    price: 1200,
    oldPrice: 1500,
    image: 'https://picsum.photos/id/1/200/300' ,
    rating: 4.5,
  ),
];


