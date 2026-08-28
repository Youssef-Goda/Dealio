import 'package:flutter/foundation.dart';
import 'package:e_commerce/data/models/store_settings_model.dart';
import 'package:e_commerce/data/services/api_service.dart';

class StoreSettingsProvider extends ChangeNotifier {
  StoreSettings _settings = StoreSettings(isBannerEnabled: true);
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isUpdating = false;
  String? _errorMessage;

  StoreSettings get settings => _settings;
  bool get isBannerEnabled => _settings.isBannerEnabled;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  /// Fetches public settings (e.g. feature flags)
  Future<void> fetchPublicSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.getRequest('/settings/public', '');
      final result = ApiService.processResponse(res);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        if (data is Map<String, dynamic>) {
          final payload = (data['data'] as Map<String, dynamic>?) ?? data;
          _settings = StoreSettings.fromJson(payload);
        }
      }
    } catch (e) {
      debugPrint('❌ Fetch store settings error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Updates store settings (Owner access only)
  Future<bool> updateOwnerSettings({
    required bool isBannerEnabled,
    required String token,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.patchAuthRequest(
        '/owner/settings',
        {'is_banner_enabled': isBannerEnabled},
        token,
      );
      final result = ApiService.processResponse(res);

      if (result['success'] == true) {
        _settings = _settings.copyWith(isBannerEnabled: isBannerEnabled);
        _isUpdating = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message']?.toString() ?? 'Failed to update settings';
        _isUpdating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Update store settings error: $e');
      _errorMessage = e.toString();
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }
}
