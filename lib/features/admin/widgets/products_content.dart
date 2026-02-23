import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/features/admin/widgets/add_product_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:e_commerce/data/providers/product_provider.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';

class ProductsContent extends StatefulWidget {
  const ProductsContent({super.key});
  @override
  State<ProductsContent> createState() => _ProductsContentState();
}

class _ProductsContentState extends State<ProductsContent> {
  PlutoGridStateManager? stateManager;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool isLoading = false;

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

  void _applySearch(String searchText) {
    if (stateManager == null) return;
    stateManager!.setShowLoading(true);
    stateManager!.setFilter((element) {
      if (searchText.isEmpty) return true;
      final query = searchText.toLowerCase();
      return element.cells['id']!.value.toString().contains(query) ||
          element.cells['name']!.value.toString().toLowerCase().contains(
            query,
          ) ||
          element.cells['price']!.value.toString().contains(query);
    });
    stateManager!.setShowLoading(false);
  }

  void _applyFilter(String filter) {
    if (stateManager == null) return;
    setState(() => _selectedFilter = filter);
    stateManager!.setShowLoading(true);
    stateManager!.setFilter((element) {
      if (filter == 'All') return true;
      final qty = element.cells['countInStock']!.value as int;
      switch (filter) {
        case 'In Stock':
          return qty > 10;
        case 'Out of Stock':
          return qty == 0;
        case 'Low Stock':
          return qty > 0 && qty <= 10;
        default:
          return true;
      }
    });
    stateManager!.setShowLoading(false);
  }

  void _handleBulkDelete() async {
    if (stateManager == null) return;
    final selectedRows = stateManager!.checkedRows;
    if (selectedRows.isEmpty) return;
    final idsToDelete = selectedRows
        .map((r) => r.cells['id']!.value.toString())
        .toList();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: Colors.red,
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
          'Are you sure you want to delete ${idsToDelete.length} product${idsToDelete.length > 1 ? 's' : ''}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
      final productProv = context.read<ProductProvider>();
      for (final id in idsToDelete) await productProv.deleteProduct(id);
      stateManager!.removeRows(selectedRows);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProv, _) {
        return Padding(
          padding: R.all(context, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, productProv),
              const SizedBox(height: 20),
              Expanded(child: _buildGridContainer(context, productProv)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridContainer(
    BuildContext context,
    ProductProvider productProv,
  ) {
    const double radius = 15;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: productProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : PlutoGrid(
              configuration: PlutoGridConfiguration(
                scrollbar: const PlutoGridScrollbarConfig(
                  isAlwaysShown: false,
                  scrollbarThickness: 6,
                  scrollbarRadius: Radius.circular(3),
                ),
                style: PlutoGridStyleConfig(
                  gridBorderRadius: BorderRadius.circular(radius),
                  gridBackgroundColor: AppColors.fillColor,
                  columnTextStyle: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: R.font(context, 13),
                  ),
                  columnHeight: 50,
                  rowHeight: R.isMobile(context) ? 65 : 55,
                  rowColor: Colors.white,
                  evenRowColor: const Color(0xFFF9FAFB),
                  gridBorderColor: Colors.transparent,
                  enableColumnBorderVertical: false,
                  enableCellBorderVertical: false,
                  enableCellBorderHorizontal: true,
                  borderColor: Colors.grey.withOpacity(0.08),
                  activatedColor: AppColors.primary.withOpacity(0.04),
                  activatedBorderColor: AppColors.primary,
                ),
                columnSize: const PlutoGridColumnSizeConfig(
                  autoSizeMode: PlutoAutoSizeMode.scale,
                ),
              ),
              columns: _buildColumns(productProv),
              rows: _buildRows(productProv),
              onLoaded: (event) {
                stateManager = event.stateManager;
                stateManager!.setSelectingMode(PlutoGridSelectingMode.row);
                setState(() {});
              },
              onRowChecked: (_) => setState(() {}),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, ProductProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products Management',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage and monitor your inventory',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child:
                      (stateManager != null &&
                          stateManager!.checkedRows.isNotEmpty)
                      ? Padding(
                          key: const ValueKey('bulk_delete'),
                          padding: const EdgeInsets.only(right: 12),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.08),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                            ),
                            icon: const Icon(LucideIcons.trash2, size: 16),
                            label: Text(
                              'Delete (${stateManager!.checkedRows.length})',
                            ),
                            onPressed: _handleBulkDelete,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no_bulk')),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: R.w(context, 220)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(R.r(context, 12)),
                      boxShadow: [
                        BoxShadow(
                          color: isLoading
                              ? Colors.transparent
                              : AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => showAddProductDialog(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withOpacity(
                          0.2,
                        ),
                        foregroundColor: AppColors.secondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(R.r(context, 10)),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: isLoading
                          ? const SizedBox.shrink()
                          : const Icon(
                              LucideIcons.plus,
                              color: AppColors.secondary,
                              size: 18,
                            ),
                      label: isLoading
                          ? SizedBox(
                              height: R.r(context, 24),
                              width: R.r(context, 24),
                              child: Lottie.asset(
                                'assets/animations/dealio_loading_js.json',
                                fit: BoxFit.contain,
                              ),
                            )
                          : Text(
                              'Add Product',
                              style: TextStyle(
                                fontSize: R.font(context, 15),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildStatCard(
              'Total Products',
              prov.products.length.toString(),
              LucideIcons.package,
              const Color(0xFF3B82F6),
            ),
            _buildStatCard(
              'In Stock',
              prov.products.where((p) => p.countInStock > 10).length.toString(),
              LucideIcons.checkCircle,
              const Color(0xFF22C55E),
            ),
            _buildStatCard(
              'Low Stock',
              prov.products
                  .where((p) => p.countInStock > 0 && p.countInStock <= 10)
                  .length
                  .toString(),
              LucideIcons.trendingDown,
              const Color(0xFFF59E0B),
            ),
            _buildStatCard(
              'Out of Stock',
              prov.products.where((p) => p.countInStock == 0).length.toString(),
              LucideIcons.alertTriangle,
              const Color(0xFFEF4444),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSearchAndFilter(context),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                _applySearch(v);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search by ID, name, or price...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: Colors.grey[400],
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'All',
              'In Stock',
              'Out of Stock',
              'Low Stock',
            ].map(_filterChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.secondary : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  List<PlutoColumn> _buildColumns(ProductProvider productProv) {
    return [
      PlutoColumn(
        title: 'All',
        field: 'checkbox',
        type: PlutoColumnType.text(),
        width: 60,
        enableRowChecked: true,
        enableSorting: false,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.left,
        titleTextAlign: PlutoColumnTextAlign.left,
        enableContextMenu: false,
        enableDropToResize: false,
      ),
      // PlutoColumn(
      //   title: 'ID',
      //   field: 'id',
      //   type: PlutoColumnType.number(),
      //   width: _getColumnWidth(context, 'id'),
      //   textAlign: PlutoColumnTextAlign.center,
      //   titleTextAlign: PlutoColumnTextAlign.center,
      // ),
      //   PlutoColumn(
      //   title: '#',
      //   field: 'serial_id',
      //   type: PlutoColumnType.number(),
      //   width: 80,
      // ),
      PlutoColumn(
        title: 'Code',
        field: 'code',
        type: PlutoColumnType.text(),
        width: 120,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Product Name',
        field: 'name',
        type: PlutoColumnType.text(),
        width: _getColumnWidth(context, 'name'),
        enableContextMenu: false,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Price',
        field: 'price',
        type: PlutoColumnType.number(),
        width: _getColumnWidth(context, 'price'),
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableDropToResize: false,
        renderer: (ctx) {
          final double price =
              double.tryParse(ctx.cell.value.toString()) ?? 0.0;
          return Center(
            child: Text(
              '${NumberFormat('#,###.##').format(price)} EGP',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF16A34A),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Old Price',
        field: 'oldPrice',
        type: PlutoColumnType.number(),
        width: _getColumnWidth(context, 'oldPrice'),
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableDropToResize: false,
        renderer: (ctx) {
          final double? oldPrice = double.tryParse(
            ctx.cell.value?.toString() ?? '',
          );
          if (oldPrice == null || oldPrice <= 0)
            return Center(
              child: Text(
                '—',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            );
          return Center(
            child: Text(
              '${NumberFormat('#,###.##').format(oldPrice)} EGP',
              style: TextStyle(
                color: Colors.grey[400],
                decoration: TextDecoration.lineThrough,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Image',
        field: 'image',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
        enableSorting: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableDropToResize: false,
        renderer: (ctx) {
          final List<String> images = List<String>.from(ctx.cell.value ?? []);
          final String? firstImage = images.isNotEmpty ? images.first : null;
          return Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: firstImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        firstImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.image_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Qty',
        field: 'countInStock',
        type: PlutoColumnType.number(),
        width: _getColumnWidth(context, 'qty'),
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableDropToResize: false,
        renderer: (ctx) {
          final int qty = ctx.cell.value as int? ?? 0;
          return Center(
            child: Text(
              qty.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: qty == 0
                    ? Colors.red
                    : qty <= 10
                    ? Colors.orange
                    : Colors.grey[800],
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Status',
        field: 'stockStatus',
        type: PlutoColumnType.text(),
        width: _getColumnWidth(context, 'status'),
        enableSorting: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableDropToResize: false,
        renderer: (ctx) {
          final int qty = ctx.row.cells['countInStock']?.value ?? 0;
          final bool inStock = qty > 10;
          final bool lowStock = qty > 0 && qty <= 10;
          final Color color = lowStock
              ? const Color(0xFFF59E0B)
              : inStock
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444);
          final String label = lowStock
              ? 'LOW STOCK'
              : inStock
              ? 'IN STOCK'
              : 'OUT OF STOCK';
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Rating',
        field: 'rating',
        type: PlutoColumnType.number(format: '#.##'),
        width: _getColumnWidth(context, 'rating'),
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableDropToResize: false,
        renderer: (ctx) {
          final double rating = double.tryParse(ctx.cell.value.toString()) ?? 0;
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 14, color: Colors.amber[600]),
                const SizedBox(width: 3),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        enableSorting: false,
        width: _getColumnWidth(context, 'actions'),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableDropToResize: false,
        renderer: (ctx) {
          final String? productId = ctx.row.cells['id']?.value.toString();
          final product = productProv.products.firstWhere(
            (p) => p.id.toString() == productId,
          );
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionBtn(
                icon: LucideIcons.edit,
                color: const Color(0xFF3B82F6),
                tooltip: 'Edit',
                onTap: () => showAddProductDialog(context, product: product),
              ),
              const SizedBox(width: 6),
              _actionBtn(
                icon: LucideIcons.trash2,
                color: const Color(0xFFEF4444),
                tooltip: 'Delete',
                onTap: () async {
                  final prov = context.read<ProductProvider>();
                  if (await prov.deleteProduct(product.id))
                    ctx.stateManager.removeRows([ctx.row]);
                },
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Add At',
        field: 'createdAt_field',
        type: PlutoColumnType.text(),
        width: _getColumnWidth(context, 'createdAt'),
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Last Update',
        field: 'updatedAt_field',
        type: PlutoColumnType.text(),
        width: _getColumnWidth(context, 'updatedAt'),
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableContextMenu: false,
        enableDropToResize: false,
      ),
    ];
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  List<PlutoRow> _buildRows(ProductProvider productProv) {
    return (productProv.products.toList()..sort((a, b) => b.id.compareTo(a.id)))
        .map(
          (p) => PlutoRow(
            cells: {
              'checkbox': PlutoCell(value: ''),
              // 'id': PlutoCell(value: p.id),
              // 'serial_id': PlutoCell(value: p.serialId),
              'code': PlutoCell(value: p.code),
              'name': PlutoCell(value: p.name),
              'price': PlutoCell(value: p.price),
              'oldPrice': PlutoCell(value: p.oldPrice),
              'image': PlutoCell(value: p.imageUrls),
              'countInStock': PlutoCell(value: p.countInStock),
              'stockStatus': PlutoCell(value: ''),
              'rating': PlutoCell(value: p.rating),
              'actions': PlutoCell(value: ''),
              'createdAt_field': PlutoCell(
                value: DateFormat(
                  'E, dd/MM/yyyy, HH:mm',
                ).format(p.createdAt!.toLocal()),
              ),
              'updatedAt_field': PlutoCell(
                value: p.updatedAt != null
                    ? DateFormat(
                        'E, dd/MM/yyyy, HH:mm',
                      ).format(p.updatedAt!.toLocal())
                    : 'Never',
              ),
            },
          ),
        )
        .toList();
  }

  double _getColumnWidth(BuildContext context, String columnType) {
    return R.w(
      context,
      R.responsive<double>(
        context,
        mobile: _getMobileWidth(columnType),
        tablet: _getTabletWidth(columnType),
        desktop: _getDesktopWidth(columnType),
      ),
    );
  }

  double _getMobileWidth(String type) {
    switch (type) {
      case 'id':
        return 80;
      case 'name':
        return 250;
      case 'price':
        return 100;
      case 'qty':
        return 60;
      case 'status':
        return 110;
      case 'actions':
        return 100;
      default:
        return 100;
    }
  }

  double _getDesktopWidth(String type) {
    switch (type) {
      case 'id':
        return 70;
      case 'name':
        return 160;
      case 'price':
        return 160;
      case 'oldPrice':
        return 140;
      case 'qty':
        return 80;
      case 'status':
        return 150;
      case 'rating':
        return 90;
      case 'actions':
        return 120;
      case 'createdAt':
        return 190;
      case 'updatedAt':
        return 190;
      default:
        return 130;
    }
  }

  double _getTabletWidth(String type) {
    switch (type) {
      case 'id':
        return 80;
      case 'name':
        return 230;
      case 'price':
        return 140;
      case 'oldPrice':
        return 140;
      case 'qty':
        return 80;
      case 'status':
        return 150;
      case 'rating':
        return 90;
      case 'actions':
        return 120;
      case 'createdAt':
        return 190;
      case 'updatedAt':
        return 190;
      default:
        return 130;
    }
  }
}
