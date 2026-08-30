import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dealio/core/constants/app_roles.dart';
import 'package:dealio/data/providers/auth_provider.dart';

/// PermissionGuard
/// ─────────────────────────────────────────────────────────────────────────────
/// Widget-level security wrapper with two independent check modes:
///
/// **Mode 1 — Role whitelist** (`allowedRoles`):
///   Renders [child] when the actor's role is in [allowedRoles].
///
/// **Mode 2 — Resource ownership** (`resourceOwnerId`):
///   Renders [child] when the actor's user id matches [resourceOwnerId].
///   Combine with [ownerOverrideRoles] so Owner/Admin always bypass this check.
///
/// At least one of [allowedRoles] or [resourceOwnerId] must be provided.
///
/// ### Examples
///
/// ```dart
/// // "Delete Product" — visible to Owner, Admin, or the product's own Vendor
/// PermissionGuard(
///   allowedRoles: AppRoles.productManagers,    // owner + admin always pass
///   resourceOwnerId: product.vendorId,          // vendor's own product passes
///   ownerOverrideRoles: AppRoles.productManagers,
///   child: DeleteProductButton(product: product),
/// )
///
/// // "Ban User" — admin/owner only, but never shown for another owner's row
/// PermissionGuard(
///   allowedRoles: AppRoles.banManagers,
///   child: Visibility(
///     visible: targetUser.role != AppRoles.owner,
///     child: BanUserButton(userId: targetUser.id),
///   ),
/// )
///
/// // Owner-only section
/// PermissionGuard(
///   allowedRoles: AppRoles.ownerOnly,
///   child: OwnerModeCard(),
/// )
///
/// // Vendor analytics section
/// PermissionGuard(
///   allowedRoles: AppRoles.analyticsViewers,
///   child: VendorAnalyticsPanel(),
/// )
/// ```
class PermissionGuard extends StatelessWidget {
  /// If the actor's role is in this list, [child] is shown unconditionally.
  final List<String>? allowedRoles;

  /// If the actor's userId equals this, [child] is shown (ownership check).
  final String? resourceOwnerId;

  /// Roles that bypass the [resourceOwnerId] ownership check.
  /// Ignored when [resourceOwnerId] is null.
  final List<String> ownerOverrideRoles;

  /// The widget to show when the actor is authorised.
  final Widget child;

  /// The widget to show when the actor is NOT authorised.
  /// Defaults to [SizedBox.shrink] (invisible, zero-size).
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    this.allowedRoles,
    this.resourceOwnerId,
    this.ownerOverrideRoles = const [],
    required this.child,
    this.fallback,
  }) : assert(
          allowedRoles != null || resourceOwnerId != null,
          'PermissionGuard: provide at least allowedRoles or resourceOwnerId.',
        );

  @override
  Widget build(BuildContext context) {
    final auth = context.select<AuthProvider, ({String role, String userId})>(
      (a) => (role: a.userRole, userId: a.userId),
    );

    // 1. Role whitelist check — owner/admin always pass here
    if (allowedRoles != null &&
        AppRoles.isAllowed(auth.role, allowedRoles!)) {
      return child;
    }

    // 2. Override roles bypass the ownership check (e.g. Admin can edit any product)
    if (resourceOwnerId != null &&
        ownerOverrideRoles.isNotEmpty &&
        AppRoles.isAllowed(auth.role, ownerOverrideRoles)) {
      return child;
    }

    // 3. Resource ownership check (e.g. Vendor editing their own product)
    if (resourceOwnerId != null &&
        auth.userId.isNotEmpty &&
        auth.userId == resourceOwnerId) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
