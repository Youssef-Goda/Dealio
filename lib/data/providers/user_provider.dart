import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:e_commerce/core/constants/base_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;

  String _currentUserId = "";

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String get currentUserId => _currentUserId;

  int _usersComparator(UserModel a, UserModel b) {
    // 1️⃣ Owner دايمًا فوق
    if (a.role.toLowerCase() == 'owner') return -1;
    if (b.role.toLowerCase() == 'owner') return 1;

    if (a.id == _currentUserId) return -1;
    if (b.id == _currentUserId) return 1;
    return b.serialId.compareTo(a.serialId);
  }

  void setCurrentUser(String id) {
    _currentUserId = id;
    _users.sort(_usersComparator);
    notifyListeners();
  }

  // 1. Fetch Users
  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
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
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _users = data.map((u) => UserModel.fromJson(u)).toList();
        _users.sort(_usersComparator);
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
      final response = await http.delete(url);
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
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
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
