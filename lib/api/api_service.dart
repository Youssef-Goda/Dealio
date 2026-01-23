import 'dart:convert';
import 'package:e_commerce/models/base_url.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = ApiConfig.baseUrl;

  static Future<http.Response> login(String email, String password) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<http.Response> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<http.Response> verifyOtp(String email, String otp) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
  }

  static Future<bool> checkAvailability(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/check-availability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'value': email}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isTaken'] ?? false;
      }
      return false;
    } catch (e) {
      // print("Error in checkAvailability: $e");
      return false;
    }
  }

  static Future<http.Response> forgotPassword(String email) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
  }

  static Future<http.Response> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );
  }
}
