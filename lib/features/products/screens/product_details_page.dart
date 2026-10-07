import 'dart:ui';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/product_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/review_provider.dart';
import 'package:dealio/features/admin/widgets/product_details_dialog.dart';
import 'package:dealio/data/providers/product_provider.dart';
import 'package:dealio/features/products/widgets/review_section.dart';
import 'package:dealio/features/products/widgets/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry — push from home grid
// ─────────────────────────────────────────────────────────────────────────────
class ProductDetailsPage extends StatefulWidget {
  final Product product;
  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Product _product;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _addingToCart = false;

  final PageController _imagePageController = PageController();

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  int get _discount {
    if (_product.oldPrice != null && _product.oldPrice! > _product.price) {
      return (((_product.oldPrice! - _product.price) / _product.oldPrice!) *
              100)
          .round();
    }
    return 0;
  }

  bool get _isAdmin {
    final auth = context.read<AuthProvider>();
    final role = (auth.user['role'] ?? '').toString().toLowerCase();
    final email = (auth.user['email'] ?? '').toString().toLowerCase();
    return role == 'admin' ||
        role == 'owner' ||
        email == 'youssefgoda.dev@gmail.com';
  }

  Future<void> _handleAddToCart() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.pushNamed(context, '/login', arguments: {'fromCart': true});
      return;
    }
    setState(() => _addingToCart = true);
    HapticFeedback.lightImpact();
    final cart = context.read<CartProvider>();
    final error = await cart.addItem(
      productId: _product.id,
      productName: _product.name,
      productCode: _product.code,
      imageUrl: _product.imageUrls.isNotEmpty ? _product.imageUrls.first : null,
      unitPrice: _product.price,
      oldPrice: _product.oldPrice,
      rating: _product.rating,
      countInStock: _product.countInStock,
      quantity: _quantity,
    );
    if (mounted) {
      setState(() => _addingToCart = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error == null
                ? '✅ Added $_quantity × ${_product.name} to cart'
                : '⚠️ $error',
          ),
          backgroundColor: error == null
              ? AppColors.successGreen
              : AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 700) {
            return _DesktopLayout(
              product: _product,
              selectedImageIndex: _selectedImageIndex,
              quantity: _quantity,
              discount: _discount,
              isAdmin: _isAdmin,
              addingToCart: _addingToCart,
              onImageTap: (i) => setState(() => _selectedImageIndex = i),
              onIncrease: () {
                if (_quantity < _product.countInStock) {
                  setState(() => _quantity++);
                }
              },
              onDecrease: () {
                if (_quantity > 1) setState(() => _quantity--);
              },
              onAddToCart: _handleAddToCart,
              onEdit: () => showProductDetailsDialog(
                context,
                _product,
                () => context.read<ProductProvider>().fetchProducts(),
              ),
              onDelete: () async {
                final confirmed = await _confirmDelete(context);
                if (confirmed == true && mounted) {
                  await context.read<ProductProvider>().deleteProduct(
                    _product.id,
                  );
                  if (mounted) Navigator.of(context).pop();
                }
              },
            );
          }
          return _MobileLayout(
            product: _product,
            selectedImageIndex: _selectedImageIndex,
            quantity: _quantity,
            discount: _discount,
            isAdmin: _isAdmin,
            addingToCart: _addingToCart,
            onImageTap: (i) => setState(() => _selectedImageIndex = i),
            onIncrease: () {
              if (_quantity < _product.countInStock) {
                setState(() => _quantity++);
              }
            },
            onDecrease: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
            onAddToCart: _handleAddToCart,
            onEdit: () => showProductDetailsDialog(
              context,
              _product,
              () => context.read<ProductProvider>().fetchProducts(),
            ),
            onDelete: () async {
              final confirmed = await _confirmDelete(context);
              if (confirmed == true && mounted) {
                await context.read<ProductProvider>().deleteProduct(
                  _product.id,
                );
                if (mounted) Navigator.of(context).pop();
              }
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Product'),
      content: Text(
        'Are you sure you want to permanently delete "${_product.name}"?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Delete',
            style: TextStyle(color: AppColors.errorRed),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared props bundle
// ─────────────────────────────────────────────────────────────────────────────
class _DetailsProps {
  final Product product;
  final int selectedImageIndex;
  final int quantity;
  final int discount;
  final bool isAdmin;
  final bool addingToCart;
  final ValueChanged<int> onImageTap;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onAddToCart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailsProps({
    required this.product,
    required this.selectedImageIndex,
    required this.quantity,
    required this.discount,
    required this.isAdmin,
    required this.addingToCart,
    required this.onImageTap,
    required this.onIncrease,
    required this.onDecrease,
    required this.onAddToCart,
    required this.onEdit,
    required this.onDelete,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop / Wide layout  (>700px)
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final Product product;
  final int selectedImageIndex;
  final int quantity;
  final int discount;
  final bool isAdmin;
  final bool addingToCart;
  final ValueChanged<int> onImageTap;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onAddToCart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DesktopLayout({
    required this.product,
    required this.selectedImageIndex,
    required this.quantity,
    required this.discount,
    required this.isAdmin,
    required this.addingToCart,
    required this.onImageTap,
    required this.onIncrease,
    required this.onDecrease,
    required this.onAddToCart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final props = _DetailsProps(
      product: product,
      selectedImageIndex: selectedImageIndex,
      quantity: quantity,
      discount: discount,
      isAdmin: isAdmin,
      addingToCart: addingToCart,
      onImageTap: onImageTap,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      onAddToCart: onAddToCart,
      onEdit: onEdit,
      onDelete: onDelete,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left — sticky image gallery
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: _ImageGallery(props: props, isDesktop: true),
              ),
              // Floating back + admin buttons
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: _BlurButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              if (isAdmin)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: _AdminFloatingBar(onEdit: onEdit, onDelete: onDelete),
                ),
            ],
          ),
        ),
        // Right — scrollable info
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 56, 32, 32),
            child: _InfoSection(props: props),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile layout  (≤700px)
// ─────────────────────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final Product product;
  final int selectedImageIndex;
  final int quantity;
  final int discount;
  final bool isAdmin;
  final bool addingToCart;
  final ValueChanged<int> onImageTap;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onAddToCart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileLayout({
    required this.product,
    required this.selectedImageIndex,
    required this.quantity,
    required this.discount,
    required this.isAdmin,
    required this.addingToCart,
    required this.onImageTap,
    required this.onIncrease,
    required this.onDecrease,
    required this.onAddToCart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final props = _DetailsProps(
      product: product,
      selectedImageIndex: selectedImageIndex,
      quantity: quantity,
      discount: discount,
      isAdmin: isAdmin,
      addingToCart: addingToCart,
      onImageTap: onImageTap,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      onAddToCart: onAddToCart,
      onEdit: onEdit,
      onDelete: onDelete,
    );

    final double expandedHeight = MediaQuery.of(context).size.height * 0.50;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: expandedHeight,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: _ImageGallery(props: props, isDesktop: false),
            collapseMode: CollapseMode.parallax,
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: _BlurButton(
              icon: LucideIcons.arrowLeft,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          actions: isAdmin
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _AdminFloatingBar(
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ),
                ]
              : [],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: _InfoSection(props: props),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image gallery widget
// ─────────────────────────────────────────────────────────────────────────────
class _ImageGallery extends StatelessWidget {
  final _DetailsProps props;
  final bool isDesktop;

  const _ImageGallery({required this.props, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images = props.product.imageUrls;
    final selectedUrl = images.isNotEmpty
        ? images[props.selectedImageIndex]
        : null;

    return Column(
      children: [
        // Main image
        Expanded(
          child: Container(
            color: isDark ? AppColors.darkBackground : AppColors.fillColor,
            child: Hero(
              tag: 'product-image-${props.product.id}',
              child: _NetworkImage(
                url: selectedUrl,
                isDark: isDark,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Thumbnail strip (only if multiple images)
        if (images.length > 1)
          Container(
            height: 70,
            color: isDark ? const Color(0xFF1A1A1A) : AppColors.surfaceLight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isActive = i == props.selectedImageIndex;
                return GestureDetector(
                  onTap: () => props.onImageTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _NetworkImage(
                        url: images[i],
                        isDark: isDark,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info section (shared between desktop & mobile)
// ─────────────────────────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final _DetailsProps props;
  const _InfoSection({required this.props});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = props.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Code + status badges
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _Pill(label: p.code, color: AppColors.infoBlue, isDark: isDark),
            _StockBadge(stock: p.countInStock, isDark: isDark),
            if (props.discount > 0)
              _Pill(
                label: '-${props.discount}%',
                color: AppColors.errorRed,
                isDark: isDark,
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Product name
        Text(
          p.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.25,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),

        // Price row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${p.price.toStringAsFixed(0)} EGP',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.successGreen,
                letterSpacing: -0.5,
              ),
            ),
            if (p.oldPrice != null && p.oldPrice! > p.price) ...[
              const SizedBox(width: 10),
              Text(
                '${p.oldPrice!.toStringAsFixed(0)} EGP',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).hintColor,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Theme.of(context).hintColor,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Rating
        Row(
          children: [
            ...List.generate(5, (i) {
              return Icon(
                i < p.rating.round()
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: AppColors.starAmber,
                size: 18,
              );
            }),
            const SizedBox(width: 6),
            Text(
              p.rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Divider
        Divider(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
        const SizedBox(height: 16),

        // Description
        if (p.description.isNotEmpty) ...[
          Text(
            'Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Theme.of(context).hintColor.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.description,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.75,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Quantity selector
        Row(
          children: [
            Text(
              'Quantity',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).hintColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 16),
            _QuantitySelector(
              quantity: props.quantity,
              max: p.countInStock,
              onIncrease: props.onIncrease,
              onDecrease: props.onDecrease,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Add to Cart button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: p.countInStock == 0 ? null : props.onAddToCart,
            icon: props.addingToCart
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  )
                : const Icon(LucideIcons.shoppingCart, size: 18),
            label: Text(
              props.addingToCart
                  ? 'Adding…'
                  : p.countInStock == 0
                  ? 'Out of Stock'
                  : 'Add to Cart',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black87,
              disabledBackgroundColor: Colors.grey.withOpacity(0.12),
              disabledForegroundColor: Colors.grey,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quantity selector
// ─────────────────────────────────────────────────────────────────────────────
class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int max;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isDark;

  const _QuantitySelector({
    required this.quantity,
    required this.max,
    required this.onIncrease,
    required this.onDecrease,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: LucideIcons.minus,
            onTap: quantity > 1 ? onDecrease : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          _QtyButton(
            icon: LucideIcons.plus,
            onTap: quantity < max ? onIncrease : null,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.25),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glassmorphism back / admin buttons
// ─────────────────────────────────────────────────────────────────────────────
class _BlurButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BlurButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.28),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _AdminFloatingBar extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminFloatingBar({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AdminIconBtn(
                icon: LucideIcons.pencil,
                color: AppColors.primary,
                onTap: onEdit,
              ),
              const SizedBox(width: 4),
              _AdminIconBtn(
                icon: LucideIcons.trash2,
                color: AppColors.errorRed,
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _Pill({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  final bool isDark;

  const _StockBadge({required this.stock, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (stock == 0) {
      color = AppColors.errorRed;
      label = 'Out of Stock';
    } else if (stock <= 5) {
      color = AppColors.warningAmber;
      label = 'Limited ($stock left)';
    } else {
      color = AppColors.successGreen;
      label = 'In Stock';
    }
    return _Pill(label: label, color: color, isDark: isDark);
  }
}

class _NetworkImage extends StatelessWidget {
  final String? url;
  final bool isDark;
  final BoxFit fit;

  const _NetworkImage({
    required this.url,
    required this.isDark,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback(context, isDark);
    return Image.network(
      url!,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _fallback(context, isDark),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        );
      },
    );
  }

  Widget _fallback(BuildContext context, bool isDark) {
    return Center(
      child: SvgPicture.asset(
        'assets/images/dealio_logo.svg',
        width: 60,
        height: 60,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
