import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ─── Issue 4 note ─────────────────────────────────────────────────────────────
// The backend VALID_STATUSES = ['pending','confirmed','processing','shipped',
// 'delivered','cancelled','refunded'] — all lowercase. The Dart enum .name
// already produces lowercase strings so this should match fine.
// If the DB has a text CHECK constraint rejecting 'processing', the backend
// must handle that via VALID_STATUSES — we keep the Dart enum name as-is.
// ──────────────────────────────────────────────────────────────────────────────

class OrderDetailsDialog extends StatefulWidget {
  final Order order;
  const OrderDetailsDialog({super.key, required this.order});

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  late OrderStatus _currentStatus;
  final bool _isUpdating = false;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    _showSnack('Status update not supported by current provider.', AppColors.errorRed);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        return const Color(0xFF8B5CF6);
      case OrderStatus.shipped:
        return const Color(0xFF06B6D4);
      case OrderStatus.delivered:
        return AppColors.successGreen;
      case OrderStatus.cancelled:
        return AppColors.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;
    

    // Issue 3: Properly resolve customer name and address
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

    final surfaceColor = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final sectionBg = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF8F9FB);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE8ECF0);
    final labelColor = isDark ? Colors.white38 : Colors.black38;
    final valueColor = isDark ? Colors.white : const Color(0xFF1A1D27);

    final statusColor = _statusColor(_currentStatus);



    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 640,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.receiptText,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: valueColor,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${order.shortId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary.withValues(alpha: 0.8),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: order.shortId),
                                );
                                setState(() => _isCopied = true);
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted)
                                    setState(() => _isCopied = false);
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isCopied
                                      ? const Icon(
                                          Icons.check_rounded,
                                          key: ValueKey('check'),
                                          size: 14,
                                          color: Colors.green,
                                        )
                                      : Icon(
                                          Icons.copy_rounded,
                                          key: const ValueKey('copy'),
                                          size: 14,
                                          color: AppColors.primary.withValues(
                                            alpha: 0.6,
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
                  // const SizedBox(width: 14),
                  // Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  //   Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
                  //   Text('#${order.shortId}', style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.8), fontFamily: 'monospace', fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  // ])),
                  // Status chip + dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.1 : 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: _isUpdating
                        ? SizedBox(
                            width: 20,
                            height: 20,
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
                                size: 13,
                                color: statusColor,
                              ),
                              dropdownColor: isDark
                                  ? const Color(0xFF1E2130)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
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
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _statusColor(s),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            s.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1A1D27),
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),
            ),

            // ── BODY ──────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                                  ).format(order.createdAt!)
                                : 'N/A',
                            isDark: isDark,
                            labelColor: labelColor,
                            valueColor: valueColor,
                            borderColor: borderColor,
                            sectionBg: sectionBg,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 20),

                    // ── CUSTOMER & SHIPPING ────────────────────────────────
                    _SectionHeader(
                      label: 'Customer & Shipping',
                      icon: LucideIcons.user,
                      valueColor: valueColor,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(14),
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
                            Divider(height: 20, color: borderColor),
                            _InfoRow(
                              icon: LucideIcons.mail,
                              label: 'Email',
                              value: customerEmail,
                              labelColor: labelColor,
                              valueColor: valueColor,
                            ),
                          ],
                          if (customerPhone != null) ...[
                            Divider(height: 20, color: borderColor),
                            _InfoRow(
                              icon: LucideIcons.phone,
                              label: 'Phone',
                              value: customerPhone,
                              labelColor: labelColor,
                              valueColor: valueColor,
                            ),
                          ],
                          Divider(height: 20, color: borderColor),
                          _InfoRow(
                            icon: LucideIcons.mapPin,
                            label: 'Address',
                            value: addrDisplay,
                            labelColor: labelColor,
                            valueColor: valueColor,
                          ),
                          if (order.notes != null &&
                              order.notes!.isNotEmpty) ...[
                            Divider(height: 20, color: borderColor),
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
                    const SizedBox(height: 20),

                    // ── ITEMS ──────────────────────────────────────────────
                    _SectionHeader(
                      label: 'Purchased Items (${order.items.length})',
                      icon: LucideIcons.shoppingCart,
                      valueColor: valueColor,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: order.items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No item details available.',
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: 13,
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
                    const SizedBox(height: 20),

                    // ── TOTALS ─────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(14),
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
                          const SizedBox(height: 8),
                          _TotalRow(
                            label: 'Tax / Fees',
                            value: order.tax,
                            labelColor: labelColor,
                            valueColor: valueColor,
                          ),
                          Divider(height: 24, color: borderColor),
                          _TotalRow(
                            label: 'Grand Total',
                            value: order.total,
                            isTotal: true,
                            labelColor: labelColor,
                            valueColor: AppColors.successGreen,
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

  Color _paymentColor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cod:
        return AppColors.warningAmber;
      case PaymentMethod.card:
      case PaymentMethod.online:
        return const Color(0xFF8B5CF6);
      case PaymentMethod.wallet:
        return const Color(0xFF06B6D4);
      case PaymentMethod.cash:
        return AppColors.successGreen;
    }
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
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
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
        Icon(icon, size: 15, color: labelColor),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
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
  final dynamic item;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 52,
              height: 52,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(LucideIcons.image, size: 22, color: labelColor),
                    )
                  : Icon(LucideIcons.image, size: 22, color: labelColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: valueColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: labelColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${NumberFormat('#,###.##').format(item.unitPrice * item.quantity)} EGP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor,
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
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? valueColor : labelColor,
          ),
        ),
        Text(
          '${NumberFormat('#,###.##').format(value)} EGP',
          style: TextStyle(
            fontSize: isTotal ? 17 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
