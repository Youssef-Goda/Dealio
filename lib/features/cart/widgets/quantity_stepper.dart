import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/data/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuantityStepper extends StatelessWidget {
  final String productId;
  final int quantity;
  final int maxQty;

  const QuantityStepper({
    super.key,
    required this.productId,
    required this.quantity,
    required this.maxQty,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Minus ───
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: () async {
              final err = await cart.updateQuantity(productId, quantity - 1);
              if (err != null && context.mounted) {
                _showError(context, err);
              }
            },
            color: quantity <= 1 ? Colors.red.shade400 : AppColors.primary,
          ),

          // ─── Count ───
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '$quantity',
              key: ValueKey(quantity),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
              ),
            ),
          ),

          // ─── Plus ───
          _StepButton(
            icon: Icons.add_rounded,
            onTap: quantity >= maxQty
                ? null
                : () async {
                    final err = await cart.updateQuantity(
                      productId,
                      quantity + 1,
                    );
                    if (err != null && context.mounted) {
                      _showError(context, err);
                    }
                  },
            color: quantity >= maxQty ? Colors.grey : AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.transparent : color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
