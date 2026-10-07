import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/review_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/review_provider.dart';
import 'package:dealio/features/products/widgets/review_card.dart';
import 'package:dealio/features/products/widgets/star_rating.dart';
import 'package:dealio/features/products/widgets/write_review_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The full review section displayed below the product details.
///
/// Responsibilities:
///   - Shows review summary (average, count, rating bars)
///   - Shows eligibility state for the logged-in user
///   - Shows the write/edit review CTA
///   - Lists reviews with sort options
///   - Handles loading/empty/error states
class ReviewSection extends StatefulWidget {
  final String productId;

  const ReviewSection({super.key, required this.productId});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  static const _sortOptions = [
    ('newest', 'Newest'),
    ('highest', 'Highest'),
    ('lowest', 'Lowest'),
    ('images', 'With Photos'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final provider = context.read<ReviewProvider>();
    final auth = context.read<AuthProvider>();
    provider.loadReviews(productId: widget.productId);
    if (auth.isLoggedIn && auth.token != null) {
      provider.checkEligibility(
        productId: widget.productId,
        token: auth.token!,
      );
    }
  }

  void _openWriteSheet(BuildContext context) {
    final reviewProvider = context.read<ReviewProvider>();
    final eligibility = reviewProvider.eligibility;
    if (eligibility == null || !eligibility.canReview) return;

    showWriteReviewSheet(
      context: context,
      productId: widget.productId,
      orderItemId: eligibility.orderItemId!,
      reviewProvider: reviewProvider,
    ).then((_) {
      // Refresh after sheet closes
      if (reviewProvider.submitState == SubmitState.success) {
        _showSuccessSnack('Your review has been submitted!');
        reviewProvider.resetSubmitState();
      }
    });
  }

  void _openEditSheet(BuildContext context, ReviewModel review) {
    final reviewProvider = context.read<ReviewProvider>();
    final eligibility = reviewProvider.eligibility;

    showWriteReviewSheet(
      context: context,
      productId: widget.productId,
      orderItemId: eligibility?.orderItemId ?? review.id,
      existingReview: review,
      reviewProvider: reviewProvider,
    ).then((_) {
      if (reviewProvider.submitState == SubmitState.success) {
        _showSuccessSnack('Your review has been updated!');
        reviewProvider.resetSubmitState();
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Review?'),
        content: const Text(
          'This action cannot be undone. Your review will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      final reviewProvider = context.read<ReviewProvider>();
      final token = auth.token ?? '';

      final success = await reviewProvider.deleteReview(
        reviewId: reviewId,
        productId: widget.productId,
        token: token,
      );

      if (success && mounted) {
        _showSuccessSnack('Review deleted.');
        reviewProvider.resetSubmitState();
      } else if (mounted && reviewProvider.submitError != null) {
        _showErrorSnack(reviewProvider.submitError!);
        reviewProvider.resetSubmitState();
      }
    }
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.darkSurface,
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.errorRed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer2<ReviewProvider, AuthProvider>(
      builder: (context, reviewProvider, auth, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ─────────────────────────────────────────────
            _SectionHeader(isDark: isDark),
            const SizedBox(height: 16),

            // ── Summary card ────────────────────────────────────────────────
            if (reviewProvider.loadState == ReviewLoadState.loaded ||
                reviewProvider.loadState == ReviewLoadState.loading)
              _SummaryCard(
                summary: reviewProvider.summary,
                isDark: isDark,
                isLoading: reviewProvider.loadState == ReviewLoadState.loading,
              ),
            const SizedBox(height: 16),

            // ── Eligibility / Write review CTA ─────────────────────────────
            if (auth.isLoggedIn)
              _EligibilityCTA(
                reviewProvider: reviewProvider,
                isDark: isDark,
                onWriteReview: () => _openWriteSheet(context),
              ),

            const SizedBox(height: 16),

            // ── Sort bar + review list ─────────────────────────────────────
            _ReviewListSection(
              reviewProvider: reviewProvider,
              auth: auth,
              isDark: isDark,
              productId: widget.productId,
              onEdit: (review) => _openEditSheet(context, review),
              onDelete: (reviewId) => _confirmDelete(context, reviewId),
              onChangeSort: (sort) {
                reviewProvider.changeSort(
                  productId: widget.productId,
                  sort: sort,
                );
              },
              sortOptions: _sortOptions,
            ),
          ],
        );
      },
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final bool isDark;

  const _SectionHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Customer Reviews',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final ReviewSummary summary;
  final bool isDark;
  final bool isLoading;

  const _SummaryCard({
    required this.summary,
    required this.isDark,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.borderLight;

    if (isLoading && summary.totalCount == 0) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (summary.totalCount == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.reviews_outlined,
              color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StarDisplay(rating: 0, starSize: 18),
                const SizedBox(height: 4),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textDark,
                  ),
                ),
                Text(
                  'Be the first to review this product',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Average score
          Column(
            children: [
              Text(
                summary.avgRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimaryDark,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              StarDisplay(rating: summary.avgRating, starSize: 16),
              const SizedBox(height: 4),
              Text(
                '${summary.totalCount} ${summary.totalCount == 1 ? 'review' : 'reviews'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Rating distribution bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = summary.distribution[star] ?? 0;
                final fraction = summary.totalCount > 0
                    ? count / summary.totalCount
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: AppColors.starAmber, size: 10),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? AppColors.darkBorder
                                : AppColors.borderLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.starAmber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Eligibility CTA ────────────────────────────────────────────────────────────

class _EligibilityCTA extends StatelessWidget {
  final ReviewProvider reviewProvider;
  final bool isDark;
  final VoidCallback onWriteReview;

  const _EligibilityCTA({
    required this.reviewProvider,
    required this.isDark,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    switch (reviewProvider.eligibilityState) {
      case EligibilityState.idle:
      case EligibilityState.loading:
        return const SizedBox.shrink();

      case EligibilityState.error:
        return const SizedBox.shrink(); // Silent — don't confuse user

      case EligibilityState.loaded:
        final e = reviewProvider.eligibility!;

        if (e.canReview) {
          // User is eligible — show CTA
          return _WriteReviewCTA(isDark: isDark, onTap: onWriteReview);
        }

        if (e.reason == 'already_reviewed') {
          // Show "you already reviewed" chip — user can edit/delete from the review card
          return _AlreadyReviewedBanner(isDark: isDark);
        }

        // not_purchased or other
        return _NotEligibleBanner(message: e.message, isDark: isDark);
    }
  }
}

class _WriteReviewCTA extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _WriteReviewCTA({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Your Experience',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rate this product and help others decide',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.star_outline, size: 16),
            label: const Text('Rate Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlreadyReviewedBanner extends StatelessWidget {
  final bool isDark;

  const _AlreadyReviewedBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 18),
          const SizedBox(width: 10),
          Text(
            "You've reviewed this product",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotEligibleBanner extends StatelessWidget {
  final String message;
  final bool isDark;

  const _NotEligibleBanner({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.isNotEmpty
                  ? message
                  : 'Purchase and receive this product to leave a review.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review list + sort bar ─────────────────────────────────────────────────────

class _ReviewListSection extends StatelessWidget {
  final ReviewProvider reviewProvider;
  final AuthProvider auth;
  final bool isDark;
  final String productId;
  final ValueChanged<ReviewModel> onEdit;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onChangeSort;
  final List<(String, String)> sortOptions;

  const _ReviewListSection({
    required this.reviewProvider,
    required this.auth,
    required this.isDark,
    required this.productId,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeSort,
    required this.sortOptions,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewProvider.loadState == ReviewLoadState.loading &&
        reviewProvider.reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (reviewProvider.loadState == ReviewLoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                reviewProvider.loadError ?? 'Failed to load reviews.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final reviews = reviewProvider.reviews;

    // Sort bar
    Widget sortBar = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sortOptions.map((opt) {
          final (value, label) = opt;
          final selected = reviewProvider.currentSort == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => onChangeSort(value),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.black87
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textDark),
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.borderLight),
                ),
              ),
              elevation: 0,
              pressElevation: 0,
            ),
          );
        }).toList(),
      ),
    );

    if (reviews.isEmpty) {
      return Column(
        children: [
          if (reviewProvider.summary.totalCount > 0) ...[
            sortBar,
            const SizedBox(height: 16),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No reviews in this category yet.',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final currentUserId = auth.userId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sortBar,
        const SizedBox(height: 16),
        ...reviews.map((review) {
          final isOwn = currentUserId != null && review.user?.id == currentUserId;
          return ReviewCard(
            review: review,
            isOwnReview: isOwn,
            onEdit: isOwn ? () => onEdit(review) : null,
            onDelete: isOwn ? () => onDelete(review.id) : null,
          );
        }),

        // Load more
        if (reviewProvider.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: reviewProvider.isLoadingMore
                  ? const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    )
                  : TextButton(
                      onPressed: () => reviewProvider.loadMore(productId: productId),
                      child: const Text(
                        'Load more reviews',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
