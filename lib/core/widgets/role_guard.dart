import 'package:dealio/core/constants/app_roles.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// RoleGuard
/// ─────────────────────────────────────────────────────────────────────────────
/// A reusable permission-based widget wrapper.
///
/// Wraps [child] and renders it only when the currently authenticated user's
/// role is present in [allowedRoles]. Otherwise renders [fallback] (defaults
/// to [SizedBox.shrink] — invisible, zero-size).
///
/// Usage:
/// ```dart
/// RoleGuard(
///   allowedRoles: AppRoles.privilegedRoles,
///   child: AdminActionButton(),
/// )
///
/// // With a custom "Access Denied" fallback:
/// RoleGuard(
///   allowedRoles: [AppRoles.superAdmin],
///   child: DeleteUserButton(),
///   fallback: AccessDeniedBanner(),
/// )
/// ```
class RoleGuard extends StatelessWidget {
  /// Roles that are permitted to see [child].
  final List<String> allowedRoles;

  /// Widget to display when the user is authorised.
  final Widget child;

  /// Widget to display when the user is NOT authorised.
  /// Defaults to an invisible [SizedBox.shrink].
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });
 
  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, String>(
      (auth) => auth.userRole,
    );

    if (AppRoles.isAllowed(role, allowedRoles)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// AccessDeniedWidget
/// ─────────────────────────────────────────────────────────────────────────────
/// A styled "Access Denied" banner — pass as [fallback] to [RoleGuard]
/// whenever you want to show visible feedback instead of hiding the widget.
class AccessDeniedWidget extends StatelessWidget {
  final String? message;

  const AccessDeniedWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? 'Access Denied. You do not have permission to view this content.',
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
