import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:e_commerce/core/constants/app_roles.dart';
import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/widgets/permission_guard.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/data/services/api_service.dart';
import 'package:e_commerce/features/products/screens/product_details_page.dart';
import 'package:e_commerce/data/models/product_model.dart';
import 'package:e_commerce/data/providers/product_provider.dart';

/// PlatformControlScreen
/// ─────────────────────────────────────────────────────────────────────────────
/// The Owner's exclusive Platform Control dashboard.
/// Double-guarded: [PermissionGuard] here + AppNav ownerOnly restriction.
class PlatformControlScreen extends StatelessWidget {
  const PlatformControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      allowedRoles: AppRoles.ownerOnly,
      fallback: const Scaffold(
        body: Center(child: Text('Access Denied')),
      ),
      child: const _PlatformControlBody(),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────────
class _PlatformControlBody extends StatefulWidget {
  const _PlatformControlBody();

  @override
  State<_PlatformControlBody> createState() => _PlatformControlBodyState();
}

class _PlatformControlBodyState extends State<_PlatformControlBody>
    with SingleTickerProviderStateMixin {
  // ── Data state ──────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _refreshing = false;
  DateTime? _lastUpdated;

  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _auditLogs = [];
  Map<String, dynamic> _commissionSettings = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  /// Initial load — shows full-screen spinner (no prior content).
  Future<void> _loadData() async {
    setState(() => _loading = true);
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
        if (mounted) setState(() => _loading = false);
        return;
      }

      // 1. Fetch Financial Summary
      final financialsRes = await ApiService.getRequest('/owner/financials/summary', token);
      final financialsResult = ApiService.processResponse(financialsRes);

      // 2. Fetch Audit Logs
      final auditRes = await ApiService.getRequest('/owner/audit-log', token);
      final auditResult = ApiService.processResponse(auditRes);

      // 3. Fetch Platform Settings
      final settingsRes = await ApiService.getRequest('/owner/settings', token);
      final settingsResult = ApiService.processResponse(settingsRes);

      if (!mounted) return;

      setState(() {
        if (financialsResult['success'] == true) {
          final data = financialsResult['data']['data'] ?? {};
          _stats = {
            'totalProfit': 'EGP ${data['netProfit'] ?? '0.00'}',
            'activeVendors': data['activeVendors'] ?? 0,
            'totalOrders': data['totalOrders'] ?? 0,
            'totalUsers': data['totalUsers'] ?? 0,
            'platformRevenue': 'EGP ${data['totalRevenue'] ?? '0.00'}',
            'pendingPayouts': 'EGP ${data['totalPayouts'] ?? '0.00'}',
          };
        }

        if (auditResult['success'] == true) {
          final dynamic rawData = auditResult['data']['data'];
          if (rawData is List) {
            _auditLogs = rawData.cast<Map<String, dynamic>>();
          }
        }

        if (settingsResult['success'] == true) {
          final data = settingsResult['data']['data'] ?? {};
          _commissionSettings = {
            'globalRate': '${data['global_rate'] ?? '10'}',
            'vendorPayout': '${data['vendor_payout'] ?? '90'}',
            'platformCut': '${data['platform_cut'] ?? '10'}',
          };
        }
        _lastUpdated = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Load owner metrics error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _refreshData),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.zap, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text(
              'Platform Control',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Last Updated Indicator ────────────────────────────────
                    if (_lastUpdated != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
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
                    const SizedBox(height: 24),

                    // ── Welcome Banner ──────────────────────────────────────
                    _buildWelcomeBanner(context, isDark),
                    const SizedBox(height: 24),

                    // ── KPI Stats Grid ────────────────────────────────────────
                    _sectionHeader(context, LucideIcons.chartBarBig, 'Platform Overview'),
                    const SizedBox(height: 12),
                    _buildStatsGrid(context, isDark),
                    const SizedBox(height: 24),

                    // ── Admin Activity Audit Log ──────────────────────────────
                    _sectionHeader(context, LucideIcons.clipboardList, 'Admin Activity Audit Log'),
                    const SizedBox(height: 12),
                    _buildAuditLog(context, isDark),
                    const SizedBox(height: 24),

                    // ── Global Commission Settings ────────────────────────────
                    _sectionHeader(context, LucideIcons.settings, 'Global Commission Settings'),
                    const SizedBox(height: 12),
                    _buildCommissionPanel(context, isDark),
                    const SizedBox(height: 24),

                    // ── System Health ─────────────────────────────────────────
                    _sectionHeader(context, LucideIcons.activity, 'System Health'),
                    const SizedBox(height: 12),
                    _buildSystemHealth(context, isDark),
                    const SizedBox(height: 32),
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
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Last updated: ${months[dt.month - 1]} ${dt.day}, ${dt.year} • $timeStr';
  }
  // ── Welcome Banner ──────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
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
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: const Icon(LucideIcons.zap, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platform Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Owner mode access — full platform visibility and control.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
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

  // ── Stats Grid ──────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(BuildContext context, bool isDark) {
    final items = [
      _StatItem('Total Platform Profit', _stats['totalProfit'] ?? '--', LucideIcons.trendingUp, AppColors.successGreen),
      _StatItem('Active Vendors', '${_stats['activeVendors'] ?? 0}', LucideIcons.store, AppColors.infoBlue),
      _StatItem('Total Orders', '${_stats['totalOrders'] ?? 0}', LucideIcons.shoppingBag, AppColors.warningAmber),
      _StatItem('Total Users', '${_stats['totalUsers'] ?? 0}', LucideIcons.users, AppColors.adminPurple),
      _StatItem('Platform Revenue', _stats['platformRevenue'] ?? '--', LucideIcons.circleDollarSign, AppColors.primary),
      _StatItem('Pending Payouts', _stats['pendingPayouts'] ?? '--', LucideIcons.clock, AppColors.errorRed),
    ];
    final cols = MediaQuery.of(context).size.width < 600 ? 2 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (_, i) => _buildStatCard(context, isDark, items[i]),
    );
  }

  Widget _buildStatCard(BuildContext context, bool isDark, _StatItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? item.color.withOpacity(0.06)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? item.color.withOpacity(0.2)
              : Theme.of(context).dividerColor.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : item.color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _viewProduct(String productId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final token = context.read<AuthProvider>().token ?? '';
      if (token.isEmpty) {
        Navigator.pop(context);
        return;
      }

      final localProducts = context.read<ProductProvider>().products;
      Product? found;
      for (final p in localProducts) {
        if (p.id.toString() == productId) {
          found = p;
          break;
        }
      }

      if (found == null) {
        final response = await ApiService.getRequest('/products/$productId', token);
        final decoded = ApiService.processResponse(response);
        if (decoded['success'] == true && decoded['data'] != null) {
          found = Product.fromJson(decoded['data']);
        }
      }

      Navigator.pop(context);

      if (found != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(product: found!),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found (it might have been deleted).')),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint('❌ View product error: $e');
    }
  }

  String _formatAction(Map<String, dynamic> log) {
    final action = log['action']?.toString() ?? '';
    final details = log['details'] as Map<String, dynamic>? ?? {};
    final entityId = log['entityId']?.toString() ?? log['entity_id']?.toString() ?? '';

    switch (action) {
      case 'CREATE_PRODUCT':
        return 'Created product "${details['name'] ?? ''}"';
      case 'UPDATE_PRODUCT':
        return 'Updated product "${details['name'] ?? ''}"';
      case 'DELETE_PRODUCT':
        return 'Deleted product "${details['name'] ?? ''}"';
      case 'CREATE_CATEGORY':
        return 'Created category "${details['name'] ?? ''}"';
      case 'UPDATE_CATEGORY':
        return 'Updated category "${details['name'] ?? ''}"';
      case 'DELETE_CATEGORY':
        return 'Deleted category "${details['name'] ?? ''}"';
      case 'CREATE_BANNER':
        return 'Created banner "${details['title'] ?? ''}"';
      case 'DELETE_BANNER':
        return 'Deleted banner "${details['title'] ?? ''}"';
      case 'DELETE_USER':
        return 'Deleted user account (${details['email'] ?? ''})';
      case 'UPDATE_USER_ROLE':
        return 'Changed ${details['email'] ?? ''} role to ${details['newRole'] ?? ''}';
      case 'TOGGLE_USER_STATUS':
        return '${details['isActive'] == true ? 'Activated' : 'Deactivated'} account of ${details['email'] ?? ''}';
      case 'UPDATE_ORDER_STATUS':
        final shortId = entityId.length > 8 ? entityId.substring(0, 8) : entityId;
        return 'Updated order #$shortId to ${details['newStatus'] ?? ''}';
      case 'CANCEL_ORDER':
        final shortId = entityId.length > 8 ? entityId.substring(0, 8) : entityId;
        return 'Cancelled order #$shortId';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  String _formatTime(String? createdAtStr) {
    if (createdAtStr == null) return '';
    final date = DateTime.tryParse(createdAtStr)?.toLocal();
    if (date == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(date.year, date.month, date.day);
    
    if (logDay == today) {
      final diff = now.difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return 'Today';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    }
  }

  Map<String, dynamic> _getLogTypeConfig(Map<String, dynamic> log) {
    final action = (log['action'] ?? '').toString().toUpperCase();
    if (action.startsWith('CREATE_') || action == 'ADD_PRODUCT' || action == 'ADD_CATEGORY') {
      return {'color': Colors.green, 'icon': LucideIcons.plus};
    } else if (action.startsWith('UPDATE_') || action.startsWith('TOGGLE_') || action == 'EDIT_PRODUCT') {
      return {'color': Colors.amber[700] ?? Colors.amber, 'icon': LucideIcons.pencil};
    } else if (action.startsWith('DELETE_') || action.startsWith('CANCEL_') || action == 'REMOVE_PRODUCT') {
      return {'color': AppColors.errorRed, 'icon': LucideIcons.trash2};
    } else {
      return {'color': AppColors.infoBlue, 'icon': LucideIcons.activity};
    }
  }

  // ── Audit Log ───────────────────────────────────────────────────────────────
  Widget _buildAuditLog(BuildContext context, bool isDark) {
    if (_auditLogs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.clipboardList, size: 36, color: Theme.of(context).hintColor.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(
              'No activity logs recorded yet.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: _auditLogs.asMap().entries.map((entry) {
          final i = entry.key;
          final log = entry.value;
          final cfg = _getLogTypeConfig(log);
          final Color color = cfg['color'];
          final IconData icon = cfg['icon'];

          final user = log['user'] as Map<String, dynamic>?;
          final String adminName = user != null
              ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
              : 'System';
          final String role = (user?['role'] ?? '').toString();

          Color _roleColor(String r) {
            switch (r.toLowerCase()) {
              case 'owner':     return AppColors.errorRed;
              case 'admin':     return AppColors.adminPurple;
              case 'moderator': return AppColors.warningAmber;
              case 'vendor':    return AppColors.successGreen;
              default:          return AppColors.infoBlue;
            }
          }
          final roleColor = _roleColor(role);

          final createdAt = log['created_at']?.toString() ?? log['createdAt']?.toString();
          
          final String action = (log['action'] ?? '').toString().toUpperCase();
          final String entityId = (log['entityId'] ?? log['entity_id'] ?? '').toString();
          final bool canView = (action == 'CREATE_PRODUCT' || action == 'UPDATE_PRODUCT') && entityId.isNotEmpty;

          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.04),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAction(log),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'by $adminName',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              if (role.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: roleColor.withOpacity(0.3), width: 0.8),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
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
                          _formatTime(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).hintColor.withOpacity(0.7),
                          ),
                        ),
                        if (canView) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _viewProduct(entityId),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.eye, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'View',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Commission Settings ─────────────────────────────────────────────────────
  Widget _buildCommissionPanel(BuildContext context, bool isDark) {
    final rate = _commissionSettings['globalRate'] ?? '10';
    final payout = _commissionSettings['vendorPayout'] ?? '90';
    final cut = _commissionSettings['platformCut'] ?? '10';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _commissionTile(context, isDark,
                  'Global Rate', '$rate%', AppColors.infoBlue, LucideIcons.percent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _commissionTile(context, isDark,
                  'Vendor Payout', '$payout%', AppColors.successGreen, LucideIcons.store),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _commissionTile(context, isDark,
                  'Platform Cut', '$cut%', AppColors.errorRed, LucideIcons.building),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(LucideIcons.pencil, size: 15),
              label: const Text('Edit Commission Settings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // TODO: navigate to settings editor
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _commissionTile(BuildContext context, bool isDark,
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── System Health ───────────────────────────────────────────────────────────
  Widget _buildSystemHealth(BuildContext context, bool isDark) {
    final items = [
      ('API Server', 'Online', AppColors.successGreen, LucideIcons.server),
      ('Database', 'Healthy', AppColors.successGreen, LucideIcons.database),
      ('FCM Push', 'Active', AppColors.successGreen, LucideIcons.bell),
      ('Storage', 'OK', AppColors.successGreen, LucideIcons.hardDrive),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.$4, size: 14, color: item.$3),
              const SizedBox(width: 6),
              Text(
                '${item.$1}: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
              Text(
                item.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: item.$3,
                ),
              ),
              const SizedBox(width: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Section header ──────────────────────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Helper model ────────────────────────────────────────────────────────────────
class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}
