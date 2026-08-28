// app_roles.dart
// ─────────────────────────────────────────────────────────────────────────────
// Single source of truth for all valid user roles in the Dealio platform.
//
// Five roles (ascending privilege):
//   customer < vendor < moderator < admin < owner
//
// To add a new role:
//   1. Add a constant below.
//   2. Update the backend ENUM in models/User.js AND Supabase CHECK constraint.
//   3. Add to the relevant permission group(s) — no other Flutter changes needed.
//   RoleGuard, PermissionGuard, and GuardedRoute pick up changes automatically.

class AppRoles {
  AppRoles._(); // Prevent instantiation.

  // ── Role Tokens (must match backend DB ENUM exactly) ─────────────────────
  /// Platform owner mode. Absolute control. Cannot be banned or modified by others.
  static const String owner = 'owner';

  /// Full operational control — manages users (non-owner), categories, discounts.
  static const String admin = 'admin';

  /// Content police — reviews listings, dele5tes reviews, handle5s support tickets.
  static const String moderator = 'moderator';

  /// Business scope — CRUD on own products, own orders, own analytics.
  static const String vendor = 'vendor';

  /// Personal scope — public catalogue, own cart/orders, own profile.
  static const String customer = 'customer';

  /// Legacy alias kept for backwards compatibility with existing `SharedPreferences` data.
  static const String user = 'user';

  // ── Permission Groups ─────────────────────────────────────────────────────

  /// Owner-mode — Owner only.
  static const List<String> ownerOnly = [owner];

  /// Admin Dashboard access (Admin + Owner).
  static const List<String> privilegedRoles = [owner, admin];

  /// Can ban/unban users (not the Owner).
  static const List<String> banManagers = [owner, admin];

  /// Can manage any product (owner/admin bypass ownership check in the handler).
  static const List<String> productManagers = [owner, admin];

  /// Can create/edit products (includes Vendors for their own products).
  static const List<String> productCreators = [owner, admin, vendor];

  /// Content moderation: delete reviews, handle support tickets.
  static const List<String> moderators = [owner, admin, moderator];

  /// Platform-wide order management.
  static const List<String> orderManagers = [owner, admin];

  /// Only Owner can promote/demote roles.
  static const List<String> userManagers = [owner];

  /// Analytics access (Owner sees all; Vendor sees own).
  static const List<String> analyticsViewers = [owner, vendor];

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns true if [role] is in [allowedRoles].
  /// Case-insensitive and trims whitespace.
  static bool isAllowed(String role, List<String> allowedRoles) {
    return allowedRoles.contains(role.toLowerCase().trim());
  }

  /// Returns true if [role] grants admin-level access (admin or owner).
  static bool isPrivileged(String role) => isAllowed(role, privilegedRoles);

  /// Returns true if [role] is the Owner.
  static bool isOwner(String role) => role.toLowerCase().trim() == owner;

  /// Returns true if [role] is a Vendor.
  static bool isVendor(String role) => role.toLowerCase().trim() == vendor;

  /// Returns true if [role] is Moderator or above.
  static bool isModerator(String role) => isAllowed(role, moderators);

  /// Normalises legacy 'user' → 'customer' for display purposes.
  static String normalise(String role) {
    final r = role.toLowerCase().trim();
    return r == user ? customer : r;
  }

  /// Human-readable display label for a role token.
  static String displayLabel(String role) {
    switch (role.toLowerCase().trim()) {
      case owner:     return '👑 Owner';
      case admin:     return '🛡️ Admin';
      case moderator: return '🔍 Moderator';
      case vendor:    return '🏪 Vendor';
      case customer:
      case user:      return '🛒 Customer';
      default:        return role;
    }
  }
}
