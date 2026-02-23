import 'package:http/http.dart' as http;
import 'package:e_commerce/data/services/api_service.dart';

class AuthRepository {
  
  Map<String, dynamic> _handleRes(http.Response res) => ApiService.processResponse(res);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await ApiService.postRequest('/auth/login', {
      "email": email, 
      "password": password
    });
    return _handleRes(res);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final res = await ApiService.postRequest('/auth/register', userData);
    return _handleRes(res);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp, bool isForPasswordReset) async {
    String endpoint = isForPasswordReset ? "/auth/verify-reset-otp" : "/auth/verify-otp";
    final res = await ApiService.postRequest(endpoint, {
      "email": email, 
      "otp": otp.trim()
    });
    return _handleRes(res);
  }

  Future<Map<String, dynamic>> sendResetCode(String email) async {
    final res = await ApiService.postRequest('/auth/forgot-password', {
      "email": email
    });
    return _handleRes(res);
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    final res = await ApiService.postRequest('/auth/reset-password', {
      "email": email, 
      "otp": otp.trim(), 
      "newPassword": newPassword
    });
    return _handleRes(res);
  }

  Future<Map<String, dynamic>> resendOtp(String userId, String email) async {
  final res = await ApiService.postRequest('/auth/send-otp', {
    "userId": userId,
    "email": email,
  });
  return ApiService.processResponse(res);
}
}