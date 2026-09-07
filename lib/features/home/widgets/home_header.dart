import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/models/shipping_address_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeHeader
//
// Displays:
//   • Greeting row  (left: "Hello, Name 👋" | right: notification icon)
//   • Location row  (left: map-pin + address from saved addresses | right: -)
//
// Removed from this widget:
//   • "Find your deals!" title text
//   • Inline search TextField (search is accessible via AppBar icon → SearchScreen)
//   • Language/locale selector
//   • Language/locale selector
// ─────────────────────────────────────────────────────────────────────────────

class HomeHeader extends StatefulWidget {
  // searchController / onSearchChanged kept in signature for zero-friction
  // compatibility — HomeContent still passes them. They are unused here because
  // the inline search bar was moved to the dedicated SearchScreen.
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const HomeHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  @override
  void initState() {
    super.initState();
    // Lazily load addresses so the location row populates shortly after
    // the Home screen opens (non-blocking).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final checkout = context.read<CheckoutProvider>();
      if (checkout.addresses.isEmpty && !checkout.isLoading) {
        checkout.fetchAddresses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firstName = (auth.user['firstName'] ?? 'Guest').toString();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Greeting + notification ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Hello, $firstName 👋',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Notification icon — functionality preserved, no change
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none_outlined,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.secondary,
                      size: 26,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: Location ─────────────────────────────────────────────
          _LocationRow(isDark: isDark),

          const SizedBox(height: 16),

          // ── Row 3: Search Pill ──────────────────────────────────────────
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.grey[100],
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: TextField(
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              onSubmitted: widget.onSearchChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search for products...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : Colors.grey[500],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: isDark ? AppColors.darkTextMuted : Colors.grey[500],
                  size: 18,
                ),
                suffixIcon: widget.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: isDark ? AppColors.darkTextMuted : Colors.grey[500],
                          size: 16,
                        ),
                        onPressed: () {
                          widget.searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location row ─────────────────────────────────────────────────────────────

class _LocationRow extends StatelessWidget {
  final bool isDark;
  const _LocationRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(
      builder: (context, checkout, _) {
        // Find the default address first; fall back to first address.
        final ShippingAddress? addr = checkout.addresses.isEmpty
            ? null
            : checkout.addresses.firstWhere(
                (a) => a.isDefault,
                orElse: () => checkout.addresses.first,
              );

        final String label = addr != null
            ? _buildLabel(addr)
            : (checkout.isLoading ? 'Detecting location…' : 'Select your location');

        final bool hasAddress = addr != null;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pin icon
            Icon(
              LucideIcons.mapPin,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery to',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : Colors.grey[500],
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasAddress
                          ? (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.secondary)
                          : (isDark
                              ? AppColors.darkTextMuted
                              : Colors.grey[500]),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Small chevron — visual affordance that location is tappable
            if (!hasAddress && !checkout.isLoading)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: isDark
                    ? AppColors.darkTextMuted
                    : Colors.grey.withOpacity(0.55),
              ),
          ],
        );
      },
    );
  }

  /// Build a concise display label from a ShippingAddress.
  /// Priority: city + governorate if both present, else whichever is known.
  String _buildLabel(ShippingAddress addr) {
    final parts = <String>[
      if (addr.city.isNotEmpty && addr.city != 'Unknown') addr.city,
      if (addr.governorate.isNotEmpty && addr.governorate != 'Unknown' &&
          addr.governorate != addr.city)
        addr.governorate,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    // Fallback to the address line if city/governorate aren't useful
    if (addr.addressLine1.isNotEmpty) return addr.addressLine1;
    return 'Home Location';
  }
}
