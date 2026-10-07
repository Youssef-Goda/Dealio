import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Sticky right-column (desktop) or bottom section (mobile) showing
/// item list, pricing, and Place Order CTA.
class OrderSummaryPanel extends StatelessWidget {
  final VoidCallback onPlaceOrder;
  final bool compact; // true on mobile, false on desktop

  const OrderSummaryPanel({
    super.key,
    required this.onPlaceOrder,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: compact
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.circular(24),
        border: compact
            ? null
            : Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: compact ? 20 : 16,
            offset: compact ? const Offset(0, -4) : const Offset(0, 4),
          ),
        ],
      ),
      padding: compact
          ? const EdgeInsets.fromLTRB(24, 20, 24, 28)
          : const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

          // ── Header ──────────────────────────────────────────
          Row(
            children: [
              const Icon(
                LucideIcons.shoppingBag,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimaryDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Item List ─────────────────────────────────────────
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '× ${item.quantity}',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'EGP ${item.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(
            height: 20,
            color: isDark ? AppColors.darkBorder : AppColors.dividerGrey,
          ),

          // ── Totals ───────────────────────────────────────────
          _Row(
            'Subtotal',
            'EGP ${cart.subtotal.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _Row(
            'Tax (10%)',
            'EGP ${cart.tax.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.dividerGrey),
          const SizedBox(height: 10),
          _Row(
            'Total',
            'EGP ${cart.total.toStringAsFixed(2)}',
            isDark: isDark,
            isTotal: true,
          ),
          const SizedBox(height: 20),

          // ── Place Order / Pay Button ──────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: checkout.canPlaceOrder
                      ? [const Color(0xFFFFD700), const Color(0xFFFFC200)]
                      : [Colors.grey.shade400, Colors.grey.shade300],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: checkout.canPlaceOrder
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: ElevatedButton.icon(
                onPressed: checkout.canPlaceOrder ? onPlaceOrder : null,
                icon: (checkout.isPlacingOrder || checkout.isInitiatingPayment)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon( 
                        LucideIcons.shieldCheck,
                        color: Colors.white,
                        size: 20,
                      ),
                label: Text(  
                  checkout.isPlacingOrder
                      ? 'Placing Order...'
                      : checkout.isInitiatingPayment
                          ? 'Initiating secure payment...'
                          : 'Pay EGP ${cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          if (!checkout.canPlaceOrder && checkout.selectedAddress == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.info,
                    size: 14,
                    color: AppColors.warningAmber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Select a delivery address to continue',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warningAmber,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isTotal;

  const _Row(
    this.label,
    this.value, {
    required this.isDark,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimaryDark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? color : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 13,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            color: isTotal ? AppColors.primary : color,
          ),
        ),
      ],
    );
  }
}
