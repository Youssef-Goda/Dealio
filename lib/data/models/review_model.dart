/// Review data model for the Dealio review system.
///
/// Matches the shape returned by:
///   GET /api/reviews/product/:productId
///   POST /api/reviews
///   PUT  /api/reviews/:id
class ReviewModel {
  final String id;
  final String productId;
  final int rating;
  final String? comment;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReviewUser? user;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.rating,
    this.comment,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
    id: j['id'] as String,
    productId: j['productId'] as String,
    rating: _toInt(j['rating']),
    comment: j['comment'] as String?,
    images: _parseImages(j['images']),
    createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    user: j['user'] != null ? ReviewUser.fromJson(j['user'] as Map<String, dynamic>) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'rating': rating,
    'comment': comment,
    'images': images,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  ReviewModel copyWith({
    String? id,
    String? productId,
    int? rating,
    String? comment,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReviewUser? user,
  }) => ReviewModel(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    images: images ?? this.images,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    user: user ?? this.user,
  );

  static int _toInt(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  static List<String> _parseImages(dynamic v) {
    if (v == null) return [];
    if (v is List) return List<String>.from(v.map((e) => e.toString()));
    return [];
  }
}

/// Minimal user info attached to a review response.
/// Only non-sensitive public fields are included.
class ReviewUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  const ReviewUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return f + l;
  }

  factory ReviewUser.fromJson(Map<String, dynamic> j) => ReviewUser(
    id: j['id'] as String,
    firstName: j['firstName']?.toString() ?? '',
    lastName: j['lastName']?.toString() ?? '',
    profilePicture: j['profilePicture']?.toString(),
  );
}

/// Summary data for a product's reviews.
class ReviewSummary {
  final int totalCount;
  final double avgRating;
  final Map<int, int> distribution;

  const ReviewSummary({
    required this.totalCount,
    required this.avgRating,
    required this.distribution,
  });

  static const ReviewSummary empty = ReviewSummary(
    totalCount: 0,
    avgRating: 0.0,
    distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
  );

  factory ReviewSummary.fromJson(Map<String, dynamic> j) {
    final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final rawDist = j['distribution'];
    if (rawDist is Map) {
      for (final entry in rawDist.entries) {
        final key = int.tryParse(entry.key.toString());
        final val = int.tryParse(entry.value.toString()) ?? 0;
        if (key != null && key >= 1 && key <= 5) dist[key] = val;
      }
    }
    return ReviewSummary(
      totalCount: _toInt(j['totalCount']),
      avgRating: double.tryParse(j['avgRating']?.toString() ?? '0') ?? 0.0,
      distribution: dist,
    );
  }

  static int _toInt(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;
}

/// Result of the eligibility check endpoint.
class ReviewEligibility {
  final bool canReview;
  final String reason; // 'eligible' | 'not_purchased' | 'already_reviewed'
  final String message;
  final String? orderItemId;
  final ReviewModel? existingReview;

  const ReviewEligibility({
    required this.canReview,
    required this.reason,
    required this.message,
    this.orderItemId,
    this.existingReview,
  });

  bool get hasExistingReview => existingReview != null;

  factory ReviewEligibility.fromJson(Map<String, dynamic> j) {
    final existing = j['existingReview'];
    ReviewModel? existingModel;
    if (existing is Map<String, dynamic>) {
      // existingReview from eligibility endpoint has slightly different shape
      existingModel = ReviewModel(
        id: existing['id'] as String,
        productId: '', // not included in eligibility response
        rating: ReviewModel._toInt(existing['rating']),
        comment: existing['comment'] as String?,
        images: ReviewModel._parseImages(existing['images']),
        createdAt: DateTime.tryParse(existing['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(existing['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
    }
    return ReviewEligibility(
      canReview: j['canReview'] as bool? ?? false,
      reason: j['reason'] as String? ?? 'not_purchased',
      message: j['message'] as String? ?? '',
      orderItemId: j['orderItemId'] as String?,
      existingReview: existingModel,
    );
  }
}
