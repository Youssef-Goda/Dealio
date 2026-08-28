class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productCode;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productCode,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    id: j['id'] as String,
    orderId: j['order_id'] as String,
    productId: j['product_id'] as String,
    productName: j['product_name'] as String,
    productCode: j['product_code'] as String?,
    imageUrl: j['image_url'] as String?,
    unitPrice: _toDouble(j['unit_price']),
    quantity: j['quantity'] as int,
    subtotal: _toDouble(j['subtotal']),
  );

  Map<String, dynamic> toInsertJson(String orderId) => {
    'order_id': orderId,
    'product_id': productId,
    'product_name': productName,
    'product_code': productCode,
    'image_url': imageUrl,
    'unit_price': unitPrice,
    'quantity': quantity,
    'subtotal': subtotal,
  };

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}
