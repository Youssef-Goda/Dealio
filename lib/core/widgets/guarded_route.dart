import 'package:dealio/core/constants/app_roles.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// GuardedRoute
/// ─────────────────────────────────────────────────────────────────────────────
/// A navigation-level permission wrapper.
///
/// Drop this as the [home] or as the [builder] of a named route to protect
/// entire screens from unauthorised access.
///
/// **Behaviour:**
/// - Not logged in → immediately redirects to `/login`.
/// - Logged in but wrong role → shows [unauthorizedScreen] or silently
///   redirects to [redirectTo] (defaults to `/home`).
/// - Authorised → renders [child].
///
/// ### Usage (named route):
/// ```dart
/// '/admin': (context) => GuardedRoute(
///   allowedRoles: AppRoles.privilegedRoles,
///   child: const AdminDashboardScreen(),
/// ),
/// '/owner-control': (context) => GuardedRoute(
///   allowedRoles: AppRoles.ownerOnly,
///   redirectTo: '/home',
///   child: const PlatformControlScreen(),
/// ),
/// ```
///
/// ### Usage (programmatic push):
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => GuardedRoute(
///     allowedRoles: [AppRoles.owner],
///     child: const PlatformControlScreen(),
///   ),
/// ));
/// ```
class GuardedRoute extends StatelessWidget {
  /// Roles allowed to view [child].
  final List<String> allowedRoles;

  /// The protected screen to show when authorised.
  final Widget child;

  /// The screen to show when the user lacks permission.
  /// If null and [redirectTo] is also null, shows [_UnauthorizedScreen].
  final Widget? unauthorizedScreen;

  /// Named route to push when the user lacks permission.
  /// Takes precedence over [unauthorizedScreen].
  /// Defaults to `'/home'` when both are null.
  final String? redirectTo;

  const GuardedRoute({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.unauthorizedScreen,
    this.redirectTo,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ── Not logged in → send to login ──────────────────────────────────────
    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ── Authorised ─────────────────────────────────────────────────────────
    if (AppRoles.isAllowed(auth.userRole, allowedRoles)) {
      return child;
    }

    // ── Unauthorised → redirect or show denied screen ──────────────────────
    final destination = redirectTo ?? '/home';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(destination);
    });

    // Show either a custom screen or a brief blank while the redirect fires
    return unauthorizedScreen ??
        _UnauthorizedScreen(
          message:
              'You do not have permission to access this page.\n'
              'Required role(s): ${allowedRoles.map(AppRoles.displayLabel).join(', ')}.',
        );
  }
}

/// _UnauthorizedScreen
/// ─────────────────────────────────────────────────────────────────────────────
/// Default full-screen access-denied page shown by [GuardedRoute].
class _UnauthorizedScreen extends StatelessWidget {
  final String message;
  final IconData icon;

  const _UnauthorizedScreen({
    required this.message,
    this.icon = Icons.gpp_bad_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: theme.colorScheme.error),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
