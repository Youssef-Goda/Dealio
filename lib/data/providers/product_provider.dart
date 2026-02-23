import 'dart:convert';
import 'package:e_commerce/core/constants/base_url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:e_commerce/data/models/product_model.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  /// 1. Fetch Products
  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

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

  /// 2. Add Product
  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required List<String> imageUrls,
    double? oldPrice,
    double rating = 0.0,
    int countInStock = 0,
  }) async {
    final url = Uri.parse("${AppConstants.baseUrl}/products/add");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": name,
          "description": description,
          "price": price,
          "imageUrls": imageUrls,
          "oldPrice": oldPrice,
          "rating": rating,
          "countInStock": countInStock,
        }),
      );

      if (response.statusCode == 201) {
        await fetchProducts();
        return true;
      } else {
        debugPrint("❌ Server Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Add Product Error: $e");
    }
    return false;
  }

  /// 3. Update Product (supports multiple images)
  Future<bool> updateProduct(Product product) async {
    final url = Uri.parse("${AppConstants.baseUrl}/products/${product.id}");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": product.name,
          "description": product.description,
          "price": product.price,
          "imageUrls": product.imageUrls,
          "oldPrice": product.oldPrice,
          "rating": product.rating,
          "countInStock": product.countInStock,
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
        debugPrint("❌ Server Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Update Error: $e");
    }
    return false;
  }

  /// 4. Delete Product
  Future<bool> deleteProduct(String id) async {
    final url = Uri.parse("${AppConstants.baseUrl}/products/$id");

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        _products.removeWhere((p) => p.id.toString() == id.toString());
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
