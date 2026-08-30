import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/services/api_service.dart';

// ── Email-change flow steps ───────────────────────────────────────────────────
enum EmailChangeStep { idle, verifyIdentity, enterNewEmail, verifyNewOtp }

// ── Month names lookup ────────────────────────────────────────────────────────
const List<String> _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'];

class ProfileProvider with ChangeNotifier {
  // ── Core profile fields ───────────────────────────────────────────────────
  String _firstName   = '';
  String _lastName    = '';
  String _email       = '';
  String _avatarUrl   = '';
  String _phoneNumber = '';
  String _gender      = '';
  String _role        = '';
  String _memberSince = '';
  DateTime? _dob;

  // ── Edit-session originals (for dirty-check & discard) ───────────────────
  String _origFirstName   = '';
  String _origLastName    = '';
  String _origAvatarUrl   = '';
  String _origPhoneNumber = '';
  String _origGender      = '';
  DateTime? _origDob;

  // ── UI / async state ──────────────────────────────────────────────────────
  bool   _isLoading       = false;
  bool   _isUploading     = false;
  double _uploadProgress  = 0.0;
  bool   _sessionExpired  = false;
  bool   _mobileVisible   = false;
  String? _errorMessage;

  // ── Email-change sub-flow ─────────────────────────────────────────────────
  EmailChangeStep _emailChangeStep    = EmailChangeStep.idle;
  bool            _emailChangeLoading = false;
  String?         _emailChangeError;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC GETTERS — every property the UI may ever touch
  // ═══════════════════════════════════════════════════════════════════════════

  String    get firstName         => _firstName;
  String    get lastName          => _lastName;
  String    get fullName          => '$_firstName $_lastName'.trim();
  String    get email             => _email;
  String    get avatarUrl         => _avatarUrl;
  String    get phoneNumber       => _phoneNumber;
  String    get gender            => _gender;
  String    get role              => _role;
  String    get memberSince       => _memberSince.isNotEmpty ? _memberSince : 'N/A';
  DateTime? get dob               => _dob;
  bool      get mobileVisible     => _mobileVisible;

  bool      get isLoading         => _isLoading;
  bool      get isUploading       => _isUploading;
  double    get uploadProgress    => _uploadProgress;
  bool      get sessionExpired    => _sessionExpired;
  String?   get errorMessage      => _errorMessage;

  EmailChangeStep get emailChangeStep    => _emailChangeStep;
  bool            get emailChangeLoading => _emailChangeLoading;
  String?         get emailChangeError   => _emailChangeError;

  /// Returns true when any editable field differs from its original snapshot.
  bool get isDirty =>
      _firstName   != _origFirstName   ||
      _lastName    != _origLastName    ||
      _avatarUrl   != _origAvatarUrl   ||
      _phoneNumber != _origPhoneNumber ||
      _gender      != _origGender      ||
      _dob         != _origDob;

  /// Initials for avatar fallback (e.g. "YG").
  String get initials {
    final f = _firstName.trim();
    final l = _lastName.trim();
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'
        .toUpperCase();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROBUST DATA PICKER — aggressively finds values across camelCase/snake_case
  // ═══════════════════════════════════════════════════════════════════════════

  /// Normalises a key to lowercase-no-underscores for fuzzy matching.
  static String _norm(String k) => k.toLowerCase().replaceAll('_', '');

  /// Searches [data] for the first non-empty value matching any of [keys].
  /// Falls back to normalised-key lookup so camelCase & snake_case both match.
  static String? _pick(Map<String, dynamic> data, List<String> keys) {
    // 1. Direct hit (fastest, preserves original casing)
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    // 2. Normalised hit (handles unexpected naming variants)
    final normData = <String, String>{};
    data.forEach((k, v) {
      if (v != null && v.toString().trim().isNotEmpty) {
        normData[_norm(k)] = v.toString().trim();
      }
    });
    for (final k in keys) {
      final v = normData[_norm(k)];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CROSS-PLATFORM DATE FORMATTER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Converts ISO-8601, Unix-timestamp (ms), or partial "YYYY-MM" strings
  /// into "June 2026" format. Returns empty string on failure.
  static String _formatJoinDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final s = raw.toString().trim();
      if (s.isEmpty) return '';

      // Unix timestamp in milliseconds
      final asInt = int.tryParse(s);
      if (asInt != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(asInt);
        return '${_kMonths[dt.month - 1]} ${dt.year}';
      }

      // ISO-8601 or partial date
      final dt = DateTime.tryParse(s);
      if (dt != null) return '${_kMonths[dt.month - 1]} ${dt.year}';

      // Partial "YYYY-MM" format
      final parts = s.split('-');
      if (parts.length >= 2) {
        final year  = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year != null && month != null && month >= 1 && month <= 12) {
          return '${_kMonths[month - 1]} $year';
        }
      }
    } catch (_) {}
    return '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD FROM USER MAP  (Smart Seed — never overwrites existing data with null)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Accepts any server response shape:
  ///   • Flat   `{ id, firstName, email, ... }`
  ///   • Nested `{ data: { user: { ... } } }`
  ///   • Mixed  `{ user: { ... }, accessToken: '...' }`
  void loadFromUser(Map<String, dynamic> raw) {
    try {
      // 1. Unwrap all nesting layers to reach the actual user object
      final Map<String, dynamic> data = _unwrap(raw);

      // 2. Aggressive multi-key extraction
      final newFirst  = _pick(data, ['firstName', 'first_name', 'fname', 'givenName']);
      final newLast   = _pick(data, ['lastName', 'last_name', 'lname', 'familyName']);
      final newEmail  = _pick(data, ['email', 'emailAddress', 'email_address']);
      final newAvatar = _pick(data, [
        'profilePicture', 'profile_picture', 'avatarUrl', 'avatar_url',
        'avatar', 'picture', 'photoUrl', 'photo_url', 'imageUrl', 'image_url',
      ]);
      final newPhone  = _pick(data, [
        'phoneNumber', 'phone_number', 'phone', 'mobile', 'mobileNumber',
        'mobile_number',
      ]);
      final newGender = _pick(data, ['gender', 'sex']);
      final newRole   = _pick(data, ['role', 'user_role', 'userRole', 'accountType']);
      final rawDob    = _pick(data, ['birthDate', 'birth_date', 'dob', 'dateOfBirth']);
      final rawJoined = _pick(data, [
        'createdAt', 'created_at', 'joinedAt', 'joined_at',
        'registeredAt', 'memberSince', 'member_since',
      ]);

      // 3. Smart merge — only update if the new value is non-null/non-empty
      if (newFirst  != null && newFirst.isNotEmpty)  _firstName   = newFirst;
      if (newLast   != null && newLast.isNotEmpty)   _lastName    = newLast;
      if (newEmail  != null && newEmail.isNotEmpty)  _email       = newEmail;
      if (newAvatar != null && newAvatar.isNotEmpty) _avatarUrl   = newAvatar;
      if (newPhone  != null && newPhone.isNotEmpty)  _phoneNumber = newPhone;
      if (newGender != null && newGender.isNotEmpty) _gender      = newGender;
      if (newRole   != null && newRole.isNotEmpty)   _role        = newRole;

      // DOB parsing
      if (rawDob != null && rawDob.isNotEmpty) {
        final parsed = DateTime.tryParse(rawDob);
        if (parsed != null) _dob = parsed;
      }

      // Member-since formatting
      final formatted = _formatJoinDate(rawJoined);
      if (formatted.isNotEmpty) _memberSince = formatted;

      // 4. Sync originals so isDirty starts as false
      _syncOriginals();

      _errorMessage  = null;
      _sessionExpired = false;

      debugPrint(
        '📋 ProfileProvider.loadFromUser → '
        'name=$_firstName $_lastName | role=$_role | '
        'email=$_email | joined=$_memberSince',
      );
    } catch (e) {
      // Defensive: never crash the app due to a bad payload
      debugPrint('⚠️ ProfileProvider.loadFromUser error: $e');
    }
    // Defer notification to avoid "setState during build" when called from
    // ChangeNotifierProxyProvider.update() which runs inside the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Recursively unwraps `{ data: { user: {...} } }` / `{ user: {...} }` shapes.
  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    // Try data.user
    final dataNode = raw['data'];
    if (dataNode is Map<String, dynamic>) {
      final userNode = dataNode['user'];
      if (userNode is Map<String, dynamic>) return userNode;
      return dataNode;
    }
    // Try top-level user
    final userNode = raw['user'];
    if (userNode is Map<String, dynamic>) return userNode;
    return raw;
  }

  void _syncOriginals() {
    _origFirstName   = _firstName;
    _origLastName    = _lastName;
    _origAvatarUrl   = _avatarUrl;
    _origPhoneNumber = _phoneNumber;
    _origGender      = _gender;
    _origDob         = _dob;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SMART CACHE — persist to SharedPreferences
  // ═══════════════════════════════════════════════════════════════════════════

  /// Saves the full raw JSON (preferred) or a reconstructed map to SharedPrefs.
  /// Always silent — never throws.
  Future<void> _persistToPrefs([Map<String, dynamic>? rawJson]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Build canonical flat map — use rawJson when available (server truth),
      // otherwise reconstruct from current in-memory state.
      final Map<String, dynamic> toSave = rawJson != null
          ? _flattenForStorage(rawJson)
          : {
              'firstName':      _firstName,
              'lastName':       _lastName,
              'email':          _email,
              'profilePicture': _avatarUrl,
              'phoneNumber':    _phoneNumber,
              'gender':         _gender,
              'role':           _role,
              if (_dob != null)
                'birthDate': _dob!.toIso8601String().split('T').first,
            };

      await prefs.setString('userData', jsonEncode(toSave));
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      debugPrint('⚠️ ProfileProvider._persistToPrefs error: $e');
    }
  }

  /// Flattens a potentially nested server response into a single-level map,
  /// preserving all keys while hoisting nested user fields to the top.
  static Map<String, dynamic> _flattenForStorage(Map<String, dynamic> raw) {
    final flat = Map<String, dynamic>.from(raw);
    final inner = _unwrap(raw);
    if (!identical(inner, raw)) {
      // Merge inner fields without overwriting outer (e.g. accessToken)
      inner.forEach((k, v) {
        if (!flat.containsKey(k) || flat[k] == null) flat[k] = v;
      });
    }
    flat.remove('user'); // no nesting in stored map
    return flat;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  void setFirstName(String v)   { _firstName   = v; notifyListeners(); }
  void setLastName(String v)    { _lastName    = v; notifyListeners(); }
  void setPhoneNumber(String v) { _phoneNumber = v; notifyListeners(); }
  void setGender(String v)      { _gender      = v; notifyListeners(); }
  void setDob(DateTime? v)      { _dob         = v; notifyListeners(); }

  void toggleMobileVisible() {
    _mobileVisible = !_mobileVisible;
    notifyListeners();
  }

  void discardChanges() {
    _firstName   = _origFirstName;
    _lastName    = _origLastName;
    _avatarUrl   = _origAvatarUrl;
    _phoneNumber = _origPhoneNumber;
    _gender      = _origGender;
    _dob         = _origDob;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH PROFILE  (Smart Cache: show local → update in background)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches the full profile from the backend.
  /// Uses the smart-cache pattern: the UI already shows local data instantly;
  /// this call silently refreshes it.
  Future<void> fetchProfile(String token) async {
    if (token.isEmpty) return;

    _isLoading      = true;
    _sessionExpired = false;
    _errorMessage   = null;
    notifyListeners();

    try {
      final response = await ApiService.getRequest('/users/profile', token);
      final result   = ApiService.processResponse(response);

      if (result['success'] == true) {
        // Handle 200 OK with empty data gracefully
        final rawData = result['data'];
        if (rawData is Map<String, dynamic> && rawData.isNotEmpty) {
          final userMap = _unwrap(rawData);
          loadFromUser(userMap);
          await _persistToPrefs(userMap);
        } else {
          debugPrint('⚠️ ProfileProvider.fetchProfile: 200 OK but empty data.');
        }
      } else {
        _sessionExpired =
            result['isForbidden'] == true || result['statusCode'] == 401;
        _errorMessage =
            result['message']?.toString() ?? 'Failed to fetch profile';
      }
    } on SocketException {
      // No internet — keep existing cached data, do not crash
      debugPrint('⚠️ ProfileProvider.fetchProfile: No internet connection.');
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      debugPrint('❌ ProfileProvider.fetchProfile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> updateProfile({
    required String token,
    AuthProvider? authProvider,
  }) async {
    if (token.isEmpty) {
      _errorMessage = 'No active session. Please log in again.';
      notifyListeners();
      return false;
    }

    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'firstName': _firstName,
        'lastName':  _lastName,
        if (_avatarUrl.isNotEmpty)   'profilePicture': _avatarUrl,
        if (_phoneNumber.isNotEmpty) 'phoneNumber':    _phoneNumber,
        if (_gender.isNotEmpty)      'gender':         _gender,
        if (_dob != null)
          'birthDate': _dob!.toIso8601String().split('T').first,
      };

      final response = await ApiService.putRequest('/users/profile', body, token);
      final result   = ApiService.processResponse(response);

      // if (result['success'] == true) {
      //   // Robustly extract the updated user from any response shape
      //   final rawData = result['data'];
      //   Map<String, dynamic> updatedUser = {};
      //   if (rawData is Map<String, dynamic>) {
      //     updatedUser = _unwrap(rawData);
      //     if (updatedUser.isEmpty) updatedUser = rawData;
      //   }

      //   // Handle edge case: 200 OK but data is empty — use current state
      //   if (updatedUser.isEmpty) {
      //     updatedUser = {
      //       'firstName':      _firstName,
      //       'lastName':       _lastName,
      //       'email':          _email,
      //       'profilePicture': _avatarUrl,
      //       'phoneNumber':    _phoneNumber,
      //       'gender':         _gender,
      //       'role':           _role,
      //     };
      //   }

      //   // Propagate to AuthProvider so all widgets globally update
      //   if (authProvider != null && updatedUser.isNotEmpty) {
      //     await authProvider.updateUserData(updatedUser);
      //   }

      //   loadFromUser(updatedUser);
      //   await _persistToPrefs(updatedUser);
      //   return true;
      // }


      // 🔥 التعديل هنا في دالة updateProfile
if (result['success'] == true) {
  final rawData = result['data'];
  Map<String, dynamic> updatedUser = {};
  if (rawData is Map<String, dynamic>) {
    updatedUser = _unwrap(rawData);
    if (updatedUser.isEmpty) updatedUser = rawData;
  }

  // 1. حدث الـ SharedPreferences الأول ببيانات اليوزر فقط (بدون لمس الـ Token)
  await _persistToPrefs(updatedUser);

  // 2. لما تنادي الـ AuthProvider، اتأكد إنه بيحدث الـ UserData بس
  // لو الـ AuthProvider بتاعك فيه دالة بتعمل Logout لما الداتا تتغير، شيل السطر ده وجرب
  if (authProvider != null && updatedUser.isNotEmpty) {
    // إحنا محتاجين نحدث الداتا "Locally" جوه الـ AuthProvider من غير ما نهز السيشن
    await authProvider.updateUserData(updatedUser); 
  }

  loadFromUser(updatedUser);
  return true;
}

      _sessionExpired =
          result['isForbidden'] == true || result['statusCode'] == 401;
      _errorMessage = result['message']?.toString() ?? 'Update failed';
      notifyListeners();
      return false;
    } on SocketException {
      _errorMessage = 'No internet connection. Changes saved locally.';
      // Optimistically sync originals so UI does not stay in dirty state
      _syncOriginals();
      await _persistToPrefs();
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      debugPrint('❌ ProfileProvider.updateProfile: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PICK & UPLOAD AVATAR
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> pickAndUploadAvatar(
    String token, {
    AuthProvider? authProvider,
  }) async {
    final picker = ImagePicker();
    XFile? xfile;
    try {
      xfile = await picker.pickImage(
        source:       ImageSource.gallery,
        imageQuality: 85,
        maxWidth:     800,
      );
    } catch (e) {
      _errorMessage = 'Could not open image picker.';
      notifyListeners();
      return null;
    }

    if (xfile == null) return null; // user cancelled

    _isUploading    = true;
    _uploadProgress = 0.0;
    _errorMessage   = null;
    notifyListeners();

    try {
      dynamic imagePayload;
      if (kIsWeb) {
        imagePayload = await xfile.readAsBytes();
      } else {
        imagePayload = File(xfile.path);
      }

      String? url;
      if (authProvider != null) {
        // All-in-one: upload → save to DB → sync AuthProvider._userData
        url = await authProvider.uploadProfileImage(imagePayload);
      } else {
        url = await ApiService.uploadImage(imagePayload, token);
      }

      if (url != null && url.isNotEmpty) {
        _avatarUrl     = url;
        _origAvatarUrl = url; // reset snapshot so isDirty stays false
        _uploadProgress = 1.0;
        await _persistToPrefs();
        notifyListeners();
        return url;
      }

      _errorMessage = 'Profile picture upload failed. Please try again.';
      notifyListeners();
      return null;
    } on SocketException {
      _errorMessage = 'No internet connection. Could not upload avatar.';
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Upload error. Please try again.';
      debugPrint('❌ ProfileProvider.pickAndUploadAvatar: $e');
      notifyListeners();
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL CHANGE FLOW  (4-step secure flow)
  // ═══════════════════════════════════════════════════════════════════════════

  void resetEmailChangeFlow() {
    _emailChangeStep    = EmailChangeStep.idle;
    _emailChangeError   = null;
    _emailChangeLoading = false;
    notifyListeners();
  }

  void clearEmailChangeError() {
    _emailChangeError = null;
    notifyListeners();
  }

  void _setEmailChangeLoading(bool v) {
    _emailChangeLoading = v;
    notifyListeners();
  }

  /// Step 0 → 1 (OTP path): sends OTP to the currently registered email.
  Future<bool> sendIdentityOtp({required String token}) async {
    _setEmailChangeLoading(true);
    _emailChangeError = null;
    try {
      final res  = await ApiService.postAuthRequest(
        '/users/change-email/send-identity-otp',
        {},
        token,
      );
      final data = _tryDecodeJson(res.body);
      if (res.statusCode == 200) {
        _emailChangeStep = EmailChangeStep.verifyIdentity;
        notifyListeners();
        return true;
      }
      _emailChangeError =
          data?['message']?.toString() ?? 'Failed to send OTP.';
      notifyListeners();
      return false;
    } on SocketException {
      _emailChangeError = 'No internet connection.';
      notifyListeners();
      return false;
    } catch (e) {
      _emailChangeError = 'Network error. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setEmailChangeLoading(false);
    }
  }

  /// Step 1: Verifies identity via password OR OTP.
  Future<bool> verifyIdentity({
    required String token,
    required String method, // 'password' | 'otp'
    String? password,
    String? otp,
  }) async {
    _setEmailChangeLoading(true);
    _emailChangeError = null;
    try {
      final body = <String, dynamic>{'method': method};
      if (method == 'password' && password != null) body['password'] = password;
      if (method == 'otp'      && otp      != null) body['otp']      = otp;

      final res  = await ApiService.postAuthRequest(
        '/users/change-email/verify-identity',
        body,
        token,
      );
      final data = _tryDecodeJson(res.body);
      if (res.statusCode == 200) {
        _emailChangeStep = EmailChangeStep.enterNewEmail;
        notifyListeners();
        return true;
      }
      _emailChangeError =
          data?['message']?.toString() ?? 'Identity verification failed.';
      notifyListeners();
      return false;
    } on SocketException {
      _emailChangeError = 'No internet connection.';
      notifyListeners();
      return false;
    } catch (e) {
      _emailChangeError = 'Network error. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setEmailChangeLoading(false);
    }
  }

  /// Step 2: Submits new email — backend sends OTP to the new address.
  Future<bool> sendNewEmailOtp({
    required String token,
    required String newEmail,
  }) async {
    _setEmailChangeLoading(true);
    _emailChangeError = null;
    try {
      final res  = await ApiService.postAuthRequest(
        '/users/change-email/send-otp',
        {'newEmail': newEmail},
        token,
      );
      final data = _tryDecodeJson(res.body);
      if (res.statusCode == 200) {
        _emailChangeStep = EmailChangeStep.verifyNewOtp;
        notifyListeners();
        return true;
      }
      _emailChangeError =
          data?['message']?.toString() ?? 'Failed to send verification code.';
      notifyListeners();
      return false;
    } on SocketException {
      _emailChangeError = 'No internet connection.';
      notifyListeners();
      return false;
    } catch (e) {
      _emailChangeError = 'Network error. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setEmailChangeLoading(false);
    }
  }

  /// Step 3: Confirms OTP — backend updates the email in the database.
  Future<bool> confirmEmailChange({
    required String token,
    required String otp,
    AuthProvider? authProvider,
  }) async {
    _setEmailChangeLoading(true);
    _emailChangeError = null;
    try {
      final res  = await ApiService.postAuthRequest(
        '/users/change-email/confirm',
        {'otp': otp},
        token,
      );
      final data = _tryDecodeJson(res.body);
      if (res.statusCode == 200) {
        // Extract new email from response, falling back to current value
        final newEmail =
            data?['data']?['email']?.toString() ??
            data?['email']?.toString()           ??
            _email;

        _email = newEmail;

        // Persist and propagate
        await _persistToPrefs({'email': newEmail});
        if (authProvider != null) {
          await authProvider.updateUserData({'email': newEmail});
        }

        _emailChangeStep = EmailChangeStep.idle;
        notifyListeners();
        return true;
      }
      _emailChangeError =
          data?['message']?.toString() ?? 'OTP verification failed.';
      notifyListeners();
      return false;
    } on SocketException {
      _emailChangeError = 'No internet connection.';
      notifyListeners();
      return false;
    } catch (e) {
      _emailChangeError = 'Network error. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setEmailChangeLoading(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, dynamic>? _tryDecodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
