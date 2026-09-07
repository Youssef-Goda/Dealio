import 'package:cached_network_image/cached_network_image.dart';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/models/category_model.dart';
import 'package:dealio/data/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CategoriesPage
//
// Full-screen category browser used as page index 13 in the nav system.
// Shows top-level categories as grid cards; tapping a parent that has children
// expands an inline sub-category list.  Tapping any category sets the filter
// in CategoryProvider and can navigate back to Home.
// ─────────────────────────────────────────────────────────────────────────────
class CategoriesPage extends StatelessWidget {
  /// When [onCategorySelected] is provided, tapping a category calls this
  /// callback (e.g. to navigate back to Home and apply filter).
  final ValueChanged<String?>? onCategorySelected;

  const CategoriesPage({super.key, this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CategoryProvider>(
      builder: (context, catProv, _) {
        if (catProv.isLoading) {
          return _CategoriesSkeleton(isDark: isDark);
        }

        final topLevel = catProv.categories
            .where((c) => c.parentId == null || c.parentId!.isEmpty)
            .toList();

        if (topLevel.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.tag, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No categories available.',
                  style: TextStyle(
                    fontSize: R.font(context, 16),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: catProv.refresh,
          child: ListView.builder(
            padding: R.symmetric(context, horizontal: 16, vertical: 16),
            itemCount: topLevel.length,
            itemBuilder: (ctx, i) => _CategoryExpandableCard(
              category: topLevel[i],
              isDark: isDark,
              selectedId: catProv.selectedCategoryId,
              onSelect: (id) {
                catProv.selectCategory(id);
                onCategorySelected?.call(id);
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Expandable top-level category card ──────────────────────────────────────

class _CategoryExpandableCard extends StatefulWidget {
  final CategoryModel category;
  final bool isDark;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _CategoryExpandableCard({
    required this.category,
    required this.isDark,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_CategoryExpandableCard> createState() =>
      _CategoryExpandableCardState();
}

class _CategoryExpandableCardState extends State<_CategoryExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final bool hasChildren = cat.children.isNotEmpty;
    final bool isSelected = widget.selectedId == cat.id;
    final isDark = widget.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.borderLight),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Parent row ────────────────────────────────────────────────
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: _CategoryAvatar(
              iconUrl: cat.iconUrl,
              size: 44,
              isSelected: isSelected,
            ),
            title: Text(
              cat.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: R.font(context, 15),
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.secondary),
              ),
            ),
            subtitle: hasChildren
                ? Text(
                    '${cat.children.length} sub-categories',
                    style: TextStyle(
                      fontSize: R.font(context, 12),
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shop now
                GestureDetector(
                  onTap: () => widget.onSelect(cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSelected ? 'Selected' : 'Shop',
                      style: TextStyle(
                        fontSize: R.font(context, 12),
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.black87
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (hasChildren) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Children list ─────────────────────────────────────────────
          if (hasChildren && _expanded) ...[
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cat.children.map((child) {
                  final bool childSelected =
                      widget.selectedId == child.id;
                  return GestureDetector(
                    onTap: () => widget.onSelect(child.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: childSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: childSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        child.name,
                        style: TextStyle(
                          fontSize: R.font(context, 12),
                          fontWeight: childSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: childSelected
                              ? Colors.black87
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textMuted),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Category avatar circle ───────────────────────────────────────────────────

class _CategoryAvatar extends StatelessWidget {
  final String? iconUrl;
  final double size;
  final bool isSelected;

  const _CategoryAvatar({
    required this.iconUrl,
    required this.size,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? AppColors.primary.withOpacity(0.18)
            : AppColors.primary.withOpacity(0.08),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: (iconUrl != null && iconUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: iconUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _icon(),
              )
            : _icon(),
      ),
    );
  }

  Widget _icon() => const Icon(
        LucideIcons.tag,
        size: 20,
        color: AppColors.primary,
      );
}

// ── Skeleton shimmer ─────────────────────────────────────────────────────────

class _CategoriesSkeleton extends StatelessWidget {
  final bool isDark;
  const _CategoriesSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base =
        isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);
    final highlight =
        isDark ? AppColors.darkSurface : const Color(0xFFF5F5F5);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
