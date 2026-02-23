import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:e_commerce/features/admin/widgets/products_content.dart';
import 'package:e_commerce/features/admin/widgets/user_content.dart';
import 'package:e_commerce/features/home/widgets/home_content.dart';
import 'package:e_commerce/features/home/widgets/search_screen.dart';

class HomeBottom extends StatefulWidget {
  const HomeBottom({super.key});

  @override
  State<HomeBottom> createState() => _HomeBottomState();
}

class _HomeBottomState extends State<HomeBottom> {
  late SidebarXController _controller;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _controller = SidebarXController(selectedIndex: 0, extended: true);

    // Define pages once with RepaintBoundary for performance
    _pages = [
      const RepaintBoundary(child: HomeContent()), // 0: Home
      const RepaintBoundary(child: ProductsContent()), // 1: Products
      const RepaintBoundary(child: UsersContent()), // 2: Users
      const RepaintBoundary(
        child: Center(child: Text("Orders Coming Soon...")),
      ), // 3: Orders
      const RepaintBoundary(child: Center(child: Text("Cart"))), // 4: Cart
      const RepaintBoundary(
        child: Center(child: Text("Profile")),
      ), // 5: Profile
      const RepaintBoundary(child: SearchScreen()), // 6: Search
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Convert BottomNavigationBar index to corresponding page index
  int _mapBottomNavToPageIndex(int bottomNavIndex) {
    switch (bottomNavIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 4; // Cart
      case 2:
        return 5; // Profile
      default:
        return 0;
    }
  }

  /// تحويل index الصفحة لـ index الـ BottomNavigationBar
  int _mapPageToBottomNavIndex(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return 0; // Home
      case 4:
        return 1; // Cart
      case 5:
        return 2; // Profile
      default:
        return 0; // Any other page (Products, Users, Orders) returns Home
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using Responsive Helper to determine screen type
    final bool useSidebar = R.isDesktop(context) || R.isTablet(context);

    return Scaffold(
      // Mobile AppBar only
      appBar: !useSidebar ? _buildMobileAppBar(context) : null,

      // Mobile Drawer only - all pages
      drawer: !useSidebar ? _buildMobileDrawer() : null,

      body: Row(
        children: [
          if (useSidebar) _buildSidebar(context),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _pages[_controller.selectedIndex],
            ),
          ),
        ],
      ),

      // Mobile BottomNavigationBar - 3 main options only
      bottomNavigationBar: useSidebar ? null : _buildBottomNavBar(),
    );
  }

  /// Mobile AppBar
  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    // Pages titles
    final List<String> pageTitles = [
      'Home',
      'Products',
      'Users',
      'Orders',
      'Cart',
      'Profile',
      'Search',
    ];

    return AppBar(
      title: Text(
        pageTitles[_controller.selectedIndex],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(LucideIcons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.search),
          onPressed: () {
            _controller.selectIndex(6); // فتح صفحة البحث
            setState(() {});
          },
          tooltip: 'Search',
        ),
      ],
    );
  }

  /// Drawer's pages list
  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Drawer's Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(LucideIcons.shoppingBag, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'E-Commerce',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Admin Panel',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Pages list
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(0, LucideIcons.home, 'Home'),
                const Divider(height: 1),
                _buildDrawerItem(1, LucideIcons.archive, 'Products'),
                _buildDrawerItem(2, LucideIcons.users, 'Users'),
                _buildDrawerItem(3, LucideIcons.shoppingBag, 'Orders'),
                const Divider(height: 1),
                _buildDrawerItem(4, LucideIcons.shoppingCart, 'Cart'),
                _buildDrawerItem(5, LucideIcons.user, 'Profile'),
              ],
            ),
          ),

          // Footer's Drawer
          const Divider(height: 1),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                'beta: (1.1.0)',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// بناء عنصر واحد في الـ Drawer
  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _controller.selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey[600],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      onTap: () {
        _controller.selectIndex(index);
        Navigator.pop(context); // قفل الـ Drawer
        setState(() {});
      },
    );
  }

  /// بناء الـ Sidebar للويب والتابلت
  Widget _buildSidebar(BuildContext context) {
    // استخدام R للأحجام الديناميكية
    final double sidebarWidth = R.isDesktop(context) ? 80 : 70;
    final double sidebarExtendedWidth = R.isDesktop(context) ? 250 : 220;
    final double iconSize = R.isDesktop(context) ? 20 : 18;

    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        width: sidebarWidth,
        margin: R.all(context, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.r(context, 20)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        iconTheme: IconThemeData(color: AppColors.secondary, size: iconSize),
        selectedIconTheme: IconThemeData(
          color: AppColors.primary,
          size: iconSize,
        ),
        textStyle: TextStyle(
          color: AppColors.secondary,
          fontSize: R.font(context, 14),
        ),
        selectedTextStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: R.font(context, 14),
        ),
        hoverColor: AppColors.primary.withOpacity(0.02),
        hoverTextStyle: TextStyle(
          color: AppColors.primary.withOpacity(0.6),
          fontWeight: FontWeight.w500,
          fontSize: R.font(context, 16),
        ),
        hoverIconTheme: IconThemeData(
          color: AppColors.primary.withOpacity(0.6),
          size: iconSize + 2,
        ),
      ),
      extendedTheme: SidebarXTheme(
        width: sidebarExtendedWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(R.r(context, 20)),
            bottomRight: Radius.circular(R.r(context, 20)),
          ),
        ),
      ),
      headerBuilder: (context, extended) {
        return SizedBox(
          height: R.h(context, 80),
          child: IconButton(
            icon: Icon(
              extended ? Icons.menu_open : Icons.menu,
              color: AppColors.secondary,
              size: iconSize + 4,
            ),
            onPressed: () => _controller.setExtended(!_controller.extended),
          ),
        );
      },
      items: const [
        SidebarXItem(icon: LucideIcons.home, label: ' Home'),
        SidebarXItem(icon: LucideIcons.archive, label: ' Products'),
        SidebarXItem(icon: LucideIcons.users, label: ' Users'),
        SidebarXItem(icon: LucideIcons.shoppingBag, label: ' Orders'),
        SidebarXItem(icon: LucideIcons.shoppingCart, label: ' Cart'),
        SidebarXItem(icon: LucideIcons.user, label: ' Profile'),
      ],
      footerBuilder: (context, extended) {
        return _buildSidebarLogout(context, extended, iconSize);
      },
    );
  }

  /// logout button
  // Widget _buildSidebarLogout(
  //   BuildContext context,
  //   bool extended,
  //   double iconSize,
  // ) {
  //   return Container(
  //     margin: R.all(context, 10),
  //     decoration: BoxDecoration(
  //       border: Border(
  //         top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
  //       ),
  //     ),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         onTap: () {
  //           _showLogoutDialog(context);
  //         },
  //         borderRadius: BorderRadius.circular(10),
  //         child: Container(
  //           padding: EdgeInsets.symmetric(
  //             vertical: R.h(context, 15),
  //             horizontal: extended ? R.w(context, 20) : R.w(context, 10),
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(LucideIcons.logOut, color: Colors.red, size: iconSize),
  //               if (extended) ...[
  //                 SizedBox(width: R.w(context, 15)),
  //                 Text(
  //                   'Logout',
  //                   style: TextStyle(
  //                     color: Colors.red,
  //                     fontSize: R.font(context, 14),
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ],
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
/// logout button with Beta version tag
  Widget _buildSidebarLogout(
    BuildContext context,
    bool extended,
    double iconSize,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min, // عشان مياخدش مساحة الشاشة كلها
      children: [
        Container(
          margin: R.all(context, 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showLogoutDialog(context);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: R.h(context, 15),
                  horizontal: extended ? R.w(context, 20) : R.w(context, 10),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, color: Colors.red, size: iconSize),
                    if (extended) ...[
                      SizedBox(width: R.w(context, 15)),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: R.font(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // --- Beta Version Tag ---
        Padding(
          padding: EdgeInsets.only(bottom: R.h(context, 15)),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: extended
                ? Text(
                    'beta: (1.1.0)',
                    key: const ValueKey('extended_version'),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: R.font(context, 11),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  )
                : Text(
                    'B',
                    key: const ValueKey('collapsed_version'),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: R.font(context, 10),
                      fontWeight: FontWeight.bold,  
                    ),
                  ),
          ),
        ),
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
              // 1. Close the dialog
              Navigator.pop(dialogContext);

              // 2. Execute logout
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();

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

  /// Mobile BottomNavigationBar - 3 main options only
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _mapPageToBottomNavIndex(_controller.selectedIndex),
      onTap: (index) {
        _controller.selectIndex(_mapBottomNavToPageIndex(index));
        setState(() {});
      },

      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.shoppingCart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
      ],
    );
  }
}
