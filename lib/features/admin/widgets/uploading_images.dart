// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:e_commerce/core/constants/base_url.dart';

// /// Handles product-image uploads through the secure backend.
// ///
// /// The backend receives the file, forwards it to ImgBB using the server-side
// /// API key, and returns a clean `i.ibb.co` direct URL — no CORS proxy, no
// /// API key exposed in the app bundle.
// class UploadingImages {
//   static const String _endpoint = '/products/upload';
//   static const Duration _timeout = Duration(seconds: 40);

//   /// Uploads [bytes] to the backend's ImgBB proxy endpoint.
//   ///
//   /// - [filename]  Original filename (used for MIME detection).
//   /// - [token]     JWT Bearer token from the logged-in admin.
//   ///
//   /// Returns the clean direct URL on success, or `null` on failure.
//   static Future<String?> uploadImageToImgBB(
//     Uint8List bytes,
//     String filename,
//     String token,
//   ) async {
//     if (token.isEmpty) {
//       debugPrint('❌ Upload error: JWT token is empty.');
//       return null;
//     }

//     final uri = Uri.parse('${AppConstants.baseUrl}$_endpoint');

//     try {
//       final request = http.MultipartRequest('POST', uri);

//       // Auth header — required by authenticateToken middleware
//       request.headers['Authorization'] = 'Bearer $token';
//       request.headers['Accept'] = 'application/json';

//       // Attach image bytes under the field name "image" (matches multer)
//       final mimeType = _getMimeType(filename);
//       final parts = mimeType.split('/');
//       request.files.add(
//         http.MultipartFile.fromBytes(
//           'image',
//           bytes,
//           filename: filename,
//           contentType: MediaType(parts[0], parts[1]),
//         ),
//       );

//       debugPrint('⏳ Uploading $filename via backend → ImgBB...');
//       final streamed = await request.send().timeout(_timeout);
//       final body = await streamed.stream.bytesToString();
//       final json = jsonDecode(body) as Map<String, dynamic>;

//       if (streamed.statusCode == 200 && json['success'] == true) {
//         final url = json['url'] as String;
//         debugPrint('✅ Upload successful: $url');
//         return url; // clean i.ibb.co URL — stored directly in DB
//       }

//       final msg = json['message'] ?? 'Unknown error';
//       debugPrint('⚠️ Upload failed (${streamed.statusCode}): $msg');
//       return null;
//     } catch (e) {
//       debugPrint('❌ Upload exception: $e');
//       return null;
//     }
//   }

//   // ── Helpers ────────────────────────────────────────────────────────────────

//   static String _getMimeType(String filename) {
//     final lower = filename.toLowerCase();
//     if (lower.endsWith('.png')) return 'image/png';
//     if (lower.endsWith('.gif')) return 'image/gif';
//     if (lower.endsWith('.webp')) return 'image/webp';
//     return 'image/jpeg';
//   }
// }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:e_commerce/core/constants/base_url.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // المكتبة الجديدة

/// Handles product-image uploads through the secure backend with Auto-Compression.
class UploadingImages {
  static const String _endpoint = '/products/upload';
  static const Duration _timeout = Duration(seconds: 40);

  /// Uploads [bytes] to the backend's ImgBB proxy endpoint after compressing them.
  static Future<String?> uploadImageToImgBB(
    Uint8List bytes,
    String filename,
    String token,
  ) async {
    if (token.isEmpty) {
      debugPrint('❌ Upload error: JWT token is empty.');
      return null;
    }

    // 1. عملية الضغط (Compression Logic)
    Uint8List compressedBytes;
    try {
      debugPrint(
        '⏳ Compressing image: $filename (Original size: ${bytes.lengthInBytes / 1024 / 1024} MB)...',
      );

      compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 1920, // دقة Full HD ممتازة للعرض
        minWidth: 1080,
        quality: 80, // جودة 80% بتقلل المساحة جداً وبتحافظ على التفاصيل
        format: CompressFormat.webp, // الـ JPEG أفضل في الضغط من الـ PNG
      );

      debugPrint(
        '📉 Compression Done: ${compressedBytes.lengthInBytes / 1024} KB',
      );
    } catch (e) {
      debugPrint('⚠️ Compression failed, sending original bytes: $e');
      compressedBytes = bytes; // لو الضغط فشل لأي سبب، ابعت الأصل
    }

    final uri = Uri.parse('${AppConstants.baseUrl}$_endpoint');

    try {
      final request = http.MultipartRequest('POST', uri);

      // Auth header — required by authenticateToken middleware
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Attach compressed image bytes under the field name "image"
      // لاحظ إننا غيرنا الـ Extension لـ .jpg لأن الضغط بيحولها JPEG
      final String uploadFilename = filename.split('.').first + ".webp";
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          compressedBytes,
          filename: uploadFilename,
          contentType: MediaType('image', 'webp'), // غيرنا الـ Type لـ webp
        ),
      );

      debugPrint('⏳ Uploading via backend → ImgBB...');
      final streamed = await request.send().timeout(_timeout);
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (streamed.statusCode == 200 && json['success'] == true) {
        final url = json['url'] as String;
        debugPrint('✅ Upload successful: $url');
        return url;
      }

      final msg = json['message'] ?? 'Unknown error';
      debugPrint('⚠️ Upload failed (${streamed.statusCode}): $msg');
      return null;
    } catch (e) {
      debugPrint('❌ Upload exception: $e');
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  // ملاحظة: مش هنحتاج _getMimeType المعقدة لأننا بنحول كله لـ JPEG أثناء الضغط
}
