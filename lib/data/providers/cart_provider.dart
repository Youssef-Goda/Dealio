import 'dart:convert';
import 'package:e_commerce/core/constants/base_url.dart';
import 'package:e_commerce/data/models/cart_item_model.dart';
import 'package:e_commerce/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider with ChangeNotifier {
  // ─────────────────────────── State ───────────────────────────
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get tax => double.parse((subtotal * 0.10).toStringAsFixed(2));
  double get total => double.parse((subtotal + tax).toStringAsFixed(2));

  // ─────────────────────────── Helpers ─────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final localToken = prefs.getString('accessToken');
    // final token = prefs.getString('token') ?? prefs.getString('accessToken');
    if (localToken != null && localToken.isNotEmpty) {
      debugPrint(
        '🔑 [CartProvider] Token from LocalStorage: ${localToken.substring(0, 10)}...',
      );
      return localToken;
    }

    debugPrint('⚠️ [CartProvider] No token found anywhere!');
    return null;
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token', // ← exact format backend expects
  };

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // ─────────────────────────── fetchCart ───────────────────────
  Future<void> fetchCart() async {
    _setLoading(true);
    _error = null;
    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Not authenticated';
        debugPrint('❌ [CartProvider] fetchCart → no token, aborting');
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/cart'),
        headers: _headers(token),
      );

      debugPrint(
        '--- SERVER RESPONSE: ${response.statusCode} | ${response.body}',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Backend shape: { success, action, data: { items: [...] } }
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final List<dynamic> raw = data['items'] ?? [];
        _items = raw.map((e) => CartItem.fromJson(e)).toList();
        debugPrint('✅ [CartProvider] fetchCart → ${_items.length} items');
      } else {
        final body = jsonDecode(response.body);
        _error =
            body['error']?['detail'] ??
            body['message'] ??
            'Failed to load cart (${response.statusCode})';
      }
    } catch (e) {
      _error = ApiService.parseErrorMessage(e);
      debugPrint('⚠️ fetchCart exception: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────── addItem ─────────────────────────
  /// Optimistic: add item locally first, rollback on failure.
  Future<String?> addItem({
    required String productId,
    required String productName,
    required String productCode,
    String? imageUrl,
    required double unitPrice,
    double? oldPrice,
    double? rating,
    required int countInStock,
    int quantity = 1,
  }) async {
    final existingIndex = _items.indexWhere((i) => i.productId == productId);
    CartItem? snapshot;

    if (existingIndex != -1) {
      snapshot = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity,
      );
      _items[existingIndex].quantity += quantity; // optimistic
    } else {
      _items.add(
        CartItem(
          cartItemId: 'optimistic-$productId',
          productId: productId,
          productCode: productCode,
          productName: productName,
          imageUrl: imageUrl,
          unitPrice: unitPrice,
          oldPrice: oldPrice,
          rating: rating,
          countInStock: countInStock,
          quantity: quantity,
        ),
      );
    }
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        return _rollbackAfterAdd(
          existingIndex,
          snapshot,
          productId,
          'Not authenticated',
        );
      }

      // ✅ Backend expects camelCase: { productId, quantity }
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/cart/add'),
        headers: _headers(token),
        body: jsonEncode({'productId': productId, 'quantity': quantity}),
      );

      debugPrint(
        '--- SERVER RESPONSE [addItem]: ${response.statusCode} | ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCart(); // sync real cart_item_id from server
        return null;
      } else {
        final body = jsonDecode(response.body);
        final msg =
            body['error']?['detail'] ??
            body['error']?['message'] ??
            body['message'] ??
            'Failed to add item';
        return _rollbackAfterAdd(existingIndex, snapshot, productId, msg);
      }
    } catch (e) {
      return _rollbackAfterAdd(
        existingIndex,
        snapshot,
        productId,
        ApiService.parseErrorMessage(e),
      );
    }
  }

  String _rollbackAfterAdd(
    int existingIndex,
    CartItem? snapshot,
    String productId,
    String msg,
  ) {
    if (existingIndex != -1 && snapshot != null) {
      _items[existingIndex].quantity = snapshot.quantity;
    } else {
      _items.removeWhere(
        (i) =>
            i.productId == productId && i.cartItemId.startsWith('optimistic-'),
      );
    }
    notifyListeners();
    return msg;
  }

  // ─────────────────────── updateQuantity ──────────────────────
  /// Optimistic: update qty locally, rollback on failure.
  Future<String?> updateQuantity(String productId, int newQty) async {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index == -1) return 'Item not found';

    if (newQty < 1) return removeItem(productId);

    final oldQty = _items[index].quantity;
    _items[index].quantity = newQty; // optimistic
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _items[index].quantity = oldQty;
        notifyListeners();
        return 'Not authenticated';
      }

      // ✅ Backend expects camelCase: { productId, quantity }
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/cart/update'),
        headers: _headers(token),
        body: jsonEncode({'productId': productId, 'quantity': newQty}),
      );

      debugPrint(
        '--- SERVER RESPONSE [updateQuantity]: ${response.statusCode} | ${response.body}',
      );

      if (response.statusCode == 200) return null;

      _items[index].quantity = oldQty; // rollback
      notifyListeners();
      final body = jsonDecode(response.body);
      return body['error']?['detail'] ?? body['message'] ?? 'Update failed';
    } catch (e) {
      _items[index].quantity = oldQty;
      notifyListeners();
      return ApiService.parseErrorMessage(e);
    }
  }

  // ─────────────────────────── removeItem ──────────────────────
  /// Optimistic: remove locally, reinsert on failure.
  Future<String?> removeItem(String productId) async {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index == -1) return null;

    final removed = _items[index];
    _items.removeAt(index); // optimistic
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _items.insert(index, removed);
        notifyListeners();
        return 'Not authenticated';
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/cart/remove/$productId'),
        headers: _headers(token),
      );

      debugPrint(
        '--- SERVER RESPONSE [removeItem]: ${response.statusCode} | ${response.body}',
      );

      if (response.statusCode == 200) return null;

      _items.insert(index, removed); // rollback
      notifyListeners();
      final body = jsonDecode(response.body);
      return body['error']?['detail'] ?? body['message'] ?? 'Remove failed';
    } catch (e) {
      _items.insert(index, removed);
      notifyListeners();
      return ApiService.parseErrorMessage(e);
    }
  }

  // ─────────────────────────── clearLocal ──────────────────────
  void clearLocal() {
    _items = [];
    _error = null;
    notifyListeners();
  }

  /// Semantic alias for [clearLocal] — clears the in-memory cart list
  /// immediately after a successful order placement so the UI reflects an
  /// empty cart without waiting for a server round-trip.
  void clearLocalCart() => clearLocal();
  void clearCart() => clearLocal();
}
