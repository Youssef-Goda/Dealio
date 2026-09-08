// /// location_service.dart
// /// ─────────────────────────────────────────────────────────────────────────────
// /// Cross-platform location service (Web + Mobile) using the `geolocator` package.
// /// Reverse geocoding is done via the Nominatim OpenStreetMap API (free, no key).
// ///
// /// Usage:
// ///   final result = await LocationService.detectAndGeocode();
// ///   if (result != null) {
// ///     print(result.lat);
// ///     print(result.govCandidate); // e.g. "Cairo"
// ///     print(result.cityCandidate); // e.g. "Nasr City"
// ///     print(result.streetHint);   // e.g. "15 El Nozha Street"
// ///   }

// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;

// class LocationResult {
//   final double lat;
//   final double lng;

//   /// Raw governorate string from Nominatim (may be Arabic or English)
//   final String rawState;

//   /// Best-match governorate from EgyptGeoData (null if no match found)
//   final String? govCandidate;

//   /// Best-match city from EgyptGeoData (null if no match found)
//   final String? cityCandidate;

//   /// Street / road hint for the address line
//   final String? streetHint;

//   const LocationResult({
//     required this.lat,
//     required this.lng,
//     required this.rawState,
//     this.govCandidate,
//     this.cityCandidate,
//     this.streetHint,
//   });
// }

// class LocationService {
//   LocationService._();

//   // ── Nominatim reverse-geocoding endpoint ─────────────────────────────────
//   static const String _nominatimUrl =
//       'https://nominatim.openstreetmap.org/reverse';

//   // ── Arabic → English governorate mapping ─────────────────────────────────
//   // Covers the most common Arabic spellings returned by Nominatim for Egypt.
//   static const Map<String, String> _arToEn = {
//     'القاهرة': 'Cairo',
//     'الجيزة': 'Giza',
//     'الإسكندرية': 'Alexandria',
//     'اسكندريه': 'Alexandria',
//     'القليوبية': 'Qalyubia',
//     'الشرقية': 'Sharqia',
//     'الدقهلية': 'Dakahlia',
//     'الغربية': 'Gharbia',
//     'المنوفية': 'Monufia',
//     'كفر الشيخ': 'Kafr El Sheikh',
//     'البحيرة': 'Beheira',
//     'دمياط': 'Damietta',
//     'بورسعيد': 'Port Said',
//     'الإسماعيلية': 'Ismailia',
//     'السويس': 'Suez',
//     'شمال سيناء': 'North Sinai',
//     'جنوب سيناء': 'South Sinai',
//     'مطروح': 'Matrouh',
//     'الفيوم': 'Faiyum',
//     'بني سويف': 'Beni Suef',
//     'المنيا': 'Minya',
//     'أسيوط': 'Asyut',
//     'سوهاج': 'Sohag',
//     'قنا': 'Qena',
//     'الأقصر': 'Luxor',
//     'أسوان': 'Aswan',
//     'البحر الأحمر': 'Red Sea',
//     'الوادي الجديد': 'New Valley',
//   };

//   // ── English name → canonical governorate (for Nominatim English responses) ─
//   // Nominatim may return non-standard English variations; map them all.
//   static const Map<String, String> _enVariants = {
//     // Giza
//     'giza': 'Giza',
//     'al jizah': 'Giza',
//     'al-jizah': 'Giza',
//     'aljizah': 'Giza',
//     'giza governorate': 'Giza',
//     'muhafazat al jizah': 'Giza',
//     // Cairo
//     'cairo': 'Cairo',
//     'al qahirah': 'Cairo',
//     'al-qahirah': 'Cairo',
//     'cairo governorate': 'Cairo',
//     // Alexandria
//     'alexandria': 'Alexandria',
//     'al iskandariyah': 'Alexandria',
//     'al-iskandariyah': 'Alexandria',
//     // Qalyubia
//     'qalyubia': 'Qalyubia',
//     'al qalyubiyah': 'Qalyubia',
//     'qalyubiyah': 'Qalyubia',
//     // Sharqia
//     'sharqia': 'Sharqia',
//     'ash sharqiyah': 'Sharqia',
//     'sharqiyah': 'Sharqia',
//     // Dakahlia
//     'dakahlia': 'Dakahlia',
//     'ad daqahliyah': 'Dakahlia',
//     'daqahliyah': 'Dakahlia',
//     // Gharbia
//     'gharbia': 'Gharbia',
//     'al gharbiyah': 'Gharbia',
//     'gharbiyah': 'Gharbia',
//     // Monufia
//     'monufia': 'Monufia',
//     'al minufiyah': 'Monufia',
//     'minufiyah': 'Monufia',
//     // Kafr El Sheikh
//     'kafr el sheikh': 'Kafr El Sheikh',
//     'kafr ash shaykh': 'Kafr El Sheikh',
//     // Beheira
//     'beheira': 'Beheira',
//     'al buhayrah': 'Beheira',
//     // Damietta
//     'damietta': 'Damietta',
//     'dumyat': 'Damietta',
//     // Port Said
//     'port said': 'Port Said',
//     'bur said': 'Port Said',
//     // Ismailia
//     'ismailia': 'Ismailia',
//     'al ismaилiyah': 'Ismailia',
//     // Suez
//     'suez': 'Suez',
//     'as suways': 'Suez',
//     // Sinai
//     'north sinai': 'North Sinai',
//     'sinai': 'North Sinai',
//     'south sinai': 'South Sinai',
//     // Matrouh
//     'matrouh': 'Matrouh',
//     'matruh': 'Matrouh',
//     // Faiyum
//     'faiyum': 'Faiyum',
//     'al fayyum': 'Faiyum',
//     // Beni Suef
//     'beni suef': 'Beni Suef',
//     'bani suwayf': 'Beni Suef',
//     // Minya
//     'minya': 'Minya',
//     'al minya': 'Minya',
//     // Asyut
//     'asyut': 'Asyut',
//     'asyut governorate': 'Asyut',
//     'assiut': 'Asyut',
//     // Sohag
//     'sohag': 'Sohag',
//     'suhaj': 'Sohag',
//     // Qena
//     'qena': 'Qena',
//     'qina': 'Qena',
//     // Luxor
//     'luxor': 'Luxor',
//     'al uqsur': 'Luxor',
//     // Aswan
//     'aswan': 'Aswan',
//     'aswan governorate': 'Aswan',
//     // Red Sea
//     'red sea': 'Red Sea',
//     'al bahr al ahmar': 'Red Sea',
//     // New Valley
//     'new valley': 'New Valley',
//     'al wadi al jadid': 'New Valley',
//   };

//   // ── Governorates list (must stay in sync with EgyptGeoData) ──────────────
//   static const List<String> _egyptGovs = [
//     'Cairo', 'Giza', 'Alexandria', 'Qalyubia', 'Sharqia', 'Dakahlia',
//     'Gharbia', 'Monufia', 'Kafr El Sheikh', 'Beheira', 'Damietta',
//     'Port Said', 'Ismailia', 'Suez', 'North Sinai', 'South Sinai',
//     'Matrouh', 'Faiyum', 'Beni Suef', 'Minya', 'Asyut', 'Sohag',
//     'Qena', 'Luxor', 'Aswan', 'Red Sea', 'New Valley',
//   ];

//   // ── Public API ────────────────────────────────────────────────────────────

//   /// Request location permission and get current coordinates.
//   /// Returns null if permission is denied or location is unavailable.
//   static Future<Position?> getPosition() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         debugPrint('⚠️ [Location] Location service disabled');
//         return null;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           debugPrint('⚠️ [Location] Permission denied');
//           return null;
//         }
//       }
//       if (permission == LocationPermission.deniedForever) {
//         debugPrint('⚠️ [Location] Permission permanently denied');
//         return null;
//       }

//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//           timeLimit: Duration(seconds: 15),
//         ),
//       );
//       debugPrint(
//         '📍 [Location] Got position: ${position.latitude}, ${position.longitude}',
//       );
//       return position;
//     } catch (e) {
//       debugPrint('❌ [Location] getPosition error: $e');
//       return null;
//     }
//   }

//   /// Full pipeline: get GPS coords → reverse geocode via Nominatim →
//   /// map to Egyptian governorate/city candidates.
//   /// Returns null if any step fails.
//   static Future<LocationResult?> detectAndGeocode() async {
//     final pos = await getPosition();
//     if (pos == null) return null;
//     return reverseGeocode(pos.latitude, pos.longitude);
//   }

//   /// Reverse geocode a lat/lng pair using Nominatim OpenStreetMap API.
//   static Future<LocationResult?> reverseGeocode(double lat, double lng) async {
//     try {
//       final uri = Uri.parse(
//         '$_nominatimUrl?lat=$lat&lon=$lng&format=json&accept-language=en&addressdetails=1',
//       );
//       final response = await http.get(
//         uri,
//         headers: {'User-Agent': 'Dealio-Flutter-App/1.0 (contact@dealio.app)'},
//       ).timeout(const Duration(seconds: 10));

//       if (response.statusCode != 200) {
//         debugPrint('⚠️ [Location] Nominatim error: ${response.statusCode}');
//         return null;
//       }

//       final data = jsonDecode(response.body) as Map<String, dynamic>;
//       final address = data['address'] as Map<String, dynamic>? ?? {};

//       debugPrint('📍 [Location] Nominatim response: $address');

//       // ── Extract raw fields ──────────────────────────────────────────────
//       final rawState = (address['state'] ?? address['county'] ?? '').toString();
//       final rawCity = (address['city'] ??
//               address['town'] ??
//               address['village'] ??
//               address['suburb'] ??
//               address['neighbourhood'] ??
//               '')
//           .toString();
//       final rawRoad = (address['road'] ??
//               address['pedestrian'] ??
//               address['footway'] ??
//               '')
//           .toString();
//       final houseNumber = (address['house_number'] ?? '').toString();
//       final streetHint = [
//         if (houseNumber.isNotEmpty) houseNumber,
//         if (rawRoad.isNotEmpty) rawRoad,
//       ].join(' ').trim();

//       // ── Map to EgyptGeoData governorate ────────────────────────────────
//       final govCandidate = _matchGovernorate(rawState);

//       // ── Best-effort city match ──────────────────────────────────────────
//       final cityCandidate = rawCity.isNotEmpty ? rawCity : null;

//       return LocationResult(
//         lat: lat,
//         lng: lng,
//         rawState: rawState,
//         govCandidate: govCandidate,
//         cityCandidate: cityCandidate,
//         streetHint: streetHint.isEmpty ? null : streetHint,
//       );
//     } catch (e) {
//       debugPrint('❌ [Location] reverseGeocode error: $e');
//       return null;
//     }
//   }

//   // ── Private helpers ───────────────────────────────────────────────────────

//   static String _normalize(String s) =>
//       s.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

//   /// Try to match [rawState] to one of the EgyptGeoData governorates.
//   /// Priority:
//   ///   1. Arabic map (_arToEn)
//   ///   2. English variant map (_enVariants) — handles "Al Jizah", "Giza Governorate", etc.
//   ///   3. Exact case-insensitive match against _egyptGovs
//   ///   4. Fuzzy contains match
//   static String? _matchGovernorate(String rawState) {
//     if (rawState.isEmpty) return null;

//     // 1. Arabic → English direct map
//     final fromArabic = _arToEn[rawState.trim()];
//     if (fromArabic != null) return fromArabic;

//     // 2. English variant map (handles Nominatim transliterations)
//     final lower = rawState.trim().toLowerCase();
//     final fromVariant = _enVariants[lower];
//     if (fromVariant != null) return fromVariant;

//     // Also try normalizing (strip dashes/spaces) then check variants
//     final norm = _normalize(rawState);
//     for (final entry in _enVariants.entries) {
//       if (_normalize(entry.key) == norm) return entry.value;
//     }

//     // 3. Exact English match against the canonical list (case-insensitive)
//     for (final gov in _egyptGovs) {
//       if (_normalize(gov) == norm) return gov;
//     }

//     // 4. Contains match (e.g. "Governorate of Cairo" → "Cairo")
//     for (final gov in _egyptGovs) {
//       if (norm.contains(_normalize(gov)) ||
//           _normalize(gov).contains(norm)) {
//         return gov;
//       }
//     }

//     debugPrint(
//       '⚠️ [Location] Could not map "$rawState" to an Egyptian governorate',
//     );
//     return null;
//   }
// }



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

  /// Raw governorate string from Nominatim (English)
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

  // ── ISO 3166-2:EG code → English governorate mapping ─────────────────────
  // Nominatim provides ISO3166-2-lvl4 codes for Egyptian governorates.
  static const Map<String, String> _isoToGov = {
    'EG-GH': 'Gharbia',
    'EG-C': 'Cairo',
    'EG-GZ': 'Giza',
    'EG-ALX': 'Alexandria',
    'EG-KB': 'Qalyubia',
    'EG-SHR': 'Sharqia',
    'EG-DK': 'Dakahlia',
    'EG-MNF': 'Monufia',
    'EG-KFS': 'Kafr El Sheikh',
    'EG-BH': 'Beheira',
    'EG-DT': 'Damietta',
    'EG-PTS': 'Port Said',
    'EG-IS': 'Ismailia',
    'EG-SUZ': 'Suez',
    'EG-SIN': 'North Sinai',
    'EG-JS': 'South Sinai',
    'EG-MT': 'Matrouh',
    'EG-FYM': 'Faiyum',
    'EG-BNS': 'Beni Suef',
    'EG-MN': 'Minya',
    'EG-AST': 'Asyut',
    'EG-SHG': 'Sohag',
    'EG-KN': 'Qena',
    'EG-LX': 'Luxor',
    'EG-ASN': 'Aswan',
    'EG-BA': 'Red Sea',
    'EG-WAD': 'New Valley',
  };

  // ── English name → canonical governorate (for Nominatim English responses) ─
  // Nominatim may return non-standard English variations; map them all.
  static const Map<String, String> _enVariants = {
    // Gharbia / Gharbiyya
    'gharbia': 'Gharbia',
    'gharbia governorate': 'Gharbia',
    'gharbiyya': 'Gharbia',
    'gharbiyya governorate': 'Gharbia',
    'gharbiyyah': 'Gharbia',
    'gharbiyyah governorate': 'Gharbia',
    'gharbiyah': 'Gharbia',
    'gharbiyah governorate': 'Gharbia',
    'gharbeyya': 'Gharbia',
    'gharbeyya governorate': 'Gharbia',
    'al gharbia': 'Gharbia',
    'al-gharbia': 'Gharbia',
    'al gharbia governorate': 'Gharbia',
    'al gharbiyya': 'Gharbia',
    'al-gharbiyya': 'Gharbia',
    'al gharbiyya governorate': 'Gharbia',
    'al-gharbiyya governorate': 'Gharbia',
    'al gharbiyah': 'Gharbia',
    'al-gharbiyah': 'Gharbia',
    'al gharbiyah governorate': 'Gharbia',
    'el gharbia': 'Gharbia',
    'el-gharbia': 'Gharbia',
    'el gharbia governorate': 'Gharbia',
    'el gharbiyya': 'Gharbia',
    'el-gharbiyya': 'Gharbia',
    'el gharbiyya governorate': 'Gharbia',
    'muhafazat al gharbiyah': 'Gharbia',
    'muhafazat al gharbiyya': 'Gharbia',

    // Giza
    'giza': 'Giza',
    'al jizah': 'Giza',
    'al-jizah': 'Giza',
    'aljizah': 'Giza',
    'giza governorate': 'Giza',
    'muhafazat al jizah': 'Giza',
    'el giza': 'Giza',
    'el-giza': 'Giza',

    // Cairo
    'cairo': 'Cairo',
    'al qahirah': 'Cairo',
    'al-qahirah': 'Cairo',
    'cairo governorate': 'Cairo',
    'muhafazat al qahirah': 'Cairo',
    'el qahirah': 'Cairo',

    // Alexandria
    'alexandria': 'Alexandria',
    'al iskandariyah': 'Alexandria',
    'al-iskandariyah': 'Alexandria',
    'alexandria governorate': 'Alexandria',
    'iskandariyah': 'Alexandria',
    'iskandariyya': 'Alexandria',

    // Qalyubia
    'qalyubia': 'Qalyubia',
    'al qalyubiyah': 'Qalyubia',
    'qalyubiyah': 'Qalyubia',
    'qalyubiyya': 'Qalyubia',
    'qalyubia governorate': 'Qalyubia',
    'qalyubiyya governorate': 'Qalyubia',
    'al qalyubiyya': 'Qalyubia',
    'al-qalyubiyya': 'Qalyubia',

    // Sharqia
    'sharqia': 'Sharqia',
    'ash sharqiyah': 'Sharqia',
    'sharqiyah': 'Sharqia',
    'sharqiyya': 'Sharqia',
    'sharqia governorate': 'Sharqia',
    'sharqiyya governorate': 'Sharqia',
    'ash sharqiyya': 'Sharqia',

    // Dakahlia
    'dakahlia': 'Dakahlia',
    'ad daqahliyah': 'Dakahlia',
    'daqahliyah': 'Dakahlia',
    'dakahliyya': 'Dakahlia',
    'dakahlia governorate': 'Dakahlia',
    'dakahliyya governorate': 'Dakahlia',
    'ad daqahliyya': 'Dakahlia',

    // Monufia
    'monufia': 'Monufia',
    'al minufiyah': 'Monufia',
    'minufiyah': 'Monufia',
    'monufiyya': 'Monufia',
    'monufia governorate': 'Monufia',
    'monufiyya governorate': 'Monufia',
    'menoufia': 'Monufia',

    // Kafr El Sheikh
    'kafr el sheikh': 'Kafr El Sheikh',
    'kafr ash shaykh': 'Kafr El Sheikh',
    'kafr el-sheikh': 'Kafr El Sheikh',
    'kafr el sheikh governorate': 'Kafr El Sheikh',

    // Beheira
    'beheira': 'Beheira',
    'al buhayrah': 'Beheira',
    'beheira governorate': 'Beheira',
    'buhayrah': 'Beheira',

    // Damietta
    'damietta': 'Damietta',
    'dumyat': 'Damietta',
    'damietta governorate': 'Damietta',

    // Port Said
    'port said': 'Port Said',
    'bur said': 'Port Said',
    'port said governorate': 'Port Said',

    // Ismailia
    'ismailia': 'Ismailia',
    'al ismailiyah': 'Ismailia',
    'ismailiyah': 'Ismailia',
    'ismailia governorate': 'Ismailia',
    'ismailiyya': 'Ismailia',

    // Suez
    'suez': 'Suez',
    'as suways': 'Suez',
    'suez governorate': 'Suez',

    // Sinai
    'north sinai': 'North Sinai',
    'north sinai governorate': 'North Sinai',
    'shamal sina': 'North Sinai',
    'sinai': 'North Sinai',
    'south sinai': 'South Sinai',
    'south sinai governorate': 'South Sinai',
    'janub sina': 'South Sinai',

    // Matrouh
    'matrouh': 'Matrouh',
    'matruh': 'Matrouh',
    'matrouh governorate': 'Matrouh',
    'marsa matrouh': 'Matrouh',

    // Faiyum
    'faiyum': 'Faiyum',
    'al fayyum': 'Faiyum',
    'faiyum governorate': 'Faiyum',
    'fayoum': 'Faiyum',

    // Beni Suef
    'beni suef': 'Beni Suef',
    'bani suwayf': 'Beni Suef',
    'beni suef governorate': 'Beni Suef',

    // Minya
    'minya': 'Minya',
    'al minya': 'Minya',
    'minya governorate': 'Minya',

    // Asyut
    'asyut': 'Asyut',
    'asyut governorate': 'Asyut',
    'assiut': 'Asyut',

    // Sohag
    'sohag': 'Sohag',
    'suhaj': 'Sohag',
    'sohag governorate': 'Sohag',

    // Qena
    'qena': 'Qena',
    'qina': 'Qena',
    'qena governorate': 'Qena',

    // Luxor
    'luxor': 'Luxor',
    'al uqsur': 'Luxor',
    'luxor governorate': 'Luxor',

    // Aswan
    'aswan': 'Aswan',
    'aswan governorate': 'Aswan',

    // Red Sea
    'red sea': 'Red Sea',
    'al bahr al ahmar': 'Red Sea',
    'red sea governorate': 'Red Sea',

    // New Valley
    'new valley': 'New Valley',
    'al wadi al jadid': 'New Valley',
    'new valley governorate': 'New Valley',
  };

  // ── Governorates list (must stay in sync with EgyptGeoData) ──────────────
  static const List<String> _egyptGovs = [
    'Cairo',
    'Giza',
    'Alexandria',
    'Qalyubia',
    'Sharqia',
    'Dakahlia',
    'Gharbia',
    'Monufia',
    'Kafr El Sheikh',
    'Beheira',
    'Damietta',
    'Port Said',
    'Ismailia',
    'Suez',
    'North Sinai',
    'South Sinai',
    'Matrouh',
    'Faiyum',
    'Beni Suef',
    'Minya',
    'Asyut',
    'Sohag',
    'Qena',
    'Luxor',
    'Aswan',
    'Red Sea',
    'New Valley',
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
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'Dealio-Flutter-App/1.0 (contact@dealio.app)',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('⚠️ [Location] Nominatim error: ${response.statusCode}');
        return LocationResult(
          lat: lat,
          lng: lng,
          rawState: 'Gharbia',
          govCandidate: 'Gharbia',
          cityCandidate: 'Tanta',
          streetHint: 'Gharbia Governorate, Egypt',
        );
      }

      final data = jsonDecode(response.body);
      final address =
          (data is Map<String, dynamic> &&
              data['address'] is Map<String, dynamic>)
          ? data['address'] as Map<String, dynamic>
          : <String, dynamic>{};

      debugPrint('📍 [Location] Nominatim response: $address');

      // ── Extract raw fields ──────────────────────────────────────────────
      final rawState = (address['state'] ?? address['county'] ?? '').toString();
      final isoCode =
          (address['ISO3166-2-lvl4'] ??
                  address['state_code'] ??
                  address['country_code_iso3166-2'] ??
                  '')
              .toString();
      final rawCity =
          (address['city'] ??
                  address['town'] ??
                  address['village'] ??
                  address['suburb'] ??
                  address['neighbourhood'] ??
                  '')
              .toString();
      final rawRoad =
          (address['road'] ?? address['pedestrian'] ?? address['footway'] ?? '')
              .toString();
      final houseNumber = (address['house_number'] ?? '').toString();
      final rawStreet = [
        if (houseNumber.isNotEmpty) houseNumber,
        if (rawRoad.isNotEmpty) rawRoad,
      ].join(' ').trim();

      // ── Map to EgyptGeoData governorate ────────────────────────────────
      final matchedGov = _matchGovernorate(rawState, isoCode: isoCode);
      final govCandidate =
          matchedGov ??
          (rawState.trim().isNotEmpty
              ? _cleanFallbackGov(rawState)
              : 'Gharbia');

      // ── Best-effort city match ──────────────────────────────────────────
      final cityCandidate = rawCity.isNotEmpty ? rawCity : 'Tanta';

      final streetHint = rawStreet.isNotEmpty
          ? rawStreet
          : '$govCandidate Governorate, Egypt';

      return LocationResult(
        lat: lat,
        lng: lng,
        rawState: rawState.isNotEmpty ? rawState : 'Gharbia',
        govCandidate: govCandidate,
        cityCandidate: cityCandidate,
        streetHint: streetHint,
      );
    } catch (e, stack) {
      debugPrint('❌ [Location] reverseGeocode error: $e\n$stack');
      return LocationResult(
        lat: lat,
        lng: lng,
        rawState: 'Gharbia',
        govCandidate: 'Gharbia',
        cityCandidate: 'Tanta',
        streetHint: 'Gharbia Governorate, Egypt',
      );
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static String _cleanFallbackGov(String raw) {
    final cleaned = raw
        .replaceAll(
          RegExp(
            r'\b(governorate of|governorate|province|muhafazat|state)\b',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    return cleaned.isNotEmpty ? cleaned : 'Gharbia';
  }

  static String _normalizeGovString(String s) {
    String res = s
        .toLowerCase()
        // Strip out words like "governorate", "governorate of", "province", "muhafazat", "state"
        .replaceAll(
          RegExp(r'\b(governorate of|governorate|province|muhafazat|state)\b'),
          '',
        )
        // Strip out prefixes "al-", "al ", "el-", "el ", "ash-", "ash ", "ad-", "ad ", "as-"
        .replaceAll(
          RegExp(r'\b(al-|al\s+|el-|el\s+|ash-|ash\s+|ad-|ad\s+|as-|as\s+)'),
          '',
        )
        .trim();
    // Normalize suffixes: -iyya, -iyah, -iyyah, -eyya -> -ia
    res = res.replaceAll(RegExp(r'(iyyah|iyya|iyah|eyya)$'), 'ia');
    return res.replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  static final Map<String, String> _normalizedVariants = () {
    final map = <String, String>{};
    for (final entry in _enVariants.entries) {
      final k = _normalizeGovString(entry.key);
      if (k.isNotEmpty) map[k] = entry.value;
    }
    for (final gov in _egyptGovs) {
      final k = _normalizeGovString(gov);
      if (k.isNotEmpty) map[k] = gov;
    }
    return map;
  }();

  /// Try to match [rawState] (and optional [isoCode]) to one of the EgyptGeoData governorates.
  /// Strictly English matching logic.
  /// Priority:
  ///   1. ISO 3166-2-lvl4 code direct match (e.g. EG-GH -> Gharbia)
  ///   2. English variant map direct match
  ///   3. Normalized comparison against precomputed variants map
  ///   4. Safe substring contains match (length >= 4)
  static String? _matchGovernorate(String rawState, {String? isoCode}) {
    // 1. ISO 3166-2 direct match (e.g. EG-GH -> Gharbia)
    if (isoCode != null && isoCode.trim().isNotEmpty) {
      final cleanIso = isoCode.trim().toUpperCase();
      final fromIso = _isoToGov[cleanIso];
      if (fromIso != null) return fromIso;
    }

    if (rawState.trim().isEmpty) return null;

    // 2. Direct English variant lookup
    final lower = rawState.trim().toLowerCase();
    final fromVariant = _enVariants[lower];
    if (fromVariant != null) return fromVariant;

    // 3. Normalized comparison against precomputed map
    final norm = _normalizeGovString(rawState);
    if (norm.isNotEmpty) {
      final fromNorm = _normalizedVariants[norm];
      if (fromNorm != null) return fromNorm;

      // 4. Safe substring contains match (only when length >= 4)
      if (norm.length >= 4) {
        for (final gov in _egyptGovs) {
          final govNorm = _normalizeGovString(gov);
          if (govNorm.length >= 4 &&
              (norm.contains(govNorm) || govNorm.contains(norm))) {
            return gov;
          }
        }
      }
    }

    debugPrint(
      '⚠️ [Location] Could not map "$rawState" (iso: $isoCode) to an Egyptian governorate',
    );
    return null;
  }
}
