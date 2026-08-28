import 'package:e_commerce/core/constants/app_nav.dart';
import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/data/providers/cart_provider.dart';
import 'package:e_commerce/data/providers/product_provider.dart';
import 'package:e_commerce/data/providers/theme_provider.dart';
import 'package:e_commerce/data/providers/wishlist_provider.dart';
import 'package:e_commerce/features/cart/screens/cart_screen.dart';
import 'package:e_commerce/features/favorites/screens/favorites_screen.dart';
import 'package:e_commerce/features/orders/screens/my_orders_screen.dart';
import 'package:e_commerce/features/owner/screens/platform_control_screen.dart';
import 'package:e_commerce/features/settings/screens/settings_screen.dart';
import 'package:e_commerce/features/admin/screens/vendor_dashboard_screen.dart';
import 'package:e_commerce/features/admin/screens/moderation_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:e_commerce/features/admin/widgets/products_content.dart';
import 'package:e_commerce/features/admin/widgets/user_content.dart';
import 'package:e_commerce/features/home/widgets/home_content.dart';
import 'package:e_commerce/features/home/widgets/search_screen.dart';
import 'package:e_commerce/features/profile/screens/profile_screen.dart';

class HomeBottom extends StatefulWidget {
  const HomeBottom({super.key});

  @override
  State<HomeBottom> createState() => _HomeBottomState();
}

class _HomeBottomState extends State<HomeBottom> {
  late SidebarXController _controller;
  late final List<Widget> _pages;
  int? _hoveredIndex;
  bool _hoveredTheme = false;
  bool _hoveredLogout = false;

  @override
  void initState() {
    super.initState();
    _controller = SidebarXController(selectedIndex: 0, extended: true);

    // ── Centralized fetch: load products once on app entry so the Home
    //    screen shows data immediately without needing to visit Products page.
    Future.microtask(() => context.read<ProductProvider>().fetchProducts());

    // داخل initState في ملف home_bottom.dart
    _pages = [
      const RepaintBoundary(child: HomeContent()), // 0
      const RepaintBoundary(
        child: MyOrdersScreen(),
      ), // 1 (عدلت مكانها عشان تبقى للكل)
      const RepaintBoundary(child: CartScreen()), // 2
      const RepaintBoundary(child: FavoritesScreen()), // 3
      const RepaintBoundary(child: ProfileScreen()), // 4
      const RepaintBoundary(child: SearchScreen()), // 5
      const RepaintBoundary(child: ProductsContent()), // 6 (Admin/Vendor)
      const RepaintBoundary(child: UsersContent()), // 7 (Admin/Owner)
      const RepaintBoundary(child: VendorDashboardScreen()), // 8 (Owner/Vendor)
      const RepaintBoundary(
        child: ModerationDashboardScreen(),
      ), // 9 (Moderator)
      const RepaintBoundary(child: PlatformControlScreen()), // 10 (Owner Only)
      const RepaintBoundary(child: SettingsScreen()), // 11
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _mapBottomNavToPageIndex(int bottomNavIndex) {
    switch (bottomNavIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 3; // Favorites (index 3 in _pages)
      case 2:
        return 2; // Cart (index 2 in _pages)
      case 3:
        return 4; // Profile (index 4 in _pages)
      default:
        return 0;
    }
  }

  int _mapPageToBottomNavIndex(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return 0; // Home
      case 3:
        return 1; // Favorites (was case 7, now Favorites is index 3)
      case 2:
        return 2; // Cart
      case 4:
        return 3; // Profile (was case 5, Profile is at index 4)
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool useSidebar = R.isDesktop(context) || R.isTablet(context);
    final bool isMobile = R.isMobile(context);

    final Widget pageBody = Row(
      children: [
        if (useSidebar) _buildSidebar(context),
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _pages[_controller.selectedIndex],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: !useSidebar ? _buildMobileAppBar(context) : null,
      drawer: !useSidebar ? _buildMobileDrawer() : null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isMobile
          ? SafeArea(top: true, bottom: false, child: pageBody)
          : pageBody,
      bottomNavigationBar: useSidebar ? null : _buildBottomNavBar(context),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    // ⚠️ Must have exactly 11 entries — one per _pages index (0-10)
    const pageTitles = [
      'Home', // 0
      'My Orders', // 1
      'Cart', // 2
      'Favorites', // 3
      'Profile', // 4
      'Search', // 5
      'Products', // 6
      'Users', // 7
      'Analytics', // 8
      'Moderation', // 9
      'Control', // 10
      'Settings', // 11
    ];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final bool isHome = _controller.selectedIndex == 0;

          // ── Home page: transparent, no title ────────────────────────────
          if (isHome) {
            return AppBar(
              toolbarHeight: R.h(context, 56),
              // Blend with the scaffold background — the HomeHeader provides
              // all visual identity on this page.
              backgroundColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.secondary,
              // No title on Home — HomeHeader owns the greeting + location
              title: null,
              centerTitle: false,
              leading: Builder(
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: GestureDetector(
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.black.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.menu,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // Cart badge
                Consumer<CartProvider>(
                  builder: (context, cart, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          LucideIcons.shoppingCart,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.secondary,
                        ),
                        onPressed: () => _controller.selectIndex(2),
                        tooltip: 'Cart',
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          top: 8,
                          right: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBackground
                                      : AppColors.background,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                cart.itemCount > 99
                                    ? '99+'
                                    : '${cart.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Search icon
                IconButton(
                  icon: Icon(
                    LucideIcons.search,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.secondary,
                  ),
                  onPressed: () => _controller.selectIndex(5),
                  tooltip: 'Search',
                ),
                const SizedBox(width: 4),
              ],
            );
          }

          // ── All other pages: standard dark AppBar with page title ────────
          return AppBar(
            toolbarHeight: R.h(context, 70),
            title: Padding(
              padding: R.only(context, top: 10),
              child: Text(
                (pageTitles.length > _controller.selectedIndex)
                    ? pageTitles[_controller.selectedIndex]
                    : 'Dealio',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            backgroundColor: isDark
                ? AppColors.darkAppBar
                : AppColors.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: Builder(
              builder: (ctx) => Padding(
                padding: R.only(context, top: 10),
                child: IconButton(
                  icon: const Icon(LucideIcons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  tooltip: 'Menu',
                ),
              ),
            ),
            actions: [
              // ─── Cart badge icon ─────────────────────────────────────────
              Consumer<CartProvider>(
                builder: (context, cart, _) => Padding(
                  padding: R.only(context, top: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.shoppingCart),
                        onPressed: () => _controller.selectIndex(2),
                        tooltip: 'Cart',
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          top: 8,
                          right: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                cart.itemCount > 99
                                    ? '99+'
                                    : '${cart.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: R.only(context, top: 10),
                child: IconButton(
                  icon: const Icon(LucideIcons.search),
                  onPressed: () => _controller.selectIndex(5),
                  tooltip: 'Search',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileDrawer() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.secondary,
      child: Column(
        children: [
          // ─── Header Branding ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 30,
              left: 24,
              right: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.shoppingBag,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dealio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        // Role-aware subtitle: admins see 'Admin Panel'
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => Text(
                            auth.isAdmin ? 'Admin Panel' : 'Customer',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Navigation Items (role-driven via AppNav) ─────────────────
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (_, auth, __) {
                final visibleItems = AppNav.visibleFor(auth.userRole);
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Separate privileged items from personal items with a divider
                    ...visibleItems.map((item) {
                      final isPersonal = [4, 5, 7].contains(item.pageIndex);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Divider before the personal section
                          if (isPersonal &&
                              item ==
                                  visibleItems.firstWhere(
                                    (i) => [4, 5, 7].contains(i.pageIndex),
                                    orElse: () => item,
                                  ))
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 15,
                              ),
                              child: Divider(color: Colors.white10, height: 1),
                            ),
                          _buildDrawerItem(
                            item.pageIndex,
                            item.icon,
                            item.label,
                          ),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          // ─── Bottom Actions ─────────────────────────────────────────────
          const Divider(color: Colors.white10, height: 1),

          // Dark Mode Toggle
          SwitchListTile(
            title: const Text(
              'Dark Mode',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            secondary: Icon(
              themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
              color: themeProvider.isDarkMode
                  ? AppColors.primary
                  : Colors.white38,
              size: 20,
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
            activeColor: AppColors.primary,
            dense: true,
          ),

          // Logout
          ListTile(
            leading: const Icon(
              LucideIcons.logOut,
              color: Colors.redAccent,
              size: 20,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
            dense: true,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'v1.1.0-beta',
              style: TextStyle(
                color: Colors.white10,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isSelected = _controller.selectedIndex == index;
        return Stack(
          children: [
            if (isSelected)
              Positioned(
                left: 0,
                top: 8,
                bottom: 8,
                width: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: ListTile(
                leading: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : Colors.white38,
                  size: 22,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                selected: isSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  _controller.selectIndex(index);
                  Navigator.pop(context);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                minLeadingWidth: 20,
                visualDensity: VisualDensity.compact,
                tileColor: isSelected
                    ? AppColors.primary.withOpacity(0.05)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isExtended = _controller.extended;
        final double sidebarWidth = isExtended ? 250 : 80;
        final double iconSize = R.isDesktop(context) ? 20 : 18;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: sidebarWidth,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.white.withOpacity(0.047)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 80,
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      isExtended ? Icons.menu_open : Icons.menu,
                      color: Colors.grey,
                      size: iconSize + 4,
                    ),
                    onPressed: () => _controller.toggleExtended(),
                  ),
                ),
              ),
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (_, auth, __) {
                    final visibleItems = AppNav.visibleFor(auth.userRole);
                    return ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: visibleItems
                          .map(
                            (item) => _buildSidebarItem(
                              context,
                              item.pageIndex,
                              item.icon,
                              item.label,
                              iconSize,
                              isDarkMode,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
              _buildSidebarLogout(context, isExtended, iconSize),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    double iconSize,
    bool isDarkMode,
  ) {
    final bool isSelected = _controller.selectedIndex == index;
    final bool isExtended = _controller.extended;
    final bool isHovered = _hoveredIndex == index;

    final Color bgColor = isDarkMode
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.08);

    final Color contentColor = isSelected
        ? AppColors.primary
        : isHovered
        ? AppColors.primary.withOpacity(0.7)
        : (Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.45) ??
              Colors.grey);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: GestureDetector(
          onTap: () => _controller.selectIndex(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            // ✅ يتحرك يمين زي زرار الدارك مود
            transform: Matrix4.translationValues(isHovered ? 5 : 0, 0, 0),
            height: 50,
            decoration: BoxDecoration(
              color: isSelected
                  ? bgColor
                  : isHovered
                  ? AppColors.primary.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),

                // ✅ الأيقونة تكبر بسلاسة
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    color: contentColor,
                    size: isHovered ? iconSize + 2 : iconSize,
                  ),
                ),

                if (isExtended) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    // ✅ النص يكبر بسلاسة مع AnimatedDefaultTextStyle
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        color: contentColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: isHovered
                            ? R.font(context, 14.8)
                            : R.font(context, 14),
                      ),
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],

                // ✅ الشريط اليميني يكبر مع الـ hover ويتضيء أكتر
                if (isSelected) ...[
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 4,
                    height: isHovered ? 34 : 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(
                            isHovered ? 0.9 : 0.6,
                          ),
                          blurRadius: isHovered ? 12.0 : 8.0,
                          spreadRadius: isHovered ? 2.0 : 1.0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  const SizedBox(width: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarLogout(
    BuildContext context,
    bool extended,
    double iconSize,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── Dark Mode Toggle ──────────────────────────────────────────────
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: R.all(context, 10).left,
            vertical: R.all(context, 5).top,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hoveredTheme = true),
            onExit: (_) => setState(() => _hoveredTheme = false),
            child: GestureDetector(
              onTap: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                // ✅ نفس الانيميشن: يتحرك يمين
                transform: Matrix4.translationValues(
                  _hoveredTheme ? 5 : 0,
                  0,
                  0,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: R.h(context, 15),
                  horizontal: extended ? R.w(context, 20) : R.w(context, 10),
                ),
                decoration: BoxDecoration(
                  color: _hoveredTheme
                      ? AppColors.primary.withOpacity(0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: extended
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    // ✅ لما hover: الأيقونة بتعرض الـ preview للتغيير (شمس ↔ قمر)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Icon(
                        _hoveredTheme
                            ? (themeProvider.isDarkMode
                                  ? LucideIcons.sun
                                  : LucideIcons.moon)
                            : (themeProvider.isDarkMode
                                  ? LucideIcons.moon
                                  : LucideIcons.sun),
                        key: ValueKey(
                          'theme_${themeProvider.isDarkMode}_$_hoveredTheme',
                        ),
                        color: _hoveredTheme
                            ? AppColors.primary
                            : (themeProvider.isDarkMode
                                  ? Colors.white
                                  : Theme.of(context).primaryColor),
                        size: _hoveredTheme ? iconSize + 2 : iconSize,
                      ),
                    ),
                    if (extended) ...[
                      SizedBox(width: R.w(context, 15)),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            color: _hoveredTheme
                                ? AppColors.primary
                                : (themeProvider.isDarkMode
                                      ? Colors.white
                                      : Theme.of(context).primaryColor),
                            fontSize: _hoveredTheme
                                ? R.font(context, 14.8)
                                : R.font(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                          child: const Text('Dark Mode'),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        child: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (val) => themeProvider.toggleTheme(val),
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // ─── Logout ────────────────────────────────────────────────────────
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: R.all(context, 10).left,
            vertical: R.all(context, 5).top,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hoveredLogout = true),
            onExit: (_) => setState(() => _hoveredLogout = false),
            child: GestureDetector(
              onTap: () => _showLogoutDialog(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                // ✅ نفس الانيميشن + خلفية حمرا مع border خفيف
                transform: Matrix4.translationValues(
                  _hoveredLogout ? 5 : 0,
                  0,
                  0,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: R.h(context, 15),
                  horizontal: extended ? R.w(context, 20) : R.w(context, 10),
                ),
                decoration: BoxDecoration(
                  color: _hoveredLogout
                      ? Colors.red.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _hoveredLogout
                      ? Border.all(
                          color: Colors.red.withOpacity(0.25),
                          width: 1,
                        )
                      : Border.all(color: Colors.transparent, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: extended
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        LucideIcons.logOut,
                        color: Colors.red,
                        size: _hoveredLogout ? iconSize + 2 : iconSize,
                      ),
                    ),
                    if (extended) ...[
                      SizedBox(width: R.w(context, 15)),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: _hoveredLogout
                              ? R.font(context, 14.8)
                              : R.font(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '';
            final buildNumber = snapshot.data?.buildNumber ?? '';

            return Text(
              'Version $version ($buildNumber) Beta',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[400],
                letterSpacing: 0.5,
              ),
            );
          },
        ),
        SizedBox(height: R.h(context, 10)),
        // ─── Beta Tag ──────────────────────────────────────────────────────
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout(context);
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final labelFontSize = R.font(context, 11);

    return Consumer2<CartProvider, WishlistProvider>(
      builder: (context, cart, wishlist, _) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Theme(
            data: Theme.of(
              context,
            ).copyWith(canvasColor: Theme.of(context).cardColor),
            child: Container(
              color: Theme.of(context).cardColor,
              child: BottomNavigationBar(
                currentIndex: _mapPageToBottomNavIndex(
                  _controller.selectedIndex,
                ),
                onTap: (index) =>
                    _controller.selectIndex(_mapBottomNavToPageIndex(index)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.darkTextMuted,
                selectedIconTheme: const IconThemeData(
                  color: AppColors.primary,
                  size: 24,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: AppColors.darkTextMuted,
                  size: 22,
                ),
                selectedLabelStyle: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.normal,
                ),
                type: BottomNavigationBarType.fixed,
                items: [
                  // 0 – Home
                  const BottomNavigationBarItem(
                    icon: Icon(LucideIcons.house),
                    label: 'Home',
                  ),
                  // 1 – Favorites
                  BottomNavigationBarItem(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.favorite_border_rounded),
                        if (wishlist.count > 0)
                          Positioned(
                            top: -6,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${wishlist.count}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    activeIcon: const Icon(Icons.favorite_rounded),
                    label: 'Favorites',
                  ),
                  // 2 – Cart
                  BottomNavigationBarItem(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(LucideIcons.shoppingCart),
                        if (cart.itemCount > 0)
                          Positioned(
                            top: -6,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                cart.itemCount > 99
                                    ? '99+'
                                    : '${cart.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Cart',
                  ),
                  // 3 – Profile
                  const BottomNavigationBarItem(
                    icon: Icon(LucideIcons.user),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
