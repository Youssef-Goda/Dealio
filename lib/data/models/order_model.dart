import 'package:dealio/data/models/order_item_model.dart';
import 'package:dealio/data/models/shipping_address_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

enum PaymentMethod { cod, card, wallet, cash, online }

extension PaymentMethodX on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.cod:
        return 'cod';
      case PaymentMethod.card:
      case PaymentMethod.online:
        return 'card';
      case PaymentMethod.wallet:
        return 'wallet';
      case PaymentMethod.cash:
        return 'cash';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.card:
      case PaymentMethod.online:
        return 'Credit / Debit Card';
      case PaymentMethod.wallet:
        return 'Mobile Wallet';
      case PaymentMethod.cash:
        return 'Cash Payment Outlets';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethod.cod:
        return 'Pay in cash upon delivery';
      case PaymentMethod.card:
      case PaymentMethod.online:
        return 'Visa, Mastercard, Meeza';
      case PaymentMethod.wallet:
        return 'Vodafone Cash, Orange, Etisalat, WE';
      case PaymentMethod.cash:
        return 'Fawry, Aman, Masary, Basata outlets';
    }
  }

  static PaymentMethod fromString(String s) {
    final lower = s.toLowerCase();
    if (lower == 'card' || lower == 'online') return PaymentMethod.card;
    if (lower == 'wallet' || lower == 'mobile_wallet')
      return PaymentMethod.wallet;
    if (lower == 'cash' || lower == 'fawry') return PaymentMethod.cash;
    return PaymentMethod.cod;
  }
}

class Order {
  final String id;
  final String userId;
  final String? shippingAddressId;
  final ShippingAddress? shippingAddress;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final double subtotal;
  final double tax;
  final double total;
  final String? notes;
  final List<OrderItem> items;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.userId,
    this.shippingAddressId,
    this.shippingAddress,
    required this.paymentMethod,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.notes,
    this.items = const [],
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'] as String,
    userId: j['user_id'] as String,
    shippingAddressId: j['shipping_address_id'] as String?,
    shippingAddress: j['shipping_addresses'] != null
        ? ShippingAddress.fromJson(
            j['shipping_addresses'] as Map<String, dynamic>,
          )
        : null,
    paymentMethod: PaymentMethodX.fromString(
      j['payment_method'] as String? ?? 'cod',
    ),
    status: OrderStatusX.fromString(j['status'] as String? ?? 'pending'),
    subtotal: _toDouble(j['subtotal']),
    tax: _toDouble(j['tax']),
    total: _toDouble(j['total']),
    notes: j['notes'] as String?,
    items: (j['order_items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  /// Short order ID for display: last 8 chars of UUID
  String get shortId => id.length >= 8
      ? id.substring(id.length - 8).toUpperCase()
      : id.toUpperCase();

  /// Returns a copy with only the status field replaced.
  /// Used by updateOrderStatus to avoid losing address/items from a thin PATCH response
  /// (Supabase .select() on a simple UPDATE returns no joins).
  Order copyWithStatus(OrderStatus s) => Order(
    id: id,
    userId: userId,
    shippingAddressId: shippingAddressId,
    shippingAddress: shippingAddress,
    paymentMethod: paymentMethod,
    status: s,
    subtotal: subtotal,
    tax: tax,
    total: total,
    notes: notes,
    items: items,
    createdAt: createdAt,
  );
}
