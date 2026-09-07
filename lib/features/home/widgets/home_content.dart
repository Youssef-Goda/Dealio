import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/models/product_model.dart';
import 'package:dealio/data/providers/category_provider.dart';
import 'package:dealio/data/providers/product_provider.dart';
import 'package:dealio/data/providers/settings_provider.dart';
import 'package:dealio/features/home/widgets/category_grid_section.dart';
import 'package:dealio/features/home/widgets/home_banner.dart';
import 'package:dealio/features/home/widgets/home_header.dart';
import 'package:dealio/features/products/screens/product_details_page.dart';
import 'package:dealio/features/products/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Kick off categories and settings fetch on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      context.read<StoreSettingsProvider>().fetchPublicSettings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<ProductProvider>().fetchProducts(),
      context.read<CategoryProvider>().fetchCategories(),
      context.read<StoreSettingsProvider>().fetchPublicSettings(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFFFFD700),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              HomeHeader(
                searchController: _searchController,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              R.verticalSpace(context, 2),

              // ── Auto-scrolling banner ──────────────────────────────────────
              const HomeBanner(),

              // ── Circular categories bar ──────────────────────────────────
              const CategoryGridSection(),

              R.verticalSpace(context, 12),

              // ── Product grid ───────────────────────────────────────────────
              Consumer2<ProductProvider, CategoryProvider>(
                builder: (context, productProv, catProv, child) {
                  // Determine which products to show
                  List<Product> products =
                      catProv.selectedCategoryId == null
                      ? productProv.products
                      : productProv.products
                            .where(
                              (p) => p.categoryId == catProv.selectedCategoryId,
                            )
                            .toList();

                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase().trim();
                    products = products.where((p) {
                      return p.name.toLowerCase().contains(query) ||
                          p.description.toLowerCase().contains(query);
                    }).toList();
                  }

                  // ── Sort: available first, out-of-stock last ────────────
                  // Stable sort preserves the server-side ordering within
                  // each group (available vs out-of-stock).
                  products = [
                    ...products.where((p) => p.countInStock > 0),
                    ...products.where((p) => p.countInStock <= 0),
                  ];

                  // loading — show skeleton grid
                  if (productProv.isLoading) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        int crossAxisCount;
                        if (width < 600) {
                          crossAxisCount = 2;
                        } else if (width < 850) {
                          crossAxisCount = 3;
                        } else if (width < 1000) {
                          crossAxisCount = 4;
                        } else {
                          crossAxisCount = 5;
                        }
                        const double spacing = 15;
                        const double hPad = 32;
                        final double tileW =
                            (width - hPad - spacing * (crossAxisCount - 1)) /
                            crossAxisCount;
                        final double cardH =
                            tileW * 0.72 + (R.isMobile(context) ? 110 : 105);

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: R.symmetric(
                            context,
                            horizontal: 16,
                            vertical: 10,
                          ),
                          itemCount: crossAxisCount * 3,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: 15,
                            mainAxisExtent: cardH,
                          ),
                          itemBuilder: (_, __) => const ProductCardSkeleton(),
                        );
                      },
                    );
                  }

                  // no products
                  if (products.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              catProv.selectedCategoryId == null
                                  ? 'No products found in the database.'
                                  : 'No products in this category.',
                              style: TextStyle(
                                fontSize: R.font(context, 16),
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // products grid
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      int crossAxisCount;

                      if (width < 600) {
                        crossAxisCount = 2;
                      } else if (width < 850) {
                        crossAxisCount = 3;
                      } else if (width < 1000) {
                        crossAxisCount = 4;
                      } else {
                        crossAxisCount = 5;
                      }

                      const double spacing = 15;
                      const double hPad = 32;
                      final double tileW =
                          (width - hPad - spacing * (crossAxisCount - 1)) /
                          crossAxisCount;
                      final double cardH =
                          tileW * 0.72 + (R.isMobile(context) ? 110 : 105);

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: R.symmetric(
                          context,
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: 15,
                          mainAxisExtent: cardH,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailsPage(product: product),
                              ),
                            ),
                            child: ProductCard(product: product),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
