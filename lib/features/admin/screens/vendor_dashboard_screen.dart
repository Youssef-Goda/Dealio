import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:e_commerce/core/constants/app_roles.dart';
import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/widgets/permission_guard.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/data/services/api_service.dart';

/// VendorDashboardScreen — Analytics & Payouts
/// ─────────────────────────────────────────────────────────────────────────────
/// Modernized analytics dashboard with Revenue chart, Top Products, and Sales Volume.
class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      allowedRoles: AppRoles.analyticsViewers,
      fallback: const Scaffold(
        body: Center(child: Text('Access Denied')),
      ),
      child: const _VendorDashboardBody(),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────────
class _VendorDashboardBody extends StatefulWidget {
  const _VendorDashboardBody();

  @override
  State<_VendorDashboardBody> createState() => _VendorDashboardBodyState();
}

class _VendorDashboardBodyState extends State<_VendorDashboardBody>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _refreshing = false; // re-fetch without blanking existing content
  DateTime? _lastUpdated;

  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // ── Data stubs ─────────────────────────────────────────────────────────────
  List<_RevenuePoint> _revenueData = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _recentOrders = [];
  Map<String, dynamic> _kpis = {};

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

  /// Initial load — shows full-screen spinner (content not yet available).
  Future<void> _loadData() async {
    setState(() => _loading = true);
    await _fetchData();
  }

  /// Re-fetch triggered by Refresh button — keeps existing content visible.
  Future<void> _refreshData() async {
    if (_refreshing) return; // guard against duplicate taps
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

      final response = await ApiService.getRequest('/analytics/dashboard', token);
      final decoded = ApiService.processResponse(response);

      if (decoded['success'] == true && decoded['data'] != null) {
        final data = decoded['data']['data'] as Map<String, dynamic>? ?? {};

        final apiKpis = data['kpis'] as Map<String, dynamic>? ?? {};

        final apiTimeline = data['revenueTimeline'] as List? ?? [];
        final List<_RevenuePoint> parsedTimeline = apiTimeline.map<_RevenuePoint>((item) {
          final m = item['month']?.toString() ?? '';
          final r = double.tryParse(item['revenue']?.toString() ?? '0') ?? 0.0;
          return _RevenuePoint(m, r);
        }).toList();

        final List<Map<String, dynamic>> apiTopProducts = (data['topProducts'] as List? ?? [])
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        final List<Map<String, dynamic>> apiRecentOrders = (data['recentOrders'] as List? ?? [])
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        if (mounted) {
          setState(() {
            _kpis = apiKpis;
            _revenueData = parsedTimeline;
            _topProducts = apiTopProducts;
            _recentOrders = apiRecentOrders;
            _lastUpdated = DateTime.now();
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load analytics: ${decoded['message'] ?? 'Unknown error'}'),
              action: SnackBarAction(label: 'Retry', onPressed: _refreshData),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Load Analytics Error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
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
            Icon(LucideIcons.chartBarBig, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Last Updated Indicator ─────────────────────────────
                    if (_lastUpdated != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
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

                    // ── Hero Banner ─────────────────────────────────────────
                    _buildHeroBanner(context, isDark),
                    const SizedBox(height: 20),

                    // ── KPI Cards ───────────────────────────────────────────
                    _sectionHeader(context, LucideIcons.trendingUp, 'Performance Overview'),
                    const SizedBox(height: 12),
                    _buildKpiRow(context, isDark),
                    const SizedBox(height: 24),

                    // ── Revenue Chart ───────────────────────────────────────
                    _sectionHeader(context, LucideIcons.chartLine, 'Revenue Over Time'),
                    const SizedBox(height: 12),
                    _buildRevenueChart(context, isDark),
                    const SizedBox(height: 24),

                    // ── Top Products + Recent Orders (side by side on wide) ──
                    _buildBottomSection(context, isDark),
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
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Last updated: ${months[dt.month - 1]} ${dt.day}, ${dt.year} • $timeStr';
  }

  // ── Hero Banner ─────────────────────────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFE6BE00), Color(0xFFD4AC00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Store Analytics',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Revenue: ${_kpis['totalRevenue']}  •  Growth: ${_kpis['growthPercent']}',
                  style: TextStyle(
                    color: AppColors.secondary.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.store, size: 40, color: AppColors.secondary),
        ],
      ),
    );
  }

  // ── KPI Row ─────────────────────────────────────────────────────────────────
  Widget _buildKpiRow(BuildContext context, bool isDark) {
    final items = [
      ('Total Revenue', _kpis['totalRevenue'] ?? '--', AppColors.successGreen, LucideIcons.circleDollarSign),
      ('Total Orders', _kpis['totalOrders'] ?? '--', AppColors.infoBlue, LucideIcons.shoppingBag),
      ('Avg Order', _kpis['avgOrder'] ?? '--', AppColors.adminPurple, LucideIcons.activity),
      ('Rating', _kpis['rating'] ?? '--', AppColors.warningAmber, LucideIcons.star),
    ];
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? item.$3.withOpacity(0.06)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.$3.withOpacity(0.18)),
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
                Icon(item.$4, size: 16, color: item.$3),
                const SizedBox(height: 8),
                Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.$1,
                  style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Revenue Chart (custom bar chart — no external dependency needed) ─────────
  Widget _buildRevenueChart(BuildContext context, bool isDark) {
    final maxValue = _revenueData.map((p) => p.value).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      height: 200,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EGP Revenue (Monthly)',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _revenueData.map((point) {
                final ratio = maxValue > 0 ? point.value / maxValue : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label on top of bar
                        Text(
                          '${(point.value / 1000).toStringAsFixed(1)}k',
                          style: TextStyle(
                            fontSize: 8,
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: 110 * ratio,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Month label
                        Text(
                          point.month,
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Section ──────────────────────────────────────────────────────────
  Widget _buildBottomSection(BuildContext context, bool isDark) {
    final isWide = MediaQuery.of(context).size.width > 800;
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(context, LucideIcons.package, 'Recent Orders'),
                const SizedBox(height: 12),
                _buildRecentOrders(context, isDark),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(context, LucideIcons.award, 'Top Products'),
                const SizedBox(height: 12),
                _buildTopProducts(context, isDark),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, LucideIcons.package, 'Recent Orders'),
        const SizedBox(height: 12),
        _buildRecentOrders(context, isDark),
        const SizedBox(height: 24),
        _sectionHeader(context, LucideIcons.award, 'Top Products'),
        const SizedBox(height: 12),
        _buildTopProducts(context, isDark),
      ],
    );
  }

  // ── Recent Orders ───────────────────────────────────────────────────────────
  Widget _buildRecentOrders(BuildContext context, bool isDark) {
    final statusColors = {
      'Pending': AppColors.warningAmber,
      'Processing': AppColors.infoBlue,
      'Shipped': AppColors.adminPurple,
      'Delivered': AppColors.successGreen,
    };
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: _recentOrders.asMap().entries.map((entry) {
          final i = entry.key;
          final order = entry.value;
          final statusColor = statusColors[order['status']] ?? Colors.grey;
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(LucideIcons.receipt, size: 14, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ${order['id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(order['time'] as String,
                              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                    Text(order['amount'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order['status'] as String,
                        style: TextStyle(
                            fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                      ),
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

  // ── Top Products ────────────────────────────────────────────────────────────
  Widget _buildTopProducts(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: _topProducts.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final growth = p['growth'] as String;
          final isPositive = growth.startsWith('+');
          final growthColor = isPositive ? AppColors.successGreen : AppColors.errorRed;

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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('${p['sold']} sold',
                              style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p['revenue'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.successGreen)),
                        Text(
                          growth,
                          style: TextStyle(
                              fontSize: 10, color: growthColor, fontWeight: FontWeight.bold),
                        ),
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
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Revenue data model ─────────────────────────────────────────────────────────
class _RevenuePoint {
  final String month;
  final double value;
  const _RevenuePoint(this.month, this.value);
}
