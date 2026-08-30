import 'package:dealio/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Triggers the Privacy Policy & Terms of Service modal bottom sheet
void showPrivacyPolicySheet(BuildContext context, {VoidCallback? onAccept}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => PrivacyPolicySheet(onAccept: onAccept),
  );
}

/// Alias for terms bottom sheet to match alternative naming conventions
typedef TermsBottomSheet = PrivacyPolicySheet;

class PrivacyPolicySheet extends StatelessWidget {
  final VoidCallback? onAccept;

  const PrivacyPolicySheet({super.key, this.onAccept});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.82; // Covers 82% of screen height

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Drag Handle & Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              children: [
                // Drag handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.shieldCheck,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Privacy Policy',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Last updated: August 2026',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textDark,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable Policy Content ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    title: '1. Overview & Service Scope',
                    content:
                        'Welcome to Dealio. By accessing or using our platform, mobile application, and related e-commerce services, you agree to be bound by these Terms & Conditions and Privacy Policy. Dealio provides a modern, seamless online shopping experience connecting buyers with verified products, automated payment gateways, and local delivery networks.',
                    isDark: isDark,
                  ),
                  _buildSection(
                    context,
                    title: '2. User Accounts & Responsibilities',
                    content:
                        'You are responsible for maintaining the confidentiality of your account credentials, shipping address information, and contact details. You agree that all information provided during registration and checkout is accurate, up to date, and authentic.',
                    isDark: isDark,
                  ),
                  _buildSection(
                    context,
                    title: '3. Payments & Transaction Security',
                    content:
                        'Online transactions on Dealio are secured via Paymob unified payment gateway supporting Credit/Debit cards (Visa, Mastercard, Meeza) and Mobile Wallets (Vodafone Cash, Orange Cash, Etisalat Cash, WE Pay), as well as Cash on Delivery. Payment authorizations are verified strictly via backend webhooks.',
                    isDark: isDark,
                  ),
                  _buildSection(
                    context,
                    title: '4. Shipping & Delivery Terms',
                    content:
                        'Delivery estimates are calculated based on your selected delivery address. Dealio strives for fast, reliable order fulfillment. Order tracking statuses are updated live within your account dashboard.',
                    isDark: isDark,
                  ),
                  _buildSection(
                    context,
                    title: '5. Privacy & Data Protection',
                    content:
                        'We value your privacy. We collect minimal personal information required for order fulfillment, account authentication, and communication. We do not sell your personal data to third parties. All sensitive data is encrypted using industry standard protocols.',
                    isDark: isDark,
                  ),
                  _buildSection(
                    context,
                    title: '6. Order Cancellations & Refunds',
                    content:
                        'Orders can be cancelled prior to dispatch through your Order Details screen or customer support. Refunds for verified card or wallet payments are processed back to the original payment method in accordance with banking policies.',
                    isDark: isDark,
                  ),
                  _buildSection(
                    context,
                    title: '7. Contact & Support',
                    content:
                        'If you have any questions or feedback regarding these terms, please contact our support team via customer care or email dealio.eg7@gmail.com.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Fixed Bottom Action Button ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onAccept?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  onAccept != null ? 'I Accept & Agree' : 'Close',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
