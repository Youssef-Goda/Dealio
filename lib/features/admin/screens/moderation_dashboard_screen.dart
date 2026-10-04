import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:dealio/core/constants/app_roles.dart';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/constants/base_url.dart';
import 'package:dealio/core/widgets/permission_guard.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/features/products/screens/product_details_page.dart';
import 'package:dealio/data/models/product_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// ModerationDashboardScreen
/// 100% real data from: orders (pending), Products table, activity_logs
class ModerationDashboardScreen extends StatelessWidget {
  const ModerationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      allowedRoles: AppRoles.moderators,
      fallback: const Scaffold(
        body: Center(child: Text('Access Denied')),
      ), 
      child: const _ModerationBody(),
    );
  }
}

class _ModerationBody extends StatefulWidget {
  const _ModerationBody();

  @override
  State<_ModerationBody> createState() => _ModerationBodyState();
}

class _ModerationBodyState extends State<_ModerationBody>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  DateTime? _lastUpdated;

  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  Map<String, dynamic> _stats = {
    'pendingOrders': 0,
    'highPriorityOrders': 0,
    'totalProducts': 0,
    'lowStockProducts': 0,
    'cancelledLast30Days': 0,
    'activityToday': 0,
  };

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _activityLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Initial load — shows full-screen spinner (no prior content).
  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    await _fetchData();
  }

  /// Re-fetch triggered by Refresh button — keeps existing content visible.
  Future<void> _refreshData() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _spinController.repeat();
    await _fetchData();
    _spinController.stop();
    _spinController.reset();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _fetchData() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      if (token.isEmpty) {
        setState(() { _loading = false; _error = 'Not authenticated.'; });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/moderation/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          setState(() {
            _stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
            _orders = (data['orders'] as List? ?? [])
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            _products = (data['products'] as List? ?? [])
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            _activityLogs = (data['activityLogs'] as List? ?? [])
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            _lastUpdated = DateTime.now();
            _loading = false;
            _error = null;
          });
          return;
        }
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load moderation data (${response.statusCode})';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh (${response.statusCode})'),
            action: SnackBarAction(label: 'Retry', onPressed: _refreshData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = e.toString(); });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _refreshData),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingOrders = _stats['pendingOrders'] ?? 0;
    final totalProducts = _stats['totalProducts'] ?? 0;
    final activityToday = _stats['activityToday'] ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shieldAlert, color: Colors.orangeAccent, size: 20),
            SizedBox(width: 8),
            Text('Moderation', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        // backgroundColor comes from appBarTheme in both light & dark
        actions: [
          // ── Refresh button: only on web/desktop ──────────────────────
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(right: 12),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: _tabLabel(
                LucideIcons.shoppingCart,
                'Orders',
                pendingOrders as int,
                Colors.orangeAccent,
              ),
            ),
            Tab(
              child: _tabLabel(
                LucideIcons.package,
                'Products',
                totalProducts as int,
                AppColors.infoBlue,
              ),
            ),
            Tab(
              child: _tabLabel(
                LucideIcons.activity,
                'Activity',
                activityToday as int,
                AppColors.successGreen,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.octagonAlert,
                          size: 48, color: AppColors.errorRed),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.errorRed),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: Column(
                    children: [
                      // ── Last Updated Indicator ─────────────────────────────
                      if (_lastUpdated != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                      _buildStatsRow(context, isDark),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrdersTab(context, isDark),
                            _buildProductsTab(context, isDark),
                            _buildActivityTab(context, isDark),
                          ],
                        ),
                      ),
                    ],
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
  Widget _tabLabel(IconData icon, String label, int count, Color badgeColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 5),
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow(BuildContext context, bool isDark) {
    final cards = [
      (
        'Pending Orders',
        '${_stats['pendingOrders'] ?? 0}',
        AppColors.warningAmber,
        LucideIcons.shoppingCart,
      ),
      (
        'High Priority',
        '${_stats['highPriorityOrders'] ?? 0}',
        AppColors.errorRed,
        LucideIcons.triangleAlert,
      ),
      (
        'Low Stock',
        '${_stats['lowStockProducts'] ?? 0}',
        AppColors.infoBlue,
        LucideIcons.packageMinus,
      ),
      (
        'Today\'s Actions',
        '${_stats['activityToday'] ?? 0}',
        AppColors.successGreen,
        LucideIcons.activity,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: cards.map((card) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? card.$3.withOpacity(0.07)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: card.$3.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(card.$4, size: 15, color: card.$3),
                  const SizedBox(height: 6),
                  Text(
                    card.$2,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: card.$3,
                    ),
                  ),
                  Text(
                    card.$1,
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tab 1: Pending Orders ─────────────────────────────────────────────────
  Widget _buildOrdersTab(BuildContext context, bool isDark) {
    if (_orders.isEmpty) {
      return _emptyState(
        context,
        LucideIcons.shoppingCart,
        'No pending orders',
        'All orders have been processed!',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, i) {
        final o = _orders[i];
        final priority = o['priority'] as String? ?? 'Normal';
        final priorityColor = priority == 'High'
            ? AppColors.errorRed
            : priority == 'Medium'
                ? AppColors.warningAmber
                : AppColors.successGreen;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : priorityColor.withOpacity(0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.shoppingCart,
                    size: 18, color: priorityColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o['id'] as String? ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${o['total']} • ${o['timeAgo']}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(o['status'] as String? ?? '', AppColors.warningAmber),
                        const SizedBox(width: 6),
                        _badge(priority, priorityColor),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _badge(
                    o['waitingHours'].toString() + 'h wait',
                    (o['waitingHours'] as int? ?? 0) >= 24
                        ? AppColors.errorRed
                        : AppColors.infoBlue,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 2: Products ───────────────────────────────────────────────────────
  Widget _buildProductsTab(BuildContext context, bool isDark) {
    if (_products.isEmpty) {
      return _emptyState(
        context,
        LucideIcons.package,
        'No products found',
        'Add products from the Admin panel.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, i) {
        final p = _products[i];
        final stock = p['countInStock'] as int? ?? 0;
        final stockColor = stock == 0
            ? AppColors.errorRed
            : stock < 5
                ? AppColors.warningAmber
                : AppColors.successGreen;
        final stockLabel = stock == 0
            ? 'Out of Stock'
            : stock < 5
                ? 'Low Stock ($stock)'
                : 'In Stock ($stock)';

        return GestureDetector(
          onTap: () => _navigateToProduct(p['id'] as String? ?? ''),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.infoBlue.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Product thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: p['imageUrl'] != null
                      ? Image.network(
                          p['imageUrl'] as String,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _productPlaceholder(AppColors.infoBlue),
                        )
                      : _productPlaceholder(AppColors.infoBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] as String? ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            p['price'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.successGreen,
                            ),
                          ),
                          if (p['oldPrice'] != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              p['oldPrice'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.star,
                              size: 11, color: AppColors.warningAmber),
                          const SizedBox(width: 3),
                          Text(
                            '${(p['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          _badge(stockLabel, stockColor),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Added',
                      style: TextStyle(
                          fontSize: 9, color: Theme.of(context).hintColor),
                    ),
                    Text(
                      p['submittedAgo'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Icon(LucideIcons.chevronRight,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab 3: Activity Logs ──────────────────────────────────────────────────
  Widget _buildActivityTab(BuildContext context, bool isDark) {
    if (_activityLogs.isEmpty) {
      return _emptyState(
        context,
        LucideIcons.activity,
        'No recent activity',
        'Admin and moderator actions will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activityLogs.length,
      itemBuilder: (context, i) {
        final log = _activityLogs[i];
        final action = log['action'] as String? ?? '';
        final Color actionColor = action.startsWith('CREATE') || action.startsWith('ADD')
            ? AppColors.successGreen
            : action.startsWith('UPDATE')
                ? AppColors.warningAmber
                : action.startsWith('DELETE') || action.startsWith('REMOVE')
                    ? AppColors.errorRed
                    : AppColors.infoBlue;

        final IconData actionIcon = action.startsWith('CREATE')
            ? LucideIcons.circlePlus
            : action.startsWith('UPDATE')
                ? LucideIcons.pencil
                : action.startsWith('DELETE')
                    ? LucideIcons.trash2
                    : LucideIcons.activity;

        final role = log['actorRole'] as String? ?? 'user';
        final roleColor = _roleColor(role);

        // Parse entity name from details
        final details = log['details'] as Map? ?? {};
        final entityName = (details['name'] as String?) ??
            (details['email'] as String?) ??
            log['actionLabel'] as String? ??
            '';

        final bool canNavigate =
            (action == 'CREATE_PRODUCT' || action == 'UPDATE_PRODUCT') &&
            (log['entityId'] as String?)?.isNotEmpty == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? actionColor.withOpacity(0.15)
                  : actionColor.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(actionIcon, size: 16, color: actionColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['actionLabel'] as String? ?? action,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: actionColor,
                      ),
                    ),
                    if (entityName.isNotEmpty)
                      Text(
                        entityName,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: roleColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8.5,
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          log['actorName'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).hintColor),
                        ),
                        const Spacer(),
                        Text(
                          log['timeAgo'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canNavigate) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      _navigateToProduct(log['entityId'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':     return AppColors.errorRed;
      case 'admin':     return AppColors.adminPurple;
      case 'moderator': return AppColors.warningAmber;
      case 'vendor':    return AppColors.successGreen;
      default:          return AppColors.infoBlue;
    }
  }

  Widget _productPlaceholder(Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(LucideIcons.package, size: 22, color: color),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _emptyState(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 52,
              color: Theme.of(context).hintColor.withOpacity(0.3)),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).hintColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToProduct(String productId) async {
    if (productId.isEmpty) return;
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final productData = body['data'] ?? body;
        if (productData is Map<String, dynamic>) {
          final product = Product.fromJson(productData);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsPage(product: product),
            ),
          );
        }
      }
    } catch (_) {}
  }
}
