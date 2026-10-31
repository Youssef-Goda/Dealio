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
    id:          j['id']?.toString()           ?? '',
    orderId:     j['order_id']?.toString()     ?? '',
    productId:   j['product_id']?.toString()   ?? '',
    productName: j['product_name']?.toString() ?? '(unknown product)',
    productCode: j['product_code']?.toString(),
    imageUrl:    j['image_url']?.toString(),
    unitPrice:   _toDouble(j['unit_price']),
    quantity:    (j['quantity'] as num?)?.toInt() ?? 0,
    subtotal:    _toDouble(j['subtotal']),
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
