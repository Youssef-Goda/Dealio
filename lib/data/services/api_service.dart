import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealio/core/constants/base_url.dart';

class ApiService {
  static const String _defaultUnauthorizedMessage =
      'Your session has expired. Please log in again.';

  static void Function()? onSessionExpired;

  // ── Single-flight lock for token refresh ───────────────────────────────────
  static Completer<String?>? _refreshCompleter;

  /// Refreshes the access token using the stored refreshToken.
  /// Uses a single-flight lock so multiple simultaneous 401s generate ONLY ONE refresh request.
  static Future<String?> refreshAccessToken() async {
    // If a refresh is already in progress, wait for its result
    if (_refreshCompleter != null) {
      debugPrint('⏳ [ApiService] Refresh already in progress, waiting...');
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    debugPrint('🔄 [ApiService] Initiating token refresh...');

    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentRefreshToken = prefs.getString('refreshToken');

      // Fallback: check stored userData JSON if standalone key is absent
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        final rawUser = prefs.getString('userData');
        if (rawUser != null) {
          final decoded = _tryDecodeJson(rawUser);
          currentRefreshToken = decoded?['refreshToken']?.toString();
        }
      }

      if (currentRefreshToken != null) {
        currentRefreshToken = currentRefreshToken.trim();
      }

      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        debugPrint('❌ [ApiService] No refresh token available in storage.');
        _refreshCompleter!.complete(null);
        _refreshCompleter = null;
        onSessionExpired?.call();
        return null;
      }

      final url = Uri.parse('${AppConstants.baseUrl}/auth/refresh');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': currentRefreshToken}),
      );

      final data = _tryDecodeJson(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data?['success'] == true) {
        final newAccessToken = data?['accessToken']?.toString();
        final newRefreshToken = data?['refreshToken']?.toString();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          debugPrint('✅ [ApiService] Token refresh successful.');

          // Update SharedPreferences standalone keys
          await prefs.setString('accessToken', newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await prefs.setString('refreshToken', newRefreshToken);
          }

          // Update stored userData JSON
          final rawUser = prefs.getString('userData');
          if (rawUser != null) {
            final decoded = _tryDecodeJson(rawUser);
            if (decoded != null) {
              decoded['accessToken'] = newAccessToken;
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                decoded['refreshToken'] = newRefreshToken;
              }
              await prefs.setString('userData', jsonEncode(decoded));
            }
          }

          _refreshCompleter!.complete(newAccessToken);
          _refreshCompleter = null;
          return newAccessToken;
        }
      }

      debugPrint('❌ [ApiService] Token refresh rejected by server (${response.statusCode}): ${response.body}');
      _refreshCompleter!.complete(null);
      _refreshCompleter = null;

      // Clear session on token revocation / expiration
      await prefs.clear();
      onSessionExpired?.call();
      return null;
    } catch (e) {
      debugPrint('❌ [ApiService] Token refresh exception: $e');
      if (!(_refreshCompleter?.isCompleted ?? true)) {
        _refreshCompleter!.complete(null);
      }
      _refreshCompleter = null;
      return null;
    }
  }

  // Helper to check if a response indicates a session error (401/403 or Session expired)
  static bool _isAuthError(http.Response res) {
    if (res.statusCode == 401) return true;
    final data = _tryDecodeJson(res.body);
    final message = data?['message']?.toString();
    return message == 'Session expired' || message == 'Session expired.' || message == 'Invalid token';
  }

  // ── GET (authenticated with auto-refresh retry) ─────────────────────────────
  static Future<http.Response> getRequest(String endpoint, String token) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    var res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.trim()}',
      },
    );

    if (_isAuthError(res) && !endpoint.contains('/auth/refresh')) {
      final newToken = await refreshAccessToken();
      if (newToken != null && newToken.isNotEmpty) {
        res = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${newToken.trim()}',
          },
        );
      }
    }
    return res;
  }

  // ── POST (authenticated with auto-refresh retry) ────────────────────────────
  static Future<http.Response> postAuthRequest(
    String endpoint, Map<String, dynamic> body, String token,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    var res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.trim()}',
      },
      body: jsonEncode(body),
    );

    if (_isAuthError(res) && !endpoint.contains('/auth/refresh')) {
      final newToken = await refreshAccessToken();
      if (newToken != null && newToken.isNotEmpty) {
        res = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${newToken.trim()}',
          },
          body: jsonEncode(body),
        );
      }
    }
    return res;
  }

  // ── PUT (authenticated with auto-refresh retry) ─────────────────────────────
  static Future<http.Response> putRequest(
    String endpoint, Map<String, dynamic> body, String token,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    var res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.trim()}',
      },
      body: jsonEncode(body),
    );

    if (_isAuthError(res) && !endpoint.contains('/auth/refresh')) {
      final newToken = await refreshAccessToken();
      if (newToken != null && newToken.isNotEmpty) {
        res = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${newToken.trim()}',
          },
          body: jsonEncode(body),
        );
      }
    }
    return res;
  }

  // ── PATCH (authenticated with auto-refresh retry) ───────────────────────────
  static Future<http.Response> patchAuthRequest(
    String endpoint, Map<String, dynamic> body, String token,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    var res = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.trim()}',
      },
      body: jsonEncode(body),
    );

    if (_isAuthError(res) && !endpoint.contains('/auth/refresh')) {
      final newToken = await refreshAccessToken();
      if (newToken != null && newToken.isNotEmpty) {
        res = await http.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${newToken.trim()}',
          },
          body: jsonEncode(body),
        );
      }
    }
    return res;
  }

  // ── POST (public) ───────────────────────────────────────────────────────────
  static Future<http.Response> postRequest(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  // ── Upload Image ────────────────────────────────────────────────────────────
  static Future<String?> uploadImage(dynamic imageFile, String token) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/users/profile/picture');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${token.trim()}'
        ..headers['Accept'] = 'application/json';

      if (imageFile is List<int>) {
        request.files.add(http.MultipartFile.fromBytes('image', imageFile, filename: 'upload.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final decoded = _tryDecodeJson(body);

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        return decoded?['data']?['profilePicture']?.toString() ?? 
               decoded?['data']?['url']?.toString() ??
               decoded?['user']?['profilePicture']?.toString();
      }
    } catch (e) {
      debugPrint('⚠️ ApiService uploadImage error: $e');
    }
    return null;
  }

  // ── Fetch user profile ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> fetchProfile(String token) async {
    try {
      final profileEndpoints = ['/users/profile', '/api/users/profile'];
      for (final endpoint in profileEndpoints) {
        final res = await getRequest(endpoint, token);
        final result = processResponse(res);
        if (result['success'] == true) {
          final data = result['data'];
          if (data is Map<String, dynamic>) {
            return (data['user'] as Map<String, dynamic>?) ?? data;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ fetchProfile error: $e');
    }
    return null;
  }

  // ── Response Processing ─────────────────────────────────────────────────────
  static Map<String, dynamic> processResponse(http.Response res) {
    final data = _tryDecodeJson(res.body);
    final rawBody = res.body.trim().toLowerCase();
    
    final isUnauthorized = res.statusCode == 401 || res.statusCode == 403;
    final isForbiddenText = rawBody == 'forbidden' || rawBody.contains('forbidden');
    final isSessionExpired = data?['message'] == 'Session expired';

    if (isUnauthorized || isForbiddenText || isSessionExpired) {
      final authHeader = res.request?.headers['Authorization'];
      
      if (authHeader != null && authHeader.length > 15) { 
        onSessionExpired?.call();
      }

      return {
        'success': false,
        'isForbidden': true,
        'statusCode': res.statusCode,
        'message': data?['message']?.toString() ?? _defaultUnauthorizedMessage,
      };
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {
        'success': true,
        'isForbidden': false,
        'statusCode': res.statusCode,
        'data': data ?? {},
      };
    }

    if (res.statusCode >= 500) {
      return {
        'success': false,
        'isForbidden': false,
        'statusCode': res.statusCode,
        'message': 'Server is currently busy. Please try again shortly.',
      };
    }

    return {
      'success': false,
      'isForbidden': false,
      'statusCode': res.statusCode,
      'message': data?['message']?.toString() ?? 'Error ${res.statusCode}',
    };
  }

  /// Global parser for Network, Timeout, 500, and HTTP exceptions.
  /// Maps raw technical exceptions to user-friendly messages for UI display.
  static String parseErrorMessage(dynamic error, {int? statusCode}) {
    if (statusCode != null && statusCode >= 500) {
      return 'Server is currently busy. Please try again shortly.';
    }

    final String msg = error is Exception
        ? error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')
        : error.toString();

    final lower = msg.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed to fetch') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('xmlhttprequest')) {
      return 'Network connection lost. Please check your internet connection and try again.';
    }

    if (lower.contains('500') || lower.contains('internal server error')) {
      return 'Server is currently busy. Please try again shortly.';
    }

    return msg;
  }

  static Map<String, dynamic>? _tryDecodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}