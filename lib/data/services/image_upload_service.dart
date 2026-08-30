import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:dealio/core/constants/base_url.dart';

// ── Result types ──────────────────────────────────────────────────────────────

/// Sealed-style result returned by [ImageUploadService.uploadImage].
abstract class UploadResult {
  const UploadResult();
}

class UploadSuccess extends UploadResult {
  /// The fully-qualified public URL of the uploaded image
  /// (e.g. "https://dealiobackend.vercel.app/uploads/1711540000000-3f2504.jpg")
  final String url;
  final String filename;

  const UploadSuccess({required this.url, required this.filename});
}

class UploadFailure extends UploadResult {
  final String message;

  const UploadFailure(this.message);
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Handles server-side image uploads via [POST /api/uploads/image].
///
/// Usage:
/// ```dart
/// final result = await ImageUploadService.uploadImage(
///   file: pickedFile,
///   token: authProvider.token,
///   onProgress: (p) => setState(() => _uploadProgress = p),
/// );
///
/// if (result is UploadSuccess) {
///   print(result.url); // use this URL to save to your product
/// } else if (result is UploadFailure) {
///   showError(result.message);
/// }
/// ```
class ImageUploadService {
  // The endpoint path relative to AppConstants.baseUrl.
  // Full URL: <baseUrl>/uploads/image
  static const String _endpoint = '/uploads/image';

  // Request timeout duration
  static const Duration _timeout = Duration(seconds: 30);

  /// Uploads [file] to the server.
  ///
  /// - [token] — JWT Bearer token (required; 401 if missing or invalid).
  /// - [onProgress] — optional callback receiving [0.0 … 1.0] upload fraction.
  static Future<UploadResult> uploadImage({
    required File file,
    required String token,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // ── Build base URL without the "/api" suffix for the static /uploads path,
      //    but we POST to /api/uploads/image.
      final uri = Uri.parse('${AppConstants.baseUrl}$_endpoint');

      // ── Build multipart request ──
      final request = http.MultipartRequest('POST', uri);

      // Auth header
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Attach file under field name "image" (must match multer's upload.single('image'))
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        file.path,
      );
      request.files.add(multipartFile);

      // ── Send & stream (enables progress tracking) ──
      final streamedResponse = await request.send().timeout(_timeout);

      // Track upload progress via content-length + bytes sent.
      // http.StreamedResponse exposes the raw byte stream; we buffer it
      // while computing progress against the declared Content-Length.
      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;
      final responseBytes = <int>[];

      await for (final chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      // Signal 100 % when done
      onProgress?.call(1.0);

      // ── Parse response body ──
      final body = utf8.decode(responseBytes);
      final Map<String, dynamic> json = jsonDecode(body);

      if (streamedResponse.statusCode == 200 && json['success'] == true) {
        return UploadSuccess(
          url: json['url'] as String,
          filename: json['filename'] as String,
        );
      }

      // Server returned a structured error
      final serverMessage = json['message'] as String? ?? 'Upload failed.';
      return _failure(streamedResponse.statusCode, serverMessage);
    } on SocketException {
      return const UploadFailure(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException {
      return const UploadFailure(
        'The request timed out. The server might be busy — please try again.',
      );
    } on http.ClientException catch (e) {
      return UploadFailure('Connection error: ${e.message}');
    } catch (e) {
      return UploadFailure('Unexpected error: $e');
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static UploadFailure _failure(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return UploadFailure('Bad request: $message');
      case 401:
        return const UploadFailure(
          'Not authorized. Please log in and try again.',
        );
      case 403:
        return const UploadFailure(
          'You do not have permission to upload images.',
        );
      case 413:
        return const UploadFailure(
          'File too large. Maximum allowed size is 5 MB.',
        );
      default:
        return UploadFailure('Server error ($statusCode): $message');
    }
  }
}
