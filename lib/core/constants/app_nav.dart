import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:e_commerce/core/constants/app_roles.dart';

/// Describes a single navigation destination.
///
/// [allowedRoles] is null   → visible to every authenticated user.
/// [allowedRoles] is a list → visible only when the user's role is in that list.
class NavItem {
  final int pageIndex;
  final IconData icon;
  final String label;
  final List<String>? allowedRoles;

  const NavItem({
    required this.pageIndex,
    required this.icon,
    required this.label,
    this.allowedRoles,
  });

  /// Returns true when a user with [role] should see this item.
  bool isVisibleFor(String role) {
    if (allowedRoles == null) return true;
    return AppRoles.isAllowed(role, allowedRoles!);
  }
}

/// Central registry of all navigation destinations.
///
/// Add a new destination here once; the sidebar, drawer, and bottom nav
/// all consume this list — no other changes required.
// lib/core/constants/app_nav.dart
class AppNav {
  AppNav._();

 // lib/core/constants/app_nav.dart
static const List<NavItem> items = [
  NavItem(pageIndex: 0, icon: LucideIcons.house,        label: 'Home'),
  NavItem(pageIndex: 1, icon: LucideIcons.shoppingBag,  label: 'Orders'),
  NavItem(pageIndex: 2, icon: LucideIcons.shoppingCart, label: 'Cart'),
  NavItem(pageIndex: 3, icon: LucideIcons.heart,        label: 'Favorites'),
  NavItem(pageIndex: 4, icon: LucideIcons.user,         label: 'Profile'),
  NavItem(pageIndex: 5, icon: LucideIcons.search,       label: 'Search'),
  
  // شاشات الإدارة
  NavItem(pageIndex: 6,  icon: LucideIcons.archive,        label: 'Products',    allowedRoles: AppRoles.productCreators),
  // Analytics: owner, admin, vendor — admin added for platform-wide view
  NavItem(pageIndex: 8,  icon: LucideIcons.chartBarBig,    label: 'Analytics',   allowedRoles: [AppRoles.owner, AppRoles.admin, AppRoles.vendor]),
  NavItem(pageIndex: 9,  icon: LucideIcons.shieldAlert,    label: 'Moderation',  allowedRoles: AppRoles.moderators),
  NavItem(pageIndex: 7,  icon: LucideIcons.users,          label: 'Users',       allowedRoles: AppRoles.privilegedRoles),
  NavItem(pageIndex: 10, icon: LucideIcons.zap,            label: 'Control',        allowedRoles: AppRoles.ownerOnly),
  NavItem(pageIndex: 11, icon: LucideIcons.settings,       label: 'Settings'),
];

  static List<NavItem> visibleFor(String role) =>
      items.where((item) => item.isVisibleFor(role)).toList();

  static const List<int> bottomNavPageIndices = [
    0,
    1,
    2,
    4,
  ]; // الصفحة 1 هي الـ Orders
}
