import 'dart:async';

import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/core/widgets/dealio_skeleton.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/data/providers/orders_provider.dart';
import 'package:dealio/features/admin/widgets/order_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
class OrdersContent extends StatefulWidget {
  const OrdersContent({super.key});
  @override
  State<OrdersContent> createState() => _OrdersContentState();
}

class _OrdersContentState extends State<OrdersContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  String _selectedStatus = 'All';
  String _selectedGov    = 'All Governorates';
  String _selectedCity   = 'All Cities';
  bool   _focusMode      = false;

  // Current active filter values sent to backend
  // ignore: unused_field
  String _activeSearch = '';
  // ignore: unused_field
  String _activeStatus = '';
  // ignore: unused_field
  String _activeGov    = '';
  // ignore: unused_field
  String _activeCity   = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch(page: 1);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Centralised fetch call ────────────────────────────────────────────────
  void _fetch({required int page}) {
    context.read<OrdersProvider>().fetchOrders();
  }

  // ── Search with 500 ms debounce ───────────────────────────────────────────
  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _activeSearch = val.trim());
      _fetch(page: 1);
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _debounce?.cancel();
    setState(() => _activeSearch = '');
    _fetch(page: 1);
  }

  // ── Status / geo filter change ────────────────────────────────────────────
  void _onStatusChanged(String v) {
    setState(() {
      _selectedStatus = v;
      _activeStatus   = v == 'All' ? '' : v.toLowerCase();
    });
    _fetch(page: 1);
  }

  void _onGovChanged(String v) {
    setState(() {
      _selectedGov  = v;
      _activeGov    = v == 'All Governorates' ? '' : v;
      // reset city whenever governorate changes
      _selectedCity = 'All Cities';
      _activeCity   = '';
    });
    _fetch(page: 1);
  }

  void _onCityChanged(String v) {
    setState(() {
      _selectedCity = v;
      _activeCity   = v == 'All Cities' ? '' : v;
    });
    _fetch(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, prov, _) {
        final bool isMobile = R.isMobile(context);
        final bool isLandscapeMobile = MediaQuery.of(context).size.height < 600;
        final bool shouldScroll = isMobile || isLandscapeMobile;

        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_focusMode) ...[
              _Header(isLoading: prov.isLoading),
              const SizedBox(height: 24),
              _StatsRow(prov: prov),
              const SizedBox(height: 20),
            ],
            _FilterBar(
              searchCtrl:       _searchCtrl,
              selectedStatus:   _selectedStatus,
              selectedGov:      _selectedGov,
              selectedCity:     _selectedCity,
              governorates:     [],
              cities:           [],
              currentPage:      1,
              totalPages:       1,
              totalOrders:      prov.orders.length,
              isLoading:        prov.isLoading,
              focusMode:        _focusMode,
              onSearchChanged:  _onSearchChanged,
              onClearSearch:    _clearSearch,
              onStatusChanged:  _onStatusChanged,
              onGovChanged:     _onGovChanged,
              onCityChanged:    _onCityChanged,
              onPageChanged:    (p) => _fetch(page: p),
              onToggleFocus:    () => setState(() => _focusMode = !_focusMode),
            ),
            const SizedBox(height: 16),
            shouldScroll
                ? SizedBox(
                    height: _focusMode
                        ? MediaQuery.of(context).size.height - 140
                        : 450,
                    child: _Table(orders: prov.orders, prov: prov),
                  )
                : Expanded(child: _Table(orders: prov.orders, prov: prov)),
          ],
        );

        return RefreshIndicator(
          onRefresh: () => Future(() => _fetch(page: 1)),
          color: AppColors.primary,
          child: Padding(
            padding: R.all(context, 20),
            child: shouldScroll
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: content,
                  )
                : content,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════ //
// HEADER
// ═══════════════════════════════════════════════════════════════════════════ //
class _Header extends StatelessWidget {
  final bool isLoading;
  const _Header({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Orders Management',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color)),
            const SizedBox(height: 4),
            Text('Monitor and manage all customer orders',
                style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14)),
          ]),
        ),
        if (isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════ //
// KPI STATS ROW — uses global_stats, unaffected by filters
// ═══════════════════════════════════════════════════════════════════════════ //
class _StatsRow extends StatelessWidget {
  final OrdersProvider prov;
  const _StatsRow({required this.prov});

  Widget _card(BuildContext ctx, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final narrow = MediaQuery.of(ctx).size.width < 550;

    if (narrow) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? color.withValues(alpha: 0.05) : Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? color.withValues(alpha: 0.2) : Theme.of(ctx).dividerColor.withValues(alpha: 0.05)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: Theme.of(ctx).textTheme.bodyLarge?.color), textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.05) : Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? color.withValues(alpha: 0.2) : Theme.of(ctx).dividerColor.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: isDark ? Colors.black26 : color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12),
              boxShadow: [if (isDark) BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)]),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: Theme.of(ctx).hintColor, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
          ])),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (prov.isLoading && prov.orders.isEmpty) return const AdminStatCardSkeleton();
    // Use global stats so KPI cards always show DB-wide numbers
    final total     = prov.orders.length     > 0 ? prov.orders.length     : prov.orders.length;
    final pending   = prov.orders.where((o) => o.status == OrderStatus.pending).length;
    final delivered = prov.orders.where((o) => o.status == OrderStatus.delivered).length;
    final cancelled = prov.orders.where((o) => o.status == OrderStatus.cancelled).length;

    return Row(children: [
      _card(context, 'Total Orders', total.toString(),     LucideIcons.shoppingBag,  AppColors.infoBlue),
      _card(context, 'Pending',      pending.toString(),   LucideIcons.clock,        AppColors.warningAmber),
      _card(context, 'Delivered',    delivered.toString(), LucideIcons.checkCheck,   AppColors.successGreen),
      _card(context, 'Cancelled',    cancelled.toString(), LucideIcons.ban,          AppColors.errorRed),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════ //
// FILTER BAR
// ═══════════════════════════════════════════════════════════════════════════ //
class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String selectedStatus;
  final String selectedGov;
  final String selectedCity;
  final List<String> governorates;
  final List<String> cities;
  final int currentPage;
  final int totalPages;
  final int totalOrders;
  final bool isLoading;
  final bool focusMode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onGovChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onToggleFocus;

  static const _statusOptions = [
    'All', 'Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled',
  ];

  const _FilterBar({
    required this.searchCtrl,
    required this.selectedStatus,
    required this.selectedGov,
    required this.selectedCity,
    required this.governorates,
    required this.cities,
    required this.currentPage,
    required this.totalPages,
    required this.totalOrders,
    required this.isLoading,
    required this.focusMode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusChanged,
    required this.onGovChanged,
    required this.onCityChanged,
    required this.onPageChanged,
    required this.onToggleFocus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = R.isMobile(context);

    final boxDeco = BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03)),
    );

    // ── Generic dropdown helper ──────────────────────────────────────────────
    Widget dropdown<T extends Object>({
      required IconData icon,
      required T value,
      required List<T> options,
      required String Function(T) label,
      required ValueChanged<T> onChanged,
      String tooltip = '',
    }) {
      return Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: boxDeco,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: Theme.of(context).hintColor.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                icon: Icon(LucideIcons.chevronDown, size: 13, color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
                dropdownColor: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                onChanged: (v) { if (v != null) onChanged(v); },
                items: options.map((v) => DropdownMenuItem<T>(value: v, child: Text(label(v)))).toList(),
                isDense: true,
              ),
            ),
          ]),
        ),
      );
    }

    // ── Governorate options ──────────────────────────────────────────────────
    final govOptions = ['All Governorates', ...governorates];
    final cityOptions = ['All Cities', ...cities];

    // ── Search field ─────────────────────────────────────────────────────────
    final searchField = TextField(
      controller: searchCtrl,
      onChanged: onSearchChanged,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search by name, email, phone, order ID, address...',
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Theme.of(context).hintColor.withValues(alpha: 0.4), fontSize: 13),
        prefixIcon: Icon(LucideIcons.search, size: 16, color: isDark ? Colors.white24 : Theme.of(context).hintColor.withValues(alpha: 0.4)),
        suffixIcon: searchCtrl.text.isNotEmpty
            ? IconButton(icon: Icon(LucideIcons.x, size: 15, color: isDark ? Colors.white38 : Colors.black38), onPressed: onClearSearch)
            : null,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background.withValues(alpha: 0.35),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );

    // ── Ellipsis pagination ──────────────────────────────────────────────────
    final pagination = totalPages > 1
        ? _EllipsisPagination(
            currentPage: currentPage,
            totalPages:  totalPages,
            isLoading:   isLoading,
            onPageChanged: onPageChanged,
          )
        : const SizedBox.shrink();

    // ── Focus mode toggle ────────────────────────────────────────────────────
    final focusBtn = Tooltip(
      message: focusMode ? 'Exit Focus Mode' : 'Focus Mode',
      child: GestureDetector(
        onTap: onToggleFocus,
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: focusMode ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: focusMode ? AppColors.primary.withValues(alpha: 0.4) : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05))),
          ),
          child: Icon(focusMode ? LucideIcons.minimize2 : LucideIcons.maximize2, size: 14,
              color: focusMode ? AppColors.primary : Theme.of(context).hintColor.withValues(alpha: 0.6)),
        ),
      ),
    );

    // ── Compose the bar ──────────────────────────────────────────────────────
    final filterChips = [
      dropdown<String>(icon: LucideIcons.listFilter, value: selectedStatus, options: _statusOptions, label: (v) => v, onChanged: onStatusChanged, tooltip: 'Filter by Status'),
      const SizedBox(width: 8),
      dropdown<String>(icon: LucideIcons.mapPin, value: selectedGov, options: govOptions, label: (v) => v, onChanged: onGovChanged, tooltip: 'Filter by Governorate'),
      const SizedBox(width: 8),
      dropdown<String>(icon: LucideIcons.building2, value: selectedCity, options: cityOptions, label: (v) => v, onChanged: onCityChanged, tooltip: 'Filter by City'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surfaceLight),
      ),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              searchField,
              const SizedBox(height: 12),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                ...filterChips,
                focusBtn,
                if (totalPages > 1) const SizedBox(width: 16),
                if (totalPages > 1) pagination,
              ])),
            ])
          : Row(children: [
              Flexible(
                flex: 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: searchField,
                ),
              ),
              const SizedBox(width: 12),
              ...filterChips,
              focusBtn,
              const Spacer(),
              if (totalPages > 1) pagination,
            ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════ //
// ELLIPSIS PAGINATION
// ═══════════════════════════════════════════════════════════════════════════ //
class _EllipsisPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final ValueChanged<int> onPageChanged;

  const _EllipsisPagination({
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.onPageChanged,
  });

  // Build the page sequence: always show 1, last, and a window around current
  List<Object> _buildSequence() {
    // Object is either int (page number) or String ('...')
    final pages = <int>{1, totalPages};
    for (int p = currentPage - 1; p <= currentPage + 1; p++) {
      if (p >= 1 && p <= totalPages) pages.add(p);
    }
    final sorted = pages.toList()..sort();
    final result = <Object>[];
    int? prev;
    for (final p in sorted) {
      if (prev != null && p - prev > 1) result.add('...');
      result.add(p);
      prev = p;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seq = _buildSequence();

    return Row(mainAxisSize: MainAxisSize.min, children: [
      // Prev arrow
      _Arrow(icon: LucideIcons.chevronLeft, enabled: currentPage > 1 && !isLoading,
          onTap: () => onPageChanged(currentPage - 1)),
      const SizedBox(width: 2),
      // Page items
      for (final item in seq)
        if (item is int)
          _PageBtn(page: item, isActive: item == currentPage, isLoading: isLoading, onTap: () => onPageChanged(item))
        else
          _EllipsisBtn(currentPage: currentPage, totalPages: totalPages, isDark: isDark, onJump: onPageChanged),
      const SizedBox(width: 2),
      // Next arrow
      _Arrow(icon: LucideIcons.chevronRight, enabled: currentPage < totalPages && !isLoading,
          onTap: () => onPageChanged(currentPage + 1)),
    ]);
  }
}

class _Arrow extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _Arrow({required this.icon, required this.enabled, required this.onTap});
  @override State<_Arrow> createState() => _ArrowState();
}
class _ArrowState extends State<_Arrow> {
  bool _hov = false;
  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: _hov && widget.enabled ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.09) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(widget.icon, size: 14,
            color: widget.enabled ? (_hov ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.65)) : Theme.of(context).hintColor.withValues(alpha: 0.28)),
        ),
      ),
    );
  }
}

class _PageBtn extends StatefulWidget {
  final int page;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;
  const _PageBtn({required this.page, required this.isActive, required this.isLoading, required this.onTap});
  @override State<_PageBtn> createState() => _PageBtnState();
}
class _PageBtnState extends State<_PageBtn> {
  bool _hov = false;
  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      cursor: widget.isActive ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: (widget.isActive || widget.isLoading) ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: 30, height: 30, margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary
                : _hov ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.09) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: widget.isActive ? null : Border.all(color: _hov ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent),
          ),
          child: Center(child: Text('${widget.page}',
            style: TextStyle(fontSize: 12, fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
              color: widget.isActive ? AppColors.secondary : (_hov ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.72))))),
        ),
      ),
    );
  }
}

// Ellipsis button — opens a popover for quick jump
class _EllipsisBtn extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final bool isDark;
  final ValueChanged<int> onJump;
  const _EllipsisBtn({required this.currentPage, required this.totalPages, required this.isDark, required this.onJump});
  @override State<_EllipsisBtn> createState() => _EllipsisBtnState();
}

class _EllipsisBtnState extends State<_EllipsisBtn> {
  bool _hov = false;

  void _openPopover() async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final jumped = await showDialog<int>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => _JumpPopover(
        anchorOffset: offset,
        anchorSize: box.size,
        currentPage: widget.currentPage,
        totalPages: widget.totalPages,
        isDark: widget.isDark,
      ),
    );
    if (jumped != null) widget.onJump(jumped);
  }

  @override Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: _openPopover,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: 30, height: 30, margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _hov ? AppColors.primary.withValues(alpha: widget.isDark ? 0.15 : 0.09) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(child: Text('···',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: -1,
              color: _hov ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.55)))),
        ),
      ),
    );
  }
}

// ─── Quick-Jump Popover ───────────────────────────────────────────────────────
class _JumpPopover extends StatefulWidget {
  final Offset anchorOffset;
  final Size anchorSize;
  final int currentPage;
  final int totalPages;
  final bool isDark;
  const _JumpPopover({
    required this.anchorOffset,
    required this.anchorSize,
    required this.currentPage,
    required this.totalPages,
    required this.isDark,
  });
  @override State<_JumpPopover> createState() => _JumpPopoverState();
}

class _JumpPopoverState extends State<_JumpPopover> {
  final TextEditingController _ctrl = TextEditingController();
  String? _error;

  void _submit() {
    final v = int.tryParse(_ctrl.text.trim());
    if (v == null || v < 1 || v > widget.totalPages) {
      setState(() => _error = 'Enter a page between 1 and ${widget.totalPages}');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popW = 260.0;
    final popH = 320.0;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    double left = widget.anchorOffset.dx - popW / 2 + widget.anchorSize.width / 2;
    double top  = widget.anchorOffset.dy + widget.anchorSize.height + 8;
    if (left + popW > screenW - 12) left = screenW - popW - 12;
    if (left < 12) left = 12;
    if (top + popH > screenH - 16) top = widget.anchorOffset.dy - popH - 8;

    final bg = widget.isDark ? const Color(0xFF1E2130) : Colors.white;
    final border = widget.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE0E4EE);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A1D27);
    final hintColor = widget.isDark ? Colors.white38 : Colors.black38;

    // Build a grid of page numbers (max 30 shown)
    final allPages = [for (int i = 1; i <= widget.totalPages; i++) i];
    const maxGrid = 30;
    final gridPages = allPages.length <= maxGrid
        ? allPages
        : <int>{
            ...allPages.take(10),
            ...allPages.skip((allPages.length ~/ 2) - 4).take(8),
            ...allPages.skip(allPages.length - 5),
          }.toList()..sort();

    return Stack(children: [
      // Dismiss on tap outside
      Positioned.fill(child: GestureDetector(onTap: () => Navigator.pop(context), child: const ColoredBox(color: Colors.transparent))),
      Positioned(
        left: left, top: top,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: popW,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: widget.isDark ? 0.45 : 0.12), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Jump to page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.7))),
              const SizedBox(height: 10),
              // Numeric input
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _submit(),
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Go to page…',
                      hintStyle: TextStyle(color: hintColor, fontSize: 12),
                      filled: true,
                      fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      isDense: true,
                      errorText: _error,
                      errorStyle: const TextStyle(fontSize: 10, height: 1.2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.6), width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Go', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Divider(color: border, height: 1),
              const SizedBox(height: 10),
              Text('Quick select', style: TextStyle(fontSize: 11, color: hintColor)),
              const SizedBox(height: 8),
              // Page grid
              Wrap(spacing: 4, runSpacing: 4, children: [
                for (final p in gridPages)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 34, height: 28,
                      decoration: BoxDecoration(
                        color: p == widget.currentPage
                            ? AppColors.primary
                            : widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text('$p', style: TextStyle(fontSize: 11, fontWeight: p == widget.currentPage ? FontWeight.bold : FontWeight.w500,
                          color: p == widget.currentPage ? Colors.black : textColor.withValues(alpha: 0.75)))),
                    ),
                  ),
              ]),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════ //
// TABLE
// ═══════════════════════════════════════════════════════════════════════════ //
class _Table extends StatelessWidget {
  final List<Order> orders;
  final OrdersProvider prov;
  const _Table({required this.orders, required this.prov});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = R.isMobile(context);

    if (prov.isLoading && prov.orders.isEmpty) return const AdminTableSkeleton();

    if (orders.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.searchX, size: 48, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text('No orders match your filters.', style: TextStyle(color: Theme.of(context).hintColor.withValues(alpha: 0.6), fontSize: 14)),
      ]));
    }

    Widget tableContent = Column(children: [
      _buildHeader(context),
      Expanded(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: orders.length,
          separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
          itemBuilder: (ctx, i) => _Row(order: orders[i], prov: prov, isEven: i % 2 == 0),
        ),
      ),
    ]);

    if (isMobile) {
      tableContent = SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 1000, child: tableContent));
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04), blurRadius: 20, offset: const Offset(0, 8))],
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surfaceLight),
      ),
      clipBehavior: Clip.hardEdge,
      child: tableContent,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05))),
      ),
      child: const Row(children: [
        Expanded(flex: 1, child: _HC('Order ID',  center: true)),
        Expanded(flex: 3, child: _HC('Customer')),
        Expanded(flex: 3, child: _HC('Location')),      // ← replaces pin icon
        Expanded(flex: 2, child: _HC('Date',     center: true)),
        Expanded(flex: 2, child: _HC('Total',    center: true)),
        Expanded(flex: 2, child: _HC('Payment',  center: true)),
        Expanded(flex: 2, child: _HC('Status',   center: true)),
        SizedBox(width: 68, child: _HC('',       center: true)),
      ]),
    );
  }
}

class _HC extends StatelessWidget {
  final String title;
  final bool center;
  const _HC(this.title, {this.center = false});
  @override Widget build(BuildContext context) {
    final s = TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).hintColor.withValues(alpha: 0.75), fontSize: 11, letterSpacing: 0.5);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
      child: center ? Center(child: Text(title, style: s)) : Align(alignment: Alignment.centerLeft, child: Text(title, style: s)));
  }
}

// ═══════════════════════════════════════════════════════════════════════════ //
// TABLE ROW
// ═══════════════════════════════════════════════════════════════════════════ //
class _Row extends StatefulWidget {
  final Order order;
  final OrdersProvider prov;
  final bool isEven;
  
  const _Row({required this.order, required this.prov, required this.isEven});
  @override State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hov = false;
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final o = widget.order;

    final bg = _hov
        ? (isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surfaceLight.withValues(alpha: 0.6))
        : widget.isEven
        ? (isDark ? Colors.white.withValues(alpha: 0.02) : AppColors.surfaceLight.withValues(alpha: 0.4))
        : Colors.transparent;

    // ── Customer data ────────────────────────────────────────────────────────
    final name  = (o.shippingAddress?.fullName.isNotEmpty == true) ? o.shippingAddress!.fullName : '—';
    final email = null;
    final phone = o.shippingAddress?.phone;

    // ── Location snippet (Issue 2) ───────────────────────────────────────────
    final addr = o.shippingAddress;
    final locationSnippet = addr != null
        ? '${addr.city}, ${addr.governorate}'
        : 'No address provided';
    final fullAddress = addr?.displayLine;

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 70,
        decoration: BoxDecoration(color: bg),
        child: Row(children: [
Expanded(
  flex: 1,
  child: Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '#${o.shortId}',
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: o.shortId));
            setState(() => _isCopied = true);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _isCopied = false);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _isCopied
                  ? const Icon(Icons.check_rounded, key: ValueKey('check'), size: 12, color: Colors.green)
                  : Icon(
                      Icons.copy_rounded,
                      key: const ValueKey('copy'),
                      size: 12,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
            ),
          ),
        ),
      ],
    ),
  ),
),
          // 1. Order ID
          // Expanded(flex: 1, child: Center(
          //   child: Text('#${o.shortId}',
          //     style: TextStyle(color: AppColors.primary.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'monospace', letterSpacing: 0.5)),
          // )),
          // 2. Customer
          Expanded(flex: 3, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(name, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (email != null || phone != null)
                Text([if (email != null) email, if (phone != null) phone].join(' · '),
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          )),
          // 3. Location — text snippet with full-address tooltip
          Expanded(flex: 3, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Tooltip(
              message: fullAddress ?? 'No address provided',
              triggerMode: TooltipTriggerMode.manual,
              preferBelow: true,
              child: MouseRegion(
                cursor: fullAddress != null ? SystemMouseCursors.help : SystemMouseCursors.basic,
                child: Row(children: [
                  Icon(LucideIcons.mapPin, size: 12,
                      color: addr != null ? AppColors.infoBlue.withValues(alpha: 0.7) : Theme.of(context).hintColor.withValues(alpha: 0.3)),
                  const SizedBox(width: 5),
                  Expanded(child: Text(
                    locationSnippet,
                    style: TextStyle(
                      fontSize: 12,
                      color: addr != null
                          ? Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.8)
                          : Theme.of(context).hintColor.withValues(alpha: 0.4),
                      fontStyle: addr == null ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                ]),
              ),
            ),
          )),
          // 4. Date
          Expanded(flex: 2, child: Center(
            child: Text(o.createdAt != null ? DateFormat('dd MMM yy').format(o.createdAt!) : '—',
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
          )),
          // 5. Total
          Expanded(flex: 2, child: Center(
            child: Text('${NumberFormat('#,###.##').format(o.total)} EGP',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen, fontSize: 13)),
          )),
          // 6. Payment badge
          Expanded(flex: 2, child: Center(child: _paymentBadge(o.paymentMethod, isDark))),
          // 7. Status badge
          Expanded(flex: 2, child: Center(child: _statusBadge(o.status, isDark))),
          // 8. Actions
          SizedBox(width: 68, child: Center(
            child: Tooltip(message: 'View Details',
              child: InkWell(
                onTap: () => showDialog(context: context, builder: (_) => OrderDetailsDialog(order: o)),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.actionIndigo.withValues(alpha: isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.actionIndigo.withValues(alpha: isDark ? 0.15 : 0.1)),
                  ),
                  child: const Icon(LucideIcons.eye, size: 17, color: AppColors.actionIndigo),
                ),
              ),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _statusBadge(OrderStatus s, bool isDark) {
    final Color c;
    switch (s) {
      case OrderStatus.pending:    c = AppColors.warningAmber;
      case OrderStatus.confirmed:  c = AppColors.infoBlue;
      case OrderStatus.processing: c = const Color(0xFF8B5CF6);
      case OrderStatus.shipped:    c = const Color(0xFF06B6D4);
      case OrderStatus.delivered:  c = AppColors.successGreen;
      case OrderStatus.cancelled:  c = AppColors.errorRed;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: isDark ? 0.08 : 0.05), borderRadius: BorderRadius.circular(11), border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Text(s.label.toUpperCase(), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5)),
    );
  }

  Widget _paymentBadge(PaymentMethod m, bool isDark) {
    final Color c; final IconData ic; final String lbl;
    switch (m) {
      case PaymentMethod.cod:    c = AppColors.warningAmber;        ic = LucideIcons.banknote;   lbl = 'COD';
      case PaymentMethod.card:
      case PaymentMethod.online: c = const Color(0xFF8B5CF6);       ic = LucideIcons.creditCard; lbl = 'CARD';
      case PaymentMethod.wallet: c = const Color(0xFF06B6D4);       ic = LucideIcons.wallet;     lbl = 'WALLET';
      case PaymentMethod.cash:   c = AppColors.successGreen;        ic = LucideIcons.coins;      lbl = 'CASH';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: isDark ? 0.1 : 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 10, color: c),
        const SizedBox(width: 4),
        Text(lbl, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.5)),
      ]),
    );
  }
}
