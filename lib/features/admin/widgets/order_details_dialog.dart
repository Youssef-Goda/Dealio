import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/models/order_item_model.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/data/providers/orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class OrderDetailsDialog extends StatefulWidget {
  final Order order;
  const OrderDetailsDialog({super.key, required this.order});

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  late OrderStatus _currentStatus;
  bool _isUpdating = false;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    if (_isUpdating || newStatus == _currentStatus) return;
    final prev = _currentStatus;
    setState(() {
      _isUpdating = true;
      _currentStatus = newStatus; // optimistic update
    });
    try {
      await context.read<OrdersProvider>().updateOrderStatus(
        widget.order.id,
        newStatus,
      );
      if (mounted) {
        _showSnack(
          'Status updated to ${newStatus.label}',
          AppColors.successGreen,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentStatus = prev); // rollback on error
        _showSnack('Failed to update status: $e', AppColors.errorRed);
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
            fontSize: R.font(context, 13),
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.r(context, 10)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return AppColors.warningAmber;
      case OrderStatus.confirmed:
        return AppColors.infoBlue;
      case OrderStatus.processing:
        return AppColors.adminPurple;
      case OrderStatus.shipped:
        return AppColors.primary;
      case OrderStatus.delivered:
        return AppColors.successGreen;
      case OrderStatus.cancelled:
        return AppColors.errorRed;
    }
  }

  // Color _paymentColor(PaymentMethod m) {
  //   switch (m) {
  //     case PaymentMethod.cod:
  //       return AppColors.warningAmber;
  //     case PaymentMethod.card:
  //       return AppColors.adminPurple;
  //     case PaymentMethod.online:
  //       return AppColors.infoBlue;
  //     case PaymentMethod.wallet:
  //       return AppColors.primary;
  //     case PaymentMethod.cash:
  //       return AppColors.successGreen;
  //   }
  // }

  Color _paymentColor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cod:
        return AppColors.warningAmber;
      case PaymentMethod.card:
      case PaymentMethod.online:
        return AppColors.adminPurple;
      case PaymentMethod.wallet:
        return AppColors.infoBlue;
      case PaymentMethod.cash:
        return AppColors.successGreen;
    }
  }

  IconData _paymentIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cod:
        return LucideIcons.banknote;
      case PaymentMethod.card:
      case PaymentMethod.online:
        return LucideIcons.creditCard;
      case PaymentMethod.wallet:
        return LucideIcons.wallet;
      case PaymentMethod.cash:
        return LucideIcons.coins;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;

    final customerName = (order.shippingAddress?.fullName.isNotEmpty == true)
        ? order.shippingAddress!.fullName
        : 'Unknown';

    final String? customerEmail = null;
    final customerPhone = order.shippingAddress?.phone;

    final addr = order.shippingAddress;
    final addrParts = <String>[
      if (addr?.addressLine1.isNotEmpty == true) addr!.addressLine1,
      if (addr?.city.isNotEmpty == true) addr!.city,
      if (addr?.governorate.isNotEmpty == true) addr!.governorate,
    ];
    final addrDisplay = addrParts.isNotEmpty
        ? addrParts.join(', ')
        : 'No address on file';

    final surfaceColor = isDark
        ? AppColors.darkSurface
        : Theme.of(context).cardColor;
    final sectionBg = isDark ? AppColors.darkBackground : AppColors.fillColor;
    final borderColor = isDark
        ? AppColors.darkBorder
        : Colors.black.withOpacity(0.06);
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textMuted;
    final valueColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;

    final statusColor = _statusColor(_currentStatus);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: R.symmetric(context, horizontal: 20, vertical: 24),
      child: Container(
        width: 640,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(R.r(context, 20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: R.r(context, 30),
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER ────────────────────────────────────────────────────
            Container(
              padding: R.symmetric(context, horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: R.all(context, 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(R.r(context, 12)),
                    ),
                    child: Icon(
                      LucideIcons.receiptText,
                      size: R.font(context, 20),
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: R.w(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: R.font(context, 17),
                            fontWeight: FontWeight.bold,
                            color: valueColor,
                          ),
                        ),
                        SizedBox(height: R.h(context, 2)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${order.shortId}',
                              style: TextStyle(
                                fontSize: R.font(context, 12),
                                color: AppColors.primary,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: R.w(context, 6)),
                            InkWell(
                              borderRadius: BorderRadius.circular(
                                R.r(context, 4),
                              ),
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: order.shortId),
                                );
                                setState(() => _isCopied = true);
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) {
                                    setState(() => _isCopied = false);
                                  }
                                });
                              },
                              child: Padding(
                                padding: R.all(context, 2),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isCopied
                                      ? Icon(
                                          LucideIcons.check,
                                          key: const ValueKey('check'),
                                          size: R.font(context, 14),
                                          color: AppColors.successGreen,
                                        )
                                      : Icon(
                                          LucideIcons.copy,
                                          key: const ValueKey('copy'),
                                          size: R.font(context, 14),
                                          color: AppColors.primary.withOpacity(
                                            0.7,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Dropdown Badge
                  Container(
                    padding: R.symmetric(context, horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(isDark ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(R.r(context, 20)),
                      border: Border.all(color: statusColor.withOpacity(0.35)),
                    ),
                    child: _isUpdating
                        ? SizedBox(
                            width: R.r(context, 18),
                            height: R.r(context, 18),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: statusColor,
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<OrderStatus>(
                              value: _currentStatus,
                              isDense: true,
                              icon: Icon(
                                LucideIcons.chevronDown,
                                size: R.font(context, 13),
                                color: statusColor,
                              ),
                              dropdownColor: surfaceColor,
                              borderRadius: BorderRadius.circular(
                                R.r(context, 14),
                              ),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: R.font(context, 12),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                              onChanged: (v) {
                                if (v != null) _updateStatus(v);
                              },
                              items: OrderStatus.values
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: R.r(context, 8),
                                            height: R.r(context, 8),
                                            decoration: BoxDecoration(
                                              color: _statusColor(s),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: R.w(context, 8)),
                                          Text(
                                            s.label,
                                            style: TextStyle(
                                              fontSize: R.font(context, 12),
                                              fontWeight: FontWeight.w600,
                                              color: valueColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),

                  SizedBox(width: R.w(context, 8)),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: R.font(context, 18),
                      color: labelColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(R.r(context, 8)),
                      ),
                      padding: R.all(context, 6),
                    ),
                  ),
                ],
              ),
            ),

            // ── BODY ──────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: R.all(context, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── ORDER META ──────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _MetaCard(
                            icon: LucideIcons.calendar,
                            label: 'Placed On',
                            value: order.createdAt != null
                                ? DateFormat(
                                    'dd MMM yyyy, HH:mm',
                                  ).format(order.createdAt!.toLocal())
                                : 'N/A',
                            isDark: isDark,
                            labelColor: labelColor,
                            valueColor: valueColor,
                            borderColor: borderColor,
                            sectionBg: sectionBg,
                          ),
                        ),
                        SizedBox(width: R.w(context, 12)),
                        Expanded(
                          child: _MetaCard(
                            icon: _paymentIcon(order.paymentMethod),
                            label: 'Payment',
                            value: order.paymentMethod.label,
                            iconColor: _paymentColor(order.paymentMethod),
                            isDark: isDark,
                            labelColor: labelColor,
                            valueColor: valueColor,
                            borderColor: borderColor,
                            sectionBg: sectionBg,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: R.h(context, 18)),

                    // ── CUSTOMER & SHIPPING ────────────────────────────────
                    _SectionHeader(
                      label: 'Customer & Shipping',
                      icon: LucideIcons.user,
                      valueColor: valueColor,
                    ),
                    SizedBox(height: R.h(context, 10)),
                    Container(
                      padding: R.all(context, 16),
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(R.r(context, 14)),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: LucideIcons.user,
                            label: 'Name',
                            value: customerName,
                            labelColor: labelColor,
                            valueColor: valueColor,
                          ),
                          if (customerEmail != null) ...[
                            Divider(
                              height: R.h(context, 20),
                              color: borderColor,
                            ),
                            _InfoRow(
                              icon: LucideIcons.mail,
                              label: 'Email',
                              value: customerEmail,
                              labelColor: labelColor,
                              valueColor: valueColor,
                            ),
                          ],
                          if (customerPhone != null) ...[
                            Divider(
                              height: R.h(context, 20),
                              color: borderColor,
                            ),
                            _InfoRow(
                              icon: LucideIcons.phone,
                              label: 'Phone',
                              value: customerPhone,
                              labelColor: labelColor,
                              valueColor: valueColor,
                            ),
                          ],
                          Divider(height: R.h(context, 20), color: borderColor),
                          _InfoRow(
                            icon: LucideIcons.mapPin,
                            label: 'Address',
                            value: addrDisplay,
                            labelColor: labelColor,
                            valueColor: valueColor,
                          ),
                          if (order.notes != null &&
                              order.notes!.isNotEmpty) ...[
                            Divider(
                              height: R.h(context, 20),
                              color: borderColor,
                            ),
                            _InfoRow(
                              icon: LucideIcons.messageSquare,
                              label: 'Notes',
                              value: order.notes!,
                              labelColor: labelColor,
                              valueColor: valueColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: R.h(context, 18)),

                    // ── ITEMS ──────────────────────────────────────────────
                    _SectionHeader(
                      label: 'Purchased Items (${order.items.length})',
                      icon: LucideIcons.shoppingBag,
                      valueColor: valueColor,
                    ),
                    SizedBox(height: R.h(context, 10)),
                    Container(
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(R.r(context, 14)),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: order.items.isEmpty
                          ? Padding(
                              padding: R.all(context, 16),
                              child: Text(
                                'No item details available.',
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: R.font(context, 13),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (
                                  int i = 0;
                                  i < order.items.length;
                                  i++
                                ) ...[
                                  _ItemRow(
                                    item: order.items[i],
                                    isDark: isDark,
                                    valueColor: valueColor,
                                    labelColor: labelColor,
                                  ),
                                  if (i < order.items.length - 1)
                                    Divider(height: 1, color: borderColor),
                                ],
                              ],
                            ),
                    ),
                    SizedBox(height: R.h(context, 18)),

                    // ── TOTALS ─────────────────────────────────────────────
                    Container(
                      padding: R.all(context, 16),
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(R.r(context, 14)),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _TotalRow(
                            label: 'Subtotal',
                            value: order.subtotal,
                            labelColor: labelColor,
                            valueColor: valueColor,
                          ),
                          SizedBox(height: R.h(context, 8)),
                          _TotalRow(
                            label: 'Tax / Fees',
                            value: order.tax,
                            labelColor: labelColor,
                            valueColor: valueColor,
                          ),
                          Padding(
                            padding: R.symmetric(context, vertical: 10),
                            child: Divider(height: 1, color: borderColor),
                          ),
                          _TotalRow(
                            label: 'Grand Total',
                            value: order.total,
                            isTotal: true,
                            labelColor: labelColor,
                            valueColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ──────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color valueColor;
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: R.font(context, 15), color: AppColors.primary),
        SizedBox(width: R.w(context, 8)),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: R.font(context, 14),
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _MetaCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final bool isDark;
  final Color labelColor;
  final Color valueColor;
  final Color borderColor;
  final Color sectionBg;

  const _MetaCard({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    required this.isDark,
    required this.labelColor,
    required this.valueColor,
    required this.borderColor,
    required this.sectionBg,
  });

  @override
  Widget build(BuildContext context) {
    final iColor = iconColor ?? AppColors.primary;
    return Container(
      padding: R.all(context, 12),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(R.r(context, 12)),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: R.all(context, 8),
            decoration: BoxDecoration(
              color: iColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(R.r(context, 8)),
            ),
            child: Icon(icon, size: R.font(context, 16), color: iColor),
          ),
          SizedBox(width: R.w(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: R.font(context, 11),
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: R.h(context, 2)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: R.font(context, 13),
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: R.font(context, 15), color: labelColor),
        SizedBox(width: R.w(context, 10)),
        SizedBox(
          width: R.w(context, 70),
          child: Text(
            label,
            style: TextStyle(
              fontSize: R.font(context, 12),
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: R.font(context, 13),
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  final bool isDark;
  final Color valueColor;
  final Color labelColor;

  const _ItemRow({
    required this.item,
    required this.isDark,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: R.symmetric(context, horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(R.r(context, 8)),
            child: Container(
              width: R.r(context, 48),
              height: R.r(context, 48),
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        LucideIcons.image,
                        size: R.font(context, 20),
                        color: labelColor,
                      ),
                    )
                  : Icon(
                      LucideIcons.package,
                      size: R.font(context, 20),
                      color: labelColor,
                    ),
            ),
          ),
          SizedBox(width: R.w(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: R.font(context, 13),
                    color: valueColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: R.h(context, 2)),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    fontSize: R.font(context, 12),
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: R.w(context, 12)),
          Text(
            '${NumberFormat('#,###.##').format(item.unitPrice * item.quantity)} EGP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: R.font(context, 13),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final Color labelColor;
  final Color valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? R.font(context, 15) : R.font(context, 13),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? valueColor : labelColor,
          ),
        ),
        Text(
          '${NumberFormat('#,###.##').format(value)} EGP',
          style: TextStyle(
            fontSize: isTotal ? R.font(context, 17) : R.font(context, 13),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
