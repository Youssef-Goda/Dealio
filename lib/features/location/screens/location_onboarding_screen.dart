// import 'package:dealio/core/constants/colors.dart';
// import 'package:dealio/data/models/shipping_address_model.dart';
// import 'package:dealio/data/providers/auth_provider.dart';
// import 'package:dealio/data/providers/checkout_provider.dart';
// import 'package:dealio/data/services/location_service.dart';
// import 'package:dealio/features/home/screens/home_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // ── Preference key ────────────────────────────────────────────────────────────
// const String kLocationOnboardingDone = 'locationOnboardingDone';

// class LocationOnboardingScreen extends StatefulWidget {
//   const LocationOnboardingScreen({super.key});

//   @override
//   State<LocationOnboardingScreen> createState() =>
//       _LocationOnboardingScreenState();
// }

// class _LocationOnboardingScreenState extends State<LocationOnboardingScreen> {
//   // ── Map state ──────────────────────────────────────────────────────────────
//   final MapController _mapCtrl = MapController();

//   /// Cairo as sensible fallback when GPS is unavailable
//   static const LatLng _cairoCentre = LatLng(30.0444, 31.2357);
//   static const double _defaultZoom = 15.0;

//   LatLng _pinPosition = _cairoCentre;
//   bool _mapReady = false;

//   // ── UX state ──────────────────────────────────────────────────────────────
//   bool _locating = true; // true while we fetch GPS on mount
//   bool _saving = false;
//   String? _addressLine; // reverse-geocoded label under the pin
//   String? _governorate;
//   String? _city;
//   String? _errorMsg;

//   // ── Lifecycle ─────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     _tryGetCurrentLocation();
//   }

//   @override
//   void dispose() {
//     _mapCtrl.dispose();
//     super.dispose();
//   }

//   // ── Location helpers ──────────────────────────────────────────────────────

//   Future<void> _tryGetCurrentLocation() async {
//     setState(() {
//       _locating = true;
//       _errorMsg = null;
//     });

//     try {
//       final Position? pos = await LocationService.getPosition();
//       if (!mounted) return;

//       if (pos != null) {
//         final newPin = LatLng(pos.latitude, pos.longitude);
//         setState(() {
//           _pinPosition = newPin;
//           _locating = false;
//         });
//         if (_mapReady) {
//           _mapCtrl.move(newPin, _defaultZoom);
//         }
//         // Reverse geocode in background
//         _reverseGeocode(pos.latitude, pos.longitude);
//       } else {
//         setState(() {
//           _locating = false;
//           _errorMsg = 'Could not detect location. Tap the map to set manually.';
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _locating = false;
//           _errorMsg = 'Location error. Tap the map to set manually.';
//         });
//       }
//     }
//   }

//   Future<void> _reverseGeocode(double lat, double lng) async {
//     final result = await LocationService.reverseGeocode(lat, lng);
//     if (!mounted) return;
//     if (result != null) {
//       setState(() {
//         _governorate = result.govCandidate;
//         _city = result.cityCandidate;
//         _addressLine = [
//           if (result.streetHint != null) result.streetHint,
//           if (result.cityCandidate != null) result.cityCandidate,
//           if (result.govCandidate != null) result.govCandidate,
//         ].join(', ');
//       });
//     }
//   }

//   void _onMapTap(TapPosition tapPos, LatLng point) {
//     setState(() {
//       _pinPosition = point;
//       _addressLine = null;
//       _governorate = null;
//       _city = null;
//     });
//     _reverseGeocode(point.latitude, point.longitude);
//   }

//   void _recenterToCurrentLocation() => _tryGetCurrentLocation();

//   // ── Save & navigate ───────────────────────────────────────────────────────

//   Future<void> _confirmLocation() async {
//     setState(() => _saving = true);
//     try {
//       final auth = context.read<AuthProvider>();
//       final checkout = context.read<CheckoutProvider>();

//       final address = ShippingAddress(
//         id: '', // assigned by server
//         userId: auth.userId,
//         fullName: auth.user['firstName']?.toString() ?? 'Home',
//         phone: auth.user['phone']?.toString() ?? '',
//         addressLine1: _addressLine ?? 'Home Location',
//         city: _city ?? 'Unknown',
//         governorate: _governorate ?? 'Unknown',
//         isDefault: true,
//         latitude: _pinPosition.latitude,
//         longitude: _pinPosition.longitude,
//       );

//       await checkout.addAddress(address);
//     } catch (e) {
//       // Non-fatal — we still mark onboarding done and proceed
//       debugPrint('⚠️ [LocationOnboarding] Could not save address: $e');
//     }

//     // Mark onboarding complete regardless of whether the API call succeeded.
//     // The user should never be stuck on this screen.
//     await _markDone();

//     if (mounted) {
//       _navigateToHome();
//     }
//   }

//   Future<void> _skip() async {
//     await _markDone();
//     if (mounted) _navigateToHome();
//   }

//   Future<void> _markDone() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(kLocationOnboardingDone, true);
//   }

//   void _navigateToHome() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const HomeScreen()),
//       (_) => false,
//     );
//   }

//   // ── Build ─────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       body: Stack(
//         children: [
//           // ── Map ──────────────────────────────────────────────────────────
//           FlutterMap(
//             mapController: _mapCtrl,
//             options: MapOptions(
//               initialCenter: _pinPosition,
//               initialZoom: _defaultZoom,
//               onMapReady: () => setState(() => _mapReady = true),
//               onTap: _onMapTap,
//             ),
//             children: [
//               // OSM tile layer — no API key needed
//               TileLayer(
//                 urlTemplate:
//                     'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 userAgentPackageName: 'com.dealio.app',
//                 maxZoom: 19,
//               ),

//               // Pin marker
//               MarkerLayer(
//                 markers: [
//                   Marker(
//                     point: _pinPosition,
//                     width: 48,
//                     height: 56,
//                     alignment: Alignment.topCenter,
//                     child: const _PinWidget(),
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           // ── Top Header bar ────────────────────────────────────────────────
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: EdgeInsets.only(
//                 top: MediaQuery.of(context).padding.top + 8,
//                 bottom: 14,
//                 left: 16,
//                 right: 16,
//               ),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.black.withOpacity(0.65),
//                     Colors.transparent,
//                   ],
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(LucideIcons.mapPin,
//                       color: Colors.white, size: 22),
//                   const SizedBox(width: 10),
//                   const Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Set Your Home Location',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         Text(
//                           'Tap the map to move the pin',
//                           style: TextStyle(
//                             color: Colors.white70,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: _saving ? null : _skip,
//                     style: TextButton.styleFrom(
//                       foregroundColor: Colors.white70,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 6),
//                     ),
//                     child: const Text('Skip',
//                         style: TextStyle(fontSize: 13)),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // ── GPS loading indicator ─────────────────────────────────────────
//           if (_locating)
//             Positioned(
//               top: MediaQuery.of(context).padding.top + 70,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 10),
//                   decoration: BoxDecoration(
//                     color: isDark
//                         ? Colors.grey[850]
//                         : Colors.white,
//                     borderRadius: BorderRadius.circular(24),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.12),
//                         blurRadius: 8,
//                       ),
//                     ],
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       SizedBox(
//                         width: 14,
//                         height: 14,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: AppColors.primary,
//                         ),
//                       ),
//                       SizedBox(width: 10),
//                       Text(
//                         'Detecting your location…',
//                         style: TextStyle(fontSize: 13),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//           // ── Error pill ───────────────────────────────────────────────────
//           if (_errorMsg != null && !_locating)
//             Positioned(
//               top: MediaQuery.of(context).padding.top + 70,
//               left: 20,
//               right: 20,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 14, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.92),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(LucideIcons.triangleAlert,
//                         color: Colors.white, size: 16),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         _errorMsg!,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//           // ── Re-center FAB ─────────────────────────────────────────────────
//           Positioned(
//             right: 16,
//             bottom: 230,
//             child: FloatingActionButton.small(
//               heroTag: 'recenter',
//               backgroundColor: isDark ? Colors.grey[850] : Colors.white,
//               onPressed: _locating ? null : _recenterToCurrentLocation,
//               tooltip: 'Go to my location',
//               child: Icon(
//                 LucideIcons.crosshair,
//                 color: AppColors.primary,
//                 size: 20,
//               ),
//             ),
//           ),

//           // ── Bottom sheet ──────────────────────────────────────────────────
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: _BottomSheet(
//               addressLine: _addressLine,
//               governorate: _governorate,
//               pinPosition: _pinPosition,
//               saving: _saving,
//               onConfirm: _confirmLocation,
//               onSkip: _saving ? null : _skip,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Pin widget ───────────────────────────────────────────────────────────────

// class _PinWidget extends StatelessWidget {
//   const _PinWidget();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: AppColors.primary,
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.white, width: 2.5),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.primary.withOpacity(0.4),
//                 blurRadius: 8,
//                 spreadRadius: 2,
//               ),
//             ],
//           ),
//           child: const Icon(LucideIcons.house,
//               color: Colors.white, size: 18),
//         ),
//         // Stem
//         Container(
//           width: 3,
//           height: 14,
//           decoration: BoxDecoration(
//             color: AppColors.primary,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ─── Bottom sheet ─────────────────────────────────────────────────────────────

// class _BottomSheet extends StatelessWidget {
//   final String? addressLine;
//   final String? governorate;
//   final LatLng pinPosition;
//   final bool saving;
//   final VoidCallback onConfirm;
//   final VoidCallback? onSkip;

//   const _BottomSheet({
//     required this.addressLine,
//     required this.governorate,
//     required this.pinPosition,
//     required this.saving,
//     required this.onConfirm,
//     required this.onSkip,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     final String coordsLabel =
//         '${pinPosition.latitude.toStringAsFixed(5)}, '
//         '${pinPosition.longitude.toStringAsFixed(5)}';

//     return Container(
//       padding: EdgeInsets.fromLTRB(
//         20,
//         20,
//         20,
//         20 + MediaQuery.of(context).padding.bottom,
//       ),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.18),
//             blurRadius: 20,
//             offset: const Offset(0, -4),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Drag handle
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: isDark ? Colors.white24 : Colors.black12,
//                 borderRadius: BorderRadius.circular(99),
//               ),
//             ),
//           ),

//           // Address / coordinates
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(LucideIcons.mapPin,
//                     color: AppColors.primary, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       addressLine ?? 'Getting address…',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 14,
//                         color: isDark
//                             ? AppColors.darkTextPrimary
//                             : AppColors.secondary,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 3),
//                     Text(
//                       coordsLabel,
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: isDark
//                             ? AppColors.darkTextMuted
//                             : AppColors.textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           // Confirm button
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: saving ? null : onConfirm,
//               icon: saving
//                   ? const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     )
//                   : const Icon(LucideIcons.check, size: 18),
//               label: Text(saving ? 'Saving…' : 'Confirm This Location'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 textStyle: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w700,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 disabledBackgroundColor:
//                     AppColors.primary.withOpacity(0.5),
//               ),
//             ),
//           ),

//           if (onSkip != null) ...[
//             const SizedBox(height: 10),
//             SizedBox(
//               width: double.infinity,
//               child: TextButton(
//                 onPressed: onSkip,
//                 style: TextButton.styleFrom(
//                   foregroundColor: isDark
//                       ? AppColors.darkTextMuted
//                       : AppColors.textSecondary,
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                 ),
//                 child: const Text(
//                   'Skip for now',
//                   style: TextStyle(fontSize: 13),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/shipping_address_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:dealio/data/services/location_service.dart';
import 'package:dealio/features/home/screens/home_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
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

  String? _mapTilerKey;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadEnv();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tryGetCurrentLocation();
      }
    });
  }

  Future<void> _loadEnv() async {
    try {
      final jsonString = await rootBundle.loadString('assets/env.json');
      final config = json.decode(jsonString);
      if (mounted) {
        setState(() {
          _mapTilerKey = config['MAPTILER_API_KEY'];
        });
      }
    } catch (e) {
      debugPrint('⚠️ Could not load env.json in LocationOnboardingScreen: $e');
      if (mounted) {
        setState(() {
          _mapTilerKey = '';
        });
      }
    }
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  // ── Location helpers ──────────────────────────────────────────────────────

  Future<void> _tryGetCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _locating = true;
      _errorMsg = null;
    });

    try {
      final Position? pos = await LocationService.getPosition();
      if (!mounted) return;

      LatLng newPin = _cairoCentre;
      bool inEgypt = true;

      if (pos != null) {
        inEgypt =
            pos.latitude >= 22.0 &&
            pos.latitude <= 32.0 &&
            pos.longitude >= 24.0 &&
            pos.longitude <= 37.0;

        if (inEgypt) {
          newPin = LatLng(pos.latitude, pos.longitude);
        } else {
          _errorMsg = 'Location outside Egypt. Defaulting to Cairo.';
        }
      } else {
        _errorMsg = 'Could not detect location. Tap the map to set manually.';
      }

      setState(() {
        _pinPosition = newPin;
        _locating = false;
      });
      if (_mapReady) {
        _mapCtrl.move(newPin, _defaultZoom);
      }
      // Reverse geocode in background
      _reverseGeocode(newPin.latitude, newPin.longitude);
    } catch (e) {
      if (mounted) {
        setState(() {
          _locating = false;
          _pinPosition = _cairoCentre;
          _errorMsg = 'Location error. Tap the map to set manually.';
        });
        if (_mapReady) {
          _mapCtrl.move(_cairoCentre, _defaultZoom);
        }
        _reverseGeocode(_cairoCentre.latitude, _cairoCentre.longitude);
      }
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final result = await LocationService.reverseGeocode(lat, lng);
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _governorate = result.govCandidate ?? 'Gharbia';
          _city = result.cityCandidate ?? 'Tanta';
          final List<String> parts = [
            if (result.streetHint != null &&
                result.streetHint!.trim().isNotEmpty)
              result.streetHint!.trim(),
            if (result.cityCandidate != null &&
                result.cityCandidate!.trim().isNotEmpty)
              result.cityCandidate!.trim(),
            if (result.govCandidate != null &&
                result.govCandidate!.trim().isNotEmpty)
              result.govCandidate!.trim(),
          ];
          _addressLine = parts.isNotEmpty
              ? parts.join(', ')
              : '${_governorate ?? "Gharbia"} Governorate, Egypt';
        });
      } else {
        setState(() {
          _governorate = 'Gharbia';
          _city = 'Tanta';
          _addressLine = 'Gharbia Governorate, Egypt';
        });
      }
    } catch (e, stack) {
      debugPrint('⚠️ [LocationOnboarding] reverseGeocode error: $e\n$stack');
      if (mounted) {
        setState(() {
          _governorate ??= 'Gharbia';
          _city ??= 'Tanta';
          _addressLine ??= 'Gharbia Governorate, Egypt';
        });
      }
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
        addressLine1: (_addressLine != null && _addressLine!.isNotEmpty)
            ? _addressLine!
            : 'Home Location',
        city: (_city != null && _city!.isNotEmpty) ? _city! : 'Tanta',
        governorate: (_governorate != null && _governorate!.isNotEmpty)
            ? _governorate!
            : 'Gharbia',
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

  //   @override
  //   Widget build(BuildContext context) {
  //     final bool isDark = Theme.of(context).brightness == Brightness.dark;

  //     final bool isKeyLoading = _mapTilerKey == null;
  //     final bool hasMapTilerKey =
  //         _mapTilerKey != null && _mapTilerKey!.trim().isNotEmpty;

  //     // Dynamic high-DPI MapTiler raster tile templates (@2x for crisp retina display) with Arabic labels,
  //     // or fallback to OSM if key is missing
  //     final String tileUrl = hasMapTilerKey
  //         ? (isDark
  //               ? 'https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}@2x.png?key=$_mapTilerKey&lang=ar'
  //               : 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}@2x.png?key=$_mapTilerKey&lang=ar')
  //         : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  //     return Scaffold(
  //       body: Stack(
  //         children: [
  //           // ── Map ──────────────────────────────────────────────────────────
  //           if (isKeyLoading)
  //             const SizedBox.expand(
  //               child: Center(
  //                 child: CircularProgressIndicator(color: AppColors.primary),
  //               ),
  //             )
  //           else
  //             SizedBox.expand(
  //               child: FlutterMap(
  //                 mapController: _mapCtrl,
  //                 options: MapOptions(
  //                   initialCenter: _pinPosition,
  //                   initialZoom: _defaultZoom,
  //                   minZoom: 3.0,
  //                   maxZoom: 20.0,
  //                   onMapReady: () {
  //                     if (mounted) {
  //                       setState(() => _mapReady = true);
  //                     }
  //                   },
  //                   onTap: _onMapTap,
  //                   // Note: onPositionChanged is intentionally not attached to setState
  //                   // to ensure 60/120fps pan/zoom gestures without re-rendering the widget tree.
  //                 ),
  //                 children: [
  //                   // High-performance MapTiler @2x tiles with auto-cancellation and retina support
  //                   TileLayer(
  //                     key: ValueKey(tileUrl),
  //                     urlTemplate: tileUrl,
  //                     userAgentPackageName: 'com.dealio.app',
  //                     tileProvider: CancellableNetworkTileProvider(),
  //                     retinaMode: true,
  //                     maxNativeZoom: 18,
  //                     maxZoom: 20.0,
  //                   ),

  //                   // Pin marker
  //                   MarkerLayer(
  //                     markers: [
  //                       Marker(
  //                         point: _pinPosition,
  //                         width: 48,
  //                         height: 56,
  //                         alignment: Alignment.topCenter,
  //                         child: const _PinWidget(),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),

  //           // ── Top Header bar ────────────────────────────────────────────────
  //           Positioned(
  //             top: 0,
  //             left: 0,
  //             right: 0,
  //             child: Container(
  //               padding: EdgeInsets.only(
  //                 top: MediaQuery.of(context).padding.top + 8,
  //                 bottom: 14,
  //                 left: 16,
  //                 right: 16,
  //               ),
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   begin: Alignment.topCenter,
  //                   end: Alignment.bottomCenter,
  //                   colors: [Colors.black.withOpacity(0.65), Colors.transparent],
  //                 ),
  //               ),
  //               child: Row(
  //                 children: [
  //                   const Icon(LucideIcons.mapPin, color: Colors.white, size: 22),
  //                   const SizedBox(width: 10),
  //                   const Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           'Set Your Home Location',
  //                           style: TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.w700,
  //                           ),
  //                         ),
  //                         Text(
  //                           'Tap the map to move the pin',
  //                           style: TextStyle(color: Colors.white70, fontSize: 12),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   TextButton(
  //                     onPressed: _saving ? null : _skip,
  //                     style: TextButton.styleFrom(
  //                       foregroundColor: Colors.white70,
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 12,
  //                         vertical: 6,
  //                       ),
  //                     ),
  //                     child: const Text('Skip', style: TextStyle(fontSize: 13)),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),

  //           // ── GPS loading indicator ─────────────────────────────────────────
  //           if (_locating)
  //             Positioned(
  //               top: MediaQuery.of(context).padding.top + 70,
  //               left: 0,
  //               right: 0,
  //               child: Center(
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 16,
  //                     vertical: 10,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: isDark ? Colors.grey[850] : Colors.white,
  //                     borderRadius: BorderRadius.circular(24),
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: Colors.black.withOpacity(0.12),
  //                         blurRadius: 8,
  //                       ),
  //                     ],
  //                   ),
  //                   child: const Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       SizedBox(
  //                         width: 14,
  //                         height: 14,
  //                         child: CircularProgressIndicator(
  //                           strokeWidth: 2,
  //                           color: AppColors.primary,
  //                         ),
  //                       ),
  //                       SizedBox(width: 10),
  //                       Text(
  //                         'Detecting your location…',
  //                         style: TextStyle(fontSize: 13),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),

  //           // ── Error pill ───────────────────────────────────────────────────
  //           if (_errorMsg != null && !_locating)
  //             Positioned(
  //               top: MediaQuery.of(context).padding.top + 70,
  //               left: 20,
  //               right: 20,
  //               child: Align(
  //                 alignment: Alignment.topCenter,
  //                 child: ConstrainedBox(
  //                   constraints: const BoxConstraints(maxWidth: 500),
  //                   child: Container(
  //                     padding: const EdgeInsets.symmetric(
  //                       horizontal: 14,
  //                       vertical: 10,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: Colors.orange.withOpacity(0.92),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     child: Row(
  //                       children: [
  //                         const Icon(
  //                           LucideIcons.triangleAlert,
  //                           color: Colors.white,
  //                           size: 16,
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Expanded(
  //                           child: Text(
  //                             _errorMsg!,
  //                             style: const TextStyle(
  //                               color: Colors.white,
  //                               fontSize: 12,
  //                               fontWeight: FontWeight.w500,
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),

  //           // ── Re-center FAB ─────────────────────────────────────────────────
  //           Positioned(
  //             right: 16,
  //             bottom: 230,
  //             child: FloatingActionButton.small(
  //               heroTag: 'recenter',
  //               backgroundColor: isDark ? Colors.grey[850] : Colors.white,
  //               onPressed: _locating ? null : _recenterToCurrentLocation,
  //               tooltip: 'Go to my location',
  //               child: Icon(
  //                 LucideIcons.crosshair,
  //                 color: AppColors.primary,
  //                 size: 20,
  //               ),
  //             ),
  //           ),

  //           // ── Bottom sheet ──────────────────────────────────────────────────
  //           Positioned(
  //             left: 0,
  //             right: 0,
  //             bottom: 0,
  //             child: Align(
  //               alignment: Alignment.bottomCenter,
  //               child: ConstrainedBox(
  //                 constraints: const BoxConstraints(maxWidth: 500),
  //                 child: _BottomSheet(
  //                   addressLine: _addressLine,
  //                   governorate: _governorate,
  //                   pinPosition: _pinPosition,
  //                   saving: _saving,
  //                   onConfirm: _confirmLocation,
  //                   onSkip: _saving ? null : _skip,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  // // ─── Pin widget ───────────────────────────────────────────────────────────────

  // class _PinWidget extends StatelessWidget {
  //   const _PinWidget();

  //   @override
  //   Widget build(BuildContext context) {
  //     return Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Container(
  //           width: 36,
  //           height: 36,
  //           decoration: BoxDecoration(
  //             color: AppColors.primary,
  //             shape: BoxShape.circle,
  //             border: Border.all(color: AppColors.secondary, width: 2.5),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: AppColors.primary.withOpacity(0.4),
  //                 blurRadius: 8,
  //                 spreadRadius: 2,
  //               ),
  //             ],
  //           ),
  //           child: const Icon(
  //             LucideIcons.house,
  //             color: AppColors.secondary,
  //             size: 18,
  //           ),
  //         ),
  //         // Stem
  //         Container(
  //           width: 3,
  //           height: 14,
  //           decoration: BoxDecoration(
  //             color: AppColors.primary,
  //             borderRadius: BorderRadius.circular(2),
  //           ),
  //         ),
  //       ],
  //     );
  //   }
  // }

  // class _BottomSheet extends StatelessWidget {
  //   final String? addressLine;
  //   final String? governorate;
  //   final LatLng pinPosition;
  //   final bool saving;
  //   final VoidCallback onConfirm;
  //   final VoidCallback? onSkip;

  //   const _BottomSheet({
  //     required this.addressLine,
  //     required this.governorate,
  //     required this.pinPosition,
  //     required this.saving,
  //     required this.onConfirm,
  //     required this.onSkip,
  //   });

  //   @override
  //   Widget build(BuildContext context) {
  //     final bool isDark = Theme.of(context).brightness == Brightness.dark;
  //     final Color textColor = isDark
  //         ? AppColors.darkTextPrimary
  //         : AppColors.secondary;
  //     final Color secondaryTextColor = isDark
  //         ? AppColors.darkTextSecondary
  //         : Colors.grey[600]!;
  //     final double bottomInset = MediaQuery.of(context).padding.bottom;
  //     final String coordsLabel =
  //         '${pinPosition.latitude.toStringAsFixed(5)}, ${pinPosition.longitude.toStringAsFixed(5)}';

  //     return Container(
  //       margin: R.isLargeScreen(context)
  //           ? R.all(context, 20)
  //           : EdgeInsets.fromLTRB(
  //               R.r(context, 15),
  //               0,
  //               R.r(context, 15),
  //               R.r(context, 15) + bottomInset,
  //             ),
  //       padding: R.all(context, 20),
  //       decoration: BoxDecoration(
  //         color: isDark ? AppColors.darkSurface : Theme.of(context).cardColor,
  //         borderRadius: BorderRadius.circular(R.r(context, 25)),
  //         boxShadow: [
  //           BoxShadow(
  //             color: isDark ? Colors.black26 : AppColors.black.withOpacity(0.07),
  //             blurRadius: R.r(context, 30),
  //             offset: const Offset(0, 12),
  //           ),
  //         ],
  //         border: isDark ? Border.all(color: AppColors.darkBorder) : null,
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Drag handle (Mobile viewports)
  //           if (!R.isLargeScreen(context))
  //             Center(
  //               child: Container(
  //                 width: R.w(context, 36),
  //                 height: R.h(context, 4),
  //                 margin: EdgeInsets.only(bottom: R.h(context, 16)),
  //                 decoration: BoxDecoration(
  //                   color: isDark ? Colors.white24 : Colors.black12,
  //                   borderRadius: BorderRadius.circular(99),
  //                 ),
  //               ),
  //             ),

  //           // Location Info Card (Matching Auth Input/Card Style)
  //           Container(
  //             padding: R.all(context, 14),
  //             decoration: BoxDecoration(
  //               color: isDark ? AppColors.darkBackground : AppColors.fillColor,
  //               borderRadius: BorderRadius.circular(R.r(context, 16)),
  //               border: Border.all(
  //                 color: isDark
  //                     ? Colors.white.withOpacity(0.08)
  //                     : Colors.black.withOpacity(0.05),
  //               ),
  //             ),
  //             child: Row(
  //               children: [
  //                 // Glowing Icon Badge (Matching OTP/Auth Icons)
  //                 Container(
  //                   padding: R.all(context, 10),
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     gradient: RadialGradient(
  //                       colors: [
  //                         AppColors.primary.withOpacity(0.25),
  //                         AppColors.primary.withOpacity(0.05),
  //                       ],
  //                     ),
  //                     border: Border.all(
  //                       color: AppColors.primary.withOpacity(0.2),
  //                       width: 1,
  //                     ),
  //                   ),
  //                   child: Icon(
  //                     LucideIcons.mapPin,
  //                     size: R.font(context, 22),
  //                     color: AppColors.primary,
  //                   ),
  //                 ),
  //                 SizedBox(width: R.w(context, 12)),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         (addressLine != null && addressLine!.trim().isNotEmpty)
  //                             ? addressLine!
  //                             : 'Getting address…',
  //                         style: TextStyle(
  //                           fontWeight: FontWeight.bold,
  //                           fontSize: R.font(context, 14),
  //                           color: textColor,
  //                         ),
  //                         maxLines: 2,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       SizedBox(height: R.h(context, 4)),
  //                       Text(
  //                         coordsLabel,
  //                         style: TextStyle(
  //                           fontSize: R.font(context, 11),
  //                           color: secondaryTextColor,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),

  //           SizedBox(height: R.h(context, 20)),

  //           // Confirm Button (With 360 Glow & Adaptive Loader)
  //           Container(
  //             width: double.infinity,
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(R.r(context, 12)),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: saving
  //                       ? Colors.transparent
  //                       : AppColors.primary.withOpacity(0.35),
  //                   blurRadius: 16,
  //                   spreadRadius: 1,
  //                   offset: Offset.zero,
  //                 ),
  //               ],
  //             ),
  //             child: ElevatedButton(
  //               onPressed: saving ? null : onConfirm,
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: AppColors.primary,
  //                 disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
  //                 foregroundColor: AppColors.secondary,
  //                 elevation: 0,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(R.r(context, 12)),
  //                 ),
  //                 padding: R.symmetric(context, vertical: 15),
  //               ),
  //               child: saving
  //                   ? SizedBox(
  //                       height: R.r(context, 22),
  //                       width: R.r(context, 22),
  //                       child: kIsWeb
  //                           ? const CircularProgressIndicator(
  //                               strokeWidth: 2.5,
  //                               valueColor: AlwaysStoppedAnimation<Color>(
  //                                 AppColors.secondary,
  //                               ),
  //                             )
  //                           : Lottie.asset(
  //                               'assets/animations/dealio_loading_js.json',
  //                               fit: BoxFit.contain,
  //                             ),
  //                     )
  //                   : Text(
  //                       'Confirm This Location',
  //                       style: TextStyle(
  //                         fontSize: R.font(context, 16),
  //                         fontWeight: FontWeight.bold,
  //                         letterSpacing: 0.5,
  //                       ),
  //                     ),
  //             ),
  //           ),

  //           // Skip Button
  //           if (onSkip != null) ...[
  //             SizedBox(height: R.h(context, 10)),
  //             SizedBox(
  //               width: double.infinity,
  //               child: TextButton(
  //                 onPressed: saving ? null : onSkip,
  //                 style: TextButton.styleFrom(
  //                   foregroundColor: secondaryTextColor,
  //                   padding: R.symmetric(context, vertical: 10),
  //                 ),
  //                 child: Text(
  //                   'Skip for now',
  //                   style: TextStyle(
  //                     fontSize: R.font(context, 13),
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ],
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isKeyLoading = _mapTilerKey == null;
    final bool hasMapTilerKey =
        _mapTilerKey != null && _mapTilerKey!.trim().isNotEmpty;

    // Dynamic high-DPI MapTiler raster tile templates (@2x for crisp retina display) with Arabic labels,
    // or fallback to OSM if key is missing
    final String tileUrl = hasMapTilerKey
        ? (isDark
              ? 'https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}@2x.png?key=$_mapTilerKey&lang=ar'
              : 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}@2x.png?key=$_mapTilerKey&lang=ar')
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    // MapTiler @2x serves tiles at requested {z} rendered at 512px (double density).
    // tileSize: 512 + zoomOffset: -1 re-aligns flutter_map's coordinate→tile mapping
    // so the pin lands on Egypt, not the ocean. OSM stays at 256 / zoomOffset 0.
    final double tileSize = hasMapTilerKey ? 512.0 : 256.0;
    final int zoomOffset = hasMapTilerKey ? -1 : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          if (isKeyLoading)
            SizedBox.expand(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            SizedBox.expand(
              child: FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: _pinPosition,
                  initialZoom: _defaultZoom,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  onMapReady: () {
                    if (mounted) {
                      setState(() => _mapReady = true);
                    }
                  },
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    key: ValueKey(tileUrl),
                    urlTemplate: tileUrl,
                    userAgentPackageName: 'com.dealio.app',
                    tileProvider: CancellableNetworkTileProvider(),
                    tileSize: tileSize,
                    zoomOffset: hasMapTilerKey ? -1.0 : 0.0,
                    retinaMode: false,
                    maxNativeZoom: 18,
                    maxZoom: 18.0,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pinPosition,
                        width: R.w(context, 48),
                        height: R.h(context, 58),
                        alignment: Alignment.topCenter,
                        child: const _PinWidget(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── Top Header bar ────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + R.h(context, 8),
                bottom: R.h(context, 16),
                left: R.w(context, 16),
                right: R.w(context, 16),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Colors.black.withOpacity(0.85)
                        : Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: R.all(context, 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.mapPin,
                      color: AppColors.primary,
                      size: R.font(context, 20),
                    ),
                  ),
                  SizedBox(width: R.w(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Your Home Location',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: R.font(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: R.h(context, 2)),
                        Text(
                          'Tap the map to move the pin',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.75),
                            fontSize: R.font(context, 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white.withOpacity(0.85),
                      padding: R.symmetric(
                        context,
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: R.font(context, 13),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── GPS loading indicator ─────────────────────────────────────────
          if (_locating)
            Positioned(
              top: MediaQuery.of(context).padding.top + R.h(context, 75),
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: R.symmetric(context, horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(R.r(context, 24)),
                    border: isDark
                        ? Border.all(color: AppColors.darkBorder)
                        : Border.all(color: Colors.black.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black38
                            : AppColors.black.withOpacity(0.12),
                        blurRadius: R.r(context, 16),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: R.r(context, 16),
                        height: R.r(context, 16),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: R.w(context, 10)),
                      Text(
                        'Detecting your location…',
                        style: TextStyle(
                          fontSize: R.font(context, 13),
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Error pill ───────────────────────────────────────────────────
          if (_errorMsg != null && !_locating)
            Positioned(
              top: MediaQuery.of(context).padding.top + R.h(context, 75),
              left: R.w(context, 20),
              right: R.w(context, 20),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    padding: R.symmetric(context, horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(R.r(context, 12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.triangleAlert,
                          color: AppColors.white,
                          size: R.font(context, 18),
                        ),
                        SizedBox(width: R.w(context, 10)),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: R.font(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Re-center FAB ─────────────────────────────────────────────────
          Positioned(
            right: R.w(context, 16),
            bottom: R.h(context, 230),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black45
                        : AppColors.black.withOpacity(0.15),
                    blurRadius: R.r(context, 12),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: isDark
                    ? AppColors.darkSurface
                    : Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                  side: isDark
                      ? const BorderSide(color: AppColors.darkBorder)
                      : BorderSide.none,
                ),
                onPressed: _locating ? null : _recenterToCurrentLocation,
                tooltip: 'Go to my location',
                child: Icon(
                  LucideIcons.crosshair,
                  color: AppColors.primary,
                  size: R.font(context, 20),
                ),
              ),
            ),
          ),

          // ── Bottom sheet ──────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _BottomSheet(
                  addressLine: _addressLine,
                  governorate: _governorate,
                  pinPosition: _pinPosition,
                  saving: _saving,
                  onConfirm: _confirmLocation,
                  onSkip: _saving ? null : _skip,
                ),
              ),
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
          width: R.r(context, 40),
          height: R.r(context, 40),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.secondary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.45),
                blurRadius: R.r(context, 12),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            LucideIcons.house,
            color: AppColors.secondary,
            size: R.font(context, 20),
          ),
        ),
        // Stem
        Container(
          width: R.w(context, 3.5),
          height: R.h(context, 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Sheet ──────────────────────────────────────────────────────────────

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
    final Color textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.secondary;
    final Color secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey[600]!;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final String coordsLabel =
        '${pinPosition.latitude.toStringAsFixed(5)}, ${pinPosition.longitude.toStringAsFixed(5)}';

    return Container(
      margin: R.isLargeScreen(context)
          ? R.all(context, 20)
          : EdgeInsets.fromLTRB(
              R.r(context, 15),
              0,
              R.r(context, 15),
              R.r(context, 15) + bottomInset,
            ),
      padding: R.all(context, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(R.r(context, 25)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : AppColors.black.withOpacity(0.07),
            blurRadius: R.r(context, 30),
            offset: const Offset(0, 12),
          ),
        ],
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle (Mobile viewports)
          if (!R.isLargeScreen(context))
            Center(
              child: Container(
                width: R.w(context, 36),
                height: R.h(context, 4),
                margin: EdgeInsets.only(bottom: R.h(context, 16)),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

          // Location Info Card
          Container(
            padding: R.all(context, 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.fillColor,
              borderRadius: BorderRadius.circular(R.r(context, 16)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: R.all(context, 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.25),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.mapPin,
                    size: R.font(context, 22),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: R.w(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (addressLine != null && addressLine!.trim().isNotEmpty)
                            ? addressLine!
                            : 'Getting address…',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: R.font(context, 14),
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: R.h(context, 4)),
                      Text(
                        coordsLabel,
                        style: TextStyle(
                          fontSize: R.font(context, 11),
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: R.h(context, 20)),

          // Confirm Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(R.r(context, 12)),
              boxShadow: [
                BoxShadow(
                  color: saving
                      ? Colors.transparent
                      : AppColors.primary.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: saving ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                foregroundColor: AppColors.secondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(R.r(context, 12)),
                ),
                padding: R.symmetric(context, vertical: 15),
              ),
              child: saving
                  ? SizedBox(
                      height: R.r(context, 22),
                      width: R.r(context, 22),
                      child: kIsWeb
                          ? const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.secondary,
                              ),
                            )
                          : Lottie.asset(
                              'assets/animations/dealio_loading_js.json',
                              fit: BoxFit.contain,
                            ),
                    )
                  : Text(
                      'Confirm This Location',
                      style: TextStyle(
                        fontSize: R.font(context, 16),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),

          // Skip Button
          if (onSkip != null) ...[
            SizedBox(height: R.h(context, 10)),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: saving ? null : onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: secondaryTextColor,
                  padding: R.symmetric(context, vertical: 10),
                ),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: R.font(context, 13),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
