import 'dart:convert';

import 'package:dealio/core/constants/base_url.dart';
import 'package:dealio/data/models/cart_item_model.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/data/models/shipping_address_model.dart';
import 'package:dealio/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum CheckoutStep { address, payment, review }

class CheckoutProvider with ChangeNotifier {
  // ─────────────────────────── State ───────────────────────────
  List<ShippingAddress> _addresses = [];
  ShippingAddress? _selectedAddress;
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  bool _isInitiatingPayment = false;
  String? _paymentUrl;
  // Cash / Fawry result
  String? _billReference;
  String? _billExpiresAt;
  String? _error;

  // ─────────────────────────── Getters ─────────────────────────
  List<ShippingAddress> get addresses => _addresses;
  ShippingAddress? get selectedAddress => _selectedAddress;
  PaymentMethod get paymentMethod => _paymentMethod;
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isInitiatingPayment => _isInitiatingPayment;
  String? get paymentUrl => _paymentUrl;
  String? get billReference => _billReference;
  String? get billExpiresAt => _billExpiresAt;
  String? get error => _error;

  bool get canPlaceOrder =>
      _selectedAddress != null &&
      !_isPlacingOrder &&
      !_isInitiatingPayment;

  // ─────────────────────── Auth helpers ────────────────────────
  /// Reads the JWT access token stored by AuthProvider after login.
  /// This token is sent as `Authorization: Bearer <token>` to the Node.js API.
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token != null && token.isNotEmpty) {
      final cleanToken = token.trim();
      if (cleanToken.isNotEmpty) return cleanToken;
    }
    debugPrint('⚠️ [CheckoutProvider] No JWT token found in SharedPrefs.');
    return null;
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ─────────────────────── fetchAddresses ──────────────────────
  /// GET /api/addresses — loads the authenticated user's saved addresses.
  Future<void> fetchAddresses() async {
    _setLoading(true);
    _error = null;
    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'You are not logged in. Please log in to view your addresses.';
        debugPrint('❌ [CheckoutProvider] fetchAddresses → no token');
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/addresses'),
        headers: _authHeaders(token),
      );

      debugPrint(
        '📡 [CheckoutProvider] GET /addresses → ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = body['data'] as List<dynamic>? ?? [];
        _addresses = raw
            .map((e) => ShippingAddress.fromJson(e as Map<String, dynamic>))
            .toList();

        await loadCheckoutPrefs();
        if (_selectedAddress == null && _addresses.isNotEmpty) {
          _selectedAddress = _addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _addresses.first,
          );
        }
        debugPrint(
          '✅ [CheckoutProvider] fetchAddresses → ${_addresses.length} addresses',
        );
      } else {
        final body = _tryDecode(response.body);
        _error = body?['message']?.toString() ??
            'Failed to load addresses (${response.statusCode})';
        debugPrint('❌ [CheckoutProvider] fetchAddresses error: $_error');
      }
    } catch (e) {
      _error = ApiService.parseErrorMessage(e);
      debugPrint('❌ [CheckoutProvider] fetchAddresses exception: $e');
    } finally {
      _setLoading(false);
    }
  }

  static const String _prefPaymentMethodKey = 'checkout_payment_method';
  static const String _prefAddressIdKey = 'checkout_address_id';

  Future<void> _saveCheckoutPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefPaymentMethodKey, _paymentMethod.name);
      if (_selectedAddress != null) {
        await prefs.setString(_prefAddressIdKey, _selectedAddress!.id);
      }
    } catch (e) {
      debugPrint('⚠️ Error saving checkout prefs: $e');
    }
  }

  Future<void> loadCheckoutPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMethod = prefs.getString(_prefPaymentMethodKey);
      if (savedMethod != null && savedMethod.isNotEmpty) {
        final match = PaymentMethod.values.firstWhere(
          (m) => m.name == savedMethod,
          orElse: () => PaymentMethod.cod,
        );
        _paymentMethod = match;
      }
      final savedAddrId = prefs.getString(_prefAddressIdKey);
      if (savedAddrId != null && savedAddrId.isNotEmpty && _addresses.isNotEmpty) {
        final matchAddr = _addresses.firstWhere(
          (a) => a.id == savedAddrId,
          orElse: () => _selectedAddress ?? _addresses.first,
        );
        _selectedAddress = matchAddr;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error loading checkout prefs: $e');
    }
  }

  // ────────────────────────── selectAddress ────────────────────
  void selectAddress(ShippingAddress address) {
    _selectedAddress = address;
    notifyListeners();
    _saveCheckoutPrefs();
  }

  // ────────────────────────── selectPayment ────────────────────
  void selectPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
    _saveCheckoutPrefs();
  }

  // ────────────────────────── addAddress ───────────────────────
  /// POST /api/addresses — creates a new address via the Node.js backend.
  Future<void> addAddress(ShippingAddress address) async {
    _setLoading(true);
    _error = null;
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception(
          'You are not logged in. Please log in to save an address.',
        );
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/addresses'),
        headers: _authHeaders(token),
        body: jsonEncode(address.toJson()),
      );

      debugPrint(
        '📡 [CheckoutProvider] POST /addresses → ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final newAddr =
            ShippingAddress.fromJson(body['data'] as Map<String, dynamic>);
        _addresses.insert(0, newAddr);
        if (address.isDefault || _addresses.length == 1) {
          _selectedAddress = newAddr;
          // Update local list if default changed
          if (address.isDefault) {
            for (var i = 0; i < _addresses.length; i++) {
              if (_addresses[i].id != newAddr.id && _addresses[i].isDefault) {
                _addresses[i] = _addresses[i].copyWith(isDefault: false);
              }
            }
          }
        }
        debugPrint('✅ [CheckoutProvider] addAddress → ${newAddr.id}');
      } else {
        final body = _tryDecode(response.body);
        final msg = body?['message']?.toString() ??
            'Failed to save address (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      _error = ApiService.parseErrorMessage(e);
      debugPrint('❌ [CheckoutProvider] addAddress: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ────────────────────────── updateAddress ────────────────────
  /// PUT /api/addresses/:id — updates an existing address.
  Future<void> updateAddress(ShippingAddress address) async {
    _setLoading(true);
    _error = null;
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('You are not logged in.');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/addresses/${address.id}'),
        headers: _authHeaders(token),
        body: jsonEncode(address.toJson()),
      );

      debugPrint(
        '📡 [CheckoutProvider] PUT /addresses/${address.id} → ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final updatedAddr =
            ShippingAddress.fromJson(body['data'] as Map<String, dynamic>);
        final idx = _addresses.indexWhere((a) => a.id == address.id);
        if (idx != -1) {
          _addresses[idx] = updatedAddr;
          if (address.isDefault) {
            for (var i = 0; i < _addresses.length; i++) {
              if (i != idx && _addresses[i].isDefault) {
                _addresses[i] = _addresses[i].copyWith(isDefault: false);
              }
            }
          }
        }
        if (_selectedAddress?.id == address.id) _selectedAddress = updatedAddr;
        debugPrint('✅ [CheckoutProvider] updateAddress → ${updatedAddr.id}');
      } else {
        final body = _tryDecode(response.body);
        final msg = body?['message']?.toString() ??
            'Failed to update address (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      _error = ApiService.parseErrorMessage(e);
      debugPrint('❌ [CheckoutProvider] updateAddress: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ────────────────────────── deleteAddress ────────────────────
  /// DELETE /api/addresses/:id — removes an address.
  Future<void> deleteAddress(String addressId) async {
    _setLoading(true);
    _error = null;
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('You are not logged in.');
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/addresses/$addressId'),
        headers: _authHeaders(token),
      );

      debugPrint(
        '📡 [CheckoutProvider] DELETE /addresses/$addressId → ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        _addresses.removeWhere((a) => a.id == addressId);
        if (_selectedAddress?.id == addressId) {
          _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
        }
        debugPrint('✅ [CheckoutProvider] deleteAddress → $addressId');
      } else {
        final body = _tryDecode(response.body);
        final msg = body?['message']?.toString() ??
            'Failed to delete address (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      _error = ApiService.parseErrorMessage(e);
      debugPrint('❌ [CheckoutProvider] deleteAddress: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────── placeOrder ──────────────────────
  /// Calls POST /api/orders (Node.js backend, JWT-authenticated).
  /// Returns the created [Order] on success, throws on failure.
  /// Zero direct Supabase calls — the backend uses the service role key.
  Future<Order> placeOrder({
    required String userId,
    required List<CartItem> cartItems,
    required double subtotal,
    required double tax,
    required double total,
    String? notes,
  }) async {
    if (_selectedAddress == null) throw Exception('No address selected');
    if (cartItems.isEmpty) throw Exception('Cart is empty');

    _isPlacingOrder = true;
    _error = null;
    notifyListeners();

    try {
      // Velocity limit is enforced server-side (backend checks role + active orders)
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not logged in. Please log in to place an order.');
      }

      final itemsPayload = cartItems.map((ci) => {
        'product_id': ci.productId,
        'product_name': ci.productName,
        'product_code': ci.productCode,
        'image_url': ci.imageUrl,
        'unit_price': ci.unitPrice,
        'quantity': ci.quantity,
        'subtotal': ci.subtotal,
      }).toList();

      final body = jsonEncode({
        'shipping_address_id': _selectedAddress!.id,
        'payment_method': _paymentMethod.value,
        'items': itemsPayload,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

      debugPrint(
        '📡 [CheckoutProvider] POST /orders → items=${cartItems.length}, total=$total',
      );

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/orders'),
        headers: _authHeaders(token),
        body: body,
      );

      debugPrint(
        '📡 [CheckoutProvider] POST /orders → ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final orderData = decoded['data'] as Map<String, dynamic>;
        debugPrint('✅ [CheckoutProvider] placeOrder → ${orderData['id']}');
        return Order.fromJson(orderData);
      } else {
        final decoded = _tryDecode(response.body);
        final msg = decoded?['message']?.toString() ??
            'Failed to place order (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      _error = ApiService.parseErrorMessage(e);
      debugPrint('❌ [CheckoutProvider] placeOrder: $e');
      rethrow;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  // ─────────────────── initiatePaymobPayment ───────────────────
  /// Calls POST /api/v1/payments/paymob/initiate.
  ///
  /// On success returns a map containing:
  ///   • card/wallet → { payment_type, iframe_url }
  ///   • cash/fawry  → { payment_type: 'cash', reference_number, expire_date }
  ///
  /// On ANY failure (network, Paymob 4xx/5xx, missing config) throws an
  /// Exception whose message is the exact server-sent reason string so the
  /// UI can display it verbatim in a SnackBar.
  ///
  /// The loading flag (_isInitiatingPayment) is ALWAYS cleared in finally,
  /// so the Pay button is never permanently stuck.
  Future<Map<String, dynamic>> initiatePaymobPayment({
    required String orderId,
    required PaymentMethod paymentMethod,
    required double amount,
    String? walletNumber,
  }) async {
    _isInitiatingPayment = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not logged in. Please log in to proceed with payment.');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/v1/payments/paymob/initiate'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'order_id': orderId,
          'payment_method': paymentMethod.value,
          // amount is intentionally sent for logging only — backend re-reads from DB
          'amount': amount,
          if (walletNumber != null && walletNumber.trim().isNotEmpty)
            'wallet_number': walletNumber.trim(),
        }),
      );

      debugPrint(
        '📡 [CheckoutProvider] POST /v1/payments/paymob/initiate '
        '→ ${response.statusCode}: ${response.body}',
      );

      // ── Always decode the body first so we can surface exact error message ──
      final decoded = _tryDecode(response.body) ?? {};
      final data = (decoded['data'] as Map<String, dynamic>?) ?? decoded;

      final serverMsg = decoded['message']?.toString() ?? data['message']?.toString();
      final isSuccess = decoded['success'] != false && data['success'] != false;

      // ── Handle error responses (4xx / 5xx or success == false) ───────────
      if (response.statusCode < 200 || response.statusCode >= 300 || !isSuccess) {
        throw Exception(
          serverMsg?.isNotEmpty == true
              ? serverMsg!
              : 'Payment initialization failed (HTTP ${response.statusCode}).',
        );
      }

      // ── 2xx — parse the success payload ──────────────────────────────────
      final paymentType = data['payment_type']?.toString() ?? 'card';
      final publicKey = data['public_key']?.toString();

      // ─ Cash / Fawry kiosk ─────────────────────────────────────────────────
      if (paymentType == 'cash') {
        // Backend now returns 'reference_number' and 'expire_date'
        final ref     = data['reference_number']?.toString() ?? '';
        final expires = data['expire_date']?.toString() ?? '';
        if (ref.isEmpty) {
          throw Exception('Bill reference was not returned by the server.');
        }
        _billReference = ref;
        _billExpiresAt = expires;
        return {
          'payment_type':     'cash',
          'reference_number': ref,
          'expire_date':      expires,
          if (publicKey != null && publicKey.isNotEmpty) 'public_key': publicKey,
        };
      }

      // ─ Card / Wallet ───────────────────────────────────────────────────────
      // Read the client_secret from the new Intention API flow.
      final clientSecret = data['client_secret']?.toString();

      // if (clientSecret != null && clientSecret.isNotEmpty) {
      //   final unifiedCheckoutUrl = (publicKey != null && publicKey.isNotEmpty)
      //       ? 'https://accept.paymob.com/unifiedcheckout/?publicKey=${Uri.encodeComponent(publicKey)}&clientSecret=${Uri.encodeComponent(clientSecret)}'
      //       : null;
      //   _paymentUrl = unifiedCheckoutUrl ?? clientSecret;
      if (clientSecret != null && clientSecret.isNotEmpty) {
        // --- التعديل هنا: تحديد الدومين ديناميكياً ---
        final isTestKey = publicKey != null && publicKey.toLowerCase().contains('test');
        final domain = isTestKey ? 'accept.paymobsolutions.com' : 'accept.paymob.com';

        final unifiedCheckoutUrl = (publicKey != null && publicKey.isNotEmpty)
            ? 'https://$domain/unifiedcheckout/?publicKey=${Uri.encodeComponent(publicKey)}&clientSecret=${Uri.encodeComponent(clientSecret)}'
            : null;
        _paymentUrl = unifiedCheckoutUrl ?? clientSecret;
        // ----------------------------------------------
        return {
          'payment_type': paymentType,
          'client_secret': clientSecret,
          if (unifiedCheckoutUrl != null) 'payment_url': unifiedCheckoutUrl,
          if (publicKey != null && publicKey.isNotEmpty) 'public_key': publicKey,
        };
      }

      final errorDetail = serverMsg?.isNotEmpty == true ? serverMsg! : 'client_secret was not returned by the server.';
      throw Exception(errorDetail);
    } catch (e) {
      _error = ApiService.parseErrorMessage(e);
      debugPrint('❌ [CheckoutProvider] initiatePaymobPayment: $e');
      rethrow;
    } finally {
      // ALWAYS reset loading flag so the Pay button is never permanently stuck
      _isInitiatingPayment = false;
      notifyListeners();
    }
  }

  // ─────────────────── verifyPaymentStatus ─────────────────────
  /// Calls GET /api/orders/:orderId/payment-status (JWT-authenticated).
  ///
  /// Returns the server-authoritative [payment_status] string:
  ///   'pending' | 'initiated' | 'paid' | 'failed'
  ///
  /// Throws an Exception on network error or unexpected response.
  /// The caller ("I Have Paid" button) uses this to decide whether
  /// to proceed to the success screen — no client-side override.
  Future<String> verifyPaymentStatus(String orderId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not logged in. Please log in to verify payment.');
    }

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/orders/$orderId/payment-status'),
      headers: _authHeaders(token),
    );

    debugPrint(
      '📡 [CheckoutProvider] GET /orders/$orderId/payment-status '
      '→ ${response.statusCode}: ${response.body}',
    );

    final decoded = _tryDecode(response.body) ?? {};
    if (response.statusCode == 200 && decoded['success'] == true) {
      final payStatus =
          (decoded['data']?['payment_status'] as String?) ?? 'pending';
      debugPrint('✅ [CheckoutProvider] verifyPaymentStatus → $payStatus');
      return payStatus;
    }

    final msg = decoded['message']?.toString()
        ?? 'Could not verify payment status (HTTP ${response.statusCode}).';
    throw Exception(msg);
  }

  // ────────────────────────── reset ────────────────────────────
  void reset() {
    _addresses = [];
    _selectedAddress = null;
    _paymentMethod = PaymentMethod.cod;
    _isLoading = false;
    _isPlacingOrder = false;
    _isInitiatingPayment = false;
    _paymentUrl = null;
    _billReference = null;
    _billExpiresAt = null;
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
