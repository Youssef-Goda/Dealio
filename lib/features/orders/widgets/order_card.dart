import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/order_item_model.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/features/orders/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;
    final dateStr = order.createdAt != null
        ? DateFormat('dd MMM · HH:mm').format(order.createdAt!.toLocal())
        : '—';
    
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.borderLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded ? AppColors.primary.withOpacity(0.4) : borderColor,
          width: _expanded ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: _expanded ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        // إلغاء الـ Splash والـ Divider الافتراضي للـ ExpansionTile
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          // ── الهيدر (Collapsed) ──
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.package, size: 18, color: AppColors.primary),
          ),
          title: Text(
            'Order #${order.shortId}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
            ),
          ),
          subtitle: Row(
            children: [
              Text(dateStr, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              const Icon(LucideIcons.dot, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'EGP ${order.total.toStringAsFixed(0)}', // شيلنا الكسور هنا للتبسيط في الهيدر
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          trailing: StatusBadge(status: order.status),
          
          // ── المحتوى (Expanded) ──
          children: [
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المنتجات
                  ...order.items.take(3).map((item) => _CompactProductRow(item: item, isDark: isDark)),
                  
                  if (order.items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        '+ ${order.items.length - 3} more items...',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                      ),
                    ),

                  const SizedBox(height: 12),
                  
                  // زرار عرض التفاصيل الكاملة
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.onTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Full Details',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.externalLink, size: 14, color: AppColors.primary),
                        ],
                      ),
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
}

// ── صف منتج مضغوط ──
class _CompactProductRow extends StatelessWidget {
  final OrderItem item;
  final bool isDark;
  const _CompactProductRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                : const Icon(LucideIcons.package, size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${item.quantity}x ${item.productName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textPrimaryDark,
              ),
            ),
          ),
          Text(
            'EGP ${item.subtotal.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
          ),
        ],
      ),
    );
  }
}