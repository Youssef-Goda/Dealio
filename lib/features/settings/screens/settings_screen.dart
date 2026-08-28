import 'package:e_commerce/core/constants/app_roles.dart';
import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/data/providers/theme_provider.dart';
import 'package:e_commerce/features/settings/screens/about_screen.dart';
import 'package:e_commerce/features/settings/screens/store_settings_screen.dart';
import 'package:e_commerce/features/settings/widgets/privacy_policy_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isOwnerOrAdmin = AppRoles.isAllowed(auth.userRole, AppRoles.ownerOnly);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: R.isMobile(context) ? 16 : 32,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App & Preferences ─────────────────────────────────────────
                _SectionHeader(title: 'App Preferences', isDark: isDark),
                const SizedBox(height: 10),
                _SettingsCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: themeProvider.isDarkMode,
                        onChanged: (val) => themeProvider.toggleTheme(val),
                        title: Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimaryDark,
                          ),
                        ),
                        subtitle: Text(
                          'Switch between light and dark themes',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            themeProvider.isDarkMode
                                ? LucideIcons.moon
                                : LucideIcons.sun,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Store Management Submenu (Owner/Admin) ──────────────────
                if (isOwnerOrAdmin) ...[
                  _SectionHeader(title: 'Store Management', isDark: isDark),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    isDark: isDark,
                    child: _SettingsTile(
                      icon: LucideIcons.store,
                      title: 'Store Settings',
                      subtitle: 'Configure store details, payment keys & options',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StoreSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── About & Support ──────────────────────────────────────────
                _SectionHeader(title: 'About & Support', isDark: isDark),
                const SizedBox(height: 10),
                _SettingsCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.info,
                        title: 'About Dealio',
                        subtitle: 'App version, highlights & developer info',
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.dividerGrey,
                      ),
                      _SettingsTile(
                        icon: LucideIcons.shieldCheck,
                        title: 'Terms of Service & Privacy Policy',
                        subtitle: 'Read our usage terms and privacy commitments',
                        isDark: isDark,
                        onTap: () => showPrivacyPolicySheet(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Account & Session ────────────────────────────────────────
                _SectionHeader(title: 'Account', isDark: isDark),
                const SizedBox(height: 10),
                _SettingsCard(
                  isDark: isDark,
                  child: _SettingsTile(
                    icon: LucideIcons.logOut,
                    title: 'Logout',
                    subtitle: 'Sign out of your current account session',
                    iconColor: AppColors.errorRed,
                    textColor: AppColors.errorRed,
                    isDark: isDark,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?'),
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
              context.read<AuthProvider>().logout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final Color? iconColor;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveTextColor = textColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveIconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveIconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: effectiveTextColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
      ),
    );
  }
}
