import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/providers/product_provider.dart';
import 'package:dealio/data/providers/wishlist_provider.dart';
import 'package:dealio/features/products/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<WishlistProvider, ProductProvider>(
      builder: (context, wishlist, products, _) {
        final favoriteProducts = products.products
            .where((p) => wishlist.isFavorite(p.id))
            .toList();

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── App Bar ─────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                foregroundColor: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.secondary,
                title: Text(
                  'My Favorites',
                  style: TextStyle(
                    fontSize: R.font(context, 18),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.secondary,
                  ),
                ),
                actions: [
                  if (favoriteProducts.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _confirmClear(context, wishlist),
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: AppColors.errorRed,
                      ),
                      label: const Text(
                        'Clear all',
                        style: TextStyle(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderLight,
                  ),
                ),
              ),

              // ── Count Chip ───────────────────────────────────────────────
              if (favoriteProducts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      R.w(context, 16),
                      R.h(context, 16),
                      R.w(context, 16),
                      R.h(context, 8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: R.w(context, 10),
                            vertical: R.h(context, 4),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.errorRed.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.errorRed,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${favoriteProducts.length} item${favoriteProducts.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: R.font(context, 12),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Product Grid ─────────────────────────────────────────────
              if (favoriteProducts.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: R.w(context, 12),
                    vertical: R.h(context, 8),
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final int cols = R.isDesktop(context)
                          ? 4
                          : R.isTablet(context)
                          ? 3
                          : 2;
                      const double spacing = 12;
                      const double hPad = 24;
                      final double tileW =
                          (constraints.crossAxisExtent -
                              hPad -
                              spacing * (cols - 1)) /
                          cols;
                      final double cardH =
                          tileW * 0.72 + (R.isMobile(context) ? 110 : 105);

                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              ProductCard(product: favoriteProducts[index]),
                          childCount: favoriteProducts.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          mainAxisExtent: cardH,
                        ),
                      );
                    },
                  ),
                ),

              // ── Empty State ──────────────────────────────────────────────
              if (favoriteProducts.isEmpty)
                SliverFillRemaining(
                  child: _EmptyFavoritesState(isDark: isDark),
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context, WishlistProvider wishlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all favorites?'),
        content: const Text(
          'All favorited products will be removed from your wishlist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              wishlist.clear();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Clear',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyFavoritesState extends StatelessWidget {
  final bool isDark;
  const _EmptyFavoritesState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(R.r(context, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heart icon with animated glow
            Container(
              width: R.r(context, 100),
              height: R.r(context, 100),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorRed.withOpacity(0.08),
                border: Border.all(
                  color: AppColors.errorRed.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: R.r(context, 44),
                color: AppColors.errorRed.withOpacity(0.5),
              ),
            ),
            SizedBox(height: R.h(context, 24)),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: R.font(context, 20),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: R.h(context, 10)),
            Text(
              'Tap the ♥ heart on any product\nto save it here for later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: R.font(context, 14),
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
