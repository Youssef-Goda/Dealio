import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_commerce/core/constants/app_roles.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';

/// NavGuard
/// ─────────────────────────────────────────────────────────────────────────────
/// Utility for programmatic navigation with role enforcement.
///
/// Use this for pushes triggered by code — deep links, notification taps,
/// button callbacks — where you cannot wrap the destination in a [GuardedRoute].
///
/// ### Usage
/// ```dart
/// // Simple push
/// NavGuard.push(context, route: '/owner-control', allowedRoles: AppRoles.ownerOnly);
///
/// // With arguments
/// NavGuard.push(
///   context,
///   route: '/vendor',
///   allowedRoles: AppRoles.productCreators,
///   arguments: {'vendorId': vendor.id},
/// );
/// ```
class NavGuard {
  NavGuard._();

  /// Navigates to [route] if the current user's role is in [allowedRoles].
  ///
  /// Shows a [SnackBar] and does nothing if the user lacks permission.
  static void push(
    BuildContext context, {
    required String route,
    required List<String> allowedRoles,
    Object? arguments,
    String? deniedMessage,
  }) {
    final role = context.read<AuthProvider>().userRole;
    if (AppRoles.isAllowed(role, allowedRoles)) {
      Navigator.of(context).pushNamed(route, arguments: arguments);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deniedMessage ??
                'Access denied. Required: ${allowedRoles.map(AppRoles.displayLabel).join(', ')}.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Replaces the current route with [route] if the user is authorised.
  static void replace(
    BuildContext context, {
    required String route,
    required List<String> allowedRoles,
    Object? arguments,
  }) {
    final role = context.read<AuthProvider>().userRole;
    if (AppRoles.isAllowed(role, allowedRoles)) {
      Navigator.of(context).pushReplacementNamed(route, arguments: arguments);
    }
  }
}
