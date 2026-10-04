import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dealio/core/constants/app_roles.dart';
import 'package:dealio/data/providers/auth_provider.dart';

class NavGuard {
  NavGuard._();
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
