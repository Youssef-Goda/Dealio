import 'package:dealio/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Fawry / Cash Reference Modal
/// ─────────────────────────────────────────────────────────────────────────────
/// Displayed after a successful cash payment initiation.
/// Shows the bill reference number, copy button, instructions, and expiry.
class FawryCashModal extends StatefulWidget {
  final String billReference;
  final String expiresAt;
  final double amount;
  final VoidCallback onDone;

  const FawryCashModal({
    super.key,
    required this.billReference,
    required this.expiresAt,
    required this.amount,
    required this.onDone,
  });

  /// Convenience static method — shows as a bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String billReference,
    required String expiresAt,
    required double amount,
    required VoidCallback onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => FawryCashModal(
        billReference: billReference,
        expiresAt: expiresAt,
        amount: amount,
        onDone: onDone,
      ),
    );
  }

  @override
  State<FawryCashModal> createState() => _FawryCashModalState();
}

class _FawryCashModalState extends State<FawryCashModal>
    with SingleTickerProviderStateMixin {
  bool _copied = false;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyReference() async {
    await Clipboard.setData(ClipboardData(text: widget.billReference));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  String _formatExpiry(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month]} ${dt.year}, $h:$m';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fawry brand amber/orange
    const fawryAmber  = Color(0xFFF5A623);
    const fawryOrange = Color(0xFFE8831A);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Drag handle ──────────────────────────────────────────
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── Header icon ──────────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [fawryAmber, fawryOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: fawryAmber.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.store,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Title ────────────────────────────────────────────────
                  Text(
                    'Payment Reference Ready!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use the code below to complete your payment\nat any cash outlet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Reference Number Card ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          fawryAmber.withValues(alpha: isDark ? 0.15 : 0.08),
                          fawryOrange.withValues(alpha: isDark ? 0.08 : 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: fawryAmber.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Bill Reference Number',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: fawryOrange,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.billReference,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Copy button
                        SizedBox(
                          width: double.infinity,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _copied
                                ? _CopyButton(
                                    key: const ValueKey('copied'),
                                    label: 'Copied!',
                                    icon: LucideIcons.circleCheck,
                                    color: AppColors.successGreen,
                                    onTap: _copyReference,
                                  )
                                : _CopyButton(
                                    key: const ValueKey('copy'),
                                    label: 'Copy Reference Code',
                                    icon: LucideIcons.copy,
                                    color: fawryAmber,
                                    onTap: _copyReference,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Amount row ──────────────────────────────────────────
                  _InfoRow(
                    icon: LucideIcons.badgeDollarSign,
                    label: 'Amount Due',
                    value: 'EGP ${widget.amount.toStringAsFixed(2)}',
                    valueColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                    isDark: isDark,
                    isBold: true,
                  ),
                  const SizedBox(height: 12),

                  // ── Expiry row ──────────────────────────────────────────
                  _InfoRow(
                    icon: LucideIcons.clock,
                    label: 'Pay Before',
                    value: _formatExpiry(widget.expiresAt),
                    valueColor: AppColors.warningAmber,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // ── Instructions card ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.info,
                              size: 15,
                              color: AppColors.infoBlue,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'How to Pay',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _InstructionStep(
                          number: '1',
                          text: 'Copy the Reference Number above.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _InstructionStep(
                          number: '2',
                          text: 'Visit any nearby Fawry, Aman, Masary, or Basata outlet.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _InstructionStep(
                          number: '3',
                          text: 'Tell the cashier "Paymob" and provide the Reference Number.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _InstructionStep(
                          number: '4',
                          text: 'Pay EGP ${widget.amount.toStringAsFixed(2)} in cash. Keep your receipt.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Outlet logos row ────────────────────────────────────
                  _OutletBadgesRow(isDark: isDark),
                  const SizedBox(height: 24),

                  // ── CTA ─────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [fawryAmber, fawryOrange],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: fawryAmber.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDone();
                        },
                        icon: const Icon(
                          LucideIcons.circleCheck,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'I Understand — View My Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CopyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CopyButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool isDark;
  final bool isBold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isDark,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: valueColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;
  final bool isDark;

  const _InstructionStep({
    required this.number,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.infoBlue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.infoBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutletBadgesRow extends StatelessWidget {
  final bool isDark;
  const _OutletBadgesRow({required this.isDark});

  static const _outlets = ['Fawry', 'Aman', 'Masary', 'Basata'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _outlets.map((name) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.textDark,
            ),
          ),
        );
      }).toList(),
    );
  }
}
