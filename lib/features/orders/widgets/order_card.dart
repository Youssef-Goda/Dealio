// import 'package:e_commerce/core/constants/colors.dart';
// import 'package:e_commerce/data/models/order_item_model.dart';
// import 'package:e_commerce/data/models/order_model.dart';
// import 'package:e_commerce/data/models/shipping_address_model.dart';
// import 'package:e_commerce/features/orders/widgets/status_badge.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';

// /// A premium ExpansionTile order card.
// ///
// /// Collapsed: shows Order ID, date, status chip, item count, and total.
// /// Expanded: reveals per-product rows (image, name, qty, price) and the
// /// delivery address — all without navigating away.
// class OrderCard extends StatefulWidget {
//   final Order order;
//   final VoidCallback? onTap;

//   const OrderCard({super.key, required this.order, this.onTap});

//   @override
//   State<OrderCard> createState() => _OrderCardState();
// }

// class _OrderCardState extends State<OrderCard>
//     with SingleTickerProviderStateMixin {
//   bool _expanded = false;

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final order = widget.order;
//     final dateStr = order.createdAt != null
//         ? DateFormat('dd MMM yyyy · HH:mm').format(order.createdAt!.toLocal())
//         : '—';
//     final hasItems = order.items.isNotEmpty;
//     final hasAddress = order.shippingAddress != null;

//     final cardColor = isDark ? AppColors.darkSurface : Colors.white;
//     final borderColor =
//         isDark ? AppColors.darkBorder : AppColors.borderLight;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 250),
//       margin: const EdgeInsets.only(bottom: 14),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: _expanded ? AppColors.primary.withOpacity(0.5) : borderColor,
//           width: _expanded ? 1.5 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
//             blurRadius: _expanded ? 18 : 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(19),
//         child: Theme(
//           // Remove the default ExpansionTile divider color leak
//           data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
//           child: ExpansionTile(
//             tilePadding:
//                 const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
//             childrenPadding: EdgeInsets.zero,
//             initiallyExpanded: false,
//             onExpansionChanged: (v) => setState(() => _expanded = v),
//             // ── Collapsed header ──────────────────────────────────────
//             leading: Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(11),
//               ),
//               child: const Icon(
//                 LucideIcons.package,
//                 size: 19,
//                 color: AppColors.primary,
//               ),
//             ),
//             title: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Order #${order.shortId}',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w800,
//                           color: isDark
//                               ? AppColors.darkTextPrimary
//                               : AppColors.textPrimaryDark,
//                         ),
//                       ),
//                       const SizedBox(height: 3),
//                       Text(
//                         dateStr,
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: AppColors.textMuted,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 StatusBadge(status: order.status),
//               ],
//             ),
//             // ── Collapsed sub-row (item count + total) ────────────────
//             subtitle: Padding(
//               padding: const EdgeInsets.only(top: 6, bottom: 4),
//               child: Row(
//                 children: [
//                   Icon(
//                     order.paymentMethod == PaymentMethod.cod
//                         ? LucideIcons.banknote
//                         : LucideIcons.creditCard,
//                     size: 13,
//                     color: AppColors.textMuted,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     order.paymentMethod.label,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: AppColors.textMuted,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   if (hasItems)
//                     Text(
//                       '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: AppColors.textMuted,
//                       ),
//                     ),
//                   const Spacer(),
//                   Text(
//                     'EGP ${order.total.toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w900,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // ── Expanded body ─────────────────────────────────────────
//             children: [
//               Divider(
//                 height: 1,
//                 thickness: 1,
//                 color: isDark ? AppColors.darkBorder : AppColors.dividerGrey,
//               ),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // ── Products ────────────────────────────
//                     if (hasItems) ...[
//                       _SectionLabel(
//                         icon: LucideIcons.shoppingBag,
//                         label: 'Products',
//                         isDark: isDark,
//                       ),
//                       const SizedBox(height: 10),
//                       ...order.items.map(
//                         (item) => _ProductRow(item: item, isDark: isDark),
//                       ),
//                     ] else
//                       Text(
//                         'No product details available.',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: AppColors.textMuted,
//                         ),
//                       ),

//                     // ── Delivery Address ─────────────────────
//                     if (hasAddress) ...[
//                       const SizedBox(height: 16),
//                       Divider(
//                         height: 1,
//                         thickness: 1,
//                         color: isDark
//                             ? AppColors.darkBorder
//                             : AppColors.dividerGrey,
//                       ),
//                       const SizedBox(height: 14),
//                       _SectionLabel(
//                         icon: LucideIcons.mapPin,
//                         label: 'Delivery Address',
//                         isDark: isDark,
//                       ),
//                       const SizedBox(height: 8),
//                       _AddressSnippet(
//                         address: order.shippingAddress!,
//                         isDark: isDark,
//                       ),
//                     ],

//                     // ── "View full details" link ─────────────
//                     if (widget.onTap != null) ...[
//                       const SizedBox(height: 14),
//                       GestureDetector(
//                         onTap: widget.onTap,
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             Text(
//                               'View full details',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w700,
//                                 color: AppColors.primary,
//                                 decoration: TextDecoration.underline,
//                                 decorationColor: AppColors.primary,
//                               ),
//                             ),
//                             const SizedBox(width: 4),
//                             const Icon(
//                               LucideIcons.arrowRight,
//                               size: 13,
//                               color: AppColors.primary,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Section label ────────────────────────────────────────────────────────────
// class _SectionLabel extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isDark;
//   const _SectionLabel({
//     required this.icon,
//     required this.label,
//     required this.isDark,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, size: 14, color: AppColors.primary),
//         const SizedBox(width: 6),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w700,
//             color: isDark
//                 ? AppColors.darkTextPrimary
//                 : AppColors.textPrimaryDark,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ─── Product row inside the expanded card ─────────────────────────────────────
// class _ProductRow extends StatelessWidget {
//   final OrderItem item;
//   final bool isDark;
//   const _ProductRow({required this.item, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         children: [
//           // Thumbnail
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: isDark
//                   ? AppColors.darkBackground
//                   : AppColors.surfaceLight,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: item.imageUrl != null && item.imageUrl!.isNotEmpty
//                 ? Image.network(
//                     item.imageUrl!,
//                     fit: BoxFit.cover,
//                     errorBuilder: (_, __, ___) => const Icon(
//                       LucideIcons.image,
//                       size: 18,
//                       color: AppColors.textMuted,
//                     ),
//                   )
//                 : const Icon(
//                     LucideIcons.package,
//                     size: 18,
//                     color: AppColors.textMuted,
//                   ),
//           ),
//           const SizedBox(width: 10),
//           // Name + price/qty
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   item.productName,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: isDark
//                         ? AppColors.darkTextPrimary
//                         : AppColors.textPrimaryDark,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   'EGP ${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: AppColors.textMuted,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Subtotal
//           Text(
//             'EGP ${item.subtotal.toStringAsFixed(2)}',
//             style: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w700,
//               color: AppColors.primary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Address snippet inside the expanded card ─────────────────────────────────
// class _AddressSnippet extends StatelessWidget {
//   final ShippingAddress address;
//   final bool isDark;
//   const _AddressSnippet({required this.address, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     final lines = <String>[
//       if (address.fullName.isNotEmpty) address.fullName,
//       if (address.phone.isNotEmpty) address.phone,
//       address.displayLine,
//     ];

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: isDark
//             ? AppColors.darkBackground
//             : AppColors.backgroundLight,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isDark ? AppColors.darkBorder : AppColors.borderLight,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: lines
//             .map(
//               (l) => Padding(
//                 padding: const EdgeInsets.only(bottom: 2),
//                 child: Text(
//                   l,
//                   style: TextStyle(
//                     fontSize: 12,
//                     height: 1.5,
//                     color: isDark
//                         ? AppColors.darkTextSecondary
//                         : AppColors.textDark,
//                   ),
//                 ),
//               ),
//             )
//             .toList(),
//       ),
//     );
//   }
// }



import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/data/models/order_item_model.dart';
import 'package:e_commerce/data/models/order_model.dart';
import 'package:e_commerce/data/models/shipping_address_model.dart';
import 'package:e_commerce/features/orders/widgets/status_badge.dart';
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