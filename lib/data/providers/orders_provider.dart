import 'dart:convert';

import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrderFetchFailure — classifies the reason a fetchOrderById call failed.
//
// Callers use this to show the right error message and decide whether to
// offer a retry, redirect to login, or surface a contact-support path.
// ─────────────────────────────────────────────────────────────────────────────
enum OrderFetchFailure {
  /// No token in SharedPreferences — user is not signed in.
  unauthenticated,

  /// Token is valid but the user does not own this order (403).
  unauthorized,

  /// The order ID does not exist in the database (404).
  notFound,

  /// Backend returned a 5xx or an unexpected non-200 status.
  server,

  /// Response body could not be decoded or mapped to [Order].
  parse,

  /// Socket/DNS/timeout — no HTTP response received at all.
  network,
}

/// Thrown by [OrdersProvider.fetchOrderById] on every non-success path.
///
/// Carries a human-readable [message] safe to display in the UI, and a
/// machine-readable [failure] tag for conditional UI logic (retry button,
/// login redirect, etc.).
class OrderFetchException implements Exception {
  final OrderFetchFailure failure;
  final String message;
  const OrderFetchException(this.failure, this.message);

  @override
  String toString() => 'OrderFetchException(${failure.name}): $message';
}

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

      final response = await ApiService.getRequest('/orders', token);

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
      if (city != null && city.trim().isNotEmpty && city != 'All Cities') {
        queryParams['city'] = city.trim();
      }

      final query = Uri(queryParameters: queryParams).query;
      final response = await ApiService.getRequest('/orders/all?$query', token);

      debugPrint(
        '📡 [OrdersProvider] GET /orders/all → ${response.statusCode}',
      );

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

      final response = await ApiService.postAuthRequest(
        '/orders/$orderId/cancel',
        const {},
        token,
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

    final response = await ApiService.patchAuthRequest(
      '/orders/$orderId/status',
      {'status': newStatus.name}, // e.g. "shipped"
      token,
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

  // ───────────────────────── fetchOrderById ────────────────────
  /// GET /api/orders/:id — Fetch a single order by its internal UUID.
  ///
  /// Returns the [Order] on success.
  ///
  /// Throws an [OrderFetchException] on every failure so callers can
  /// distinguish authentication, authorization, not-found, server, parsing,
  /// and network errors and surface a useful message to the user.
  ///
  /// Also upserts the order into the local [_orders] list so
  /// [OrderDetailScreen] can read it via context.select immediately.
  Future<Order> fetchOrderById(String orderId) async {
    // ── 1. Auth token ────────────────────────────────────────────────────────
    final token = await _getToken();
    if (token == null) {
      debugPrint('❌ [OrdersProvider] fetchOrderById → no token');
      throw const OrderFetchException(
        OrderFetchFailure.unauthenticated,
        'Not signed in. Please log in and try again.',
      );
    }

    // ── 2. HTTP request ──────────────────────────────────────────────────────
    late http.Response response;
    try {
      response = await ApiService.getRequest('/orders/$orderId', token);
    } catch (e) {
      // Socket / DNS / timeout errors
      debugPrint('❌ [OrdersProvider] fetchOrderById network error: $e');
      throw OrderFetchException(
        OrderFetchFailure.network,
        'Network error — please check your connection and try again.',
      );
    }

    debugPrint(
      '📡 [OrdersProvider] GET /orders/$orderId → ${response.statusCode}',
    );

    // ── 3. HTTP error responses ──────────────────────────────────────────────
    if (response.statusCode != 200) {
      final body = _tryDecode(response.body);
      final serverMsg = body?['message']?.toString();

      final failure = switch (response.statusCode) {
        401 => OrderFetchFailure.unauthenticated,
        403 => OrderFetchFailure.unauthorized,
        404 => OrderFetchFailure.notFound,
        >= 500 => OrderFetchFailure.server,
        _ => OrderFetchFailure.server,
      };

      final displayMsg = switch (failure) {
        OrderFetchFailure.unauthenticated =>
          'Your session has expired. Please log in again.',
        OrderFetchFailure.unauthorized =>
          'You do not have permission to view this order.',
        OrderFetchFailure.notFound =>
          'Order not found (it may still be processing).',
        _ =>
          serverMsg ??
              'Server error (${response.statusCode}). '
                  'Please try again in a moment.',
      };

      debugPrint(
        '❌ [OrdersProvider] fetchOrderById HTTP ${response.statusCode}: '
        '${serverMsg ?? "(no message)"}',
      );
      throw OrderFetchException(failure, displayMsg);
    }

    // ── 4. Parse response body ───────────────────────────────────────────────
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = body['data'] as Map<String, dynamic>?;
      if (raw == null) {
        throw OrderFetchException(
          OrderFetchFailure.parse,
          'Unexpected response format from server (missing "data" field).',
        );
      }

      final order = Order.fromJson(raw);

      // Upsert into local list so OrderDetailScreen.context.select picks it up
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = order;
      } else {
        _orders.insert(0, order);
      }
      notifyListeners();

      debugPrint(
        '✅ [OrdersProvider] fetchOrderById → ${order.id} '
        '(${order.items.length} items)',
      );
      return order;
    } on OrderFetchException {
      rethrow;
    } catch (e) {
      // JSON decode error or fromJson type cast failure
      debugPrint('❌ [OrdersProvider] fetchOrderById parse error: $e');
      throw OrderFetchException(
        OrderFetchFailure.parse,
        'Could not read order data. '
        'Details: ${e.toString().split('\n').first}',
      );
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
