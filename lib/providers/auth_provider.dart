import 'dart:async';

import 'package:e_commerce/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic> get user => _userData ?? {};
  bool get isLoading => _isLoading;
  String _tempEmail = ""; // متغير هيشيل الإيميل في الرام
  String get tempEmail => _tempEmail;
  int _remainingSeconds = 0;
  Timer? _timer;
  String _lastResetEmail = "";

  int get remainingSeconds => _remainingSeconds;
  set tempEmail(String value) {
    _tempEmail = value;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (_isLoggedIn) {
      String? userDataString = prefs.getString('userData');
      if (userDataString != null) _userData = jsonDecode(userDataString);
    }
    notifyListeners();
  }

  Future<void> _saveUserSession(Map<String, dynamic> user) async {
    _userData = user;
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userData', jsonEncode(user));
    if (user['accessToken'] != null) {
      await prefs.setString('token', user['accessToken']);
    }
    notifyListeners();
  }
  Map<String, dynamic> _processResponse(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': res.statusCode >= 500
            ? 'Server side error, please try again later'
            : 'Unexpected error occurred',
      };
    }
  }

  // 2. Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      final result = _processResponse(res);
      if (result['success']) {
        await _saveUserSession(result['data']['user']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      _setLoading(false);
    }
  }

  // 3. Register
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "password": password,
        }),
      );
      final result = _processResponse(res);
      if (result['success']) {
        _userData = {'userId': result['data']['userId'], 'email': email};
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      _setLoading(false);
    }
  }

  // 4. Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": _userData?['userId'],
          "email": _userData?['email'],
          "otp": otp.trim(),
        }),
      );
      final result = _processResponse(res);
      if (result['success']) {
        await _saveUserSession(result['data']['user']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      _setLoading(false);
    }
  }

  // 5. Send forgot password code
  Future<Map<String, dynamic>> sendResetCode(String email) async {
    if (_remainingSeconds > 0 && _lastResetEmail == email) {
      return {
        'success': true,
        'message': 'Code already sent, please wait and try again later.',
      };
    }
    if (_lastResetEmail != email) {
      stopOtpTimer();
    }
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/forgot-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      final result = _processResponse(res);
      if (result['success']) {
        _lastResetEmail = email;
        startOtpTimer();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      _setLoading(false);
    }
  }

  // 6. New Password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/reset-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "newPassword": newPassword,
        }),
      );

      final result = _processResponse(res);

      if (result['success']) {
        await _saveUserSession(result['data']['user']);
        return {'success': true, 'message': 'Password updated successfully'};
      } else {
        return result;
      }
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      _setLoading(false);
    }
  }

  // 7. Resend otp
  Future<Map<String, dynamic>> resendOtp() async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/send-otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": _userData?['userId'],
          "email": _userData?['email'],
        }),
      );
      return _processResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      _setLoading(false);
    }
  }

  void startOtpTimer() {
    if (_timer?.isActive ?? false) return;
    _timer?.cancel();
    _remainingSeconds = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopOtpTimer();
      }
    });
  }

  void stopOtpTimer() {
    _timer?.cancel();
    _remainingSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 8. Logout
  Future<void> logout() async {
    _userData = null;
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
