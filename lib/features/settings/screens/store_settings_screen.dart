import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:dealio/core/constants/app_roles.dart';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/widgets/permission_guard.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/settings_provider.dart';

/// StoreSettingsScreen
/// ─────────────────────────────────────────────────────────────────────────────
/// Owner-only Store Settings screen inside the Dashboard.
/// Guarded by [PermissionGuard] for AppRoles.ownerOnly.
class StoreSettingsScreen extends StatelessWidget {
  const StoreSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      allowedRoles: AppRoles.ownerOnly,
      fallback: const Scaffold(
        body: Center(child: Text('Access Denied')),
      ),
      child: const _StoreSettingsBody(),
    );
  }
}

class _StoreSettingsBody extends StatefulWidget {
  const _StoreSettingsBody();

  @override
  State<_StoreSettingsBody> createState() => _StoreSettingsBodyState();
}

class _StoreSettingsBodyState extends State<_StoreSettingsBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreSettingsProvider>().fetchPublicSettings();
    });
  }

  Future<void> _toggleBanner(bool value) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: 'Authentication session expired. Please log in again.'),
        );
      }
      return;
    }

    final provider = context.read<StoreSettingsProvider>();
    final success = await provider.updateOwnerSettings(
      isBannerEnabled: value,
      token: token,
    );

    if (!mounted) return;

    if (success) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(
          message: value
              ? 'Homepage banners enabled system-wide.'
              : 'Homepage banners disabled system-wide.',
        ),
      );
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: provider.errorMessage ?? 'Failed to update store settings.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = context.watch<StoreSettingsProvider>();
    final isLoading = settingsProvider.isLoading;
    final isUpdating = settingsProvider.isUpdating;
    final isBannerEnabled = settingsProvider.isBannerEnabled;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.settings, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Store Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Refresh Settings',
            onPressed: (isLoading || isUpdating)
                ? null
                : () => context.read<StoreSettingsProvider>().fetchPublicSettings(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
              onRefresh: () => context.read<StoreSettingsProvider>().fetchPublicSettings(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header Banner ──────────────────────────────────
                        _buildHeaderBanner(context, isDark),
                        const SizedBox(height: 24),

                        // ── Feature Management Section ─────────────────────
                        _buildSectionHeader(
                          context,
                          LucideIcons.slidersHorizontal,
                          'Feature Management',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          context,
                          isDark: isDark,
                          isUpdating: isUpdating,
                          isBannerEnabled: isBannerEnabled,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(LucideIcons.settings, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Store Settings & Control',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure system-wide feature flags and operational preferences for the store.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required bool isDark,
    required bool isUpdating,
    required bool isBannerEnabled,
  }) {
    final cardBg = isDark
        ? Theme.of(context).cardColor
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Homepage Banners',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          if (isUpdating) ...[
                            const SizedBox(width: 10),
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enable or disable the top banner carousel across the mobile app and website.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).hintColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: isBannerEnabled,
                  onChanged: isUpdating ? null : (val) => _toggleBanner(val),
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
