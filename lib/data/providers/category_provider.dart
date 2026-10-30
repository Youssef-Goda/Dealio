import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dealio/core/constants/base_url.dart';
import 'package:dealio/data/models/category_model.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _selectedCategoryId; // null = "All"

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get selectedCategoryId => _selectedCategoryId;

  /// Select a category for filtering (null = All).
  void selectCategory(String? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  /// Fetch all categories from GET /categories.
  Future<void> fetchCategories() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('${AppConstants.baseUrl}/categories');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> list;
        // Handle both shapes: plain array OR { data: [...] }
        if (body is List) {
          list = body;
        } else if (body is Map && body['data'] is List) {
          list = body['data'] as List;
        } else if (body is Map && body['categories'] is List) {
          list = body['categories'] as List;
        } else {
          list = [];
        }
        _categories = list
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList();

        debugPrint(
          '✅ CategoryProvider: ${_categories.length} categories fetched.',
        );
      } else {
        debugPrint('⚠️ CategoryProvider: server error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ CategoryProvider: network error $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force re-fetch (e.g. pull-to-refresh).
  Future<void> refresh() async {
    _categories = [];
    await fetchCategories();
  }

  // ── Admin CRUD ───────────────────────────────────────────────────────────────

  /// Creates a new category. Returns null on success, error message on failure.
  Future<String?> createCategory(
    String token,
    String name, {
    String? imageUrl,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/categories');
      final body = <String, dynamic>{'name': name};
      if (imageUrl != null && imageUrl.isNotEmpty) body['iconUrl'] = imageUrl;

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 || decoded['success'] == true) {
        await fetchCategories();
        return null; // success
      }
      return decoded['message']?.toString() ?? 'Failed to create category';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Updates an existing category. Returns null on success, error message on failure.
  Future<String?> updateCategory(
    String token,
    String id,
    String name, {
    String? imageUrl,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/categories/$id');
      final body = <String, dynamic>{'name': name};
      // Always send iconUrl so the backend can clear it too
      body['iconUrl'] = (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null;

      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || decoded['success'] == true) {
        await fetchCategories();
        return null; // success
      }
      return decoded['message']?.toString() ?? 'Failed to update category';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Deletes a category. Returns null on success, error message on failure.
  Future<String?> deleteCategory(String token, String id) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/categories/$id');
      final res = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || decoded['success'] == true) {
        // Remove locally and deselect if it was selected
        _categories.removeWhere((c) => c.id == id);
        if (_selectedCategoryId == id) _selectedCategoryId = null;
        notifyListeners();
        return null; // success
      }
      return decoded['message']?.toString() ?? 'Failed to delete category';
    } catch (e) {
      return 'Network error: $e';
    }
  }
}
