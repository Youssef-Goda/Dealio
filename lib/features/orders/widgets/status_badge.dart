import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool large;

  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cfg = _config(status, isDark);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 3, // قللت الـ vertical شوية عشان يبقى Compact
      ),
      decoration: BoxDecoration(
        color: cfg.color.withOpacity(isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(large ? 10 : 8), // خليته Rounded أكتر
        border: Border.all(
          color: cfg.color.withOpacity(isDark ? 0.4 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            cfg.icon,
            size: large ? 15 : 12,
            color: cfg.color,
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: large ? 12 : 10.5,
              fontWeight: FontWeight.w800, // خليته أتقل شوية عشان يوضح
              color: cfg.color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _config(OrderStatus s, bool isDark) {
    // استخدمت ألوان Adaptive عشان الـ Contrast في الـ Dark Mode
    switch (s) {
      case OrderStatus.pending:
        return _StatusConfig(
          isDark ? const Color(0xFFFFD54F) : AppColors.warningAmber,
          LucideIcons.clock,
        );
      case OrderStatus.confirmed:
        return _StatusConfig(
          isDark ? const Color(0xFF81D4FA) : AppColors.infoBlue,
          LucideIcons.shieldCheck, // أيقونة أنسب للـ Confirmation
        );
      case OrderStatus.processing:
        return _StatusConfig(
          isDark ? const Color(0xFFFFB74D) : const Color(0xFFF59E0B),
          LucideIcons.loader,
        );
      case OrderStatus.shipped:
        return _StatusConfig(
          isDark ? const Color(0xFF9FA8DA) : AppColors.actionIndigo,
          LucideIcons.truck,
        );
      case OrderStatus.delivered:
        return _StatusConfig(
          isDark ? const Color(0xFF81C784) : AppColors.successGreen,
          LucideIcons.packageCheck,
        );
      case OrderStatus.cancelled:
        return _StatusConfig(
          isDark ? const Color(0xFFE57373) : AppColors.errorRed,
          LucideIcons.circleSlash, // شكل أوضح للـ Cancel
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  const _StatusConfig(this.color, this.icon);
}