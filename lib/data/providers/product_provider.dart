// import 'dart:convert';
// import 'package:e_commerce/core/constants/base_url.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:e_commerce/data/models/product_model.dart';

// class ProductProvider with ChangeNotifier {
//   List<Product> _products = [];
//   bool _isLoading = false;

//   List<Product> get products => _products;
//   bool get isLoading => _isLoading;

//   /// 1. Fetch Products
//   Future<void> fetchProducts() async {
//     _isLoading = true;
//     notifyListeners();

//     final url = Uri.parse("${AppConstants.baseUrl}/products/all");

//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         _products = data.map((item) => Product.fromJson(item)).toList();
//         _products.sort((a, b) => b.serialId.compareTo(a.serialId));
//         debugPrint(" ${_products.length} has been fetched successfully ✅");
//       } else {
//         debugPrint("❌ Server Error: ${response.statusCode} - ${response.body}");
//       }
//     } catch (error) {
//       debugPrint("⚠️ Network Error: $error");
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// 2. Add Product
//   Future<bool> addProduct({
//     required String name,
//     required String description,
//     required double price,
//     required List<String> imageUrls,
//     double? oldPrice,
//     double rating = 0.0,
//     int countInStock = 0,
//   }) async {
//     final url = Uri.parse("${AppConstants.baseUrl}/products/add");

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({
//           "name": name,
//           "description": description,
//           "price": price,
//           "imageUrls": imageUrls,
//           "oldPrice": oldPrice,
//           "rating": rating,
//           "countInStock": countInStock,
//         }),
//       );

//       if (response.statusCode == 201) {
//         await fetchProducts();
//         return true;
//       } else {
//         debugPrint("❌ Server Error: ${response.body}");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Add Product Error: $e");
//     }
//     return false;
//   }

//   /// 3. Update Product (supports multiple images)
//   Future<bool> updateProduct(Product product) async {
//     final url = Uri.parse("${AppConstants.baseUrl}/products/${product.id}");

//     try {
//       final response = await http.put(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({
//           "name": product.name,
//           "description": product.description,
//           "price": product.price,
//           "imageUrls": product.imageUrls,
//           "oldPrice": product.oldPrice,
//           "rating": product.rating,
//           "countInStock": product.countInStock,
//         }),
//       );

//       if (response.statusCode == 200) {
//         int index = _products.indexWhere(
//           (p) => p.id.toString() == product.id.toString(),
//         );
//         if (index != -1) {
//           _products[index] = product;
//           notifyListeners();
//         }
//         return true;
//       } else {
//         debugPrint("❌ Server Error: ${response.body}");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Update Error: $e");
//     }
//     return false;
//   }

//   /// 4. Delete Product
//   Future<bool> deleteProduct(String id) async {
//     final url = Uri.parse("${AppConstants.baseUrl}/products/$id");

//     try {
//       final response = await http.delete(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           "Accept": "application/json",
//         },
//       );

//       if (response.statusCode == 200) {
//         _products.removeWhere((p) => p.id.toString() == id.toString());
//         notifyListeners();
//         return true;
//       } else {
//         debugPrint("❌ Delete Error: ${response.statusCode} - ${response.body}");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Delete Error: $e");
//     }
//     return false;
//   }
// }

import 'dart:convert';
import 'package:e_commerce/core/constants/base_url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:e_commerce/data/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;

  // القائمة اللي هنخزن فيها الـ IDs بتاعة المنتجات المختارة
  final List<String> _selectedProductIds = [];

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  List<String> get selectedProductIds => _selectedProductIds;

  // دالة مساعدة للهيدر: هل كل المنتجات اللي معروضة دلوقتي مختارة؟
  bool get isAllSelected =>
      _products.isNotEmpty && _selectedProductIds.length == _products.length;

  // --- [1. Selection Logic] ---

  // تحديد أو إلغاء تحديد منتج واحد
  void toggleProductSelection(String id) {
    if (_selectedProductIds.contains(id)) {
      _selectedProductIds.remove(id);
    } else {
      _selectedProductIds.add(id);
    }
    notifyListeners();
  }

  // تحديد الكل / إلغاء الكل
  void toggleSelectAll() {
    if (isAllSelected) {
      _selectedProductIds.clear();
    } else {
      _selectedProductIds.clear();
      _selectedProductIds.addAll(_products.map((p) => p.id.toString()));
    }
    notifyListeners();
  }

  // --- [2. API Calls] ---

  /// Fetch Products
  Future<void> fetchProducts() async {
    // Only show the skeleton loader on first/empty load.
    // On a refresh when data already exists, keep showing the data silently.
    final bool isInitialLoad = _products.isEmpty;
    if (isInitialLoad) {
      _isLoading = true;
      notifyListeners();
    }
    _selectedProductIds.clear();

    final url = Uri.parse("${AppConstants.baseUrl}/products/all");

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _products = data.map((item) => Product.fromJson(item)).toList();
        _products.sort((a, b) => b.serialId.compareTo(a.serialId));
        debugPrint(" ${_products.length} has been fetched successfully ✅");
      } else {
        debugPrint("❌ Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (error) {
      debugPrint("⚠️ Network Error: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add Product
  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required List<String> imageUrls,
    double? oldPrice,
    double rating = 0.0,
    int countInStock = 0,
    String? categoryId,
  }) async {
    final url = Uri.parse("${AppConstants.baseUrl}/products/add");

    try {
      // ── Read auth token ──────────────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? prefs.getString('token') ?? '';

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: json.encode({
          "name": name,
          "description": description,
          "price": price,
          "imageUrls": imageUrls,
          "oldPrice": oldPrice,
          "rating": rating,
          "countInStock": countInStock,
          if (categoryId != null && categoryId.isNotEmpty)
            "categoryId": categoryId,
        }),
      );

      if (response.statusCode == 201) {
        await fetchProducts();
        return true;
      } else {
        debugPrint("❌ Server Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Add Product Error: $e");
    }
    return false;
  }

  /// Update Product
  Future<bool> updateProduct(Product product) async {
    final url = Uri.parse("${AppConstants.baseUrl}/products/${product.id}");

    try {
      // ── Read auth token ──────────────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? prefs.getString('token') ?? '';

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: json.encode({
          "name": product.name,
          "description": product.description,
          "price": product.price,
          "imageUrls": product.imageUrls,
          "oldPrice": product.oldPrice,
          "rating": product.rating,
          "countInStock": product.countInStock,
          if (product.categoryId != null && product.categoryId!.isNotEmpty)
            "categoryId": product.categoryId,
        }),
      );

      if (response.statusCode == 200) {
        int index = _products.indexWhere(
          (p) => p.id.toString() == product.id.toString(),
        );
        if (index != -1) {
          _products[index] = product;
          notifyListeners();
        }
        return true;
      } else {
        debugPrint("❌ Server Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Update Error: $e");
    }
    return false;
  }

  /// Delete Product
  Future<bool> deleteProduct(String id) async {
    final url = Uri.parse("${AppConstants.baseUrl}/products/$id");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? prefs.getString('token') ?? '';

      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        _products.removeWhere((p) => p.id.toString() == id.toString());
        _selectedProductIds.remove(
          id.toString(),
        ); // شيله من الاختيارات لو اتمسح
        notifyListeners();
        return true;
      } else {
        debugPrint("❌ Delete Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Delete Error: $e");
    }
    return false;
  }
}
