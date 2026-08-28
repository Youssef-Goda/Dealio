import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/widgets/dealio_skeleton.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/data/providers/user_provider.dart';
import 'package:e_commerce/data/models/user_model.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce/features/admin/widgets/user_details_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// ── Owner identity constant ─────────────────────────────────────────────────
// The founding owner account. Identified client-side for UI protection.
const String _kOwnerEmail = 'youssefgoda.dev@gmail.com';

bool _isOwnerAccount(UserModel u) => u.email.toLowerCase() == _kOwnerEmail;

// ── Role-based code prefix (U-/V-/M-/A-/O-) ─────────────────────────────────
String _rolePrefix(String role) {
  switch (role.toLowerCase()) {
    case 'owner':     return 'O';
    case 'admin':     return 'A';
    case 'moderator': return 'M';
    case 'vendor':    return 'V';
    default:          return 'U'; // user / customer
  }
}

/// Returns the user code with a role-based prefix.
/// The owner account always shows 'O-1' regardless of DB sequence.
/// Strips any existing prefix first so switching roles never double-prefixes.
String _prefixedCode(UserModel user) {
  if (_isOwnerAccount(user)) return 'O-1';
  final base = user.code.replaceAll(RegExp(r'^[A-Za-z]+-'), '');
  return '${_rolePrefix(user.role)}-$base';
}

class UsersContent extends StatefulWidget {
  const UsersContent({super.key});

  @override
  State<UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends State<UsersContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchBy = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProv = context.read<AuthProvider>();
      final currentIdFromAuth = authProv.user['userId'] ?? authProv.user['id'];
      if (currentIdFromAuth != null) {
        context.read<UserProvider>().setCurrentUser(
          currentIdFromAuth.toString(),
        );
      }
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    final searchText = _searchController.text.toLowerCase().trim();

    return users.where((user) {
      // Filter
      bool matchesFilter = true;
      if (_selectedFilter != 'All') {
        switch (_selectedFilter) {
          case 'Active':
            matchesFilter = user.isActive;
            break;
          case 'Blocked':
            matchesFilter = !user.isActive;
            break;
          case 'Admin':
            matchesFilter = user.role.toLowerCase() == 'admin';
            break;
          case 'Moderator':
            matchesFilter = user.role.toLowerCase() == 'moderator';
            break;
        }
      }

      // Search
      bool matchesSearch = true;
      if (searchText.isNotEmpty) {
        switch (_searchBy) {
          case 'All':
            matchesSearch =
                user.fullName.toLowerCase().contains(searchText) ||
                user.email.toLowerCase().contains(searchText) ||
                user.code.toLowerCase().contains(searchText) ||
                user.role.toLowerCase().contains(searchText);
            break;
          case 'Name':
            matchesSearch = user.fullName.toLowerCase().contains(searchText);
            break;
          case 'Email':
            matchesSearch = user.email.toLowerCase().contains(searchText);
            break;
          case 'Code':
            matchesSearch = user.code.toLowerCase().contains(searchText);
            break;
          case 'Role':
            matchesSearch = user.role.toLowerCase().contains(searchText);
            break;
        }
      }

      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _handleBulkDelete(BuildContext context) async {
    final userProv = context.read<UserProvider>();
    final selectedIds = List<String>.from(userProv.selectedUserIds);
    if (selectedIds.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: AppColors.errorRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${selectedIds.length} '
          'user${selectedIds.length > 1 ? 's' : ''}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      for (final id in selectedIds) {
        await userProv.deleteUser(id);
      }
      userProv.selectedUserIds.clear();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProv, _) {
        final filteredUsers = _getFilteredUsers(userProv.users);
        final bool isMobile = R.isMobile(context);
        final bool isLandscapeMobile = MediaQuery.of(context).size.height < 600;
        final bool shouldScroll = isMobile || isLandscapeMobile;

        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _UsersHeader(
              checkedRowsCount: userProv.selectedUserIds.length,
              onBulkDelete: () => _handleBulkDelete(context),
              isLoading: userProv.isLoading,
            ),
            const SizedBox(height: 24),
            // Stat cards — skeleton only on initial empty load
            userProv.isLoading && userProv.users.isEmpty
                ? const AdminStatCardSkeleton()
                : _UsersStatsRow(userProv: userProv),
            const SizedBox(height: 20),
            _UsersSearchFilterBar(
              searchController: _searchController,
              searchBy: _searchBy,
              selectedFilter: _selectedFilter,
              onSearchChanged: (v) => setState(() {}),
              onSearchByChanged: (v) => setState(() => _searchBy = v),
              onFilterChanged: (v) => setState(() => _selectedFilter = v),
            ),
            const SizedBox(height: 20),
            // Slim progress bar on background refresh
            if (userProv.isLoading && userProv.users.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  minHeight: 2,
                ),
              ),
            shouldScroll
                ? SizedBox(
                    height: 450,
                    child: _CustomUsersTable(
                      users: filteredUsers,
                      userProv: userProv,
                    ),
                  )
                : Expanded(
                    child: _CustomUsersTable(
                      users: filteredUsers,
                      userProv: userProv,
                    ),
                  ),
          ],
        );

        return RefreshIndicator(
          onRefresh: () => userProv.fetchUsers(),
          color: const Color(0xFFFFD700),
          child: Padding(
            padding: R.all(context, 20),
            child: shouldScroll
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: content,
                  )
                : content,
          ),
        );
      },
    );
  }
}

// ===========================================================================
// HEADER
// ===========================================================================

class _UsersHeader extends StatelessWidget {
  final int checkedRowsCount;
  final VoidCallback onBulkDelete;
  final bool isLoading;

  const _UsersHeader({
    required this.checkedRowsCount,
    required this.onBulkDelete,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Users Management',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage accounts, roles & permissions',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: checkedRowsCount > 0
                  ? Padding(
                      key: const ValueKey('bulk_delete'),
                      padding: const EdgeInsets.only(right: 12),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.errorRed.withOpacity(
                            isDark ? 0.15 : 0.08,
                          ),
                          foregroundColor: AppColors.errorRed,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: AppColors.errorRed.withOpacity(0.3),
                            ),
                          ),
                        ),
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        label: Text('Delete ($checkedRowsCount)'),
                        onPressed: onBulkDelete,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// STAT CARDS ROW
// ===========================================================================

class _UsersStatsRow extends StatelessWidget {
  final UserProvider userProv;
  const _UsersStatsRow({required this.userProv});

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPortraitMobile = MediaQuery.of(context).size.width < 550;

    if (isPortraitMobile) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.05) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? color.withOpacity(0.2)
                  : Theme.of(context).dividerColor.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : color.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.05) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? color.withOpacity(0.2)
                : Theme.of(context).dividerColor.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (isDark)
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardInner(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPortraitMobile = MediaQuery.of(context).size.width < 550;

    if (isPortraitMobile) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.05) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? color.withOpacity(0.2)
                  : Theme.of(context).dividerColor.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : color.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.05) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? color.withOpacity(0.2)
                : Theme.of(context).dividerColor.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : color.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPortraitMobile = MediaQuery.of(context).size.width < 550;

    return Row(
      children: [
        _buildStatCard(
          context,
          'Total Users',
          userProv.users.length.toString(),
          LucideIcons.users,
          AppColors.infoBlue,
        ),
        _buildStatCard(
          context,
          'Active',
          userProv.users.where((u) => u.isActive).length.toString(),
          LucideIcons.circleCheckBig,
          AppColors.successGreen,
        ),
        _buildStatCard(
          context,
          'Blocked',
          userProv.users.where((u) => !u.isActive).length.toString(),
          LucideIcons.ban,
          AppColors.errorRed,
        ),
        Expanded(
          flex: isPortraitMobile ? 2 : 1,
          child: Row(
            children: [
              _buildStatCardInner(
                context,
                isPortraitMobile ? 'Admin' : 'Admins',
                userProv.users
                    .where((u) => u.role.toLowerCase() == 'admin')
                    .length
                    .toString(),
                LucideIcons.shield,
                AppColors.adminPurple,
              ),
              _buildStatCardInner(
                context,
                isPortraitMobile ? 'Mod' : 'Moderators',
                userProv.users
                    .where((u) => u.role.toLowerCase() == 'moderator')
                    .length
                    .toString(),
                LucideIcons.shieldAlert,
                AppColors.warningAmber,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// SEARCH & FILTER BAR
// ===========================================================================

class _UsersSearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchBy;
  final String selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchByChanged;
  final ValueChanged<String> onFilterChanged;

  static const List<String> _searchByOptions = [
    'All',
    'Name',
    'Email',
    'Code',
    'Role',
  ];
  static const List<String> _filterOptions = [
    'All',
    'Active',
    'Blocked',
    'Admin',
    'Moderator',
  ];

  const _UsersSearchFilterBar({
    required this.searchController,
    required this.searchBy,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onSearchByChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = R.isMobile(context);

    final inputDecoration = BoxDecoration(
      color: isDark
          ? Colors.white.withOpacity(0.04)
          : AppColors.background.withOpacity(0.35),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
      ),
    );

    Widget buildDropdown({
      required IconData icon,
      required String value,
      required List<String> options,
      required ValueChanged<String> onChanged,
      String? tooltip,
    }) {
      return Tooltip(
        message: tooltip ?? '',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: inputDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: Theme.of(context).hintColor.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  icon: Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: Theme.of(context).hintColor.withOpacity(0.5),
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                  items: options
                      .map(
                        (v) =>
                            DropdownMenuItem<String>(value: v, child: Text(v)),
                      )
                      .toList(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final searchField = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search users...',
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white24
              : Theme.of(context).hintColor.withOpacity(0.4),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          LucideIcons.search,
          size: 17,
          color: isDark
              ? Colors.white24
              : Theme.of(context).hintColor.withOpacity(0.4),
        ),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: isDark
                      ? Colors.white24
                      : Theme.of(context).hintColor.withOpacity(0.4),
                ),
                onPressed: () {
                  searchController.clear();
                  onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.04)
            : AppColors.background.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.03),
          ),
        ),
        // No yellow focus border — neutral grey instead
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
        isDense: true,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.surfaceLight,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildDropdown(
                        icon: LucideIcons.listFilter,
                        value: selectedFilter,
                        options: _filterOptions,
                        onChanged: onFilterChanged,
                        tooltip: 'Filter',
                      ),
                      const SizedBox(width: 8),
                      buildDropdown(
                        icon: LucideIcons.search,
                        value: searchBy,
                        options: _searchByOptions,
                        onChanged: onSearchByChanged,
                        tooltip: 'Search By',
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                buildDropdown(
                  icon: LucideIcons.listFilter,
                  value: selectedFilter,
                  options: _filterOptions,
                  onChanged: onFilterChanged,
                  tooltip: 'Filter',
                ),
                const SizedBox(width: 8),
                buildDropdown(
                  icon: LucideIcons.search,
                  value: searchBy,
                  options: _searchByOptions,
                  onChanged: onSearchByChanged,
                  tooltip: 'Search By',
                ),
              ],
            ),
    );
  }
}

// ===========================================================================
// CUSTOM USERS TABLE
// ===========================================================================

class _CustomUsersTable extends StatelessWidget {
  final List<UserModel> users;
  final UserProvider userProv;

  const _CustomUsersTable({required this.users, required this.userProv});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = R.isMobile(context);

    // Initial load skeleton
    if (userProv.isLoading && userProv.users.isEmpty) {
      return const AdminTableSkeleton();
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.usersRound,
              size: 48,
              color: Theme.of(context).hintColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found.',
              style: TextStyle(
                color: Theme.of(context).hintColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    Widget tableContent = Column(
      children: [
        _buildTableHeader(context, userProv),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: users.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.05),
            ),
            itemBuilder: (context, index) {
              return _UserRow(
                user: users[index],
                userProv: userProv,
                isEven: index % 2 == 0,
                currentUserId: userProv.currentUserId,
              );
            },
          ),
        ),
      ],
    );

    if (isMobile) {
      tableContent = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 850,
          child: tableContent,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : AppColors.surfaceLight,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: tableContent,
    );
  }

  Widget _buildTableHeader(BuildContext context, UserProvider userProv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        // Seamless — matches table body card color
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: _CheckboxCell(
              isChecked: userProv.isAllSelected,
              onToggle: () => userProv.toggleSelectAll(),
            ),
          ),
          const Expanded(flex: 1, child: _HeaderCell('Code', center: true)),
          const Expanded(flex: 3, child: _HeaderCell('Full Name')),
          const Expanded(flex: 3, child: _HeaderCell('Email')),
          const Expanded(flex: 1, child: _HeaderCell('Status', center: true)),
          const Expanded(flex: 1, child: _HeaderCell('Role', center: true)),
          const SizedBox(
            width: 80,
            child: _HeaderCell('Details', center: true),
          ),
        ],
      ),
    );
  }
}

// ── Shared header cell ──────────────────────────────────────────────────────
class _HeaderCell extends StatelessWidget {
  final String title;
  final bool center;

  const _HeaderCell(this.title, {this.center = false});

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        // Matches Products _HeaderCell — uses theme hintColor for dark/light compat
        color: Theme.of(context).hintColor.withOpacity(0.7),
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: center
          ? Center(child: textWidget)
          : Align(alignment: Alignment.centerLeft, child: textWidget),
    );
  }
}

// ── Checkbox cell ───────────────────────────────────────────────────────────
class _CheckboxCell extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onToggle;

  const _CheckboxCell({required this.isChecked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.scale(
        scale: 0.85,
        child: Checkbox(
          value: isChecked,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.primary,
          checkColor: AppColors.secondary,
          side: BorderSide(color: Theme.of(context).hintColor.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}

// ── User row ────────────────────────────────────────────────────────────────
class _UserRow extends StatefulWidget {
  final UserModel user;
  final UserProvider userProv;
  final bool isEven;
  final String currentUserId;

  const _UserRow({
    required this.user,
    required this.userProv,
    required this.isEven,
    required this.currentUserId,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.userProv.selectedUserIds.contains(widget.user.id);

    final bgColor = isSelected
        ? AppColors.primary.withOpacity(0.06)
        : _isHovered
        ? (isDark
              ? Colors.white.withOpacity(0.04)
              : AppColors.surfaceLight.withOpacity(0.6))
        // even index = lighter tint, odd = transparent
        : widget.isEven
        ? (isDark
              ? Colors.white.withOpacity(0.02)
              : AppColors.surfaceLight.withOpacity(0.4))
        : Colors.transparent;

    // Hardcoded owner identification — email-based, no DB roundtrip
    final isOwner = widget.user.email == 'youssefgoda.dev@gmail.com';
    final isSelf = widget.user.id == widget.currentUserId;

    Color _colorForRole(String role) {
      switch (role.toLowerCase()) {
        case 'owner':     return AppColors.errorRed;
        case 'admin':     return AppColors.adminPurple;
        case 'moderator': return AppColors.warningAmber;
        case 'vendor':    return AppColors.successGreen;
        default:          return AppColors.infoBlue; // user / customer
      }
    }

    final roleColor = _colorForRole(
      isOwner ? 'owner' : widget.user.role,
    );

    final statusColor = widget.user.isActive
        ? AppColors.successGreen
        : AppColors.errorRed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.userProv.toggleUserSelection(widget.user.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: bgColor),
          child: Row(
            children: [
              // 1. Checkbox
              SizedBox(
                width: 50,
                child: _CheckboxCell(
                  isChecked: isSelected,
                  onToggle: () =>
                      widget.userProv.toggleUserSelection(widget.user.id),
                ),
              ),
              // 2. Code
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    // Display role-prefixed code — updates live when role changes
                    _prefixedCode(widget.user),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // 3. Full Name
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.user.fullName,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              color: AppColors.infoBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isOwner)
                        const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Icon(
                            LucideIcons.crown,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // 4. Email
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.user.email,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // 5. Status badge
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 6, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          widget.user.isActive ? 'Active' : 'Blocked',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 6. Role badge
              Expanded(
                flex: 1,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        // Force 'OWNER' display for hardcoded owner email
                        isOwner ? 'OWNER' : widget.user.role.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              // 7. Details eye
              SizedBox(
                width: 60,
                child: Center(
                  child: Tooltip(
                    message: 'View Details',
                    child: InkWell(
                      onTap: () => showUserDetailsDialog(
                        context,
                        widget.user,
                        widget.userProv,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.actionIndigo.withOpacity(
                            isDark ? 0.08 : 0.05,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.actionIndigo.withOpacity(
                              isDark ? 0.15 : 0.1,
                            ),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.eye,
                          size: 16,
                          color: AppColors.actionIndigo,
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
    );
  }
}
