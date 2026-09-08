import 'dart:async';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/models/cart_item_model.dart';
import 'package:dealio/data/models/product_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/wishlist_provider.dart';
import 'package:dealio/core/widgets/focal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';


// ─── Shimmer / Skeleton Card ──────────────────────────────────────────────────
class ProductCardSkeleton extends StatefulWidget {
  const ProductCardSkeleton({super.key});

  @override
  State<ProductCardSkeleton> createState() => _ProductCardSkeletonState();
}

class _ProductCardSkeletonState extends State<ProductCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base = isDark
        ? const Color(0xFF252525)
        : const Color(0xFFEAEAEA);
    final Color hi = isDark ? const Color(0xFF363636) : const Color(0xFFF6F6F6);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final Color c = Color.lerp(base, hi, _anim.value)!;
        return LayoutBuilder(
          builder: (context, constraints) {
            // Match the real card formula exactly:
            // cardH = tileW * 0.72 + 105/110 → image height = tileW * 0.72
            final double imageH = constraints.maxWidth * 0.72;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image placeholder — exact same height as real card
                    Container(height: imageH, color: c),
                    // Details section — fixed, predictable heights
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ShimmerBox(color: c, h: 12, w: double.infinity),
                          const SizedBox(height: 6),
                          _ShimmerBox(color: c, h: 10, w: 40),
                          const SizedBox(height: 6),
                          _ShimmerBox(color: c, h: 13, w: 75),
                          const SizedBox(height: 6),
                          _ShimmerBox(color: c, h: 10, w: 55),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final Color color;
  final double h;
  final double w;

  const _ShimmerBox({required this.color, required this.h, required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: R.h(context, h),
      width: w == double.infinity ? double.infinity : R.w(context, w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────
//
// Layout philosophy (no more overflow / frozen buttons):
//   • The card is a plain Column — NO Stack wrapping the whole card.
//   • Image section: fixed height = maxWidth * 0.72, with its own Stack
//     for the discount badge + wishlist heart.  ClipRRect only wraps the image.
//   • Details section: normal flow Column — name, rating, price row with
//     the cart button inline on the right.  Zero Positioned widgets here.
//   • The GridView uses mainAxisExtent so every card has the same height and
//     there is never an unconstrained vertical axis inside the card.
//
// Multi-image carousel:
//   • Only created when product.imageUrls.length > 1.
//   • Auto-rotates every 5 s; pauses while user is dragging.
//   • PageController and Timer are disposed correctly.
//   • Single-image products: zero overhead (no controller, no timer).
//
// Out-of-stock:
//   • Detected via product.countInStock == 0.
//   • Gray semi-transparent overlay with "OUT OF STOCK" label on image.
//   • Add to Cart button is replaced with a visually disabled state.

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  // ── Cart stepper collapse timer ──────────────────────────────────────────
  bool _isExpanded = false;
  Timer? _collapseTimer;

  void _resetCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isExpanded = false);
    });
  }

  // ── Multi-image carousel ─────────────────────────────────────────────────
  // Only initialized when imageUrls.length > 1.
  PageController? _pageCtrl;
  Timer? _autoTimer;
  int _pageIndex = 0;
  bool _userDragging = false;

  bool get _isMultiImage => widget.product.imageUrls.length > 1;

  void _startAutoRotate() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _userDragging) return;
      final urls = widget.product.imageUrls;
      final next = (_pageIndex + 1) % urls.length;
      _pageCtrl?.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    if (_isMultiImage) {
      _pageCtrl = PageController();
      _startAutoRotate();
    }
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _autoTimer?.cancel();
    _pageCtrl?.dispose();
    super.dispose();
  }

  // ── Stock helper ─────────────────────────────────────────────────────────
  bool get _outOfStock => widget.product.countInStock <= 0;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    int discount = 0;
    if (widget.product.oldPrice != null &&
        widget.product.oldPrice! > widget.product.price) {
      discount =
          (((widget.product.oldPrice! - widget.product.price) /
                      widget.product.oldPrice!) *
                  100)
              .round();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Image height: 72 % of card width — keeps a nice proportion on all sizes.
        final double imageH = constraints.maxWidth * 0.72;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(R.r(context, 12)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.06),
                blurRadius: R.r(context, 10),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // ── outer Column — fully in-flow, no global Stack ──────────────
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── IMAGE + overlay badges ──────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(R.r(context, 12)),
                  topRight: Radius.circular(R.r(context, 12)),
                ),
                child: Stack(
                  // Stack is constrained: same size as the image SizedBox
                  children: [
                    SizedBox(
                      height: imageH,
                      width: double.infinity,
                      child: ColoredBox(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.fillColor,
                        child: Hero(
                          tag: 'product-image-${widget.product.id}',
                          child: _buildImageArea(context, isDark),
                        ),
                      ),
                    ),

                    // ── Out-of-stock overlay ──────────────────────────
                    if (_outOfStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.52),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.70),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: R.font(context, 10),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Discount badge — top-left
                    if (discount > 0)
                      Positioned(
                        top: R.r(context, 8),
                        left: R.r(context, 8),
                        child: _buildDiscountBadge(context, discount),
                      ),
                    // Wishlist heart — top-right
                    Positioned(
                      top: R.r(context, 8),
                      right: R.r(context, 8),
                      child: _WishlistButton(
                        isDark: isDark,
                        productId: widget.product.id,
                      ),
                    ),

                    // ── Dot indicators — bottom-center (multi-image only) ──
                    if (_isMultiImage)
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: _DotIndicator(
                          count: widget.product.imageUrls.length,
                          current: _pageIndex,
                        ),
                      ),
                  ],
                ),
              ),

              // ── DETAILS — fully in-flow ─────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    R.w(context, 10),
                    R.h(context, 8),
                    R.w(context, 10),
                    R.h(context, 8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product name
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: R.font(context, 13),
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.secondary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Rating row
                      _buildRatingRow(context, isDark),

                      // Price + Cart button on same row ← KEY FIX
                      // No Positioned at all — everything is in normal flow.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price column
                          Expanded(child: _buildPriceColumn(context)),

                          // Cart button — inline, always tappable
                          // Disabled when out of stock
                          if (_outOfStock)
                            _DisabledCartButton(context: context)
                          else
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Consumer<CartProvider>(
                                builder: (context, cart, _) {
                                  final CartItem? inCart = cart.items.where((i) => i.productId == widget.product.id).firstOrNull;

                                  if (inCart == null) {
                                    return _CartButton(
                                      onTap: () {
                                        _handleAdd(context, cart);
                                        setState(() => _isExpanded = true);
                                        _resetCollapseTimer();
                                      },
                                      child: Icon(
                                        LucideIcons.plus,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textDark,
                                        size: R.iconSize(context, 17),
                                      ),
                                    );
                                  }

                                  if (!_isExpanded) {
                                    return _CartButton(
                                      onTap: () {
                                        setState(() => _isExpanded = true);
                                        _resetCollapseTimer();
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Icon(
                                            LucideIcons.shoppingCart,
                                            color: AppColors.primary,
                                            size: R.iconSize(context, 17),
                                          ),
                                          Positioned(
                                            top: -6,
                                            right: -6,
                                            child: CircleAvatar(
                                              radius: 6,
                                              backgroundColor:
                                                  AppColors.errorRed,
                                              child: Text(
                                                '${inCart.quantity}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      R.font(context, 8),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  // Expanded stepper
                                  return _buildStepper(context, cart, inCart);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Builds the image area: PageView carousel (multi-image) or single Image.
  Widget _buildImageArea(BuildContext context, bool isDark) {
    final urls = widget.product.imageUrls;

    if (_isMultiImage) {
      return GestureDetector(
        // Consume horizontal drag so it doesn't bubble up to the parent
        // GestureDetector (onTap → ProductDetails). Vertical scrolling still
        // works because HorizontalDragGestureRecognizer doesn't compete with
        // vertical scroll.
        onHorizontalDragStart: (_) {
          _userDragging = true;
          _autoTimer?.cancel();
        },
        onHorizontalDragEnd: (_) {
          _userDragging = false;
          _startAutoRotate();
        },
        child: PageView.builder(
          controller: _pageCtrl,
          itemCount: urls.length,
          onPageChanged: (i) {
            if (mounted) setState(() => _pageIndex = i);
          },
          itemBuilder: (_, i) => _buildSingleImage(context, isDark, urls[i]),
        ),
      );
    }

    // Single image — same as before, zero overhead
    return _buildImage(context, isDark);
  }

  Widget _buildSingleImage(BuildContext context, bool isDark, String url) {
    if (url.trim().isEmpty) return _fallbackIcon(context, isDark);
    return FocalNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorWidget: (_, __, ___) => _fallbackIcon(context, isDark),
    );
  }

  Widget _buildImage(BuildContext context, bool isDark) {
    final bool hasImage =
        widget.product.imageUrls.isNotEmpty &&
        widget.product.imageUrls.first.trim().isNotEmpty;
    if (hasImage) {
      return FocalNetworkImage(
        imageUrl: widget.product.imageUrls.first,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
          errorWidget: (_, __, ___) => _fallbackIcon(context, isDark),
      );
    }
    return _fallbackIcon(context, isDark);
  }

  Widget _fallbackIcon(BuildContext context, bool isDark) {
    return Center(
      child: SvgPicture.asset(
        'assets/images/dealio_logo.svg',
        width: R.r(context, 60),
        height: R.r(context, 60),
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildDiscountBadge(BuildContext context, int discount) {
    return Container(
      padding: R.symmetric(context, horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.errorRed,
        borderRadius: BorderRadius.circular(R.r(context, 8)),
      ),
      child: Text(
        '-$discount%',
        style: TextStyle(
          color: Colors.white,
          fontSize: R.font(context, 10),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          color: AppColors.starAmber,
          size: R.iconSize(context, 15),
        ),
        const SizedBox(width: 3),
        Text(
          widget.product.rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: R.font(context, 11),
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.product.price.toStringAsFixed(0)} EGP',
          style: TextStyle(
            fontSize: R.font(context, 14),
            fontWeight: FontWeight.w900,
            color: _outOfStock ? Colors.grey : AppColors.successGreen,
          ),
        ),
        if (widget.product.oldPrice != null &&
            widget.product.oldPrice! > widget.product.price)
          Text(
            '${widget.product.oldPrice!.toStringAsFixed(0)} EGP',
            style: TextStyle(
              fontSize: R.font(context, 10),
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildStepper(
    BuildContext context,
    CartProvider cart,
    CartItem inCart,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: R.symmetric(context, horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(R.r(context, 10)),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepTap(
            onTap: () {
              _handleDecrease(context, cart, inCart);
              _resetCollapseTimer();
            },
            child: Icon(
              inCart.quantity <= 1 ? LucideIcons.trash2 : LucideIcons.minus,
              size: R.iconSize(context, 14),
              color: inCart.quantity <= 1 ? Colors.red : AppColors.primary,
            ),
          ),
          Padding(
            padding: R.symmetric(context, horizontal: 6),
            child: Text(
              '${inCart.quantity}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: R.font(context, 13),
                color: AppColors.primary,
              ),
            ),
          ),
          _StepTap(
            onTap: () {
              _handleIncrease(context, cart, inCart);
              _resetCollapseTimer();
            },
            child: Icon(
              LucideIcons.plus,
              size: R.iconSize(context, 14),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context, CartProvider cart) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      HapticFeedback.mediumImpact();
      Navigator.pushNamed(context, '/login', arguments: {'fromCart': true});
      return;
    }
    HapticFeedback.lightImpact();
    await cart.addItem(
      productId: widget.product.id,
      productName: widget.product.name,
      productCode: widget.product.code,
      imageUrl: widget.product.imageUrls.isNotEmpty
          ? widget.product.imageUrls.first
          : null,
      unitPrice: widget.product.price,
      oldPrice: widget.product.oldPrice,
      rating: widget.product.rating,
      countInStock: widget.product.countInStock,
    );
  }

  Future<void> _handleIncrease(
    BuildContext context,
    CartProvider cart,
    CartItem item,
  ) async {
    HapticFeedback.selectionClick();
    if (item.quantity >= item.countInStock) return;
    await cart.updateQuantity(item.productId, item.quantity + 1);
  }

  Future<void> _handleDecrease(
    BuildContext context,
    CartProvider cart,
    CartItem item,
  ) async {
    HapticFeedback.selectionClick();
    if (item.quantity <= 1) {
      await cart.removeItem(item.productId);
    } else {
      await cart.updateQuantity(item.productId, item.quantity - 1);
    }
  }
}

// ─── Disabled Cart Button (out-of-stock) ─────────────────────────────────────

class _DisabledCartButton extends StatelessWidget {
  final BuildContext context;
  const _DisabledCartButton({required this.context});

  @override
  Widget build(BuildContext ctx) {
    final bool isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(R.r(ctx, 7)),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.withOpacity(0.10),
        borderRadius: BorderRadius.circular(R.r(ctx, 9)),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.grey.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Icon(
        LucideIcons.shoppingCart,
        size: R.iconSize(ctx, 17),
        color: Colors.grey.withOpacity(0.45),
      ),
    );
  }
}

// ─── Dot Indicator ───────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: active ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

// ─── Wishlist Button ──────────────────────────────────────────────────────────

class _WishlistButton extends StatelessWidget {
  final bool isDark;
  final String productId;

  const _WishlistButton({required this.isDark, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlist, _) {
        final bool liked = wishlist.isFavorite(productId);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              wishlist.toggle(productId);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(R.r(context, 6)),
              decoration: BoxDecoration(
                color: liked
                    ? AppColors.errorRed.withOpacity(0.15)
                    : (isDark
                          ? Colors.black.withOpacity(0.35)
                          : Colors.white.withOpacity(0.85)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(liked),
                  size: R.iconSize(context, 16),
                  color: liked
                      ? AppColors.errorRed
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Cart Button ──────────────────────────────────────────────────────────────

class _CartButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _CartButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(R.r(context, 7)),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(R.r(context, 9)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Step Tap ─────────────────────────────────────────────────────────────────

class _StepTap extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _StepTap({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: EdgeInsets.all(R.r(context, 4)), child: child),
      ),
    );
  }
}
