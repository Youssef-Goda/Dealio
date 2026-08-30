import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealio/core/constants/base_url.dart';
import 'package:dealio/data/repositories/auth_repository.dart';
import 'package:dealio/data/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dealio/data/providers/profile_provider.dart';

class AuthProvider with ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  String? get token        => _userData?['accessToken']?.toString();
  String? get refreshToken => _userData?['refreshToken']?.toString();
  bool get isLoggedIn      => _isLoggedIn;
  bool get isInitialized   => _isInitialized;
  Map<String, dynamic> get user => _userData ?? {};
  bool get isLoading     => _isLoading;

  /// The authenticated user's id — used by PermissionGuard for ownership checks.
  String get userId =>
      (_userData?['userId']  ??
       _userData?['id']      ??
       _userData?['user_id'] ?? '').toString();

  /// Role is always lower-case and non-null. Falls back to 'customer'.
  String get userRole =>
      _userData?['role']?.toString().toLowerCase().trim() ?? 'customer';

  // ── Role helpers (match AppRoles 5-role system) ───────────────────────────
  bool get isOwner     => userRole == 'owner';
  bool get isAdmin     => userRole == 'owner' || userRole == 'admin';
  bool get isModerator => isAdmin || userRole == 'moderator';
  bool get isVendor    => userRole == 'vendor';
  bool get isCustomer  => userRole == 'customer' || userRole == 'user';

  /// True for admin OR owner — backwards-compatible alias used by existing widgets.
  bool get isPrivileged => isAdmin;

  /// Legacy alias kept for any widgets still calling isSuperAdmin.
  bool get isSuperAdmin => isOwner;

  // ── OTP Timer ──────────────────────────────────────────────────────────────
  String _tempEmail = '';
  String get tempEmail => _tempEmail;
  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;
  Timer? _timer;
  String _lastResetEmail = '';

  set tempEmail(String value) {
    _tempEmail = value;
    notifyListeners();
  }

  final AuthRepository _authRepo = AuthRepository();

  static String _truncate(String? s, [int max = 40]) {
    if (s == null) return 'null';
    return s.length <= max ? s : '${s.substring(0, max)}…';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════

  /// Restores session from SharedPreferences (Phase 1 — synchronous, no network)
  /// then kicks off a silent background sync (Phase 2 — network, fire-and-forget).
  ///
  /// Called from main.dart when there is NO active Supabase session.
  // Future<void> loadUserData() async {
  //   debugPrint('🔄 [Auth] loadUserData START');
  //   final prefs = await SharedPreferences.getInstance();

  //   // ── Phase 1: Restore from disk immediately ──────────────────────────────
  //   // This is the most critical step — prevents the "Guest" flicker on restart.
  //   final String? raw = prefs.getString('userData');
  //   final bool wasLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  //   if (wasLoggedIn && raw != null) {
  //     try {
  //       final decoded = jsonDecode(raw);
  //       if (decoded is Map<String, dynamic>) {
  //         _userData = decoded;
  //         _isLoggedIn = true;
  //         debugPrint(
  //           '✅ [Auth] Restored from prefs — role: $userRole | '
  //           'name: ${_userData?['firstName']} | '
  //           'token: ${_truncate(token)}',
  //         );
  //       } else {
  //         // Corrupt data — clean slate
  //         await _clearPrefsKeys(prefs);
  //       }
  //     } catch (e) {
  //       debugPrint('❌ [Auth] Prefs parse error: $e — clearing session');
  //       await _clearPrefsKeys(prefs);
  //     }
  //   }

  //   // Signal the UI: initialization is done — route based on what we have.
  //   _isInitialized = true;
  //   notifyListeners();

  //   // ── Phase 2: Silent background sync (never blocks the UI) ───────────────
  //   if (_isLoggedIn) {
  //     final t = token;
  //     if (t != null && t.isNotEmpty) {
  //       _syncProfileFromServer(t); // fire-and-forget
  //     }
  //   }

  //   debugPrint(
  //     '🏁 [Auth] loadUserData END — isLoggedIn: $_isLoggedIn | role: $userRole',
  //   );
  // }

  /// Handles a live Supabase session (Google OAuth callback OR cold-start
  /// with an existing Supabase session). Always awaitable.
  ///
  /// Key guarantee: the ACTUAL role from the `users` DB table is fetched and
  /// stored. The default 'user' role in the upsert payload is only applied
  /// when the row does NOT yet exist (ignoreDuplicates: true prevents
  /// overwriting an existing admin row).
  Future<void> handleGoogleSuccess(
    Session session, {
    ProfileProvider? profileProvider,
  }) async {
    final supaUser = session.user;
    debugPrint('🔵 [Auth] handleGoogleSuccess — ${supaUser.email}');

    try {
      // Extract display name from OAuth metadata
      final String fullName =
          supaUser.userMetadata?['full_name']?.toString().trim() ?? '';
      final List<String> parts = fullName.split(' ');
      final String metaFirst = parts.isNotEmpty ? parts[0] : '';
      final String metaLast =
          parts.length > 1 ? parts.sublist(1).join(' ') : '';

      // Upsert: creates a new row for first-time Google users.
      // ignoreDuplicates: true means existing rows (including admin role) are
      // NEVER overwritten here.
      await Supabase.instance.client.from('users').upsert({
        'id': supaUser.id,
        'email': supaUser.email,
        'firstName': metaFirst,
        'lastName': metaLast,
        'role': 'user', // only applied on INSERT — ignored on conflict
        'createdAt': DateTime.now().toIso8601String(),
      }, ignoreDuplicates: true);

      // CRITICAL: Fetch the actual DB row to get the real role and profile.
      final row = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', supaUser.id)
          .maybeSingle();

      final Map<String, dynamic> db = row ?? {};

      // Prefer DB values; fall back to OAuth metadata for name fields.
      final Map<String, dynamic> userData = {
        'userId': supaUser.id,
        'email': supaUser.email ?? db['email'],
        'firstName': (db['firstName']?.toString().isNotEmpty == true)
            ? db['firstName']
            : metaFirst,
        'lastName': (db['lastName']?.toString().isNotEmpty == true)
            ? db['lastName']
            : metaLast,
        'role': db['role']?.toString() ?? 'user',
        'phoneNumber': db['phoneNumber'],
        'profilePicture': db['profilePicture'],
        'birthDate': db['birthDate'],
        'gender': db['gender'],
        'accessToken': session.accessToken,
      };

      await _saveUserSession(userData);

      if (profileProvider != null) {
        profileProvider.loadFromUser(_userData ?? userData);
      }

      debugPrint(
        '✅ [Auth] Google user synced — role: ${userData['role']}',
      );

      // Background tasks
      final authToken = _userData?['accessToken']?.toString() ?? '';
      if (authToken.isNotEmpty) {
        _syncFcmToken(authToken); // fire-and-forget
      }
    } catch (e) {
      debugPrint('❌ [Auth] handleGoogleSuccess error: $e');
      // Fallback: save minimal data so the app is still usable
      await _saveUserSession({
        'userId': supaUser.id,
        'email': supaUser.email,
        'role': 'user',
        'accessToken': session.accessToken,
      });
    }

    // Always mark initialized — even on error
    _isInitialized = true;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SESSION PERSISTENCE — Single Source of Truth
  // ══════════════════════════════════════════════════════════════════════════

  /// Persists a **flat** user map to memory + SharedPreferences.
  ///
  /// Handles two response shapes:
  ///   - Flat:   `{ id, firstName, role, accessToken, ... }`
  ///   - Nested: `{ success, accessToken, user: { id, firstName, role, ... } }`
  Future<void> _saveUserSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Flatten nested 'user' key if present
    final Map<String, dynamic> userInfo =
        (data['user'] is Map<String, dynamic>)
            ? data['user'] as Map<String, dynamic>
            : Map<String, dynamic>.from(data);

    // Token can live at the top level or inside 'user'
    final String? accessToken =
        data['accessToken']?.toString() ??
        userInfo['accessToken']?.toString();
    final String? refreshTokenVal =
        data['refreshToken']?.toString() ??
        userInfo['refreshToken']?.toString();

    // Build the canonical flat map
    _userData = {
      ...userInfo,
      if (accessToken != null && accessToken.isNotEmpty)
        'accessToken': accessToken,
      if (refreshTokenVal != null && refreshTokenVal.isNotEmpty)
        'refreshToken': refreshTokenVal,
    };
    // Ensure no nested 'user' key leaks into the stored map
    _userData!.remove('user');

    _isLoggedIn = true;

    // Persist
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userData', jsonEncode(_userData));
    if (accessToken != null && accessToken.isNotEmpty) {
      await prefs.setString('accessToken', accessToken);
    }
    if (refreshTokenVal != null && refreshTokenVal.isNotEmpty) {
      await prefs.setString('refreshToken', refreshTokenVal);
    }

    debugPrint(
      '💾 [Auth] Session saved — role: $userRole | '
      'name: ${_userData?['firstName']} | '
      'token: ${_truncate(accessToken)}',
    );
  }

  /// Merges [updatedFields] into the existing session.
  /// The access token is NEVER overwritten unless explicitly included.
//  Future<void> updateUserData(Map<String, dynamic> updatedFields) async {
//     if (_userData == null) return;
    
//     // الاحتفاظ بالتوكن القديم عشان ميتمسحش وقت التحديث
//     final currentToken = _userData!['accessToken'];
    
//     _userData = {
//       ..._userData!,
//       ...updatedFields,
//       'accessToken': currentToken, // ضمان وجود التوكن
//     };

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('userData', jsonEncode(_userData));
//     notifyListeners();
//   }
//   /// Refreshes the Supabase session by re-fetching the DB row.
//   /// Called when the Supabase token rotates.
//   Future<void> refreshSession() async {
//     final session = Supabase.instance.client.auth.currentSession;
//     if (session == null) return;

//     debugPrint('⚡ [Auth] Refreshing session from Supabase DB...');
//     try {
//       final row = await Supabase.instance.client
//           .from('users')
//           .select()
//           .eq('id', session.user.id)
//           .maybeSingle();

//       if (row != null) {
//         await _saveUserSession({
//           ...row,
//           'accessToken': session.accessToken,
//           'email': session.user.email ?? row['email'],
//         });
//       }
//     } catch (e) {
//       debugPrint('⚠️ [Auth] refreshSession error: $e');
//     }
//   }

Future<void> updateUserData(Map<String, dynamic> updatedFields) async {
    if (_userData == null) return;
    
    debugPrint('🔄 [Auth] Updating user data with fields: ${updatedFields.keys.toList()}');

    // 1. الاحتفاظ بالقيم الحيوية (التوكن والرتبة) من الداتا الحالية
    final currentToken = token;
    final currentRefreshToken = refreshToken;
    final currentRole = userRole;
    
    // 2. الدمج الذكي: بنحافظ على كل القديم ونغير بس اللي جه جديد
    _userData = {
      ..._userData!,
      ...updatedFields,
      'accessToken': currentToken, // حماية التوكن
      if (currentRefreshToken != null && currentRefreshToken.isNotEmpty)
        'refreshToken': currentRefreshToken,
      'role': currentRole,        // حماية الرتبة
    };

    // 3. مسح أي nesting لو جه غلط من السيرفر
    _userData!.remove('user');

    // 4. الحفظ في الـ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(_userData));
    await prefs.setBool('isLoggedIn', true); 
    
    _isLoggedIn = true;
    notifyListeners();
    debugPrint('✅ [Auth] Update Complete. Current Role: $userRole');
  }

// // ── استبدل دالة updateUserData بالنسخة دي ────────────────────────────────
//   Future<void> updateUserData(Map<String, dynamic> updatedFields) async {
//     if (_userData == null) return;
    
//     // 1. الاحتفاظ بالقيم الحيوية (التوكن والرتبة)
//     final currentToken = token;
//     final currentRole = userRole;
    
//     // 2. دمج البيانات بشكل "فلات"
//     _userData = {
//       ..._userData!,
//       ...updatedFields,
//       'accessToken': currentToken, // ضمان عدم الضياع
//       'role': currentRole,        // ضمان ثبات الرتبة
//     };

//     // 3. الحفظ الذري (Atomic Persistence)
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('userData', jsonEncode(_userData));
//     // 🔥 المسمار اللي كان ناقص: لازم نأكد إن الحالة "مسجل دخول"
//     await prefs.setBool('isLoggedIn', true); 
    
//     _isLoggedIn = true;
//     notifyListeners();
//     debugPrint('✅ [Auth] updateUserData Saved & Persistent');
//   }

// ── وتأكد إن loadUserData بقت كدة (الترتيب بيفرق) ────────────────────────
  // Future<void> loadUserData() async {
  //   debugPrint('🔄 [Auth] loadUserData START');
  //   final prefs = await SharedPreferences.getInstance();

  //   final String? raw = prefs.getString('userData');
  //   // بنخلي الـ Default هو فحص الـ raw data نفسها مش بس الـ bool
  //   final bool wasLoggedIn = prefs.getBool('isLoggedIn') ?? (raw != null);

  //   if (raw != null && wasLoggedIn) {
  //     try {
  //       final decoded = jsonDecode(raw);
  //       if (decoded is Map<String, dynamic> && decoded.containsKey('accessToken')) {
  //         _userData = decoded;
  //         _isLoggedIn = true;
  //         debugPrint('✅ [Auth] Restored Session for: ${decoded['firstName']}');
  //       } else {
  //         _isLoggedIn = false;
  //       }
  //     } catch (e) {
  //       debugPrint('❌ [Auth] Corrupt session: $e');
  //       _isLoggedIn = false;
  //     }
  //   } else {
  //     _isLoggedIn = false;
  //   }

  //   // الإشارة للـ UI إننا خلصنا "بعد" ما حددنا الـ isLoggedIn بالظبط
  //   _isInitialized = true;
  //   notifyListeners();

  //   if (_isLoggedIn && token != null) {
  //     _syncProfileFromServer(token!);
  //   }
  //   debugPrint('🏁 [Auth] loadUserData END — isLoggedIn: $_isLoggedIn');
  // }

Future<void> loadUserData() async {
  debugPrint('🔄 [Auth] loadUserData START');

  final prefs = await SharedPreferences.getInstance();

  try {
    final raw = prefs.getString('userData');
    final storedAccessToken = prefs.getString('accessToken')?.trim();
    final storedRefreshToken = prefs.getString('refreshToken')?.trim();

    Map<String, dynamic>? decoded;

    if (raw != null && raw.isNotEmpty) {
      final value = jsonDecode(raw);
      if (value is Map<String, dynamic>) {
        decoded = Map<String, dynamic>.from(value);
      }
    }

    final accessToken =
        (storedAccessToken != null && storedAccessToken.isNotEmpty)
            ? storedAccessToken
            : decoded?['accessToken']?.toString().trim();

    if (decoded != null &&
        accessToken != null &&
        accessToken.isNotEmpty) {
      _userData = {
        ...decoded,
        'accessToken': accessToken,
        if (storedRefreshToken != null &&
            storedRefreshToken.isNotEmpty)
          'refreshToken': storedRefreshToken,
      };

      _isLoggedIn = true;

      debugPrint(
        '✅ [Auth] Restored session from persistent storage '
        '(token present)',
      );
    } else {
      _userData = null;
      _isLoggedIn = false;
      debugPrint('ℹ️ [Auth] No persisted session found');
    }
  } catch (e) {
    debugPrint('❌ [Auth] Session restore error: $e');

    // Do NOT clear SharedPreferences here.
    // A parsing/network/startup issue must not silently log the user out.
    _isLoggedIn = false;
  }

  _isInitialized = true;
  notifyListeners();

  if (_isLoggedIn) {
    final t = token;
    if (t != null && t.isNotEmpty) {
      _syncProfileFromServer(t);
    }
  }

  debugPrint(
    '🏁 [Auth] loadUserData END — isLoggedIn: $_isLoggedIn',
  );
}


  // ══════════════════════════════════════════════════════════════════════════
  // BACKGROUND NETWORK TASKS (fire-and-forget)
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetches the full profile from the Node.js backend and merges into state.
  Future<void> _syncProfileFromServer(String bearerToken) async {
    try {
      final profile = await ApiService.fetchProfile(bearerToken);
      if (profile != null) {
        await updateUserData({...profile, 'accessToken': bearerToken});
        debugPrint(
          '✅ [Auth] Profile synced — role: $userRole | '
          'phone: ${_userData?['phoneNumber']}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [Auth] _syncProfileFromServer error: $e');
    }
  }

  /// Uploads the device FCM token to the backend.
  Future<void> _syncFcmToken(String bearerToken) async {
    try {
      final fcmToken = await NotificationService.instance.getToken();
      if (fcmToken == null || bearerToken.isEmpty) return;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Auth] FCM token synced');
        NotificationService.instance.onTokenRefresh(
          (_) => _syncFcmToken(bearerToken),
        );
      } else {
        debugPrint(
          '⚠️ [Auth] FCM sync failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [Auth] _syncFcmToken error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE IMAGE
  // ══════════════════════════════════════════════════════════════════════════

  Future<String?> uploadProfileImage(dynamic imageFile) async {
    final t = token;
    if (t == null || t.isEmpty) return null;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/users/profile/picture'),
      )
        ..headers['Authorization'] = 'Bearer $t'
        ..headers['Accept'] = 'application/json';

      if (imageFile is List<int>) {
        request.files.add(
          http.MultipartFile.fromBytes('image', imageFile, filename: 'avatar.jpg'),
        );
      } else if (imageFile is File) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      } else {
        final bytes = await (imageFile as dynamic).readAsBytes() as List<int>;
        request.files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: 'avatar.jpg'),
        );
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final decoded = _tryDecodeJson(body);

      if (streamed.statusCode >= 200 &&
          streamed.statusCode < 300 &&
          decoded?['success'] == true) {
        final updatedUser =
            decoded?['data']?['user'] as Map<String, dynamic>?;
        if (updatedUser != null) {
          await updateUserData(updatedUser);
          return updatedUser['profilePicture']?.toString();
        }
      }
      debugPrint('⚠️ uploadProfileImage (${streamed.statusCode}): $body');
    } catch (e) {
      debugPrint('❌ [Auth] uploadProfileImage error: $e');
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PUBLIC AUTH METHODS
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> login(String email, String password) async {
    setLoading(true);
    try {
      final result = await _authRepo.login(email, password);
      // Backend shape: { success, accessToken, refreshToken, user: { ... } }
      if (result['success'] == true) {
        await _saveUserSession(result['data'] ?? {});
        final authToken = _userData?['accessToken']?.toString() ?? '';
        if (authToken.isNotEmpty) {
          _syncProfileFromServer(authToken); // fire-and-forget
          _syncFcmToken(authToken);          // fire-and-forget
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    setLoading(true);
    try {
      final result = await _authRepo.register({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      });
      // ✅ Save email so OTP screen can use it — this was missing!
      if (result['success'] == true) {
        _tempEmail = email;
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  /// Verifies an OTP.
  /// - For registration: auto-logs the user in if the backend returns a token.
  /// - For password reset: just validates; does NOT log in.
  /// 
  /// 
  /// 
  Future<Map<String, dynamic>> verifyOtp({
    required String otp,
    required String email,
    bool isForPasswordReset = false,
  }) async {
    setLoading(true);
    try {
      final result = await _authRepo.verifyOtp(email, otp, isForPasswordReset);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map<String, dynamic>) {
          // 🔥 بنسيف السيشن فوراً في الحالتين عشان نضمن إن الداتا تلمس الحديد وما تضربش كراش
          await _saveUserSession(data);
          
          final String authToken = _userData?['accessToken']?.toString() ?? '';
          if (authToken.isNotEmpty) {
            // مزامنة الـ FCM token في الخلفية بشكل آمن
            _syncFcmToken(authToken); 
            
            // لو مش ريسيت باسورد، ممكن نعمل مزامنة سريعة للبروفايل كمان للتأكيد
            if (!isForPasswordReset) {
              _syncProfileFromServer(authToken);
            }
          }
        }
      }
      return result;
    } catch (e) {
      debugPrint('❌ Error inside verifyOtp: $e');
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }
  // Future<Map<String, dynamic>> verifyOtp({
  //   required String otp,
  //   required String email,
  //   bool isForPasswordReset = false,
  // }) async {
  //   setLoading(true);
  //   try {
  //     final result = await _authRepo.verifyOtp(email, otp, isForPasswordReset);

  //     if (result['success'] == true && !isForPasswordReset) {
  //       // Backend now returns { success, accessToken, refreshToken, user: {...} }
  //       final data = result['data'];
  //       if (data is Map<String, dynamic> &&
  //           (data.containsKey('accessToken') || data.containsKey('user'))) {
  //         await _saveUserSession(data);
  //         final authToken = _userData?['accessToken']?.toString() ?? '';
  //         if (authToken.isNotEmpty) {
  //           _syncFcmToken(authToken); // fire-and-forget
  //         }
  //       }
  //     }
  //     return result;
  //   } catch (e) {
  //     return {'success': false, 'message': 'Network Error: $e'};
  //   } finally {
  //     setLoading(false);
  //   }
  // }

  Future<Map<String, dynamic>> sendResetCode(String email) async {
    if (_remainingSeconds > 0 && _lastResetEmail == email) {
      return {
        'success': true,
        'message': 'Code already sent, please wait and try again later.',
      };
    }
    if (_lastResetEmail != email) stopOtpTimer();

    setLoading(true);
    try {
      final result = await _authRepo.sendResetCode(email);
      if (result['success'] == true) {
        _lastResetEmail = email;
        _userData = {'email': email};
        startOtpTimer();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    setLoading(true);
    try {
      final result = await _authRepo.resetPassword(email, otp, newPassword);
      // Backend now returns { success, accessToken, refreshToken, user: { ..., role } }
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map<String, dynamic>) {
          await _saveUserSession(data);
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> resendOtp() async {
    setLoading(true);
    try {
      return await _authRepo.resendOtp(_userData?['email'] ?? '');
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    setLoading(true);
    try {
      debugPrint('🔵 [Auth] Starting Google Sign-in...');
      const String redirectUrl = 'io.supabase.dealio://login-callback/';

      final bool success = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        queryParams: {'prompt': 'select_account'},
        redirectTo: redirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );

      return success
          ? {'success': true, 'message': 'Redirecting to Google...'}
          : {'success': false, 'message': 'Google Sign-in failed to launch'};
    } catch (e) {
      debugPrint('❌ [Auth] signInWithGoogle error: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout(BuildContext context) async {
    // Read CartProvider synchronously BEFORE any await to avoid
    // BuildContext-across-async-gap issues.
    final cart = context.read<CartProvider>();
    try {
      await Supabase.instance.client.auth.signOut();
      cart.clearLocal();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _userData = null;
      _isLoggedIn = false;
      _tempEmail = '';
      _lastResetEmail = '';
      stopOtpTimer();

      debugPrint('✅ [Auth] Logged out');
    } catch (e) {
      debugPrint('❌ [Auth] logout error: $e');
    }
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OTP TIMER
  // ══════════════════════════════════════════════════════════════════════════

  void startOtpTimer() {
    if (_timer?.isActive ?? false) return;
    _timer?.cancel();
    _remainingSeconds = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
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

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  static Map<String, dynamic>? _tryDecodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
