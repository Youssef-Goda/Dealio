import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/models/order_item_model.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/data/providers/orders_provider.dart';
import 'package:dealio/features/orders/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  void _showCancelDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
            'Cancel Order',
          style: TextStyle(fontWeight: FontWeight.bold),
          // textAlign: TextAlign.right,
        ),
        content: const Text(
          'Are you sure you want to cancel this order?',
          textAlign: TextAlign.right,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleCancelOrder(context, order.id);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelOrder(BuildContext context, String orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await context.read<OrdersProvider>().cancelOrder(orderId);
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order canceled successfully', textAlign: TextAlign.right),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to cancel order: ${e.toString().replaceAll('Exception: ', '')}',
              textAlign: TextAlign.right,
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildActionSection(BuildContext context, Order order, bool isDark) {
    if (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed) {
      return Padding(
        padding: const EdgeInsets.only(top: 50),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCancelDialog(context, order),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(LucideIcons.circleX, size: 20),
            label: const Text(
              'Cancel Order',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    } else if (order.status == OrderStatus.processing ||
        order.status == OrderStatus.shipped ||
        order.status == OrderStatus.delivered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.info, color: AppColors.warningAmber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'To cancel the order, please contact customer support',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    // استقبال الأوردر من الـ Arguments
    final orderArg = ModalRoute.of(context)?.settings.arguments as Order?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (orderArg == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Detail')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.searchX, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text('Order not found.', style: TextStyle(fontSize: 16)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              )
            ],
          ),
        ),
      );
    }

    // Live listen to OrdersProvider state updates
    final order = context.select<OrdersProvider, Order>(
      (prov) => prov.orders.firstWhere((o) => o.id == orderArg.id, orElse: () => orderArg),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkAppBar : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Order #${order.shortId}',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.dividerGrey,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: R.isMobile(context) ? 16 : 32,
          vertical: 24,
        ),
        child: Center( // لضمان التوسط في الشاشات الكبيرة
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status + Date ──
                _Card(
                  isDark: isDark,
                  child: Row(
                     children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            const SizedBox(height: 6),
                            StatusBadge(status: order.status, large: true),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Placed on', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            order.createdAt != null
                                ? DateFormat('dd MMM yyyy').format(order.createdAt!.toLocal())
                                : '—',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Items ──
                _SectionTitle('Items Ordered', LucideIcons.shoppingBag, isDark),
                const SizedBox(height: 10),
                _Card(
                  isDark: isDark,
                  child: Column(
                    children: order.items
                        .map((item) => _OrderItemRow(item: item, isDark: isDark))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Shipping Address ──
                if (order.shippingAddress != null) ...[
                  _SectionTitle('Delivery Address', LucideIcons.mapPin, isDark),
                  const SizedBox(height: 10),
                  _Card(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.shippingAddress!.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(order.shippingAddress!.phone, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          order.shippingAddress!.displayLine,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Payment ──
                _SectionTitle('Payment', LucideIcons.creditCard, isDark),
                const SizedBox(height: 10),
                _Card(
                  isDark: isDark,
                  child: Row(
                    children: [
                      Icon(
                        order.paymentMethod == PaymentMethod.cod ? LucideIcons.banknote : LucideIcons.creditCard,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        order.paymentMethod.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Totals Summary ──
                _SectionTitle('Order Summary', LucideIcons.fileText, isDark),
                const SizedBox(height: 10),
                _Card(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _TotalRow('Subtotal', 'EGP ${order.subtotal.toStringAsFixed(2)}', isDark),
                      const SizedBox(height: 8),
                      _TotalRow('Tax', 'EGP ${order.tax.toStringAsFixed(2)}', isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: isDark ? AppColors.darkBorder : AppColors.dividerGrey),
                      ),
                      _TotalRow('Total', 'EGP ${order.total.toStringAsFixed(2)}', isDark, isTotal: true),
                    ],
                  ),
                ),
                
                // ── Actions Section (Arabic Cancel / Support Info) ──
                _buildActionSection(context, order, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── المكونات الفرعية (Sub-widgets) ───────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDark;
  const _SectionTitle(this.text, this.icon, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item; // تم تغيير dynamic لـ OrderItem لزيادة الدقة
  final bool isDark;
  const _OrderItemRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, color: AppColors.textMuted, size: 22),
                  )
                : const Icon(LucideIcons.package, color: AppColors.textMuted, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'EGP ${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            'EGP ${item.subtotal.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isTotal;
  const _TotalRow(this.label, this.value, this.isDark, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark;
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