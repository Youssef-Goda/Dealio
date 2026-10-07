import 'dart:convert';
import 'package:dealio/core/constants/base_url.dart';
import 'package:dealio/data/models/review_model.dart';
import 'package:dealio/data/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Repository for all product review operations.
///
/// All mutating operations require a valid JWT token.
/// The backend enforces all authorization rules — this class only
/// handles HTTP transport and response parsing.
class ReviewRepository {
  static const String _base = '/reviews';

  // ── GET product reviews (public) ──────────────────────────────────────────

  /// Fetches paginated reviews + summary for [productId].
  ///
  /// Returns a map with:
  ///   - `summary`    → [ReviewSummary]
  ///   - `reviews`    → `List<ReviewModel>`
  ///   - `pagination` → `{ page, limit, total, hasMore }`
  Future<Map<String, dynamic>> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 10,
    String sort = 'newest', // newest | highest | lowest | images
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.baseUrl}$_base/product/$productId'
        '?page=$page&limit=$limit&sort=$sort',
      );
      final res = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final body = _tryDecode(res.body);

      if (res.statusCode == 200 && body?['success'] == true) {
        final data = body!['data'] as Map<String, dynamic>;
        final summary = ReviewSummary.fromJson(
          data['summary'] as Map<String, dynamic>? ?? {},
        );
        final reviewsRaw = data['reviews'] as List<dynamic>? ?? [];
        final reviews = reviewsRaw
            .whereType<Map<String, dynamic>>()
            .map(ReviewModel.fromJson)
            .toList();
        return {
          'success': true,
          'summary': summary,
          'reviews': reviews,
          'pagination': data['pagination'],
        };
      }

      return {
        'success': false,
        'message': body?['message']?.toString() ?? 'Failed to load reviews.',
      };
    } catch (e) {
      debugPrint('❌ [ReviewRepo] getProductReviews error: $e');
      return {
        'success': false,
        'message': ApiService.parseErrorMessage(e),
      };
    }
  }

  // ── GET eligibility (authenticated) ──────────────────────────────────────

  /// Checks if the authenticated user can review [productId].
  Future<Map<String, dynamic>> checkEligibility({
    required String productId,
    required String token,
  }) async {
    try {
      final res = await ApiService.getRequest(
        '$_base/eligibility/$productId',
        token,
      );
      final body = _tryDecode(res.body);

      if (res.statusCode == 200 && body?['success'] == true) {
        final data = body!['data'] as Map<String, dynamic>;
        return {
          'success': true,
          'eligibility': ReviewEligibility.fromJson(data),
        };
      }
      return {
        'success': false,
        'message': body?['message']?.toString() ?? 'Could not check eligibility.',
      };
    } catch (e) {
      debugPrint('❌ [ReviewRepo] checkEligibility error: $e');
      return {
        'success': false,
        'message': ApiService.parseErrorMessage(e),
      };
    }
  }

  // ── POST create review (authenticated) ───────────────────────────────────

  /// Creates a new review. Returns the created [ReviewModel] on success.
  Future<Map<String, dynamic>> createReview({
    required String productId,
    required String orderItemId,
    required int rating,
    String? comment,
    List<String>? images,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{
        'productId': productId,
        'orderItemId': orderItemId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment.trim(),
        if (images != null && images.isNotEmpty) 'images': images,
      };

      final res = await ApiService.postAuthRequest(_base, body, token);
      final decoded = _tryDecode(res.body);

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          decoded?['success'] == true) {
        final data = decoded!['data'] as Map<String, dynamic>;
        return {'success': true, 'review': ReviewModel.fromJson(data)};
      }

      return {
        'success': false,
        'message': decoded?['message']?.toString() ?? 'Failed to submit review.',
      };
    } catch (e) {
      debugPrint('❌ [ReviewRepo] createReview error: $e');
      return {'success': false, 'message': ApiService.parseErrorMessage(e)};
    }
  }

  // ── PUT update review (authenticated) ─────────────────────────────────────

  /// Updates an existing review by [reviewId]. Returns updated [ReviewModel].
  Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
    List<String>? images,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{
        if (rating != null) 'rating': rating,
        if (comment != null) 'comment': comment.trim(),
        if (images != null) 'images': images,
      };

      final res = await ApiService.putRequest('$_base/$reviewId', body, token);
      final decoded = _tryDecode(res.body);

      if (res.statusCode == 200 && decoded?['success'] == true) {
        final data = decoded!['data'] as Map<String, dynamic>;
        return {'success': true, 'review': ReviewModel.fromJson(data)};
      }

      return {
        'success': false,
        'message': decoded?['message']?.toString() ?? 'Failed to update review.',
      };
    } catch (e) {
      debugPrint('❌ [ReviewRepo] updateReview error: $e');
      return {'success': false, 'message': ApiService.parseErrorMessage(e)};
    }
  }

  // ── DELETE review (authenticated) ─────────────────────────────────────────

  /// Deletes a review by [reviewId].
  Future<Map<String, dynamic>> deleteReview({
    required String reviewId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$_base/$reviewId');
      final res = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.trim()}',
        },
      ).timeout(const Duration(seconds: 15));

      final decoded = _tryDecode(res.body);

      if (res.statusCode == 200 && decoded?['success'] == true) {
        return {'success': true};
      }

      return {
        'success': false,
        'message': decoded?['message']?.toString() ?? 'Failed to delete review.',
      };
    } catch (e) {
      debugPrint('❌ [ReviewRepo] deleteReview error: $e');
      return {'success': false, 'message': ApiService.parseErrorMessage(e)};
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
