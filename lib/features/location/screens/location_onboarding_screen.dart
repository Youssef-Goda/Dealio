import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/shipping_address_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:dealio/data/services/location_service.dart';
import 'package:dealio/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Preference key ────────────────────────────────────────────────────────────
const String kLocationOnboardingDone = 'locationOnboardingDone';

class LocationOnboardingScreen extends StatefulWidget {
  const LocationOnboardingScreen({super.key});

  @override
  State<LocationOnboardingScreen> createState() =>
      _LocationOnboardingScreenState();
}

class _LocationOnboardingScreenState extends State<LocationOnboardingScreen> {
  // ── Map state ──────────────────────────────────────────────────────────────
  final MapController _mapCtrl = MapController();

  /// Cairo as sensible fallback when GPS is unavailable
  static const LatLng _cairoCentre = LatLng(30.0444, 31.2357);
  static const double _defaultZoom = 15.0;

  LatLng _pinPosition = _cairoCentre;
  bool _mapReady = false;

  // ── UX state ──────────────────────────────────────────────────────────────
  bool _locating = true; // true while we fetch GPS on mount
  bool _saving = false;
  String? _addressLine; // reverse-geocoded label under the pin
  String? _governorate;
  String? _city;
  String? _errorMsg;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tryGetCurrentLocation();
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  // ── Location helpers ──────────────────────────────────────────────────────

  Future<void> _tryGetCurrentLocation() async {
    setState(() {
      _locating = true;
      _errorMsg = null;
    });

    try {
      final Position? pos = await LocationService.getPosition();
      if (!mounted) return;

      if (pos != null) {
        final newPin = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _pinPosition = newPin;
          _locating = false;
        });
        if (_mapReady) {
          _mapCtrl.move(newPin, _defaultZoom);
        }
        // Reverse geocode in background
        _reverseGeocode(pos.latitude, pos.longitude);
      } else {
        setState(() {
          _locating = false;
          _errorMsg = 'Could not detect location. Tap the map to set manually.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locating = false;
          _errorMsg = 'Location error. Tap the map to set manually.';
        });
      }
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    final result = await LocationService.reverseGeocode(lat, lng);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _governorate = result.govCandidate;
        _city = result.cityCandidate;
        _addressLine = [
          if (result.streetHint != null) result.streetHint,
          if (result.cityCandidate != null) result.cityCandidate,
          if (result.govCandidate != null) result.govCandidate,
        ].join(', ');
      });
    }
  }

  void _onMapTap(TapPosition tapPos, LatLng point) {
    setState(() {
      _pinPosition = point;
      _addressLine = null;
      _governorate = null;
      _city = null;
    });
    _reverseGeocode(point.latitude, point.longitude);
  }

  void _recenterToCurrentLocation() => _tryGetCurrentLocation();

  // ── Save & navigate ───────────────────────────────────────────────────────

  Future<void> _confirmLocation() async {
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final checkout = context.read<CheckoutProvider>();

      final address = ShippingAddress(
        id: '', // assigned by server
        userId: auth.userId,
        fullName: auth.user['firstName']?.toString() ?? 'Home',
        phone: auth.user['phone']?.toString() ?? '',
        addressLine1: _addressLine ?? 'Home Location',
        city: _city ?? 'Unknown',
        governorate: _governorate ?? 'Unknown',
        isDefault: true,
        latitude: _pinPosition.latitude,
        longitude: _pinPosition.longitude,
      );

      await checkout.addAddress(address);
    } catch (e) {
      // Non-fatal — we still mark onboarding done and proceed
      debugPrint('⚠️ [LocationOnboarding] Could not save address: $e');
    }

    // Mark onboarding complete regardless of whether the API call succeeded.
    // The user should never be stuck on this screen.
    await _markDone();

    if (mounted) {
      _navigateToHome();
    }
  }

  Future<void> _skip() async {
    await _markDone();
    if (mounted) _navigateToHome();
  }

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kLocationOnboardingDone, true);
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _pinPosition,
              initialZoom: _defaultZoom,
              onMapReady: () => setState(() => _mapReady = true),
              onTap: _onMapTap,
            ),
            children: [
              // OSM tile layer — no API key needed
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dealio.app',
                maxZoom: 19,
              ),

              // Pin marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pinPosition,
                    width: 48,
                    height: 56,
                    alignment: Alignment.topCenter,
                    child: const _PinWidget(),
                  ),
                ],
              ),
            ],
          ),

          // ── Top Header bar ────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 14,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPin,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Your Home Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Tap the map to move the pin',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Skip',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),

          // ── GPS loading indicator ─────────────────────────────────────────
          if (_locating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[850]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Detecting your location…',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Error pill ───────────────────────────────────────────────────
          if (_errorMsg != null && !_locating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.triangleAlert,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Re-center FAB ─────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 230,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: isDark ? Colors.grey[850] : Colors.white,
              onPressed: _locating ? null : _recenterToCurrentLocation,
              tooltip: 'Go to my location',
              child: Icon(
                LucideIcons.crosshair,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),

          // ── Bottom sheet ──────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomSheet(
              addressLine: _addressLine,
              governorate: _governorate,
              pinPosition: _pinPosition,
              saving: _saving,
              onConfirm: _confirmLocation,
              onSkip: _saving ? null : _skip,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pin widget ───────────────────────────────────────────────────────────────

class _PinWidget extends StatelessWidget {
  const _PinWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(LucideIcons.house,
              color: Colors.white, size: 18),
        ),
        // Stem
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom sheet ─────────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final String? addressLine;
  final String? governorate;
  final LatLng pinPosition;
  final bool saving;
  final VoidCallback onConfirm;
  final VoidCallback? onSkip;

  const _BottomSheet({
    required this.addressLine,
    required this.governorate,
    required this.pinPosition,
    required this.saving,
    required this.onConfirm,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String coordsLabel =
        '${pinPosition.latitude.toStringAsFixed(5)}, '
        '${pinPosition.longitude.toStringAsFixed(5)}';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // Address / coordinates
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.mapPin,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addressLine ?? 'Getting address…',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      coordsLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onConfirm,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.check, size: 18),
              label: Text(saving ? 'Saving…' : 'Confirm This Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.5),
              ),
            ),
          ),

          if (onSkip != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
