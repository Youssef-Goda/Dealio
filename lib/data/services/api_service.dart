import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealio/core/constants/base_url.dart';

class ApiService {
  static const String _defaultUnauthorizedMessage =
      'Your session has expired. Please log in again.';

  static bool Function(String expiredAccessToken)? onSessionExpired;
  static void Function(
    String previousRefreshToken,
    String accessToken,
    String refreshToken,
  )?
  onTokensRefreshed;

  // ── Single-flight lock for token refresh ───────────────────────────────────
  static Completer<String?>? _refreshCompleter;
  static String? _refreshingAccessToken;

  /// Refreshes the access token using the stored refreshToken.
  /// Uses a single-flight lock so multiple simultaneous 401s generate ONLY ONE refresh request.
  static Future<String?> refreshAccessToken({
    required String failedAccessToken,
  }) async {
    // If a refresh is already in progress, wait for its result
    if (_refreshCompleter != null) {
      if (_refreshingAccessToken != failedAccessToken.trim()) return null;
      return await _refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;
    _refreshingAccessToken = failedAccessToken.trim();
    debugPrint('🔄 [ApiService] Initiating token refresh...');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final expectedAccessToken = failedAccessToken.trim();
      if (!_sessionStillUsesAccessToken(prefs, expectedAccessToken)) {
        return _finishRefresh(completer, null);
      }

      final currentRefreshToken = _readStoredRefreshToken(prefs);

      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        debugPrint('❌ [ApiService] No refresh token available in storage.');
        return _expireSessionIfCurrent(
          prefs,
          completer,
          expectedAccessToken,
          currentRefreshToken,
        );
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

        if (newAccessToken != null &&
            newAccessToken.isNotEmpty &&
            newRefreshToken != null &&
            newRefreshToken.isNotEmpty) {
          debugPrint('✅ [ApiService] Token refresh successful.');

          // A user may log out or switch accounts while this request is in
          // flight (possibly in another browser tab). Reload SharedPreferences
          // so the comparison sees the current origin-scoped localStorage.
          await prefs.reload();
          if (!_sessionStillUsesRefreshToken(
            prefs,
            expectedAccessToken,
            currentRefreshToken,
          )) {
            return _finishRefresh(completer, null);
          }

          // Start the preference writes together, without yielding between
          // checking the session and scheduling writes on this app isolate.
          final writes = <Future<bool>>[
            prefs.setString('accessToken', newAccessToken),
            prefs.setString('refreshToken', newRefreshToken),
          ];
          final rawUser = prefs.getString('userData');
          if (rawUser != null) {
            final decoded = _tryDecodeJson(rawUser);
            if (decoded != null) {
              decoded['accessToken'] = newAccessToken;
              decoded['refreshToken'] = newRefreshToken;
              writes.add(prefs.setString('userData', jsonEncode(decoded)));
            }
          }
          await Future.wait(writes);

          onTokensRefreshed?.call(
            currentRefreshToken,
            newAccessToken,
            newRefreshToken,
          );

          return _finishRefresh(completer, newAccessToken);
        }
      }

      debugPrint(
        '❌ [ApiService] Token refresh rejected by server (${response.statusCode}): ${response.body}',
      );
      // A server outage or a missing refresh endpoint is not proof that this
      // refresh token was revoked. Retain the local session unless the server
      // explicitly rejects it; this avoids turning transient failures into Guest.
      if (response.statusCode != 401 && response.statusCode != 403) {
        return _finishRefresh(completer, null);
      }

      // A rejection for an older in-flight session must never clear a newer
      // account's credentials or invoke the global logout handler. Reload to
      // observe changes made by another tab before deciding whether to expire.
      await prefs.reload();
      if (!_sessionStillUsesRefreshToken(
        prefs,
        expectedAccessToken,
        currentRefreshToken,
      )) {
        return _finishRefresh(completer, null);
      }

      return _expireSessionIfCurrent(
        prefs,
        completer,
        expectedAccessToken,
        currentRefreshToken,
      );
    } catch (e) {
      debugPrint('❌ [ApiService] Token refresh exception: $e');
      return _finishRefresh(completer, null);
    }
  }

  static bool _sessionStillUsesAccessToken(
    SharedPreferences prefs,
    String expectedAccessToken,
  ) {
    if (expectedAccessToken.isEmpty || prefs.getBool('isLoggedIn') != true) {
      return false;
    }
    final standalone = prefs.getString('accessToken')?.trim();
    if (standalone != null &&
        standalone.isNotEmpty &&
        standalone != expectedAccessToken) {
      return false;
    }
    final rawUser = prefs.getString('userData');
    final decoded = rawUser == null ? null : _tryDecodeJson(rawUser);
    final embedded = decoded?['accessToken']?.toString().trim();
    if (embedded != null &&
        embedded.isNotEmpty &&
        embedded != expectedAccessToken) {
      return false;
    }
    return standalone == expectedAccessToken || embedded == expectedAccessToken;
  }

  static String? _readStoredRefreshToken(SharedPreferences prefs) {
    final standalone = prefs.getString('refreshToken')?.trim();
    if (standalone != null && standalone.isNotEmpty) return standalone;

    final rawUser = prefs.getString('userData');
    final decoded = rawUser == null ? null : _tryDecodeJson(rawUser);
    final embedded = decoded?['refreshToken']?.toString().trim();
    return embedded == null || embedded.isEmpty ? null : embedded;
  }

  static bool _sessionStillUsesRefreshToken(
    SharedPreferences prefs,
    String expectedAccessToken,
    String expectedRefreshToken,
  ) {
    if (!_sessionStillUsesAccessToken(prefs, expectedAccessToken)) return false;

    final standalone = prefs.getString('refreshToken')?.trim();
    if (standalone != null &&
        standalone.isNotEmpty &&
        standalone != expectedRefreshToken) {
      return false;
    }

    final rawUser = prefs.getString('userData');
    final decoded = rawUser == null ? null : _tryDecodeJson(rawUser);
    final embedded = decoded?['refreshToken']?.toString().trim();
    if (embedded != null &&
        embedded.isNotEmpty &&
        embedded != expectedRefreshToken) {
      return false;
    }

    // At least one of the two existing storage locations must still identify
    // the session that initiated refresh.
    return standalone == expectedRefreshToken ||
        embedded == expectedRefreshToken;
  }

  static Future<String?> _expireSessionIfCurrent(
    SharedPreferences prefs,
    Completer<String?> completer,
    String expectedAccessToken,
    String? expectedRefreshToken,
  ) async {
    await prefs.reload();
    if (!_sessionStillUsesAccessToken(prefs, expectedAccessToken) ||
        (expectedRefreshToken != null &&
            !_sessionStillUsesRefreshToken(
              prefs,
              expectedAccessToken,
              expectedRefreshToken,
            ))) {
      return _finishRefresh(completer, null);
    }

    // The AuthProvider can detect an account switch that has reached memory
    // but has not finished persisting yet. Let it confirm ownership before
    // deleting any stored credentials.
    final canExpire = onSessionExpired?.call(expectedAccessToken);
    if (onSessionExpired != null && canExpire != true) {
      return _finishRefresh(completer, null);
    }

    // Schedule the related removals together so an account change cannot be
    // interleaved between clearing individual auth keys on this app isolate.
    final removals = <Future<bool>>[
      prefs.remove('accessToken'),
      prefs.remove('refreshToken'),
      prefs.remove('userData'),
      prefs.setBool('isLoggedIn', false),
    ];
    await Future.wait(removals);
    return _finishRefresh(completer, null);
  }

  static String? _finishRefresh(Completer<String?> completer, String? result) {
    if (!completer.isCompleted) completer.complete(result);
    if (identical(_refreshCompleter, completer)) {
      _refreshCompleter = null;
      _refreshingAccessToken = null;
    }
    return result;
  }

  // Only 401 responses trigger refresh. A response body must not turn a 403
  // authorization denial into an authentication failure.
  static bool _isAuthError(http.Response res) {
    return res.statusCode == 401;
  }

  static Future<bool> _isActiveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return _sessionStillUsesAccessToken(prefs, token);
  }

  static Future<http.Response> _sendWithSessionRefresh(
    String endpoint,
    String token,
    Future<http.Response> Function(String token) send,
  ) async {
    final originalResponse = await send(token.trim());
    if (!_isAuthError(originalResponse) || endpoint.contains('/auth/refresh')) {
      return originalResponse;
    }

    final refreshedToken = await refreshAccessToken(
      failedAccessToken: token.trim(),
    );
    if (refreshedToken == null ||
        refreshedToken.isEmpty ||
        !await _isActiveAccessToken(refreshedToken)) {
      return originalResponse;
    }

    // Retry exactly once and only with the refreshed token from the same
    // still-active session that sent the original request.
    return send(refreshedToken.trim());
  }

  // ── GET (authenticated with auto-refresh retry) ─────────────────────────────
  static Future<http.Response> getRequest(String endpoint, String token) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return _sendWithSessionRefresh(endpoint, token, (requestToken) {
      return http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $requestToken',
        },
      );
    });
  }

  // ── POST (authenticated with auto-refresh retry) ────────────────────────────
  static Future<http.Response> postAuthRequest(
    String endpoint,
    Map<String, dynamic> body,
    String token,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return _sendWithSessionRefresh(endpoint, token, (requestToken) {
      return http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $requestToken',
        },
        body: jsonEncode(body),
      );
    });
  }

  // ── PUT (authenticated with auto-refresh retry) ─────────────────────────────
  static Future<http.Response> putRequest(
    String endpoint,
    Map<String, dynamic> body,
    String token,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return _sendWithSessionRefresh(endpoint, token, (requestToken) {
      return http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $requestToken',
        },
        body: jsonEncode(body),
      );
    });
  }

  // ── PATCH (authenticated with auto-refresh retry) ───────────────────────────
  static Future<http.Response> patchAuthRequest(
    String endpoint,
    Map<String, dynamic> body,
    String token,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return _sendWithSessionRefresh(endpoint, token, (requestToken) {
      return http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $requestToken',
        },
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> deleteAuthRequest(
    String endpoint,
    String token,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return _sendWithSessionRefresh(endpoint, token, (requestToken) {
      return http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $requestToken',
        },
      );
    });
  }

  // ── POST (public) ───────────────────────────────────────────────────────────
  static Future<http.Response> postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
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
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageFile,
            filename: 'upload.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
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

    final isUnauthorized = res.statusCode == 401;
    final isForbiddenText =
        rawBody == 'forbidden' || rawBody.contains('forbidden');
    final isSessionExpired = data?['message'] == 'Session expired';

    if (isUnauthorized || isForbiddenText || isSessionExpired) {
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
