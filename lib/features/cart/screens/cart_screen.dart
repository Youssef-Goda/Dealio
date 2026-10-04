import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/features/cart/widgets/cart_item_card.dart';
import 'package:dealio/features/cart/widgets/checkout_summary.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCartWithAuth(); 

      // ─── Listen to auth changes to re-fetch cart after login ────────────
      // When the user logs in from the guest state, AuthProvider notifies.
      // We pick that up here to refresh the cart without requiring them to
      // re-navigate.
      context.read<AuthProvider>().addListener(_onAuthChanged);
    });
  }

  @override
  void dispose() {
    // Safely remove listener — guard against unmounted widget
    try {
      context.read<AuthProvider>().removeListener(_onAuthChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      // User just logged in — clear stale optimistic state and fetch fresh cart
      final cart = context.read<CartProvider>();
      cart.clearLocal();
      cart.fetchCart();
    } else {
      // User logged out — clear cart locally
      context.read<CartProvider>().clearLocal();
    }
  }

  void _syncCartWithAuth() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      context.read<CartProvider>().fetchCart();
    }
    // If not logged in, we show the guest wall — no API call needed
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Consumer2<AuthProvider, CartProvider>(
        builder: (context, auth, cart, _) {
          // ─── Guest Wall ───────────────────────────────────────────────────
          if (!auth.isLoggedIn) {
            return _buildGuestWall(context, isDark);
          }

          // ─── Loading Shimmer ──────────────────────────────────────────────
          if (cart.isLoading && cart.items.isEmpty) {
            return _buildShimmer(isDark);
          }

          // ─── Error State ──────────────────────────────────────────────────
          if (cart.error != null && cart.items.isEmpty) {
            return _buildErrorState(context, cart, isDark);
          }

          // ─── Empty Cart ───────────────────────────────────────────────────
          if (cart.items.isEmpty) {
            return _buildEmptyState(context, isDark);
          }

          // ─── Filled Cart ──────────────────────────────────────────────────
          return _buildFilledCart(cart, isDark);
        },
      ),
    );
  }

  // ─── Guest Wall ─────────────────────────────────────────────────────────────
  Widget _buildGuestWall(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.lockKeyhole,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Sign in to view your cart',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Your cart is waiting!\nLog in to see what you've saved.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            _GoldenButton(
              label: 'Login / Sign Up',
              icon: LucideIcons.logIn,
              onTap: () => Navigator.pushNamed(
                context,
                '/login',
                arguments: {'fromCart': true},
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────────
  Widget _buildErrorState(
    BuildContext context,
    CartProvider cart,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.cloudOff, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 20),
            Text(
              cart.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _GoldenButton(
              label: 'Retry',
              icon: LucideIcons.refreshCw,
              onTap: () => cart.fetchCart(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Loading Shimmer ────────────────────────────────────────────────────────
  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 4,
      itemBuilder: (_, __) => _ShimmerCard(isDark: isDark),
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated cart illustration
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 68,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Add some products and they'll\nshow up right here!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            _GoldenButton(
              label: 'Start Shopping',
              icon: Icons.storefront_outlined,
              onTap: () {
                // Pop back to home content (index 0 on SidebarXController)
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filled Cart ────────────────────────────────────────────────────────────
  Widget _buildFilledCart(CartProvider cart, bool isDark) {
    return Column(
      children: [
        // Item count header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Text(
                '${cart.items.length} item${cart.items.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmClear(context);
                  if (confirmed == true) {
                    // Remove all one-by-one (small carts); or show coming-soon
                    for (final item in List.from(cart.items)) {
                      await cart.removeItem(item.productId);
                    }
                  }
                },
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 16,
                  color: Colors.red,
                ),
                label: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => cart.fetchCart(),
            child: AnimatedList(
              key: GlobalKey<AnimatedListState>(),
              padding: const EdgeInsets.only(bottom: 16),
              initialItemCount: cart.items.length,
              itemBuilder: (_, index, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: CartItemCard(item: cart.items[index]),
                );
              },
            ),
          ),
        ),

        // Checkout summary
        const CheckoutSummary(),
      ],
    );
  }

  Future<bool?> _confirmClear(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Clear Cart'),
      content: const Text('Remove all items from your cart?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Clear',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

// ─── Golden Button ─────────────────────────────────────────────────────────────
class _GoldenButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GoldenButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFC200)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.40),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer Card ───────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  final bool isDark;
  const _ShimmerCard({required this.isDark});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          height: 110,
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [_bar(0.7), _bar(0.4), _bar(0.5)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(double widthFraction) => FractionallySizedBox(
    widthFactor: widthFraction,
    child: Container(
      height: 12,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkBorder : AppColors.dividerGrey,
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}
