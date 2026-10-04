import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:dealio/data/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand colour palette for payment methods
// ─────────────────────────────────────────────────────────────────────────────
abstract class _PayBrand {
  // Card
  static const cardBlue    = Color(0xFF1A56DB);
  static const cardBlueBg  = Color(0xFFEEF4FF);
  static const cardBlueDk  = Color(0xFF1E3A8A);

  // Wallets
  static const vodafoneRed = Color(0xFFE60000);
  static const orangeOg    = Color(0xFFFF6600);
  static const etisalatGrn = Color(0xFF00A651);
  static const wePurple    = Color(0xFF6D1F9D);

  // Cash / Fawry
  static const fawryAmber  = Color(0xFFF5A623);
  static const fawryOrange = Color(0xFFE8831A);
  static const fawryBg     = Color(0xFFFFF8ED);
  static const fawryBgDk   = Color(0xFF2A1E08);
}

// ─────────────────────────────────────────────────────────────────────────────
// PaymentMethodSelector
// ─────────────────────────────────────────────────────────────────────────────
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckoutProvider>();
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final selected = provider.paymentMethod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Option A: Cash on Delivery ─────────────────────────────────────
        _CodCard(
          isSelected: selected == PaymentMethod.cod,
          isDark:     isDark,
          onTap:      () => provider.selectPaymentMethod(PaymentMethod.cod),
        ),
        const SizedBox(height: 12),

        // ── Option B: Credit / Debit Card ──────────────────────────────────
        _CardPaymentCard(
          isSelected: selected == PaymentMethod.card ||
                      selected == PaymentMethod.online,
          isDark: isDark,
          onTap:  () => provider.selectPaymentMethod(PaymentMethod.card),
        ),
        const SizedBox(height: 12),

        // ── Option C: Mobile Wallets ────────────────────────────────────────
        _WalletCard(
          isSelected: selected == PaymentMethod.wallet,
          isDark:     isDark,
          onTap:      () => provider.selectPaymentMethod(PaymentMethod.wallet),
        ),
        const SizedBox(height: 12),

        // ── Option D: Cash / Fawry Outlets ─────────────────────────────────
        _FawryCard(
          isSelected: selected == PaymentMethod.cash,
          isDark:     isDark,
          onTap:      () => provider.selectPaymentMethod(PaymentMethod.cash),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared animated card shell
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentShell extends StatelessWidget {
  final bool    isSelected;
  final bool    isDark;
  final Color   accentColor;
  final Color?  selectedBg;
  final VoidCallback onTap;
  final Widget  child;

  const _PaymentShell({
    required this.isSelected,
    required this.isDark,
    required this.accentColor,
    this.selectedBg,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? (selectedBg ?? accentColor.withValues(alpha: 0.07))
        : (isDark ? AppColors.darkSurface : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? AppColors.darkBorder : AppColors.borderLight),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
          ],
        ),
      ),
    );
  }
}

// Radio dot used by all cards
class _RadioDot extends StatelessWidget {
  final bool isSelected;
  final Color accentColor;
  const _RadioDot({required this.isSelected, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? accentColor : Colors.transparent,
        border: Border.all(
          color: isSelected ? accentColor : AppColors.textHint,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
} 

// Icon box used in the header row
class _IconBox extends StatelessWidget {
  final Widget child;
  final Color  bg;
  const _IconBox({required this.child, required this.bg});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }
}

// Pill badge
class _Badge extends StatelessWidget {
  final String text;
  final Color  bg;
  final Color  fg;
  const _Badge({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A) Cash on Delivery card
// ─────────────────────────────────────────────────────────────────────────────
class _CodCard extends StatelessWidget {
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  const _CodCard({required this.isSelected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.successGreen;

    return _PaymentShell(
      isSelected: isSelected,
      isDark:     isDark,
      accentColor: accent,
      onTap:      onTap,
      child: Row(
        children: [
          _IconBox(
            bg: isSelected
                ? accent.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkBackground : AppColors.surfaceLight),
            child: Icon(
              LucideIcons.banknote,
              size: 24,
              color: isSelected ? accent : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pay in cash when your order arrives',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _RadioDot(isSelected: isSelected, accentColor: accent),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// B) Credit / Debit Card — blue theme with Visa / MC network icons
// ─────────────────────────────────────────────────────────────────────────────
class _CardPaymentCard extends StatelessWidget {
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  const _CardPaymentCard({required this.isSelected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = _PayBrand.cardBlue;
    final selectedBg = isDark
        ? _PayBrand.cardBlueDk.withValues(alpha: 0.25)
        : _PayBrand.cardBlueBg;

    return _PaymentShell(
      isSelected:  isSelected,
      isDark:      isDark,
      accentColor: accent,
      selectedBg:  selectedBg,
      onTap:       onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _IconBox(
                bg: isSelected
                    ? accent.withValues(alpha: 0.18)
                    : (isDark ? AppColors.darkBackground : AppColors.surfaceLight),
                child: Icon(
                  LucideIcons.creditCard,
                  size: 24,
                  color: isSelected ? accent : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credit / Debit Card',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Visa, Mastercard, Meeza — Secure SSL',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _RadioDot(isSelected: isSelected, accentColor: accent),
            ],
          ),
          const SizedBox(height: 12),

          // Network badges
          Row(
            children: [
              _NetworkBadge(
                label: 'VISA',
                bg: isSelected ? const Color(0xFF1A56DB) : const Color(0xFF1A56DB).withValues(alpha: 0.08),
                fg: isSelected ? Colors.white : const Color(0xFF1A56DB),
                italic: true,
              ),
              const SizedBox(width: 6),
              _NetworkBadge(
                label: 'MC',
                bg: isSelected ? const Color(0xFFEB001B) : const Color(0xFFEB001B).withValues(alpha: 0.08),
                fg: isSelected ? Colors.white : const Color(0xFFEB001B),
              ),
              const SizedBox(width: 6),
              _Badge(
                text: 'Meeza',
                bg: isSelected
                    ? accent.withValues(alpha: 0.18)
                    : (isDark ? AppColors.darkBackground : Colors.grey.withValues(alpha: 0.1)),
                fg: isSelected ? accent : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              // SSL badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.lock, size: 10, color: AppColors.successGreen),
                    const SizedBox(width: 3),
                    Text(
                      '256-SSL',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final bool italic;
  const _NetworkBadge({required this.label, required this.bg, required this.fg, this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// C) Mobile Wallets — multi-brand coloured dots
// ─────────────────────────────────────────────────────────────────────────────
class _WalletCard extends StatelessWidget {
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _WalletCard({
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.actionIndigo;

    return _PaymentShell(
      isSelected:  isSelected,
      isDark:      isDark,
      accentColor: accent,
      onTap:       onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _IconBox(
                bg: isSelected
                    ? accent.withValues(alpha: 0.15)
                    : (isDark ? AppColors.darkBackground : AppColors.surfaceLight),
                child: Icon(
                  LucideIcons.wallet,
                  size: 24,
                  color: isSelected ? accent : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Wallet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pay directly from your mobile wallet',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _RadioDot(isSelected: isSelected, accentColor: accent),
            ],
          ),
          const SizedBox(height: 12),

          // Wallet brand badges
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: [
              _WalletBrand(
                label: 'Vodafone Cash',
                dotColor: _PayBrand.vodafoneRed,
                isSelected: isSelected,
                isDark: isDark,
              ),
              _WalletBrand(
                label: 'Orange Cash',
                dotColor: _PayBrand.orangeOg,
                isSelected: isSelected,
                isDark: isDark,
              ),
              _WalletBrand(
                label: 'Etisalat Cash',
                dotColor: _PayBrand.etisalatGrn,
                isSelected: isSelected,
                isDark: isDark,
              ),
              _WalletBrand(
                label: 'WE Pay',
                dotColor: _PayBrand.wePurple,
                isSelected: isSelected,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletBrand extends StatelessWidget {
  final String label;
  final Color dotColor;
  final bool isSelected;
  final bool isDark;
  const _WalletBrand({
    required this.label,
    required this.dotColor,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? dotColor.withValues(alpha: 0.1)
            : (isDark ? AppColors.darkBackground : Colors.grey.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? dotColor.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? dotColor
                  : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// D) Cash Payment Outlets (Fawry) — amber/orange theme
// ─────────────────────────────────────────────────────────────────────────────
class _FawryCard extends StatelessWidget {
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  const _FawryCard({required this.isSelected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent   = _PayBrand.fawryAmber;
    const accentDk = _PayBrand.fawryOrange;
    final selectedBg = isDark ? _PayBrand.fawryBgDk : _PayBrand.fawryBg;

    return _PaymentShell(
      isSelected:  isSelected,
      isDark:      isDark,
      accentColor: accent,
      selectedBg:  selectedBg,
      onTap:       onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _IconBox(
                bg: isSelected
                    ? accent.withValues(alpha: 0.22)
                    : (isDark ? AppColors.darkBackground : AppColors.surfaceLight),
                child: isSelected
                    ? const Icon(LucideIcons.store, size: 24, color: accentDk)
                    : Icon(LucideIcons.store, size: 24, color: AppColors.textMuted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Cash Payment Outlets',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // "Popular" pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Popular',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: accentDk,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pay at any Fawry, Aman or Masary outlet',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _RadioDot(isSelected: isSelected, accentColor: accent),
            ],
          ),
          const SizedBox(height: 12),

          // Outlet badges
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: const [
              _OutletBadge(label: 'Fawry',  color: Color(0xFFF5A623)),
              _OutletBadge(label: 'Aman',   color: Color(0xFF16A34A)),
              _OutletBadge(label: 'Masary', color: Color(0xFF2563EB)),
              _OutletBadge(label: 'Basata', color: Color(0xFF7C3AED)),
            ],
          ),

          const SizedBox(height: 10),

          // Info note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 13, color: accentDk),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'A bill reference number will be generated for you to pay at the outlet within 48 hours.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: accentDk,
                    ),
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

class _OutletBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _OutletBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
