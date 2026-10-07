import 'dart:convert';

import 'package:dealio/core/constants/base_url.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrdersProvider with ChangeNotifier {
  // ─────────────────────────── State ───────────────────────────
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ─────────────────────── Auth helpers ────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    // 1️⃣ Primary key — written by _saveUserSession() on every login/restart
    final direct = prefs.getString('accessToken');
    if (direct != null && direct.isNotEmpty) return direct;

    // 2️⃣ Fallback: extract from the 'userData' blob in case the primary key
    //    wasn't re-pinned yet (e.g. race condition on first cold start after
    //    the auth_provider fix lands).
    try {
      final raw = prefs.getString('userData');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        // Handle both flat and nested { data: { accessToken, user: {} } }
        final dataMap = (map['data'] as Map<String, dynamic>?) ?? map;
        final userMap = (dataMap['user'] as Map<String, dynamic>?) ?? dataMap;
        final fallback =
            dataMap['accessToken']?.toString() ??
            userMap['accessToken']?.toString();
        if (fallback != null && fallback.isNotEmpty) {
          debugPrint(
            '⚠️ [OrdersProvider] accessToken key was missing — '
            'recovered from userData blob. Auth provider will re-pin it.',
          );
          // Re-pin so the next call hits path 1️⃣
          await prefs.setString('accessToken', fallback);
          return fallback;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [OrdersProvider] userData fallback parse error: $e');
    }

    debugPrint('❌ [OrdersProvider] No token found in SharedPrefs at all.');
    return null;
  }

  Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ─────────────────────────── fetchOrders ─────────────────────
  /// GET /api/orders — authenticated via JWT in SharedPreferences.
  /// No direct Supabase calls.
  Future<void> fetchOrders() async {
    _setLoading(true);
    _error = null;
    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'You are not logged in.';
        debugPrint('❌ [OrdersProvider] fetchOrders → no token');
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/orders'),
        headers: _authHeaders(token),
      );

      debugPrint('📡 [OrdersProvider] GET /orders → ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = body['data'] as List<dynamic>? ?? [];
        _orders = raw
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [OrdersProvider] fetchOrders → ${_orders.length} orders');
      } else {
        final body = _tryDecode(response.body);
        _error =
            body?['message']?.toString() ??
            'Failed to load orders (${response.statusCode})';
        debugPrint('❌ [OrdersProvider] fetchOrders error: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      debugPrint('❌ [OrdersProvider] fetchOrders exception: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────── fetchAdminOrders ───────────────────
  /// GET /api/orders/all — Admin: list all orders across all users (paginated + filtered).
  /// Authenticated via JWT in SharedPreferences (must have admin/super_admin/owner/moderator role).
  Future<void> fetchAdminOrders({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
    String? governorate,
    String? city,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'You are not logged in.';
        debugPrint('❌ [OrdersProvider] fetchAdminOrders → no token');
        return;
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null &&
          status.trim().isNotEmpty &&
          status.trim().toLowerCase() != 'all') {
        queryParams['status'] = status.trim().toLowerCase();
      }
      if (governorate != null &&
          governorate.trim().isNotEmpty &&
          governorate != 'All Governorates') {
        queryParams['governorate'] = governorate.trim();
      }
      if (city != null &&
          city.trim().isNotEmpty &&
          city != 'All Cities') {
        queryParams['city'] = city.trim();
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/orders/all')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _authHeaders(token),
      );

      debugPrint('📡 [OrdersProvider] GET /orders/all → ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = body['data'] as List<dynamic>? ?? [];
        _orders = raw
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint(
          '✅ [OrdersProvider] fetchAdminOrders → ${_orders.length} orders',
        );
      } else {
        final body = _tryDecode(response.body);
        _error =
            body?['message']?.toString() ??
            'Failed to load admin orders (${response.statusCode})';
        debugPrint('❌ [OrdersProvider] fetchAdminOrders error: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      debugPrint('❌ [OrdersProvider] fetchAdminOrders exception: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ────────────────────── prependOrder ─────────────────────────
  /// Called right after placeOrder() to immediately surface the new order.
  void prependOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  // ────────────────────── cancelOrder ─────────────────────────
  /// Calls POST /api/orders/:id/cancel on the backend.
  /// Updates the local order in the state list.
  Future<void> cancelOrder(String orderId) async {
    _setLoading(true);
    _error = null;
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('You are not logged in.');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/orders/$orderId/cancel'),
        headers: _authHeaders(token),
      );

      debugPrint(
        '📡 [OrdersProvider] POST /orders/$orderId/cancel → ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final orderData = body['data'] as Map<String, dynamic>;
        final updatedOrder = Order.fromJson(orderData);

        // Update local state list
        final idx = _orders.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          _orders[idx] = updatedOrder;
          notifyListeners();
        }
        debugPrint('✅ [OrdersProvider] cancelOrder success for $orderId');
      } else {
        final body = _tryDecode(response.body);
        final msg =
            body?['message']?.toString() ??
            'Failed to cancel order (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [OrdersProvider] cancelOrder exception: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────── updateOrderStatus ──────────────────────
  /// PATCH /api/orders/:id/status  (admin/owner/moderator only).
  /// Sends the new status as a lowercase string matching the backend
  /// VALID_STATUSES list.  Patches the order in-place in _orders and
  /// notifies listeners so the table row updates immediately.
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final token = await _getToken();
    if (token == null) throw Exception('You are not logged in.');

    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/orders/$orderId/status'),
      headers: _authHeaders(token),
      body: jsonEncode({'status': newStatus.name}), // e.g. "shipped"
    );

    debugPrint(
      '📡 [OrdersProvider] PATCH /orders/$orderId/status '
      '→ ${response.statusCode}: ${response.body}',
    );

    if (response.statusCode == 200) {
      // PATCH response is a thin Supabase row with no joins (no shipping_addresses,
      // no order_items). Do NOT rebuild from JSON — that wipes customer/address/items.
      // Instead patch only the status onto the existing in-memory Order.
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = _orders[idx].copyWithStatus(newStatus);
        notifyListeners();
      }
    } else {
      final body = _tryDecode(response.body);
      final msg =
          body?['message']?.toString() ??
          'Failed to update status (${response.statusCode})';
      throw Exception(msg);
    }
  }

  void clearOrders() {
    _orders = [];
    _error = null;
    notifyListeners();
  }

  // ─────────────────────── Helpers ─────────────────────────────
  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
