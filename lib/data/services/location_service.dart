/// location_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Cross-platform location service (Web + Mobile) using the `geolocator` package.
/// Reverse geocoding is done via the Nominatim OpenStreetMap API (free, no key).
///
/// Usage:
///   final result = await LocationService.detectAndGeocode();
///   if (result != null) {
///     print(result.lat);
///     print(result.govCandidate); // e.g. "Cairo"
///     print(result.cityCandidate); // e.g. "Nasr City"
///     print(result.streetHint);   // e.g. "15 El Nozha Street"
///   }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final double lat;
  final double lng;

  /// Raw governorate string from Nominatim (may be Arabic or English)
  final String rawState;

  /// Best-match governorate from EgyptGeoData (null if no match found)
  final String? govCandidate;

  /// Best-match city from EgyptGeoData (null if no match found)
  final String? cityCandidate;

  /// Street / road hint for the address line
  final String? streetHint;

  const LocationResult({
    required this.lat,
    required this.lng,
    required this.rawState,
    this.govCandidate,
    this.cityCandidate,
    this.streetHint,
  });
}

class LocationService {
  LocationService._();

  // ── Nominatim reverse-geocoding endpoint ─────────────────────────────────
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/reverse';

  // ── Arabic → English governorate mapping ─────────────────────────────────
  // Covers the most common Arabic spellings returned by Nominatim for Egypt.
  static const Map<String, String> _arToEn = {
    'القاهرة': 'Cairo',
    'الجيزة': 'Giza',
    'الإسكندرية': 'Alexandria',
    'اسكندريه': 'Alexandria',
    'القليوبية': 'Qalyubia',
    'الشرقية': 'Sharqia',
    'الدقهلية': 'Dakahlia',
    'الغربية': 'Gharbia',
    'المنوفية': 'Monufia',
    'كفر الشيخ': 'Kafr El Sheikh',
    'البحيرة': 'Beheira',
    'دمياط': 'Damietta',
    'بورسعيد': 'Port Said',
    'الإسماعيلية': 'Ismailia',
    'السويس': 'Suez',
    'شمال سيناء': 'North Sinai',
    'جنوب سيناء': 'South Sinai',
    'مطروح': 'Matrouh',
    'الفيوم': 'Faiyum',
    'بني سويف': 'Beni Suef',
    'المنيا': 'Minya',
    'أسيوط': 'Asyut',
    'سوهاج': 'Sohag',
    'قنا': 'Qena',
    'الأقصر': 'Luxor',
    'أسوان': 'Aswan',
    'البحر الأحمر': 'Red Sea',
    'الوادي الجديد': 'New Valley',
  };

  // ── English name → canonical governorate (for Nominatim English responses) ─
  // Nominatim may return non-standard English variations; map them all.
  static const Map<String, String> _enVariants = {
    // Giza
    'giza': 'Giza',
    'al jizah': 'Giza',
    'al-jizah': 'Giza',
    'aljizah': 'Giza',
    'giza governorate': 'Giza',
    'muhafazat al jizah': 'Giza',
    // Cairo
    'cairo': 'Cairo',
    'al qahirah': 'Cairo',
    'al-qahirah': 'Cairo',
    'cairo governorate': 'Cairo',
    // Alexandria
    'alexandria': 'Alexandria',
    'al iskandariyah': 'Alexandria',
    'al-iskandariyah': 'Alexandria',
    // Qalyubia
    'qalyubia': 'Qalyubia',
    'al qalyubiyah': 'Qalyubia',
    'qalyubiyah': 'Qalyubia',
    // Sharqia
    'sharqia': 'Sharqia',
    'ash sharqiyah': 'Sharqia',
    'sharqiyah': 'Sharqia',
    // Dakahlia
    'dakahlia': 'Dakahlia',
    'ad daqahliyah': 'Dakahlia',
    'daqahliyah': 'Dakahlia',
    // Gharbia
    'gharbia': 'Gharbia',
    'al gharbiyah': 'Gharbia',
    'gharbiyah': 'Gharbia',
    // Monufia
    'monufia': 'Monufia',
    'al minufiyah': 'Monufia',
    'minufiyah': 'Monufia',
    // Kafr El Sheikh
    'kafr el sheikh': 'Kafr El Sheikh',
    'kafr ash shaykh': 'Kafr El Sheikh',
    // Beheira
    'beheira': 'Beheira',
    'al buhayrah': 'Beheira',
    // Damietta
    'damietta': 'Damietta',
    'dumyat': 'Damietta',
    // Port Said
    'port said': 'Port Said',
    'bur said': 'Port Said',
    // Ismailia
    'ismailia': 'Ismailia',
    'al ismaилiyah': 'Ismailia',
    // Suez
    'suez': 'Suez',
    'as suways': 'Suez',
    // Sinai
    'north sinai': 'North Sinai',
    'sinai': 'North Sinai',
    'south sinai': 'South Sinai',
    // Matrouh
    'matrouh': 'Matrouh',
    'matruh': 'Matrouh',
    // Faiyum
    'faiyum': 'Faiyum',
    'al fayyum': 'Faiyum',
    // Beni Suef
    'beni suef': 'Beni Suef',
    'bani suwayf': 'Beni Suef',
    // Minya
    'minya': 'Minya',
    'al minya': 'Minya',
    // Asyut
    'asyut': 'Asyut',
    'asyut governorate': 'Asyut',
    'assiut': 'Asyut',
    // Sohag
    'sohag': 'Sohag',
    'suhaj': 'Sohag',
    // Qena
    'qena': 'Qena',
    'qina': 'Qena',
    // Luxor
    'luxor': 'Luxor',
    'al uqsur': 'Luxor',
    // Aswan
    'aswan': 'Aswan',
    'aswan governorate': 'Aswan',
    // Red Sea
    'red sea': 'Red Sea',
    'al bahr al ahmar': 'Red Sea',
    // New Valley
    'new valley': 'New Valley',
    'al wadi al jadid': 'New Valley',
  };

  // ── Governorates list (must stay in sync with EgyptGeoData) ──────────────
  static const List<String> _egyptGovs = [
    'Cairo', 'Giza', 'Alexandria', 'Qalyubia', 'Sharqia', 'Dakahlia',
    'Gharbia', 'Monufia', 'Kafr El Sheikh', 'Beheira', 'Damietta',
    'Port Said', 'Ismailia', 'Suez', 'North Sinai', 'South Sinai',
    'Matrouh', 'Faiyum', 'Beni Suef', 'Minya', 'Asyut', 'Sohag',
    'Qena', 'Luxor', 'Aswan', 'Red Sea', 'New Valley',
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Request location permission and get current coordinates.
  /// Returns null if permission is denied or location is unavailable.
  static Future<Position?> getPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ [Location] Location service disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ [Location] Permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ [Location] Permission permanently denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      debugPrint(
        '📍 [Location] Got position: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('❌ [Location] getPosition error: $e');
      return null;
    }
  }

  /// Full pipeline: get GPS coords → reverse geocode via Nominatim →
  /// map to Egyptian governorate/city candidates.
  /// Returns null if any step fails.
  static Future<LocationResult?> detectAndGeocode() async {
    final pos = await getPosition();
    if (pos == null) return null;
    return reverseGeocode(pos.latitude, pos.longitude);
  }

  /// Reverse geocode a lat/lng pair using Nominatim OpenStreetMap API.
  static Future<LocationResult?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        '$_nominatimUrl?lat=$lat&lon=$lng&format=json&accept-language=en&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'Dealio-Flutter-App/1.0 (contact@dealio.app)'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('⚠️ [Location] Nominatim error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>? ?? {};

      debugPrint('📍 [Location] Nominatim response: $address');

      // ── Extract raw fields ──────────────────────────────────────────────
      final rawState = (address['state'] ?? address['county'] ?? '').toString();
      final rawCity = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['suburb'] ??
              address['neighbourhood'] ??
              '')
          .toString();
      final rawRoad = (address['road'] ??
              address['pedestrian'] ??
              address['footway'] ??
              '')
          .toString();
      final houseNumber = (address['house_number'] ?? '').toString();
      final streetHint = [
        if (houseNumber.isNotEmpty) houseNumber,
        if (rawRoad.isNotEmpty) rawRoad,
      ].join(' ').trim();

      // ── Map to EgyptGeoData governorate ────────────────────────────────
      final govCandidate = _matchGovernorate(rawState);

      // ── Best-effort city match ──────────────────────────────────────────
      final cityCandidate = rawCity.isNotEmpty ? rawCity : null;

      return LocationResult(
        lat: lat,
        lng: lng,
        rawState: rawState,
        govCandidate: govCandidate,
        cityCandidate: cityCandidate,
        streetHint: streetHint.isEmpty ? null : streetHint,
      );
    } catch (e) {
      debugPrint('❌ [Location] reverseGeocode error: $e');
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

  /// Try to match [rawState] to one of the EgyptGeoData governorates.
  /// Priority:
  ///   1. Arabic map (_arToEn)
  ///   2. English variant map (_enVariants) — handles "Al Jizah", "Giza Governorate", etc.
  ///   3. Exact case-insensitive match against _egyptGovs
  ///   4. Fuzzy contains match
  static String? _matchGovernorate(String rawState) {
    if (rawState.isEmpty) return null;

    // 1. Arabic → English direct map
    final fromArabic = _arToEn[rawState.trim()];
    if (fromArabic != null) return fromArabic;

    // 2. English variant map (handles Nominatim transliterations)
    final lower = rawState.trim().toLowerCase();
    final fromVariant = _enVariants[lower];
    if (fromVariant != null) return fromVariant;

    // Also try normalizing (strip dashes/spaces) then check variants
    final norm = _normalize(rawState);
    for (final entry in _enVariants.entries) {
      if (_normalize(entry.key) == norm) return entry.value;
    }

    // 3. Exact English match against the canonical list (case-insensitive)
    for (final gov in _egyptGovs) {
      if (_normalize(gov) == norm) return gov;
    }

    // 4. Contains match (e.g. "Governorate of Cairo" → "Cairo")
    for (final gov in _egyptGovs) {
      if (norm.contains(_normalize(gov)) ||
          _normalize(gov).contains(norm)) {
        return gov;
      }
    }

    debugPrint(
      '⚠️ [Location] Could not map "$rawState" to an Egyptian governorate',
    );
    return null;
  }
}
