import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:e_commerce/core/constants/base_url.dart';
import 'package:e_commerce/data/models/category_model.dart';

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
}
