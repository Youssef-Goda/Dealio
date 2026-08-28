import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/widgets/dealio_skeleton.dart';
import 'package:e_commerce/features/admin/widgets/add_product_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:e_commerce/data/providers/product_provider.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:e_commerce/features/admin/widgets/product_details_dialog.dart';
import 'package:e_commerce/data/models/product_model.dart';

class ProductsContent extends StatefulWidget {
  const ProductsContent({super.key});
  @override
  State<ProductsContent> createState() => _ProductsContentState();
}

class _ProductsContentState extends State<ProductsContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProductProvider>().fetchProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateForSearch(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return isoString.toLowerCase();
    }
  }

  List<Product> _getFilteredAndSortedProducts(List<Product> products) {
    final searchText = _searchController.text.toLowerCase().trim();

    var filtered = products.where((element) {
      bool matchesSearch = true;

      if (searchText.isNotEmpty) {
        final String code = element.code.toLowerCase();
        final String name = element.name.toLowerCase();
        final String desc = element.description.toLowerCase();
        final String price = element.price.toString().toLowerCase();

        matchesSearch =
            code.contains(searchText) ||
            name.contains(searchText) ||
            desc.contains(searchText) ||
            price.contains(searchText);
      }

      bool matchesFilter = true;
      if (_selectedFilter != 'All') {
        final qty = element.countInStock;
        switch (_selectedFilter) {
          case 'In Stock':
            matchesFilter = qty > 10;
            break;
          case 'Out of Stock':
            matchesFilter = qty == 0;
            break;
          case 'Low Stock':
            matchesFilter = qty > 0 && qty <= 10;
            break;
        }
      }

      return matchesSearch && matchesFilter;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'Newest':
        filtered.sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          if (aDate == null && bDate == null) return (b.id).compareTo(a.id);
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        break;
      case 'Oldest':
        filtered.sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          if (aDate == null && bDate == null) return (a.id).compareTo(b.id);
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
        break;
      case 'Price High-Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Price Low-High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Name A-Z':
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'Name Z-A':
        filtered.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
    }

    return filtered;
  }

  void _handleBulkDelete(BuildContext context) async {
    final productProv = context.read<ProductProvider>();
    final selectedIds = productProv.selectedProductIds;
    if (selectedIds.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: AppColors.errorRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${selectedIds.length} '
          'product${selectedIds.length > 1 ? 's' : ''}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final idsToDelete = List<String>.from(selectedIds);
      for (final id in idsToDelete) {
        await productProv.deleteProduct(id);
      }
      productProv.selectedProductIds.clear();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProv, _) {
        final filteredProducts = _getFilteredAndSortedProducts(
          productProv.products,
        );
        final bool isMobile = R.isMobile(context);
        final bool isLandscapeMobile = MediaQuery.of(context).size.height < 600;
        final bool shouldScroll = isMobile || isLandscapeMobile;

        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProductsHeader(
              checkedRowsCount: productProv.selectedProductIds.length,
              onBulkDelete: () => _handleBulkDelete(context),
              isLoading: productProv.isLoading,
              onAddProduct: () => showAddProductDialog(context),
            ),
            const SizedBox(height: 24),
            _ProductsStatsRow(productProv: productProv),
            const SizedBox(height: 20),
            _ProductsSearchFilterBar(
              searchController: _searchController,
              sortBy: _sortBy,
              selectedFilter: _selectedFilter,
              onSearchChanged: (v) => setState(() {}),
              onSortByChanged: (v) => setState(() => _sortBy = v),
              onFilterChanged: (v) => setState(() => _selectedFilter = v),
            ),
            const SizedBox(height: 20),
            shouldScroll
                ? SizedBox(
                    height: 450,
                    child: _CustomProductsTable(
                      products: filteredProducts,
                      productProv: productProv,
                    ),
                  )
                : Expanded(
                    child: _CustomProductsTable(
                      products: filteredProducts,
                      productProv: productProv,
                    ),
                  ),
          ],
        );

        return RefreshIndicator(
          onRefresh: () => productProv.fetchProducts(),
          color: const Color(0xFFFFD700),
          child: Padding(
            padding: R.all(context, 20),
            child: shouldScroll
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: content,
                  )
                : content,
          ),
        );
      },
    );
  }
}

// ===========================================================================
// PRIVATE SUB-WIDGETS
// ===========================================================================

class _ProductsHeader extends StatelessWidget {
  final int checkedRowsCount;
  final VoidCallback onBulkDelete;
  final bool isLoading;
  final VoidCallback onAddProduct;

  const _ProductsHeader({
    required this.checkedRowsCount,
    required this.onBulkDelete,
    required this.isLoading,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Products Management',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and monitor your inventory',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: checkedRowsCount > 0
                  ? Padding(
                      key: const ValueKey('bulk_delete'),
                      padding: const EdgeInsets.only(right: 12),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.errorRed.withOpacity(
                            isDark ? 0.15 : 0.08,
                          ),
                          foregroundColor: AppColors.errorRed,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: AppColors.errorRed.withOpacity(0.3),
                            ),
                          ),
                        ),
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        label: Text('Delete ($checkedRowsCount)'),
                        onPressed: onBulkDelete,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isLoading)
                    BoxShadow(
                      color: AppColors.primary.withOpacity(
                        isDark ? 0.25 : 0.15,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onAddProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: isLoading
                    ? const SizedBox.shrink()
                    : const Icon(LucideIcons.plus, size: 18),
                label: isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: Lottie.asset(
                          'assets/animations/dealio_loading_js.json',
                        ),
                      )
                    : const Text(
                        'Add Product',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductsStatsRow extends StatelessWidget {
  final ProductProvider productProv;
  const _ProductsStatsRow({required this.productProv});

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPortraitMobile = MediaQuery.of(context).size.width < 550;

    if (isPortraitMobile) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.05) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? color.withOpacity(0.2)
                  : Theme.of(context).dividerColor.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : color.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.05) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? color.withOpacity(0.2)
                : Theme.of(context).dividerColor.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (isDark)
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show stat-card skeletons while loading for a polished first impression.
    if (productProv.isLoading) {
      return const AdminStatCardSkeleton();
    }
    return Row(
      children: [
        _buildStatCard(
          context,
          'Total Products',
          productProv.products.length.toString(),
          LucideIcons.package,
          AppColors.infoBlue,
        ),
        _buildStatCard(
          context,
          'In Stock',
          productProv.products
              .where((p) => p.countInStock > 10)
              .length
              .toString(),
          LucideIcons.circleCheckBig,
          AppColors.successGreen,
        ),
        _buildStatCard(
          context,
          'Low Stock',
          productProv.products
              .where((p) => p.countInStock > 0 && p.countInStock <= 10)
              .length
              .toString(),
          LucideIcons.trendingDown,
          AppColors.warningAmber,
        ),
        _buildStatCard(
          context,
          'Out of Stock',
          productProv.products
              .where((p) => p.countInStock == 0)
              .length
              .toString(),
          LucideIcons.triangleAlert,
          AppColors.errorRed,
        ),
      ],
    );
  }
}

class _ProductsSearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String sortBy;
  final String selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortByChanged;
  final ValueChanged<String> onFilterChanged;

  static const List<String> _sortByOptions = [
    'Newest',
    'Oldest',
    'Price High-Low',
    'Price Low-High',
    'Name A-Z',
    'Name Z-A',
  ];
  static const List<String> _filterOptions = [
    'All',
    'In Stock',
    'Out of Stock',
    'Low Stock',
  ];

  const _ProductsSearchFilterBar({
    required this.searchController,
    required this.sortBy,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onSortByChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = R.isMobile(context);

    final inputDecoration = BoxDecoration(
      color: isDark
          ? Colors.white.withOpacity(0.04)
          : AppColors.background.withOpacity(0.35),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
      ),
    );

    Widget buildDropdown({
      required IconData icon,
      required String value,
      required List<String> options,
      required ValueChanged<String> onChanged,
      String? tooltip,
    }) {
      return Tooltip(
        message: tooltip ?? '',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: inputDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: Theme.of(context).hintColor.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  icon: Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: Theme.of(context).hintColor.withOpacity(0.5),
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                  items: options
                      .map(
                        (v) =>
                            DropdownMenuItem<String>(value: v, child: Text(v)),
                      )
                      .toList(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final searchField = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white24
              : Theme.of(context).hintColor.withOpacity(0.4),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          LucideIcons.search,
          size: 17,
          color: isDark
              ? Colors.white24
              : Theme.of(context).hintColor.withOpacity(0.4),
        ),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: isDark
                      ? Colors.white24
                      : Theme.of(context).hintColor.withOpacity(0.4),
                ),
                onPressed: () {
                  searchController.clear();
                  onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.04)
            : AppColors.background.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.03),
          ),
        ),
        // No yellow focus border — neutral grey instead
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.surfaceLight,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildDropdown(
                        icon: LucideIcons.arrowUpDown,
                        value: sortBy,
                        options: _sortByOptions,
                        onChanged: onSortByChanged,
                        tooltip: 'Sort By',
                      ),
                      const SizedBox(width: 8),
                      buildDropdown(
                        icon: LucideIcons.listFilter,
                        value: selectedFilter,
                        options: _filterOptions,
                        onChanged: onFilterChanged,
                        tooltip: 'Filter',
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                buildDropdown(
                  icon: LucideIcons.arrowUpDown,
                  value: sortBy,
                  options: _sortByOptions,
                  onChanged: onSortByChanged,
                  tooltip: 'Sort By',
                ),
                const SizedBox(width: 8),
                buildDropdown(
                  icon: LucideIcons.listFilter,
                  value: selectedFilter,
                  options: _filterOptions,
                  onChanged: onFilterChanged,
                  tooltip: 'Filter',
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOM TABLE
// ---------------------------------------------------------------------------

class _CustomProductsTable extends StatelessWidget {
  final List<Product> products;
  final ProductProvider productProv;

  const _CustomProductsTable({
    required this.products,
    required this.productProv,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = R.isMobile(context);

    if (productProv.isLoading) {
      return const AdminTableSkeleton();
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.packageOpen,
              size: 48,
              color: Theme.of(context).hintColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No products found.',
              style: TextStyle(
                color: Theme.of(context).hintColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    Widget tableContent = Column(
      children: [
        _buildHeader(context, productProv),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: products.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.05),
            ),
            itemBuilder: (context, index) {
              return _TableRow(
                product: products[index],
                productProv: productProv,
                isEven: index % 2 == 0,
              );
            },
          ),
        ),
      ],
    );

    if (isMobile) {
      tableContent = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 850,
          child: tableContent,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : AppColors.surfaceLight,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: tableContent,
    );
  }

  Widget _buildHeader(BuildContext context, ProductProvider productProv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        // Seamless — matches table body card color
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: _CheckboxCell(
              isChecked: productProv.isAllSelected,
              onToggle: () => productProv.toggleSelectAll(),
            ),
          ),
          const Expanded(flex: 1, child: _HeaderCell('SKU', center: true)),
          const Expanded(flex: 4, child: _HeaderCell('Product Name')),
          const Expanded(flex: 2, child: _HeaderCell('Price', center: true)),
          const SizedBox(width: 80, child: _HeaderCell('Image', center: true)),
          const Expanded(flex: 1, child: _HeaderCell('Qty', center: true)),
          const Expanded(flex: 2, child: _HeaderCell('Status', center: true)),
          const SizedBox(
            width: 80,
            child: _HeaderCell('Actions', center: true),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String title;
  final bool center;

  const _HeaderCell(this.title, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: center
          ? Center(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor.withOpacity(0.8),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor.withOpacity(0.8),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
    );
  }
}

class _TableRow extends StatefulWidget {
  final Product product;
  final ProductProvider productProv;
  final bool isEven;

  const _TableRow({
    required this.product,
    required this.productProv,
    required this.isEven,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.productProv.selectedProductIds.contains(
      widget.product.id,
    );

    final bgColor = isSelected
        ? AppColors.primary.withOpacity(0.06)
        : _isHovered
        ? (isDark
              ? Colors.white.withOpacity(0.04)
              : AppColors.surfaceLight.withOpacity(0.6))
        // even index = lighter tint, odd = transparent
        : widget.isEven
        ? (isDark
              ? Colors.white.withOpacity(0.02)
              : AppColors.surfaceLight.withOpacity(0.4))
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          widget.productProv.toggleProductSelection(widget.product.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 68,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: bgColor),
          child: Row(
            children: [
              // 1. Checkbox: Fixed 50
              SizedBox(
                width: 50,
                child: _CheckboxCell(
                  isChecked: isSelected,
                  onToggle: () => widget.productProv.toggleProductSelection(
                    widget.product.id,
                  ),
                ),
              ),
              // 2. Code (SKU): Flex 1
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    widget.product.code,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // 3. Product Name: Flex 4
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.product.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // 4. Price: Flex 2
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '${NumberFormat('#,###.##').format(widget.product.price)} EGP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.successGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // 5. Image: Fixed 80
              SizedBox(
                width: 80,
                child: Center(
                  child: _buildImage(widget.product.imageUrls, context),
                ),
              ),
              // 6. Qty: Flex 1
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    widget.product.countInStock.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.product.countInStock == 0
                          ? AppColors.errorRed
                          : widget.product.countInStock <= 10
                          ? AppColors.warningAmber
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              // 7. Status: Flex 2
              Expanded(
                flex: 2,
                child: Center(
                  child: _buildStatus(widget.product.countInStock, context),
                ),
              ),
              // 8. Actions: Fixed 80
              SizedBox(
                width: 80,
                child: Center(
                  child: Tooltip(
                    message: 'View Details',
                    child: InkWell(
                      onTap: () {
                        showProductDetailsDialog(
                          context,
                          widget.product,
                          () async {
                            await widget.productProv.deleteProduct(
                              widget.product.id,
                            );
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.actionIndigo.withOpacity(
                            isDark ? 0.08 : 0.05,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.actionIndigo.withOpacity(
                              isDark ? 0.15 : 0.1,
                            ),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.eye,
                          size: 18,
                          color: AppColors.actionIndigo,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(List<String>? imageUrls, BuildContext context) {
    final String? firstImage = (imageUrls != null && imageUrls.isNotEmpty)
        ? imageUrls.first
        : null;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: firstImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                firstImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  LucideIcons.image,
                  color: Theme.of(context).hintColor.withOpacity(0.3),
                  size: 18,
                ),
              ),
            )
          : Icon(
              LucideIcons.image,
              color: Theme.of(context).hintColor.withOpacity(0.3),
              size: 18,
            ),
    );
  }

  Widget _buildStatus(int qty, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool inStock = qty > 10;
    final bool lowStock = qty > 0 && qty <= 10;

    final Color color = lowStock
        ? AppColors.warningAmber
        : inStock
        ? (isDark ? const Color(0xFF4ADE80) : AppColors.successGreen)
        : AppColors.errorRed;

    final String label = lowStock
        ? 'LOW STOCK'
        : inStock
        ? 'IN STOCK'
        : 'OUT OF STOCK';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CheckboxCell extends StatefulWidget {
  final bool isChecked;
  final VoidCallback onToggle;

  const _CheckboxCell({required this.isChecked, required this.onToggle});

  @override
  State<_CheckboxCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends State<_CheckboxCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final checkColor = AppColors.primary;
    final checkBgChecked = AppColors.primary.withOpacity(isDark ? 0.18 : 0.12);
    final checkBgHover = AppColors.primary.withOpacity(isDark ? 0.08 : 0.05);
    final checkBorderIdle = isDark
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.2);

    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: widget.isChecked
                  ? checkBgChecked
                  : _hovered
                  ? checkBgHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.isChecked
                    ? checkColor
                    : _hovered
                    ? checkColor.withOpacity(0.6)
                    : checkBorderIdle,
                width: widget.isChecked ? 1.5 : 1.2,
              ),
            ),
            child: widget.isChecked
                ? Icon(LucideIcons.check, size: 13, color: checkColor)
                : null,
          ),
        ),
      ),
    );
  }
}
