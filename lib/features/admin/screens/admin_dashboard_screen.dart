import 'package:dealio/core/constants/app_roles.dart';
import 'package:dealio/core/widgets/role_guard.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/user_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// AdminDashboardScreen
/// ─────────────────────────────────────────────────────────────────────────────
/// Entry point for the admin panel. Protected at the route level by
/// [GuardedRoute] so only admin/super_admin users can reach it.
///
/// Extend this screen with real widgets (order table, product management, etc.)
/// by adding cards to [_buildDashboardGrid].
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key}); 

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  bool _refreshing = false;
  DateTime? _lastUpdated;

  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    // Trigger user list fetch when the dashboard mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
      setState(() => _lastUpdated = DateTime.now());
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _spinController.repeat();
    await context.read<UserProvider>().fetchUsers();
    _spinController.stop();
    _spinController.reset();
    if (mounted) {
      setState(() {
        _refreshing = false;
        _lastUpdated = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // ── Refresh button: only on web/desktop ──────────────────────
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _refreshing ? null : _refreshData,
                icon: RotationTransition(
                  turns: _spinController,
                  child: const Icon(LucideIcons.refreshCw, size: 16),
                ),
                label: Text(
                  _refreshing ? 'Refreshing...' : 'Refresh',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white54,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
          // Only super_admin sees user management action
          RoleGuard(
            allowedRoles: AppRoles.userManagers,
            child: IconButton(
              icon: const Icon(Icons.manage_accounts_rounded),
              tooltip: 'User Management',
              onPressed: () => Navigator.of(context).pushNamed('/admin/users'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFFFD700),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Last Updated Indicator ─────────────────────────────
              if (_lastUpdated != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(LucideIcons.clock, size: 12,
                          color: Theme.of(context).hintColor),
                      const SizedBox(width: 5),
                      Text(
                        _formatLastUpdated(_lastUpdated!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              // ── Welcome Banner ─────────────────────────────────────
              _WelcomeBanner(
                name: '${auth.user['firstName'] ?? 'Admin'}',
                role: auth.userRole,
              ),
              const SizedBox(height: 24),

              // ── Stats Grid ───────────────────────────────────────────
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDashboardGrid(context, auth.userRole),

              const SizedBox(height: 24),

              // ── Super-Admin Only Section ───────────────────────────
              RoleGuard(
                allowedRoles: AppRoles.userManagers,
                child: _SuperAdminSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastUpdated(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (dtDay == today) return 'Last updated: Today, $timeStr';
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Last updated: ${months[dt.month - 1]} ${dt.day}, ${dt.year} • $timeStr';
  }

  Widget _buildDashboardGrid(BuildContext context, String role) {
    final items = [
      _DashboardItem(
        icon: Icons.inventory_2_rounded,
        label: 'Products',
        color: Colors.indigo,
        onTap: () => Navigator.of(context).pushNamed('/admin/products'),
        allowedRoles: AppRoles.productManagers,
      ),
      _DashboardItem(
        icon: Icons.receipt_long_rounded,
        label: 'Orders',
        color: Colors.teal,
        onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
        allowedRoles: AppRoles.orderManagers,
      ),
      _DashboardItem(
        icon: Icons.category_rounded,
        label: 'Categories',
        color: Colors.orange,
        onTap: () => Navigator.of(context).pushNamed('/admin/categories'),
        allowedRoles: AppRoles.productManagers,
      ),
      _DashboardItem(
        icon: Icons.people_alt_rounded,
        label: 'Users',
        color: Colors.deepPurple,
        onTap: () => Navigator.of(context).pushNamed('/admin/users'),
        allowedRoles: AppRoles.userManagers,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return RoleGuard(
          allowedRoles: item.allowedRoles,
          child: _DashboardCard(item: item),
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final String role;

  const _WelcomeBanner({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $name 👋',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.toUpperCase().replaceAll('_', ' '),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final List<String> allowedRoles;

  const _DashboardItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.allowedRoles,
  });
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;

  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 32),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: item.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuperAdminSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Super Admin Controls',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Role management and user deletion are restricted to Super Admin only.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
