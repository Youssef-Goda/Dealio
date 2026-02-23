import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:e_commerce/data/providers/user_provider.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';

class UsersContent extends StatefulWidget {
  const UsersContent({super.key});

  @override
  State<UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends State<UsersContent> {
  final TextEditingController _searchController = TextEditingController();
  PlutoGridStateManager? stateManager;
  String _selectedFilter = 'All';

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

  // ─── البحث ───────────────────────────────────
  void _applySearch(String searchText) {
    if (stateManager == null) return;
    stateManager!.setShowLoading(true);
    stateManager!.setFilter((element) {
      if (searchText.isEmpty) return true;
      final query = searchText.toLowerCase();
      return element.cells['id']!.value.toString().contains(query) ||
          element.cells['name']!.value.toString().toLowerCase().contains(
            query,
          ) ||
          element.cells['email']!.value.toString().toLowerCase().contains(
            query,
          );
    });
    stateManager!.setShowLoading(false);
  }

  // ─── الفلتر ───────────────────────────────────
  void _applyFilter(String filter) {
    if (stateManager == null) return;
    setState(() => _selectedFilter = filter);
    stateManager!.setShowLoading(true);
    stateManager!.setFilter((element) {
      if (filter == 'All') return true;
      switch (filter) {
        case 'Active':
          return element.cells['status']!.value == 'ACTIVE';
        case 'Blocked':
          return element.cells['status']!.value == 'BLOCKED';
        case 'Admin':
          return element.cells['role']!.value.toString().toLowerCase() ==
              'admin';
        default:
          return true;
      }
    });
    stateManager!.setShowLoading(false);
  }

  // ─── حذف مستخدم ──────────────────────────────
  void _confirmDelete(
    BuildContext context,
    String userId,
    String name,
    PlutoRow row,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: Colors.red,
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
          'Are you sure you want to delete $name?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // مش محتاج تغير حاجة هنا لو الـ userId اللي معاك String
              context.read<UserProvider>().deleteUser(userId);
              stateManager?.removeRows([row]);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProv, _) {
        final String currentUserId = userProv.currentUserId;
        return Padding(
          padding: R.all(context, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, userProv),
              const SizedBox(height: 20),
              Expanded(
                child: _buildGridContainer(context, userProv, currentUserId),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridContainer(
    BuildContext context,
    UserProvider userProv,
    String currentUserId,
  ) {
    const double radius = 15;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: userProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : PlutoGrid(
              configuration: PlutoGridConfiguration(
                scrollbar: const PlutoGridScrollbarConfig(
                  isAlwaysShown: false,
                  scrollbarThickness: 6,
                  scrollbarRadius: Radius.circular(3),
                ),
                style: PlutoGridStyleConfig(
                  gridBorderRadius: BorderRadius.circular(radius),
                  gridBackgroundColor: AppColors.primary,
                  columnTextStyle: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: R.font(context, 13),
                  ),
                  columnHeight: 50,
                  rowHeight: 56,
                  rowColor: Colors.white,
                  evenRowColor: const Color(0xFFF9FAFB),
                  gridBorderColor: Colors.transparent,
                  enableColumnBorderVertical: false,
                  enableCellBorderVertical: false,
                  enableCellBorderHorizontal: true,
                  borderColor: Colors.grey.withOpacity(0.08),
                  activatedColor: AppColors.primary.withOpacity(0.04),
                  activatedBorderColor: AppColors.primary,
                  // loadingIndicatorColor: AppColors.primary,
                ),
                columnSize: const PlutoGridColumnSizeConfig(
                  autoSizeMode: PlutoAutoSizeMode.scale,
                ),
              ),
              columns: _buildColumns(userProv, currentUserId),
              rows: _buildRows(userProv, currentUserId),
              onLoaded: (event) {
                stateManager = event.stateManager;
                stateManager!.setSelectingMode(PlutoGridSelectingMode.row);
                setState(() {});
              },
            ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, UserProvider userProv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and refresh button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Users Management',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage accounts, roles & permissions',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                tooltip: 'Refresh',
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                color: AppColors.secondary,
                onPressed: () => userProv.fetchUsers(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ─── Stats Cards ───
        Row(
          children: [
            _buildStatCard(
              'Total Users',
              userProv.users.length.toString(),
              LucideIcons.users,
              const Color(0xFF3B82F6),
            ),
            _buildStatCard(
              'Active',
              userProv.users.where((u) => u.isActive).length.toString(),
              LucideIcons.checkCircle,
              const Color(0xFF22C55E),
            ),
            _buildStatCard(
              'Blocked',
              userProv.users.where((u) => !u.isActive).length.toString(),
              LucideIcons.ban,
              const Color(0xFFEF4444),
            ),
            _buildStatCard(
              'Admins',
              userProv.users
                  .where((u) => u.role.toLowerCase() == 'admin')
                  .length
                  .toString(),
              LucideIcons.shield,
              const Color(0xFFA855F7),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ─── Search and Filter ───
        _buildSearchAndFilter(context),
      ],
    );
  }

  // ─── Stat Card ─────────────────────────────
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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

  // ─── Search and Filter ───────────────────────
  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                _applySearch(v);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search by ID, name, or email...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: Colors.grey[400],
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'All',
              'Active',
              'Blocked',
              'Admin',
            ].map(_filterChip).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Filter Chip ──────────────────────────────
  Widget _filterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.secondary : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Columns
  // ─────────────────────────────────────────────
  List<PlutoColumn> _buildColumns(UserProvider userProv, String currentUserId) {
    return [
      // PlutoColumn(
      //   title: 'ID',
      //   field: 'id',
      //   type: PlutoColumnType.number(),
      //   width: 70,
      //   textAlign: PlutoColumnTextAlign.center,
      //   titleTextAlign: PlutoColumnTextAlign.center,
      // ),
      // PlutoColumn(
      //   title: '#',
      //   field: 'serial_id',
      //   type: PlutoColumnType.number(),
      //   width: 80,
      //   titleTextAlign: PlutoColumnTextAlign.center,
      //   textAlign: PlutoColumnTextAlign.center,
      // ),
      PlutoColumn(
        title: 'Code',
        field: 'code',
        type: PlutoColumnType.text(),
        width: 100,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
      ),

      PlutoColumn(
        title: 'Full Name',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 200,
      ),
      PlutoColumn(
        title: 'Email Address',
        field: 'email',
        type: PlutoColumnType.text(),
        width: 230,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 130,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (ctx) {
          final bool isActive = ctx.cell.value == 'ACTIVE';
          final Color color = isActive
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444);
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: color),
                  const SizedBox(width: 5),
                  Text(
                    isActive ? 'ACTIVE' : 'BLOCKED',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Role',
        field: 'role',
        type: PlutoColumnType.text(),
        width: 110,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (ctx) {
          final String role = ctx.cell.value.toString().toLowerCase();
          final Color color = role == 'owner'
              ? const Color(0xFFEF4444)
              : role == 'admin'
              ? const Color(0xFFA855F7)
              : const Color(0xFF3B82F6);
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
      // PlutoColumn(
      //   title: 'Actions',
      //   field: 'actions',
      //   type: PlutoColumnType.text(),
      //   width: 160,
      //   titleTextAlign: PlutoColumnTextAlign.center,
      //   enableEditingMode: false,
      //   enableSorting: false,
      //   renderer: (ctx) {
      //     final user = userProv.users[ctx.rowIdx];
      //     final bool isOwner = user.role.toLowerCase() == 'owner';

      //     return Row(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         // ─ تغيير الـ Role ─
      //         _actionBtn(
      //           icon: Icons.security_rounded,
      //           color: isOwner ? Colors.grey : const Color(0xFFF59E0B),
      //           tooltip: isOwner ? 'Immortal Role' : 'Change Role',
      //           enabled: !isOwner,
      //           onTap: () => context.read<UserProvider>().updateUserRole(
      //             user.id,
      //             user.role == 'admin' ? 'user' : 'admin',
      //           ),
      //         ),
      //         const SizedBox(width: 6),
      //         // ─ Block / Activate ─
      //         _actionBtn(
      //           icon: user.isActive ? LucideIcons.ban : LucideIcons.checkCircle,
      //           color: isOwner
      //               ? Colors.grey
      //               : (user.isActive
      //                     ? const Color(0xFFEF4444)
      //                     : const Color(0xFF22C55E)),
      //           tooltip: isOwner
      //               ? 'Want to block your Uncle!'
      //               : (user.isActive ? 'Block User' : 'Activate User'),
      //           enabled: !isOwner,
      //           onTap: () => context.read<UserProvider>().toggleUserStatus(
      //             user.id,
      //             user.isActive,
      //           ),
      //         ),
      //         const SizedBox(width: 6),
      //         // ─ Delete ─
      //         _actionBtn(
      //           icon: LucideIcons.trash2,
      //           color: isOwner ? Colors.grey : const Color(0xFFEF4444),
      //           tooltip: isOwner ? 'Are you kidding me?' : 'Delete User',
      //           enabled: !isOwner,
      //           onTap: () =>
      //               _confirmDelete(context, user.id, user.fullName, ctx.row),
      //         ),
      //       ],
      //     );
      //   },
      // ),
      // PlutoColumn(
      //   title: 'Joined At',
      //   field: 'createdAt_field',
      //   type: PlutoColumnType.text(),
      //   width: 190,
      //   textAlign: PlutoColumnTextAlign.center,
      //   titleTextAlign: PlutoColumnTextAlign.center,
      // ),
      // PlutoColumn(
      //   title: 'Last Update',
      //   field: 'updatedAt_field',
      //   type: PlutoColumnType.text(),
      //   width: 190,
      //   textAlign: PlutoColumnTextAlign.center,
      //   titleTextAlign: PlutoColumnTextAlign.center,
      // ),
      PlutoColumn(
        title: 'Details',
        field: 'details',
        type: PlutoColumnType.text(),
        width: 100,
        enableSorting: false,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (ctx) {
          final user = userProv.users[ctx.rowIdx];
          return IconButton(
            icon: const Icon(
              Icons.visibility_rounded,
              color: Color(0xFF3B82F6),
            ),

            onPressed: () {},

            // onPressed: () => _showUserManagementModal(context, user, userProv),
          );
        },
      ),
    ];
  }

  // // ─── Action Button ───────────────────────────
  // Widget _actionBtn({
  //   required IconData icon,
  //   required Color color,
  //   required String tooltip,
  //   required bool enabled,
  //   required VoidCallback onTap,
  // }) {
  //   return Tooltip(
  //     message: tooltip,
  //     child: InkWell(
  //       onTap: enabled ? onTap : null,
  //       borderRadius: BorderRadius.circular(8),
  //       child: Container(
  //         padding: const EdgeInsets.all(7),
  //         decoration: BoxDecoration(
  //           color: enabled ? color.withOpacity(0.08) : Colors.grey.shade100,
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: Icon(icon, size: 16, color: color),
  //       ),
  //     ),
  //   );
  // }

  // ─────────────────────────────────────────────
  //  Rows
  // ─────────────────────────────────────────────
  List<PlutoRow> _buildRows(UserProvider userProv, String currentUserId) {
    return userProv.users
        .map(
          (user) => PlutoRow(
            cells: {
              // 'id': PlutoCell(value: user.id),
              // 'serial_id': PlutoCell(value: user.serialId),
              'code': PlutoCell(value: user.code),
              'name': PlutoCell(
                value:
                    '${user.fullName}'
                    '${user.id.toString() == currentUserId ? ' (You)' : ''}'
                    '${user.role.toLowerCase() == 'owner' ? ' 👑' : ''}',
              ),
              'email': PlutoCell(value: user.email),
              'status': PlutoCell(value: user.isActive ? 'ACTIVE' : 'BLOCKED'),
              'role': PlutoCell(value: user.role),
              // 'actions': PlutoCell(value: ''),
              // 'createdAt_field': PlutoCell(
              //   value: DateFormat(
              //     'E, dd/MM/yyyy, HH:mm',
              //   ).format(user.createdAt.toLocal()),
              // ),
              // 'updatedAt_field': PlutoCell(
              //   value: user.updatedAt != null
              //       ? DateFormat(
              //           'E, dd/MM/yyyy, HH:mm',
              //         ).format(user.updatedAt!.toLocal())
              //       : 'Never',
              // ),
              'details': PlutoCell(value: ''),
            },
          ),
        )
        .toList();
  }
}
