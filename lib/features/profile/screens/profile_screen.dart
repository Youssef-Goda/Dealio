import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// ─── Owner constant (mirrors user_provider.dart) ─────────────────────────────
const String _kOwnerEmail = 'youssefgoda.dev@gmail.com';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();

    // Use postFrameCallback to safely read providers after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      _initProfile();
    });
  }

  void _initProfile() {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final token = auth.user['accessToken']?.toString();

    if (token == null || token.isEmpty) {
      debugPrint('⏳ ProfileScreen: Waiting for valid token...');
      return;
    }

    _initialized = true;
    debugPrint('🚀 ProfileScreen: Token found, fetching data...');

    // Seed controllers from already-loaded provider data
    _firstNameCtrl.text = profile.firstName;
    _lastNameCtrl.text = profile.lastName;
    _phoneCtrl.text = _nationalNumber(profile.phoneNumber);

    // Fetch fresh data from server
    profile.fetchProfile(token).then((_) {
      if (!mounted) return;
      if (profile.sessionExpired) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        auth.logout(context);
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        return;
      }
      _firstNameCtrl.text = profile.firstName;
      _lastNameCtrl.text = profile.lastName;
      _phoneCtrl.text = _nationalNumber(profile.phoneNumber);
    });
  }

  /// Strips the E.164 country code (+20 for Egypt, or any +XX prefix) from a
  /// stored phone number and returns only the national number for the controller.
  String _nationalNumber(String fullNumber) {
    String n = fullNumber.trim();
    // Remove leading + and country code prefix (up to 3 digits)
    if (n.startsWith('+')) {
      // Egypt: +20  → strip '+20'
      if (n.startsWith('+20')) return n.substring(3);
      // Generic: +X or +XX
      final match = RegExp(r'^\+(\d{1,3})').firstMatch(n);
      if (match != null) return n.substring(match.end);
    }
    return n;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  bool _isOwner(Map<String, dynamic> user) =>
      (user['email']?.toString().toLowerCase() == _kOwnerEmail) ||
      (user['role']?.toString().toLowerCase() == 'owner');

  String _roleLabel(Map<String, dynamic> user) {
    if (_isOwner(user)) return 'Owner (O-1)';
    final role = user['role']?.toString() ?? 'user';
    return role[0].toUpperCase() + role.substring(1);
  }

  Color _roleColor(Map<String, dynamic> user) {
    if (_isOwner(user)) return AppColors.primary;
    final role = user['role']?.toString().toLowerCase() ?? 'user';
    if (role == 'admin') return AppColors.adminPurple;
    return AppColors.infoBlue;
  }

  IconData _roleIcon(Map<String, dynamic> user) {
    if (_isOwner(user)) return LucideIcons.crown;
    final role = user['role']?.toString().toLowerCase() ?? 'user';
    if (role == 'admin') return LucideIcons.shieldCheck;
    return LucideIcons.user;
  }

  String _initials(Map<String, dynamic> user) {
    final f = (user['firstName']?.toString() ?? '').trim();
    final l = (user['lastName']?.toString() ?? '').trim();
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'
        .toUpperCase();
  }

  String _memberSince(Map<String, dynamic> user) {
    final raw = user['createdAt']?.toString();
    if (raw == null) return 'N/A';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return 'N/A';
    return DateFormat('MMM yyyy').format(dt);
  }

  // ─── Save handler ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final token = auth.user['accessToken']?.toString() ?? '';
    // Pass auth so changes propagate to AuthProvider._userData (global state)
    final ok = await profile.updateProfile(token: token, authProvider: auth);

    if (!mounted) return;
    if (ok) {
      // Sync controllers to the now-canonical values
      _firstNameCtrl.text = profile.firstName;
      _lastNameCtrl.text = profile.lastName;
      _phoneCtrl.text = _nationalNumber(profile.phoneNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.circleCheck, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      if (profile.sessionExpired) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        await auth.logout(context);
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profile.errorMessage ?? 'Update failed'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ─── Avatar picker ──────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final token = auth.user['accessToken']?.toString() ?? '';
    // Pass authProvider so upload+DB-save+global-sync happen in one shot
    await profile.pickAndUploadAvatar(token, authProvider: auth);
  }

  // ─── Change-email dialog (blurred backdrop) ────────────────────────────────

  void _showChangeEmailSheet() {
    final auth = context.read<AuthProvider>();
    final token = auth.user['accessToken']?.toString() ?? '';
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => _ChangeEmailDialog(token: token),
    );
  }

  // ─── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDob() async {
    final profile = context.read<ProfileProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: profile.dob ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Theme.of(ctx).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) profile.setDob(picked);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = R.isMobile(context);
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Consumer2<AuthProvider, ProfileProvider>(
      builder: (context, auth, profile, _) {
        final user = auth.user;

        return Stack(
          children: [
            // ── Main content ────────────────────────────────────────────────
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: isMobile
                  ? _mobileLayout(context, user, profile)
                  : _desktopLayout(context, user, profile),
            ),

            // ── Floating Save button ─────────────────────────────────────────
            _FloatingSaveButton(
              isDirty: profile.isDirty,
              isLoading: profile.isLoading,
              onSave: _save,
              onDiscard: () {
                profile.discardChanges();
                _firstNameCtrl.text = profile.firstName;
                _lastNameCtrl.text = profile.lastName;
                _phoneCtrl.text = _nationalNumber(profile.phoneNumber);
              },
            ),
          ],
        );
      },
    );
  }

  // ─── Mobile single-column ────────────────────────────────────────────────────

  Widget _mobileLayout(
    BuildContext context,
    Map<String, dynamic> user,
    ProfileProvider profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(
            user: user,
            profile: profile,
            onPickAvatar: _pickAvatar,
            isOwner: _isOwner(user),
            roleLabel: _roleLabel(user),
            roleColor: _roleColor(user),
            roleIcon: _roleIcon(user),
            initials: _initials(user),
            isMobile: true,
          ),
          Padding(
            padding: EdgeInsets.all(R.w(context, 20)),
            child: Column(
              children: [
                _StatsRow(user: user, memberSince: _memberSince(user)),
                SizedBox(height: R.h(context, 24)),
                _IdentitySection(
                  firstNameCtrl: _firstNameCtrl,
                  lastNameCtrl: _lastNameCtrl,
                  profile: profile,
                  user: user,
                  onChangeEmail: _showChangeEmailSheet,
                  isDark: isDark,
                ),
                SizedBox(height: R.h(context, 24)),
                _PersonalInfoSection(
                  profile: profile,
                  user: user,
                  phoneCtrl: _phoneCtrl,
                  onPickDob: _pickDob,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Desktop side-by-side ────────────────────────────────────────────────────

  Widget _desktopLayout(
    BuildContext context,
    Map<String, dynamic> user,
    ProfileProvider profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left column: avatar + stats ──────────────────────────────────
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  _ProfileHeader(
                    user: user,
                    profile: profile,
                    onPickAvatar: _pickAvatar,
                    isOwner: _isOwner(user),
                    roleLabel: _roleLabel(user),
                    roleColor: _roleColor(user),
                    roleIcon: _roleIcon(user),
                    initials: _initials(user),
                    isMobile: false,
                  ),
                  const SizedBox(height: 20),
                  _StatsColumn(user: user, memberSince: _memberSince(user)),
                ],
              ),
            ),
            const SizedBox(width: 28),

            // ── Right column: fields ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IdentitySection(
                    firstNameCtrl: _firstNameCtrl,
                    lastNameCtrl: _lastNameCtrl,
                    profile: profile,
                    user: user,
                    onChangeEmail: _showChangeEmailSheet,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _PersonalInfoSection(
                    profile: profile,
                    user: user,
                    phoneCtrl: _phoneCtrl,
                    onPickDob: _pickDob,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PROFILE HEADER
// ══════════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final ProfileProvider profile;
  final VoidCallback onPickAvatar;
  final bool isOwner;
  final String roleLabel;
  final Color roleColor;
  final IconData roleIcon;
  final String initials;
  final bool isMobile;

  const _ProfileHeader({
    required this.user,
    required this.profile,
    required this.onPickAvatar,
    required this.isOwner,
    required this.roleLabel,
    required this.roleColor,
    required this.roleIcon,
    required this.initials,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarSize = isMobile ? 100.0 : 120.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primary.withOpacity(0.18), AppColors.darkSurface]
              : [AppColors.primary.withOpacity(0.22), AppColors.background],
        ),
        borderRadius: isMobile
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              )
            : BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isMobile ? 40 : 32,
      ),
      child: Column(
        children: [
          // ── Upload progress bar ─────────────────────────────────────────────
          if (profile.isUploading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: profile.uploadProgress,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uploading avatar…',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

          // ── Avatar ──────────────────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profile.avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profile.avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _AvatarPlaceholder(
                            initials: initials,
                            size: avatarSize,
                          ),
                          errorWidget: (_, __, ___) => _AvatarPlaceholder(
                            initials: initials,
                            size: avatarSize,
                          ),
                        )
                      : _AvatarPlaceholder(
                          initials: initials,
                          size: avatarSize,
                        ),
                ),
              ),

              // Camera button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: profile.isUploading ? null : onPickAvatar,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: profile.isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black87,
                            ),
                          )
                        : const Icon(
                            LucideIcons.camera,
                            size: 16,
                            color: Colors.black87,
                          ),
                  ),
                ),
              ),

              // Upload overlay spinner on top of avatar
              if (profile.isUploading)
                Positioned.fill(
                  child: ClipOval(
                    child: Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Full name ────────────────────────────────────────────────────────
          Text(
            '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: R.font(context, 22),
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimaryDark,
            ),
          ),

          const SizedBox(height: 8),

          // ── Email ─────────────────────────────────────────────────────────────
          Text(
            profile.email,
            style: TextStyle(
              fontSize: R.font(context, 13),
              color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // ── Role badge ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: roleColor.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, size: 14, color: roleColor),
                const SizedBox(width: 6),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: R.font(context, 12.5),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar placeholder ────────────────────────────────────────────────────────
class _AvatarPlaceholder extends StatelessWidget {
  final String initials;
  final double size;
  const _AvatarPlaceholder({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            fontSize: size * 0.33,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STATS — MOBILE ROW
// ══════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final String memberSince;
  const _StatsRow({required this.user, required this.memberSince});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: LucideIcons.shoppingBag,
          label: 'Total Orders',
          value: '0',
          flex: true,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.calendarDays,
          label: 'Member Since',
          value: memberSince,
          flex: true,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.zap,
          label: 'Level',
          value: 'Bronze',
          showProgress: true,
          flex: true,
        ),
      ],
    );
  }
}

// ── STATS — DESKTOP COLUMN ─────────────────────────────────────────────────────

class _StatsColumn extends StatelessWidget {
  final Map<String, dynamic> user;
  final String memberSince;
  const _StatsColumn({required this.user, required this.memberSince});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatCard(
          icon: LucideIcons.shoppingBag,
          label: 'Total Orders',
          value: '0',
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: LucideIcons.calendarDays,
          label: 'Member Since',
          value: memberSince,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: LucideIcons.zap,
          label: 'Account Level',
          value: 'Bronze',
          showProgress: true,
        ),
      ],
    );
  }
}

// ── Individual stat card ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showProgress;
  final bool flex;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.showProgress = false,
    this.flex = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: flex ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: R.font(context, 11.5),
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: R.font(context, 17),
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimaryDark,
            ),
          ),
          if (showProgress) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.25,
                minHeight: 5,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '25% to Silver',
              style: TextStyle(
                fontSize: R.font(context, 10),
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
    return flex
        ? Expanded(child: card)
        : SizedBox(width: double.infinity, child: card);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  IDENTITY SECTION
// ══════════════════════════════════════════════════════════════════════════════

class _IdentitySection extends StatelessWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final ProfileProvider profile;
  final Map<String, dynamic> user;
  final VoidCallback onChangeEmail;
  final bool isDark;

  const _IdentitySection({
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.profile,
    required this.user,
    required this.onChangeEmail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Identity',
      icon: LucideIcons.userPen,
      isDark: isDark,
      child: Column(
        children: [
          // ── First Name ────────────────────────────────────────────────────
          _ProfileTextField(
            controller: firstNameCtrl,
            label: 'First Name',
            icon: LucideIcons.user,
            isDark: isDark,
            onChanged: profile.setFirstName,
          ),
          const SizedBox(height: 16),

          // ── Last Name ─────────────────────────────────────────────────────
          _ProfileTextField(
            controller: lastNameCtrl,
            label: 'Last Name',
            icon: LucideIcons.users,
            isDark: isDark,
            onChanged: profile.setLastName,
          ),
          const SizedBox(height: 16),

          // ── Email (read-only + change button) ─────────────────────────────
          _EmailRow(
            email: profile.email,
            isDark: isDark,
            onChangeTap: onChangeEmail,
          ),
        ],
      ),
    );
  }
}

// ── Email display row ──────────────────────────────────────────────────────────

class _EmailRow extends StatelessWidget {
  final String email;
  final bool isDark;
  final VoidCallback onChangeTap;

  const _EmailRow({
    required this.email,
    required this.isDark,
    required this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.fillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            LucideIcons.mail,
            size: 18,
            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: R.font(context, 11),
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: R.font(context, 14),
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.circleCheck,
                            size: 11,
                            color: AppColors.successGreen,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: R.font(context, 10.5),
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onChangeTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.pencil,
                size: 15,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PERSONAL INFO SECTION
// ══════════════════════════════════════════════════════════════════════════════

class _PersonalInfoSection extends StatelessWidget {
  final ProfileProvider profile;
  final Map<String, dynamic> user;
  final TextEditingController phoneCtrl;
  final VoidCallback onPickDob;
  final bool isDark;

  const _PersonalInfoSection({
    required this.profile,
    required this.user,
    required this.phoneCtrl,
    required this.onPickDob,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Personal Info',
      icon: LucideIcons.info,
      isDark: isDark,
      child: Column(
        children: [
          // ── Phone Number (international) ──────────────────────────────────
          IntlPhoneField(
            controller: phoneCtrl,
            initialCountryCode: 'EG',
            // Disable built-in validation so our custom validator runs
            disableLengthCheck: true,
            // onChanged: store the full E.164 in the provider, keep controller
            // holding only the national number to prevent double country code.
            onChanged: (phone) {
              // Strip a leading 0 the user may have typed (Egyptian habit)
              String national = phone.number.trim();
              if (national.startsWith('0')) national = national.substring(1);

              // Update controller to national-only (prevents +20+20… bug)
              if (phoneCtrl.text != national) {
                phoneCtrl.value = phoneCtrl.value.copyWith(
                  text: national,
                  selection: TextSelection.collapsed(offset: national.length),
                );
              }
              // Store full E.164 (+20XXXXXXXXX) in the provider
              profile.setPhoneNumber(phone.countryCode + national);
            },
            validator: (phone) {
              if (phone == null || phone.number.trim().isEmpty) return null;
              String national = phone.number.trim();
              if (national.startsWith('0')) national = national.substring(1);
              // After stripping leading 0, Egyptian number = exactly 10 digits
              final egyptRegex = RegExp(r'^(10|11|12|15)\d{8}$');
              if (!egyptRegex.hasMatch(national)) {
                return 'Invalid phone number';
              }
              return null;
            },
            style: TextStyle(
              fontSize: R.font(context, 14.5),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimaryDark,
            ),
            dropdownTextStyle: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimaryDark,
              fontWeight: FontWeight.w600,
            ),
            pickerDialogStyle: PickerDialogStyle(
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(28),
              // ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              searchFieldInputDecoration: InputDecoration(
                hintText: 'Search country…',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              countryCodeStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              countryNameStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
              listTileDivider: Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                indent: 56,
              ),
              listTilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              width: 400,
            ),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: TextStyle(
                fontSize: R.font(context, 13),
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textSecondary,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.8,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),

          _Divider(isDark: isDark),

          // ── Date of Birth ─────────────────────────────────────────────────
          _InfoTile(
            icon: LucideIcons.cake,
            label: 'Date of Birth',
            isDark: isDark,
            trailing: GestureDetector(
              onTap: onPickDob,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.dob != null
                        ? DateFormat('dd MMM yyyy').format(profile.dob!)
                        : 'Not set',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: R.font(context, 13.5),
                      color: profile.dob != null
                          ? (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimaryDark)
                          : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textHint),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.calendarDays,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          _Divider(isDark: isDark),

          // ── Gender ────────────────────────────────────────────────────────
          _GenderSelector(profile: profile, isDark: isDark),

          _Divider(isDark: isDark),

          // ── Location (static) ─────────────────────────────────────────────
          _InfoTile(
            icon: LucideIcons.mapPin,
            label: 'Location',
            isDark: isDark,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🇪🇬  Egypt',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: R.font(context, 13.5),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final ProfileProvider profile;
  final bool isDark;

  const _GenderSelector({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('male', '♂ Male'),
      ('female', '♀ Female'),
      ('other', 'Prefer not'),
    ];

    final bool isMobile = MediaQuery.of(context).size.width < 550;

    Widget segmentedControl = Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.map((opt) {
          final isSelected = profile.gender == opt.$1;

          Color activeColor;
          if (opt.$1 == 'male') {
            activeColor = Colors.blue;
          } else if (opt.$1 == 'female') {
            activeColor = Colors.pink;
          } else {
            activeColor = AppColors.primary;
          }

          return Expanded(
            flex: isMobile ? 1 : 0,
            child: GestureDetector(
              onTap: () => profile.setGender(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  opt.$2,
                  style: TextStyle(
                    fontSize: R.font(context, 11.5),
                    color: isSelected
                        ? (isDark ? Colors.white : activeColor)
                        : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textSecondary),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.personStanding,
                  size: 22,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: R.font(context, 14.5),
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            segmentedControl,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          Icon(
            LucideIcons.personStanding,
            size: 22,
            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            'Gender',
            style: TextStyle(
              fontSize: R.font(context, 14.5),
              color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          segmentedControl,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  REUSABLE SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

// Section card wrapper
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: R.font(context, 15),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimaryDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // ── Thin divider ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// Profile text field
class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final void Function(String) onChanged;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [], // prevent yellow autofill tint
      style: TextStyle(
        fontSize: R.font(context, 14.5),
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: R.font(context, 13),
          color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// Info tile (label + trailing widget)
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: R.font(context, 13.5),
              color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

// Thin divider
class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkBorder : AppColors.dividerGrey,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FLOATING SAVE BUTTON
// ══════════════════════════════════════════════════════════════════════════════

class _FloatingSaveButton extends StatelessWidget {
  final bool isDirty;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _FloatingSaveButton({
    required this.isDirty,
    required this.isLoading,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        offset: isDirty ? Offset.zero : const Offset(0, 1.8),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isDirty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 280),
          child: IgnorePointer(
            ignoring: !isDirty,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withOpacity(0.95)
                      : Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Discard ──────────────────────────────────────────────
                    GestureDetector(
                      onTap: isLoading ? null : onDiscard,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Text(
                            'Discard',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ── Save Changes (neon bloom on button only) ─────────────
                    Flexible(
                      child: GestureDetector(
                        onTap: isLoading ? null : onSave,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFD700,
                                ).withOpacity(0.55),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFFFFD700,
                                ).withOpacity(0.20),
                                blurRadius: 40,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black87,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHANGE EMAIL DIALOG  — 4-step secure flow with blurred backdrop
// ══════════════════════════════════════════════════════════════════════════════

class _ChangeEmailDialog extends StatefulWidget {
  final String token;
  const _ChangeEmailDialog({required this.token});

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  int _step = 0;
  bool _useOtp = false;

  final _passwordCtrl = TextEditingController();
  final _newEmailCtrl = TextEditingController();

  // OTP values collected from box widgets
  String _identOtpValue = '';
  String _newOtpValue = '';

  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _newEmailCtrl.dispose();
    super.dispose();
  }

  ProfileProvider get _profile => context.read<ProfileProvider>();
  void _clearError() => _profile.clearEmailChangeError();

  Future<void> _requestIdentityOtp() async {
    final ok = await _profile.sendIdentityOtp(token: widget.token);
    if (ok && mounted)
      setState(() {
        _step = 1;
        _useOtp = true;
      });
  }

  Future<void> _verifyPassword() async {
    final ok = await _profile.verifyIdentity(
      token: widget.token,
      method: 'password',
      password: _passwordCtrl.text.trim(),
    );
    if (ok && mounted) setState(() => _step = 2);
  }

  Future<void> _verifyIdentOtp() async {
    final ok = await _profile.verifyIdentity(
      token: widget.token,
      method: 'otp',
      otp: _identOtpValue,
    );
    if (ok && mounted) setState(() => _step = 2);
  }

  Future<void> _sendNewEmailOtp() async {
    final ok = await _profile.sendNewEmailOtp(
      token: widget.token,
      newEmail: _newEmailCtrl.text.trim(),
    );
    if (ok && mounted) setState(() => _step = 3);
  }

  Future<void> _confirmEmailChange() async {
    final ok = await _profile.confirmEmailChange(
      token: widget.token,
      otp: _newOtpValue,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.circleCheck, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Email updated successfully!'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _stepDots(int total, int current) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  InputDecoration _inputDec(
    String hint,
    IconData icon,
    bool isDark, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 18,
        color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _primaryBtn(String label, VoidCallback? onTap, bool loading) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStep0(bool isDark, bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Change Email Address',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: R.font(context, 18),
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'First, verify your identity to protect your account.',
          style: TextStyle(
            fontSize: R.font(context, 13),
            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _primaryBtn('Continue with Password', () {
          _clearError();
          setState(() {
            _step = 1;
            _useOtp = false;
          });
        }, false),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: loading ? null : _requestIdentityOtp,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.mail, size: 16),
            label: Text(loading ? 'Sending…' : 'Send OTP to current email'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(bool isDark, bool loading, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _useOtp ? 'Enter Identity OTP' : 'Verify Your Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: R.font(context, 18),
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _useOtp
              ? 'Enter the code sent to your current email.'
              : 'Enter your current account password.',
          style: TextStyle(
            fontSize: R.font(context, 13),
            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (_useOtp)
          _OtpBoxRow(
            isDark: isDark,
            onChanged: (v) => _identOtpValue = v,
            onCompleted: (v) => setState(() => _identOtpValue = v),
          )
        else
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [],
            decoration: _inputDec(
              'Current password',
              LucideIcons.lock,
              isDark,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        _primaryBtn(
          'Verify',
          _useOtp ? _verifyIdentOtp : _verifyPassword,
          loading,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _clearError();
            setState(() => _step = 0);
          },
          child: const Text('← Back'),
        ),
      ],
    );
  }

  Widget _buildStep2(bool isDark, bool loading, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter New Email',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: R.font(context, 18),
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "We'll send a verification code to this address.",
          style: TextStyle(
            fontSize: R.font(context, 13),
            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _newEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [],
          decoration: _inputDec('new@email.com', LucideIcons.mail, isDark),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        _primaryBtn('Send Verification Code', _sendNewEmailOtp, loading),
      ],
    );
  }

  Widget _buildStep3(bool isDark, bool loading, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify New Email',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: R.font(context, 18),
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the code sent to ${_newEmailCtrl.text.trim()}.',
          style: TextStyle(
            fontSize: R.font(context, 13),
            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        _OtpBoxRow(
          isDark: isDark,
          onChanged: (v) => _newOtpValue = v,
          onCompleted: (v) => setState(() => _newOtpValue = v),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        _primaryBtn('Confirm Email Change', _confirmEmailChange, loading),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _clearError();
            setState(() => _step = 2);
          },
          child: const Text('← Back'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<ProfileProvider>(
      builder: (ctx, profile, _) {
        final loading = profile.emailChangeLoading;
        final error = profile.emailChangeError;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _stepDots(4, _step),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                profile.resetEmailChangeFlow();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkBackground
                                      : AppColors.fillColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: switch (_step) {
                              0 => _buildStep0(isDark, loading),
                              1 => _buildStep1(isDark, loading, error),
                              2 => _buildStep2(isDark, loading, error),
                              _ => _buildStep3(isDark, loading, error),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  OTP BOX ROW  — 6 individual digit squares (Auth-style)
// ══════════════════════════════════════════════════════════════════════════════

class _OtpBoxRow extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _OtpBoxRow({
    this.length = 6,
    required this.onCompleted,
    required this.onChanged,
    required this.isDark,
  });

  @override
  State<_OtpBoxRow> createState() => _OtpBoxRowState();
}

class _OtpBoxRowState extends State<_OtpBoxRow> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (i) {
        return Container(
          width: 46,
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimaryDark,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (val) {
              // Clamp to single char
              if (val.length > 1) {
                _controllers[i].text = val[val.length - 1];
                _controllers[i].selection = const TextSelection.collapsed(
                  offset: 1,
                );
              }
              if (val.isNotEmpty && i < widget.length - 1) {
                _focusNodes[i + 1].requestFocus();
              }
              final full = _value;
              widget.onChanged(full);
              if (full.length == widget.length) widget.onCompleted(full);
            },
          ),
        );
      }),
    );
  }
}
