import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerce/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic> get user => _userData ?? {};
  bool get isLoading => _isLoading;
  String _tempEmail = "";
  String get tempEmail => _tempEmail;
  int _remainingSeconds = 0;
  Timer? _timer;
  String _lastResetEmail = "";

  int get remainingSeconds => _remainingSeconds;

  final AuthRepository _authRepo = AuthRepository();

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

  // 2. Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    setLoading(true);
    try {
      final result = await _authRepo.login(email, password);
      if (result['success']) {
        await _saveUserSession(result['data']['user']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  // 3. Register
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    setLoading(true);
    try {
      final result = await _authRepo.register({
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "password": password,
      });

      if (result['success']) {
        if (result['data']['user'] != null) {
          await _saveUserSession(result['data']['user']);
        } else {
          await _saveUserSession({
            'userId': result['data']['userId'],
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
          });
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  // 4. verify otp
  Future<Map<String, dynamic>> verifyOtp({
    required String otp,
    required String email,
    bool isForPasswordReset = false,
  }) async {
    setLoading(true);
    try {
      final result = await _authRepo.verifyOtp(email, otp, isForPasswordReset);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
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
    setLoading(true);
    try {
      final result = await _authRepo.sendResetCode(email);
      if (result['success']) {
        _lastResetEmail = email;
        _userData = {'userId': result['data']['userId'], 'email': email};
        startOtpTimer();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  // 6. Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    setLoading(true);
    try {
      final result = await _authRepo.resetPassword(email, otp, newPassword);
      if (result['success']) {
        if (result['data'] != null && result['data']['user'] != null) {
          await _saveUserSession(result['data']['user']);
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  // 7. Resend otp
  Future<Map<String, dynamic>> resendOtp() async {
    setLoading(true);
    try {
      final result = await _authRepo.resendOtp(
        _userData?['userId'] ?? '',
        _userData?['email'] ?? '',
      );
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
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

  // 8. Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    setLoading(true);
    try {
      debugPrint("🔵 Starting Google Sign-in...");

      // const String redirectUrl = kIsWeb
      //     ? 'http://localhost:5555/'
      //     : 'io.supabase.dealio://login-callback/';
      const String redirectUrl = 'io.supabase.dealio://login-callback/';

      // 1. تشغيل عملية الدخول
      final bool success = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        queryParams: {'prompt': 'select_account'},
        redirectTo: redirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );

      if (success) {
        return {'success': true, 'message': 'Redirecting to Google...'};
      } else {
        return {'success': false, 'message': 'Google Sign-in failed to launch'};
      }
    } catch (e) {
      debugPrint("❌ Google Sign-in Error: $e");
      return {'success': false, 'message': e.toString()};
    } finally {
      setLoading(false);
    }
  }

  void handleGoogleSuccess(Session session) async {
    final user = session.user;
    final String fullName = user.userMetadata?['full_name'] ?? 'Google User';

    final List<String> nameParts = fullName.split(' ');
    final String firstName = nameParts.isNotEmpty ? nameParts[0] : '          ';
    final String lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';

    final userData = {
      'userId': user.id,
      'email': user.email,
      'firstName': firstName,
      'lastName': lastName,
      'accessToken': session.accessToken,
    };

    try {
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'firstName': firstName,
        'lastName': lastName,
        'role': 'user',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _saveUserSession(userData);
      debugPrint("✅ Google User Synced correctly with firstName/lastName");
    } catch (e) {
      debugPrint("❌ Error syncing google user: $e");
    }

    notifyListeners();
  }

  // 9. Logout
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      _userData = null;
      _isLoggedIn = false;
      _tempEmail = "";
      _lastResetEmail = "";

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      stopOtpTimer();

      debugPrint(
        "✅ User logged out successfully from Supabase and Local Storage",
      );
    } catch (e) {
      debugPrint("❌ Error during logout: $e");
    }

    notifyListeners();
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
