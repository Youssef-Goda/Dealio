import 'package:dealio/core/widgets/focal_network_image.dart';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/models/category_model.dart';
import 'package:dealio/data/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CategoryGridSection
//
// Displays a horizontal row of circular avatar cards for top-level categories
// (those without a parentId) under the heading "Shop by Category".
//
// Tapping an avatar selects that category in [CategoryProvider], which the
// product grid in [HomeContent] already filters by.
// ─────────────────────────────────────────────────────────────────────────────
class CategoryGridSection extends StatelessWidget {
  const CategoryGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CategoryProvider>(
      builder: (context, catProv, _) {
        // Loading skeleton
        if (catProv.isLoading) {
          return _CategorySectionSkeleton(isDark: isDark);
        }

        // Only show top-level (parent) categories
        final topLevel = catProv.categories
            .where((c) => c.parentId == null || c.parentId!.isEmpty)
            .toList();

        if (topLevel.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(
            top: R.h(context, 16),
            bottom: R.h(context, 4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section header ───────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: R.w(context, 20),
                ),
                child: Row(
                  children: [
                    Text(
                      'Shop by Category',
                      style: TextStyle(
                        fontSize: R.font(context, 16),
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.secondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => catProv.selectCategory(null),
                      child: Text(
                        'See all',
                        style: TextStyle(
                          fontSize: R.font(context, 13),
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Horizontal avatar row ───────────────────────────────────
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: R.w(context, 16),
                  ),
                  itemCount: topLevel.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (ctx, i) => _CategoryAvatarCard(
                    category: topLevel[i],
                    isDark: isDark,
                    isSelected:
                        catProv.selectedCategoryId == topLevel[i].id,
                    onTap: () => catProv.selectCategory(topLevel[i].id),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Individual circular avatar card ─────────────────────────────────────────

class _CategoryAvatarCard extends StatelessWidget {
  final CategoryModel category;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryAvatarCard({
    required this.category,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 60;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: avatarSize + 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Circle avatar ─────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary.withOpacity(0.18)
                    : (isDark
                        ? AppColors.darkSurface
                        : const Color(0xFFF0F0F0)),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipOval(
                child: _buildIcon(avatarSize),
              ),
            ),

            const SizedBox(height: 6),

            // ── Label ─────────────────────────────────────────────────────
            Text(
              category.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMuted),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(double size) {
    final iconUrl = category.iconUrl;

    if (iconUrl != null && iconUrl.isNotEmpty) {
      return FocalNetworkImage(
        imageUrl: iconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallbackIcon(size),
        errorWidget: (_, __, ___) => _fallbackIcon(size),
      );
    }

    return _fallbackIcon(size);
  }

  Widget _fallbackIcon(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.transparent,
      child: const Icon(
        LucideIcons.tag,
        size: 26,
        color: AppColors.primary,
      ),
    );
  }
}

// ── Skeleton shimmer while categories are loading ───────────────────────────

class _CategorySectionSkeleton extends StatelessWidget {
  final bool isDark;
  const _CategorySectionSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmerBase =
        isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);
    final shimmerHighlight =
        isDark ? AppColors.darkSurface : const Color(0xFFF5F5F5);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: shimmerBase,
              highlightColor: shimmerHighlight,
              child: Container(
                width: 160,
                height: 18,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Avatar row skeleton
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, __) => Shimmer.fromColors(
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 52,
                      height: 10,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
