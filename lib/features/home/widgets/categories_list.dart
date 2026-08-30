import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/models/category_model.dart';
import 'package:dealio/data/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesList extends StatelessWidget {
  const CategoriesList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<CategoryProvider>(
      builder: (context, catProv, _) {
        if (catProv.isLoading) {
          return _SkeletonBar(isDark: isDark);
        }

        if (catProv.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        final cats = catProv.categories;

        return SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: R.symmetric(context, horizontal: 16, vertical: 0),
            itemCount: cats.length + 1, // +1 for "All"
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return _CategoryChip(
                  label: 'All',
                  isSelected: catProv.selectedCategoryId == null,
                  isDark: isDark,
                  onTap: () => catProv.selectCategory(null),
                );
              }
              final cat = cats[i - 1];
              return _CategoryChip(
                label: cat.name,
                isSelected: catProv.selectedCategoryId == cat.id,
                isDark: isDark,
                onTap: () => catProv.selectCategory(cat.id),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Individual chip ─────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.borderLight),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.black87
                : (isDark ? AppColors.darkTextSecondary : AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

// ── Skeleton shimmer bar ─────────────────────────────────────────────────────

class _SkeletonBar extends StatelessWidget {
  final bool isDark;
  const _SkeletonBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final widths = [60.0, 90.0, 75.0, 50.0, 80.0, 65.0];
          return Shimmer.fromColors(
            baseColor: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
            highlightColor: isDark
                ? AppColors.darkSurface
                : const Color(0xFFF5F5F5),
            child: Container(
              width: widths[i % widths.length],
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          );
        },
      ),
    );
  }
}
