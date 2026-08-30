import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dealio/core/constants/base_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// Owner email — same constant used across dialogs and table display
const String _kOwnerEmail = 'youssefgoda.dev@gmail.com';

bool _isOwnerUser(UserModel u) =>
    u.email.toLowerCase() == _kOwnerEmail || u.role.toLowerCase() == 'owner';

class UserProvider with ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;
  final List<String> _selectedUserIds = [];

  String _currentUserId = "";

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String get currentUserId => _currentUserId;
  List<String> get selectedUserIds => _selectedUserIds;

  bool get isAllSelected =>
      _users.isNotEmpty && _selectedUserIds.length == _users.length;

  void toggleUserSelection(String id) {
    if (_selectedUserIds.contains(id)) {
      _selectedUserIds.remove(id);
    } else {
      _selectedUserIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAll() {
    if (isAllSelected) {
      _selectedUserIds.clear();
    } else {
      _selectedUserIds.clear();
      _selectedUserIds.addAll(_users.map((u) => u.id));
    }
    notifyListeners();
  }

  int _usersComparator(UserModel a, UserModel b) {
    // 1. Owner always first (by email OR DB role)
    final aIsOwner = _isOwnerUser(a);
    final bIsOwner = _isOwnerUser(b);
    if (aIsOwner && !bIsOwner) return -1;
    if (!aIsOwner && bIsOwner) return 1;

    // 2. Current logged-in user second
    if (a.id == _currentUserId) return -1;
    if (b.id == _currentUserId) return 1;

    // 3. Most recently registered first
    return b.serialId.compareTo(a.serialId);
  }

  void setCurrentUser(String id) {
    _currentUserId = id;
    _users.sort(_usersComparator);
    notifyListeners();
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    if (token == null || token.isEmpty) {
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        token = userData['accessToken']?.toString();
      }
    }
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Fetch Users
  Future<void> fetchUsers() async {
    // Only show skeleton on first/empty load — refresh keeps data visible.
    final bool isInitialLoad = _users.isEmpty;
    if (isInitialLoad) {
      _isLoading = true;
      notifyListeners();
    }
    _selectedUserIds.clear();

    if (_currentUserId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        _currentUserId = (userData['userId'] ?? userData['id'] ?? "")
            .toString();
      }
    }

    final url = Uri.parse("${AppConstants.baseUrl}/users");
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        url,
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _users = data.map((u) => UserModel.fromJson(u)).toList();
        _users.sort(_usersComparator);
      } else {
        debugPrint("⚠️ Fetch Error: status code ${response.statusCode}, body: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Fetch Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Delete User
  Future<bool> deleteUser(String id) async {
    final url = Uri.parse("${AppConstants.baseUrl}/users/$id");
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        // Delete from memory
        _users.removeWhere((user) => user.id == id);
        _users.sort(_usersComparator);

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("⚠️ Delete Error: $e");
    }
    return false;
  }

  // 3. Update User Role
  Future<void> updateUserRole(String id, String newRole) async {
    final url = Uri.parse("${AppConstants.baseUrl}/users/update-role/$id");
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({'role': newRole}),
      );
      if (response.statusCode == 200) {
        // Update in memory
        int index = _users.indexWhere((u) => u.id == id);
        if (index != -1) {
          _users[index].role = newRole;
          _users.sort(_usersComparator);

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("⚠️ Role Update Error: $e");
    }
  }

  // 4. Toggle User Status
  Future<void> toggleUserStatus(String id, bool currentStatus) async {
    final url = Uri.parse("${AppConstants.baseUrl}/users/toggle-status/$id");
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({'isActive': !currentStatus}),
      );

      if (response.statusCode == 200) {
        int index = _users.indexWhere((u) => u.id == id);
        if (index != -1) {
          _users[index].isActive = !currentStatus;
          _users.sort(_usersComparator);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("⚠️ Status Toggle Error: $e");
    }
  }
}
