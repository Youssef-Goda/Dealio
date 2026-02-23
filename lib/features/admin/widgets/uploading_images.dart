import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UploadingImages {
  static Future<String?> uploadImageToImgBB(
    Uint8List bytes,
    String filename,
  ) async {
    final String imgbbApiKey =
        dotenv.maybeGet('IMGBB_API_KEY') ??
        const String.fromEnvironment('IMGBB_API_KEY');
    const String imgbbBaseUrl = 'https://api.imgbb.com/1/upload';

    if (imgbbApiKey.isEmpty) {
      debugPrint("❌ Error: IMGBB_API_KEY is not found");
      return null;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$imgbbBaseUrl?key=$imgbbApiKey'),
      );

      String mimeType = _getMimeType(filename);
      final split = mimeType.split('/');

      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: MediaType(split[0], split[1]),
      );

      request.files.add(multipartFile);

      debugPrint("⏳ Uploading $filename to ImgBB...");
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        String imageUrl =
            jsonResponse['data']['display_url'] ?? jsonResponse['data']['url'];

        String proxiedUrl =
            "https://corsproxy.io/?${Uri.encodeComponent(imageUrl)}";

        debugPrint("✅ Upload successful: $proxiedUrl");
        return proxiedUrl;
      } else {
        debugPrint("⚠️ Server error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      return null;
    }
  }

  static String _getMimeType(String filename) {
    if (filename.toLowerCase().endsWith('.png')) return 'image/png';
    if (filename.toLowerCase().endsWith('.gif')) return 'image/gif';
    if (filename.toLowerCase().endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
