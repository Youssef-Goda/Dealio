import 'package:dealio/data/models/review_model.dart';
import 'package:dealio/data/repositories/review_repository.dart';
import 'package:flutter/foundation.dart';

// ── Review load states ────────────────────────────────────────────────────────

enum ReviewLoadState { idle, loading, loaded, error }

enum EligibilityState { idle, loading, loaded, error }

enum SubmitState { idle, submitting, success, error }

// ── Provider ──────────────────────────────────────────────────────────────────

/// Manages review state for a single product on the Product Details page.
///
/// Lifecycle:
///   1. [init] — called when the product details page opens.
///   2. [loadReviews] — fetches paginated reviews + summary.
///   3. [checkEligibility] — determines if the user can review.
///   4. [submitReview] / [updateReview] / [deleteReview] — mutate state.
class ReviewProvider with ChangeNotifier {
  final ReviewRepository _repo;

  ReviewProvider({ReviewRepository? repo})
      : _repo = repo ?? ReviewRepository();

  // ── Review list state ─────────────────────────────────────────────────────
  ReviewLoadState _loadState = ReviewLoadState.idle;
  ReviewSummary _summary = ReviewSummary.empty;
  List<ReviewModel> _reviews = [];
  String? _loadError;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  String _currentSort = 'newest';

  // ── Eligibility state ─────────────────────────────────────────────────────
  EligibilityState _eligibilityState = EligibilityState.idle;
  ReviewEligibility? _eligibility;
  String? _eligibilityError;

  // ── Submit state ──────────────────────────────────────────────────────────
  SubmitState _submitState = SubmitState.idle;
  String? _submitError;
  String? _submitSuccess;

  // ── Getters ───────────────────────────────────────────────────────────────
  ReviewLoadState get loadState => _loadState;
  ReviewSummary get summary => _summary;
  List<ReviewModel> get reviews => _reviews;
  String? get loadError => _loadError;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String get currentSort => _currentSort;

  EligibilityState get eligibilityState => _eligibilityState;
  ReviewEligibility? get eligibility => _eligibility;
  String? get eligibilityError => _eligibilityError;

  SubmitState get submitState => _submitState;
  String? get submitError => _submitError;
  String? get submitSuccess => _submitSuccess;

  bool get isLoading => _loadState == ReviewLoadState.loading;
  bool get isSubmitting => _submitState == SubmitState.submitting;

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Initializes or resets state for a new product.
  void init() {
    _loadState = ReviewLoadState.idle;
    _summary = ReviewSummary.empty;
    _reviews = [];
    _loadError = null;
    _currentPage = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _currentSort = 'newest';
    _eligibilityState = EligibilityState.idle;
    _eligibility = null;
    _eligibilityError = null;
    _submitState = SubmitState.idle;
    _submitError = null;
    _submitSuccess = null;
  }

  // ── Load reviews ──────────────────────────────────────────────────────────

  /// Loads the first page of reviews for [productId].
  Future<void> loadReviews({
    required String productId,
    String? sort,
  }) async {
    if (sort != null && sort != _currentSort) {
      _currentSort = sort;
    }
    _currentPage = 1;
    _reviews = [];
    _hasMore = false;
    _loadState = ReviewLoadState.loading;
    _loadError = null;
    notifyListeners();

    final result = await _repo.getProductReviews(
      productId: productId,
      page: 1,
      limit: 10,
      sort: _currentSort,
    );

    if (result['success'] == true) {
      _summary = result['summary'] as ReviewSummary;
      _reviews = List<ReviewModel>.from(result['reviews'] as List);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      _hasMore = pagination?['hasMore'] as bool? ?? false;
      _loadState = ReviewLoadState.loaded;
    } else {
      _loadError = result['message']?.toString();
      _loadState = ReviewLoadState.error;
    }
    notifyListeners();
  }

  /// Loads the next page of reviews (infinite scroll).
  Future<void> loadMore({required String productId}) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _currentPage + 1;
    final result = await _repo.getProductReviews(
      productId: productId,
      page: nextPage,
      limit: 10,
      sort: _currentSort,
    );

    if (result['success'] == true) {
      _currentPage = nextPage;
      final newReviews = List<ReviewModel>.from(result['reviews'] as List);
      _reviews.addAll(newReviews);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      _hasMore = pagination?['hasMore'] as bool? ?? false;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Changes the sort order and reloads.
  Future<void> changeSort({
    required String productId,
    required String sort,
  }) => loadReviews(productId: productId, sort: sort);

  // ── Eligibility ───────────────────────────────────────────────────────────

  /// Checks if the authenticated user is eligible to review [productId].
  Future<void> checkEligibility({
    required String productId,
    required String token,
  }) async {
    _eligibilityState = EligibilityState.loading;
    _eligibilityError = null;
    notifyListeners();

    final result = await _repo.checkEligibility(
      productId: productId,
      token: token,
    );

    if (result['success'] == true) {
      _eligibility = result['eligibility'] as ReviewEligibility;
      _eligibilityState = EligibilityState.loaded;
    } else {
      _eligibilityError = result['message']?.toString();
      _eligibilityState = EligibilityState.error;
    }
    notifyListeners();
  }

  // ── Submit review ─────────────────────────────────────────────────────────

  /// Submits a new review.
  Future<bool> submitReview({
    required String productId,
    required String orderItemId,
    required int rating,
    String? comment,
    List<String>? images,
    required String token,
  }) async {
    _submitState = SubmitState.submitting;
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();

    final result = await _repo.createReview(
      productId: productId,
      orderItemId: orderItemId,
      rating: rating,
      comment: comment,
      images: images,
      token: token,
    );

    if (result['success'] == true) {
      final newReview = result['review'] as ReviewModel;

      // Optimistically prepend the new review
      _reviews.insert(0, newReview);
      _summary = _recalculateSummary();
      _submitState = SubmitState.success;
      _submitSuccess = 'Your review has been submitted. Thank you!';

      // Mark as already reviewed in eligibility
      _eligibility = ReviewEligibility(
        canReview: false,
        reason: 'already_reviewed',
        message: 'You have already reviewed this product.',
        existingReview: newReview,
      );

      notifyListeners();
      return true;
    }

    _submitState = SubmitState.error;
    _submitError = result['message']?.toString() ?? 'Failed to submit review.';
    notifyListeners();
    return false;
  }

  // ── Update review ─────────────────────────────────────────────────────────

  /// Updates an existing review.
  Future<bool> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
    List<String>? images,
    required String token,
  }) async {
    _submitState = SubmitState.submitting;
    _submitError = null;
    notifyListeners();

    final result = await _repo.updateReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
      images: images,
      token: token,
    );

    if (result['success'] == true) {
      final updated = result['review'] as ReviewModel;

      // Update in list
      final idx = _reviews.indexWhere((r) => r.id == reviewId);
      if (idx != -1) _reviews[idx] = updated;

      // Update eligibility's existing review
      if (_eligibility?.existingReview?.id == reviewId) {
        _eligibility = ReviewEligibility(
          canReview: false,
          reason: 'already_reviewed',
          message: 'You have already reviewed this product.',
          existingReview: updated,
          orderItemId: _eligibility?.orderItemId,
        );
      }

      _summary = _recalculateSummary();
      _submitState = SubmitState.success;
      _submitSuccess = 'Your review has been updated.';
      notifyListeners();
      return true;
    }

    _submitState = SubmitState.error;
    _submitError = result['message']?.toString() ?? 'Failed to update review.';
    notifyListeners();
    return false;
  }

  // ── Delete review ─────────────────────────────────────────────────────────

  /// Deletes a review.
  Future<bool> deleteReview({
    required String reviewId,
    required String productId,
    required String token,
  }) async {
    _submitState = SubmitState.submitting;
    _submitError = null;
    notifyListeners();

    final result = await _repo.deleteReview(reviewId: reviewId, token: token);

    if (result['success'] == true) {
      _reviews.removeWhere((r) => r.id == reviewId);
      _summary = _recalculateSummary();

      // Reset eligibility — user can now review again (using same order item)
      if (_eligibility?.existingReview?.id == reviewId) {
        _eligibility = ReviewEligibility(
          canReview: true,
          reason: 'eligible',
          message: 'You are eligible to review this product.',
          orderItemId: _eligibility?.orderItemId,
        );
      }

      _submitState = SubmitState.success;
      _submitSuccess = 'Your review has been deleted.';
      notifyListeners();
      return true;
    }

    _submitState = SubmitState.error;
    _submitError = result['message']?.toString() ?? 'Failed to delete review.';
    notifyListeners();
    return false;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Recalculates summary from the current local review list.
  /// Used for optimistic updates after create/update/delete.
  ReviewSummary _recalculateSummary() {
    final count = _reviews.length;
    final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _reviews) {
      if (r.rating >= 1 && r.rating <= 5) dist[r.rating] = (dist[r.rating] ?? 0) + 1;
    }
    final avg = count == 0
        ? 0.0
        : double.parse(
            (_reviews.fold<int>(0, (s, r) => s + r.rating) / count).toStringAsFixed(1),
          );
    return ReviewSummary(totalCount: count, avgRating: avg, distribution: dist);
  }

  /// Resets submit state so forms can be re-used.
  void resetSubmitState() {
    _submitState = SubmitState.idle;
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
  }
}
