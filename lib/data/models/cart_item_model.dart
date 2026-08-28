class CartItem {
  final String cartItemId;
  final String productId;
  final String productCode;
  final String productName;
  final String? imageUrl;
  final double unitPrice;
  final double? oldPrice;
  final double? rating;
  final int countInStock;
  int quantity;

  CartItem({
    required this.cartItemId,
    required this.productId,
    required this.productCode,
    required this.productName,
    this.imageUrl,
    required this.unitPrice,
    this.oldPrice,
    this.rating,
    required this.countInStock,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productCode: json['product_code']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Unknown',
      imageUrl: json['image_url']?.toString(),
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      oldPrice: json['old_price'] != null
          ? double.tryParse(json['old_price'].toString())
          : null,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      countInStock:
          int.tryParse(json['count_in_stock']?.toString() ?? '0') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      cartItemId: cartItemId,
      productId: productId,
      productCode: productCode,
      productName: productName,
      imageUrl: imageUrl,
      unitPrice: unitPrice,
      oldPrice: oldPrice,
      rating: rating,
      countInStock: countInStock,
      quantity: quantity ?? this.quantity,
    );
  }
}
