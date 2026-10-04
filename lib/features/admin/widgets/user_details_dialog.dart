import 'dart:ui';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/user_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// Owner email — identifies the protected founding account client-side
const String _kOwnerEmail = 'youssefgoda.dev@gmail.com';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────
void showUserDetailsDialog(
  BuildContext context,
  UserModel user,
  UserProvider userProv,
) {
  showGeneralDialog( 
    context: context,
    barrierDismissible: true,
    barrierLabel: 'User Details',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) => UserDetailsDialog(user: user),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15 * anim1.value,
          sigmaY: 15 * anim1.value,
        ),
        child: FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.93, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog
// ─────────────────────────────────────────────────────────────────────────────
class UserDetailsDialog extends StatefulWidget {
  final UserModel user;
  const UserDetailsDialog({super.key, required this.user});

  @override
  State<UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<UserDetailsDialog> {
  // Pending (staged) values — only committed on Confirm
  late String _pendingRole;
  late bool _pendingIsActive;
  bool _isSaving = false;

  // ── All 5 selectable roles ──────────────────────────────────────────────
  static const List<String> _roles = [
    'user',
    'vendor',
    'moderator',
    'admin',
    'owner',
  ];
  static const List<String> _roleLabels = [
    'User',
    'Vendor',
    'Moderator',
    'Admin',
    'Owner',
  ];
  static const List<Color> _roleColors = [
    AppColors.infoBlue,
    AppColors.successGreen,
    AppColors.warningAmber,
    AppColors.adminPurple,
    AppColors.errorRed,
  ];
  static const List<IconData> _roleIcons = [
    LucideIcons.user,
    LucideIcons.store,
    LucideIcons.shield,
    LucideIcons.shieldCheck,
    LucideIcons.crown,
  ];

  // Owner: identified by email OR DB role
  bool get _isOwnerAccount =>
      widget.user.email.toLowerCase() == _kOwnerEmail ||
      widget.user.role.toLowerCase() == 'owner';

  // Caller role from AuthProvider
  String get _callerRole => context.read<AuthProvider>().userRole.toLowerCase();
  bool get _callerIsAdmin => _callerRole == 'admin';
  bool get _callerIsOwner => _callerRole == 'owner';

  // Target user's role
  String get _targetRole => widget.user.role.toLowerCase();
  bool get _targetIsAdmin => _targetRole == 'admin' || _targetRole == 'owner';

  // Logic guards:
  // 1. Admin cannot modify an owner account
  // 2. Admin cannot modify another admin account (peer protection)
  bool get _isReadOnly =>
      _isOwnerAccount && _callerIsAdmin ||
      (_callerIsAdmin && _targetIsAdmin && !_isOwnerAccount);

  @override
  void initState() {
    super.initState();
    final role = widget.user.role.toLowerCase();
    // normalise legacy 'customer' → 'user'
    final normalisedRole =
        (role == 'customer' || role == 'user') ? 'user' : role;
    _pendingRole = _roles.contains(normalisedRole) ? normalisedRole : 'user';
    _pendingIsActive = widget.user.isActive;
  }

  bool get _hasChanges =>
      !_isOwnerAccount &&
      (_pendingRole != widget.user.role.toLowerCase() ||
          _pendingIsActive != widget.user.isActive);

  Color _colorForRole(String role) {
    final idx = _roles.indexOf(role.toLowerCase());
    if (idx == -1) return AppColors.infoBlue;
    return _roleColors[idx];
  }

  String _prefixedCode(String code, String role) {
    if (widget.user.email.toLowerCase() == _kOwnerEmail) return 'O-1';
    String prefix;
    switch (role.toLowerCase()) {
      case 'owner':     prefix = 'O'; break;
      case 'admin':     prefix = 'A'; break;
      case 'moderator': prefix = 'M'; break;
      case 'vendor':    prefix = 'V'; break;
      default:          prefix = 'U'; // user / customer / any unknown
    }
    final base = code.replaceAll(RegExp(r'^[A-Za-z]+-'), '');
    return '$prefix-$base';
  }

  Future<void> _confirmChanges() async {
    if (!_hasChanges || _isSaving) return;
    setState(() => _isSaving = true);
    final userProv = context.read<UserProvider>();
    if (_pendingRole != widget.user.role.toLowerCase()) {
      await userProv.updateUserRole(widget.user.id, _pendingRole);
    }
    if (_pendingIsActive != widget.user.isActive) {
      await userProv.toggleUserStatus(widget.user.id, widget.user.isActive);
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accentColor = _isOwnerAccount
        ? AppColors.errorRed
        : _colorForRole(_pendingRole);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.55 : 0.18),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Accent bar (live-updates with pending role) ─────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  color: accentColor,
                ),

                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(context, accentColor, isDark),
                          const SizedBox(height: 20),
                          _divider(context, isDark),
                          const SizedBox(height: 20),
                          _buildRoleSection(context, isDark),
                          const SizedBox(height: 20),
                          _divider(context, isDark),
                          const SizedBox(height: 16),
                          _buildStatusSection(context, isDark),
                          const SizedBox(height: 20),

                          // ── Owner warning ─────────────────────────────────
                          if (_isOwnerAccount) ...[
                            _divider(context, isDark),
                            const SizedBox(height: 14),
                            _buildOwnerWarning(context, isDark),
                          ],

                          // ── Admin-cannot-modify-owner warning ─────────────
                          if (_isReadOnly && !_isOwnerAccount) ...[
                            _divider(context, isDark),
                            const SizedBox(height: 14),
                            _buildAdminRestrictionWarning(context, isDark),
                          ],

                          // ── Confirm button (hidden for Owner or if read-only) ──
                          if (!_isOwnerAccount && !_isReadOnly) ...[
                            const SizedBox(height: 4),
                            _buildConfirmButton(context, accentColor),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Profile header ────────────────────────────────────────────────────────
  Widget _buildProfileHeader(
    BuildContext context,
    Color accentColor,
    bool isDark,
  ) {
    final user = widget.user;
    final displayCode = _prefixedCode(
      user.code,
      _isOwnerAccount ? user.role : _pendingRole,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withOpacity(0.35), width: 2),
          ),
          child: Center(
            child: Text(
              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Name & meta
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isOwnerAccount)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        LucideIcons.crown,
                        size: 15,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                user.email,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(
                    context,
                    icon: LucideIcons.hash,
                    label: displayCode,
                    color: accentColor,
                  ),
                  _chip(
                    context,
                    icon: LucideIcons.calendarDays,
                    label: DateFormat('MMM d, yyyy').format(user.createdAt),
                    color: AppColors.successGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Close
        IconButton(
          icon: Icon(
            LucideIcons.x,
            size: 17,
            color: Theme.of(context).hintColor,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // ── Role section ──────────────────────────────────────────────────────────
  Widget _buildRoleSection(BuildContext context, bool isDark) {
    // ── Owner account: completely read-only ──────────────────────────────
    if (_isOwnerAccount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              _label(context, 'ROLE'),
              _systemProtectedBadge(context),
            ],
          ),
          const SizedBox(height: 10),
          _buildReadOnlyRoleRow(context, isDark, activeRole: 'owner'),
        ],
      );
    }

    // ── Admin caller cannot modify roles ─────────────────────────────────
    // (shown as read-only but not "system protected" — just admin restriction)
    if (_isReadOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, 'ROLE'),
          const SizedBox(height: 10),
          _buildReadOnlyRoleRow(context, isDark, activeRole: _pendingRole),
        ],
      );
    }

    // ── Interactive role selector ─────────────────────────────────────────
    // Owner can assign any role; Admin can assign any role EXCEPT owner
    final selectableRoles = _callerIsOwner
        ? _roles
        : _roles.where((r) => r != 'owner').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, 'ROLE'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: selectableRoles.map((role) {
              final i = _roles.indexOf(role);
              final isActive = _pendingRole == role;
              final isVendor = role == 'vendor';
              final rColor = isVendor
                  ? Colors.grey.shade600
                  : _roleColors[i];
              return GestureDetector(
                onTap: isVendor ? null : () => setState(() => _pendingRole = role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? rColor.withOpacity(isDark ? 0.15 : 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isActive
                        ? Border.all(color: rColor.withOpacity(0.35))
                        : Border.all(color: Colors.transparent),
                  ),
                  child: Opacity(
                    opacity: isVendor ? 0.35 : 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVendor ? LucideIcons.lock : _roleIcons[i],
                          size: 13,
                          color: isActive
                              ? rColor
                              : Theme.of(context).hintColor.withOpacity(0.4),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _roleLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isActive
                                ? rColor
                                : Theme.of(context).hintColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Renders the role pills in read-only mode
  Widget _buildReadOnlyRoleRow(
    BuildContext context,
    bool isDark, {
    required String activeRole,
  }) {
    return AbsorbPointer(
      absorbing: true,
      child: Opacity(
        opacity: 0.55,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: _roles.map((role) {
              final i = _roles.indexOf(role);
              final isActive = role == activeRole;
              final rColor = _roleColors[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? rColor.withOpacity(isDark ? 0.15 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive
                      ? Border.all(color: rColor.withOpacity(0.35))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _roleIcons[i],
                      size: 13,
                      color: isActive
                          ? rColor
                          : Theme.of(context).hintColor.withOpacity(0.3),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _roleLabels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive
                            ? rColor
                            : Theme.of(context).hintColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Status section ────────────────────────────────────────────────────────
  Widget _buildStatusSection(BuildContext context, bool isDark) {
    final disabled = _isOwnerAccount || _isReadOnly;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  _label(context, 'ACCOUNT STATUS'),
                  if (_isOwnerAccount) _systemProtectedBadge(context),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _pendingIsActive
                      ? 'Active — account is enabled'
                      : 'Blocked — account is disabled',
                  key: ValueKey(_pendingIsActive),
                  style: TextStyle(
                    fontSize: 12,
                    color: disabled
                        ? AppColors.errorRed
                        : (_pendingIsActive
                              ? AppColors.successGreen
                              : AppColors.errorRed),
                  ),
                ),
              ),
            ],
          ),
        ),
        AbsorbPointer(
          absorbing: disabled,
          child: Opacity(
            opacity: disabled ? 0.35 : 1.0,
            child: Switch(
              value: _pendingIsActive,
              onChanged: disabled
                  ? null
                  : (_) {
                      setState(() => _pendingIsActive = !_pendingIsActive);
                    },
              activeColor: disabled
                  ? AppColors.errorRed
                  : AppColors.successGreen,
              activeTrackColor: disabled
                  ? AppColors.errorRed.withOpacity(0.25)
                  : AppColors.successGreen.withOpacity(0.25),
              inactiveThumbColor: AppColors.errorRed,
              inactiveTrackColor: AppColors.errorRed.withOpacity(0.18),
            ),
          ),
        ),
      ],
    );
  }

  // ── Owner warning banner ──────────────────────────────────────────────────
  Widget _buildOwnerWarning(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.shieldAlert, size: 15, color: AppColors.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Owner permissions cannot be modified by anyone.',
              style: TextStyle(
                color: AppColors.errorRed,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Admin restriction banner ──────────────────────────────────────────────
  Widget _buildAdminRestrictionWarning(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withOpacity(isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warningAmber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.lock, size: 15, color: AppColors.warningAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Admins cannot modify Owner accounts. Contact the Owner directly.',
              style: TextStyle(
                color: AppColors.warningAmber,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm button ─────────────────────────────────────────────────────────
  Widget _buildConfirmButton(BuildContext context, Color accentColor) {
    final bool canSave = _hasChanges && !_isSaving;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: canSave ? _confirmChanges : null,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(LucideIcons.check, size: 17),
        label: Text(
          _isSaving ? 'Saving…' : 'Confirm Changes',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canSave
              ? accentColor
              : Colors.grey.withOpacity(0.12),
          foregroundColor: canSave ? Colors.white : Colors.grey,
          disabledBackgroundColor: Colors.grey.withOpacity(0.1),
          disabledForegroundColor: Colors.grey,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _systemProtectedBadge(BuildContext context) {
    const badgeColor = AppColors.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.lock, size: 9, color: AppColors.errorRed),
          SizedBox(width: 4),
          Text(
            'System Protected',
            style: TextStyle(
              color: AppColors.errorRed,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Theme.of(context).hintColor.withOpacity(0.55),
    ),
  );

  Widget _divider(BuildContext context, bool isDark) => Divider(
    height: 1,
    thickness: 1,
    color: isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05),
  );

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
