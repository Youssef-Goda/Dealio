// import 'package:e_commerce/core/constants/colors.dart';
// import 'package:e_commerce/core/utils/responsive_helper.dart';
// import 'package:e_commerce/data/providers/auth_provider.dart';
// import 'package:e_commerce/data/providers/orders_provider.dart';
// import 'package:e_commerce/features/orders/widgets/order_card.dart';
// import 'package:flutter/material.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';
// import 'package:provider/provider.dart';

// class MyOrdersScreen extends StatefulWidget {
//   const MyOrdersScreen({super.key});

//   @override
//   State<MyOrdersScreen> createState() => _MyOrdersScreenState();
// }

// class _MyOrdersScreenState extends State<MyOrdersScreen> {
//   bool _fetchedOnce = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_fetchedOnce) return;

//     final auth = context.watch<AuthProvider>();

//     // Only fetch once AuthProvider has finished loadUserData().
//     // This guarantees the 'accessToken' is already in SharedPreferences
//     // before OrdersProvider tries to read it.
//     if (!auth.isInitialized) return; // wait for next rebuild

//     _fetchedOnce = true;
//     Future.microtask(() {
//       if (mounted) {
//         context.read<OrdersProvider>().fetchOrders();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final isDesktop = R.isDesktop(context) || R.isTablet(context);

//     return Scaffold(
//       backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
//       appBar: AppBar(
//         backgroundColor: isDark ? AppColors.darkAppBar : Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(
//             LucideIcons.arrowLeft,
//             color: isDark
//                 ? AppColors.darkTextPrimary
//                 : AppColors.textPrimaryDark,
//           ),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: Text(
//           'My Orders',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w800,
//             color: isDark
//                 ? AppColors.darkTextPrimary
//                 : AppColors.textPrimaryDark,
//           ),
//         ),
//         // ── AppBar refresh button ─────────────────────────────
//         actions: [
//           Consumer<OrdersProvider>(
//             builder: (_, provider, __) => IconButton(
//               tooltip: 'Refresh orders',
//               icon: AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 300),
//                 child: provider.isLoading
//                     ? SizedBox(
//                         key: const ValueKey('spin'),
//                         width: 18,
//                         height: 18,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: isDark
//                               ? AppColors.darkTextPrimary
//                               : AppColors.textPrimaryDark,
//                         ),
//                       )
//                     : Icon(
//                         LucideIcons.refreshCw,
//                         key: const ValueKey('icon'),
//                         size: 20,
//                         color: isDark
//                             ? AppColors.darkTextPrimary
//                             : AppColors.textPrimaryDark,
//                       ),
//               ),
//               onPressed: provider.isLoading
//                   ? null
//                   : () => context.read<OrdersProvider>().fetchOrders(),
//             ),
//           ),
//           const SizedBox(width: 4),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Divider(
//             height: 1,
//             color: isDark ? AppColors.darkBorder : AppColors.dividerGrey,
//           ),
//         ),
//       ),
//       body: Consumer<OrdersProvider>(
//         builder: (context, provider, _) {
//           // ── 1. First load → shimmer skeleton ─────────────────
//           if (provider.isLoading && provider.orders.isEmpty) {
//             return _buildShimmer(isDark);
//           }

//           // ── 2. Error (no cached data) ─────────────────────────
//           if (provider.error != null && provider.orders.isEmpty) {
//             return _buildError(context, provider, isDark);
//           }

//           // ── 3. Empty (authenticated, fetch succeeded, 0 orders)
//           if (provider.orders.isEmpty) {
//             return _buildEmpty(context, isDark);
//           }

//           // ── 4. Data ───────────────────────────────────────────
//           return RefreshIndicator(
//             color: AppColors.primary,
//             backgroundColor:
//                 isDark ? AppColors.darkSurface : Colors.white,
//             strokeWidth: 2.5,
//             onRefresh: provider.fetchOrders,
//             child: isDesktop
//                 ? _buildGrid(context, provider, isDark)
//                 : _buildList(context, provider, isDark),
//           );
//         },
//       ),
//     );
//   }

//   // ─── List (mobile) ───────────────────────────────────────────
//   Widget _buildList(
//     BuildContext context,
//     OrdersProvider provider,
//     bool isDark,
//   ) {
//     return ListView.builder(
//       physics: const AlwaysScrollableScrollPhysics(),
//       padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
//       itemCount: provider.orders.length,
//       itemBuilder: (_, i) => OrderCard(
//         order: provider.orders[i],
//         onTap: () => Navigator.of(context)
//             .pushNamed('/order-detail', arguments: provider.orders[i]),
//       ),
//     );
//   }

//   // ─── Grid (desktop/tablet) ───────────────────────────────────
//   Widget _buildGrid(
//     BuildContext context,
//     OrdersProvider provider,
//     bool isDark,
//   ) {
//     return GridView.builder(
//       physics: const AlwaysScrollableScrollPhysics(),
//       padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
//       gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
//         maxCrossAxisExtent: 480,
//         childAspectRatio: 1.85,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 0,
//       ),
//       itemCount: provider.orders.length,
//       itemBuilder: (_, i) => OrderCard(
//         order: provider.orders[i],
//         onTap: () => Navigator.of(context)
//             .pushNamed('/order-detail', arguments: provider.orders[i]),
//       ),
//     );
//   }

//   // ─── Empty state ─────────────────────────────────────────────
//   Widget _buildEmpty(BuildContext context, bool isDark) {
//     // Wrap in a scrollable so the RefreshIndicator still works when empty
//     return SingleChildScrollView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       child: SizedBox(
//         height: MediaQuery.of(context).size.height - kToolbarHeight - 120,
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Animated icon
//                 TweenAnimationBuilder<double>(
//                   tween: Tween(begin: 0, end: 1),
//                   duration: const Duration(milliseconds: 700),
//                   curve: Curves.elasticOut,
//                   builder: (_, v, child) =>
//                       Transform.scale(scale: v, child: child),
//                   child: Container(
//                     width: 130,
//                     height: 130,
//                     decoration: BoxDecoration(
//                       color: AppColors.primary.withValues(alpha: 0.10),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       LucideIcons.packageX,
//                       size: 54,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 28),

//                 Text(
//                   'No orders yet',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w800,
//                     color: isDark
//                         ? AppColors.darkTextPrimary
//                         : AppColors.textPrimaryDark,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   'Your completed orders will appear here.\nBrowse and place your first order!',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14,
//                     height: 1.6,
//                     color: AppColors.textMuted,
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // ── Start Shopping CTA ──────────────────────
//                 SizedBox(
//                   height: 50,
//                   child: DecoratedBox(
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFFFFD700), Color(0xFFFFC200)],
//                       ),
//                       borderRadius: BorderRadius.circular(14),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.primary.withValues(alpha: 0.35),
//                           blurRadius: 14,
//                           offset: const Offset(0, 6),
//                         ),
//                       ],
//                     ),
//                     child: ElevatedButton.icon(
//                       onPressed: () => Navigator.of(context)
//                           .pushNamedAndRemoveUntil(
//                               '/home', (r) => false),
//                       icon: const Icon(
//                         LucideIcons.shoppingBag,
//                         color: Colors.white,
//                         size: 18,
//                       ),
//                       label: const Text(
//                         'Start Shopping',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w800,
//                           fontSize: 15,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         minimumSize: const Size(220, 50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ─── Error state ─────────────────────────────────────────────
//   Widget _buildError(
//     BuildContext context,
//     OrdersProvider provider,
//     bool isDark,
//   ) {
//     final isAuthError =
//         provider.error?.toLowerCase().contains('not logged in') == true;

//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 32),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: AppColors.errorRed.withValues(alpha: 0.10),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isAuthError
//                     ? LucideIcons.lockKeyhole
//                     : LucideIcons.cloudOff,
//                 size: 34,
//                 color: AppColors.errorRed,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               isAuthError ? 'Session Expired' : 'Something went wrong',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w800,
//                 color: isDark
//                     ? AppColors.darkTextPrimary
//                     : AppColors.textPrimaryDark,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               isAuthError
//                   ? 'Please log in again to view your orders.'
//                   : (provider.error ?? 'Could not load orders.'),
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 13,
//                 height: 1.5,
//                 color: AppColors.textMuted,
//               ),
//             ),
//             const SizedBox(height: 28),
//             if (isAuthError)
//               ElevatedButton.icon(
//                 onPressed: () => Navigator.of(context)
//                     .pushNamedAndRemoveUntil('/login', (r) => false),
//                 icon: const Icon(LucideIcons.logIn, size: 16),
//                 label: const Text('Log In'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               )
//             else
//               OutlinedButton.icon(
//                 onPressed: provider.fetchOrders,
//                 icon: const Icon(LucideIcons.refreshCw, size: 16),
//                 label: const Text('Try Again'),
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: AppColors.primary,
//                   side: const BorderSide(color: AppColors.primary),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─── Shimmer skeleton ────────────────────────────────────────
//   Widget _buildShimmer(bool isDark) {
//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
//       itemCount: 5,
//       itemBuilder: (_, __) => _OrderShimmer(isDark: isDark),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// /// Animated shimmer skeleton that mirrors the real OrderCard structure.
// class _OrderShimmer extends StatefulWidget {
//   final bool isDark;
//   const _OrderShimmer({required this.isDark});

//   @override
//   State<_OrderShimmer> createState() => _OrderShimmerState();
// }

// class _OrderShimmerState extends State<_OrderShimmer>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _ctrl;
//   late Animation<double> _anim;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);
//     _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final base = widget.isDark ? AppColors.darkSurface : Colors.white;
//     final pulse = widget.isDark ? AppColors.darkBorder : AppColors.dividerGrey;

//     return AnimatedBuilder(
//       animation: _anim,
//       builder: (_, __) {
//         final shimmerColor = Color.lerp(pulse, base, _anim.value)!;
//         return Container(
//           margin: const EdgeInsets.only(bottom: 14),
//           padding: const EdgeInsets.all(18),
//           decoration: BoxDecoration(
//             color: base,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: widget.isDark
//                   ? AppColors.darkBorder
//                   : AppColors.borderLight,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header row: icon box + title lines + badge
//               Row(
//                 children: [
//                   _ShimmerBox(w: 40, h: 40, r: 11, color: shimmerColor),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _ShimmerBox(w: 130, h: 13, r: 6, color: shimmerColor),
//                         const SizedBox(height: 6),
//                         _ShimmerBox(w: 90, h: 10, r: 5, color: shimmerColor),
//                       ],
//                     ),
//                   ),
//                   _ShimmerBox(w: 72, h: 24, r: 6, color: shimmerColor),
//                 ],
//               ),
//               const SizedBox(height: 14),
//               // Sub-row: payment label + total
//               Row(
//                 children: [
//                   _ShimmerBox(w: 80, h: 10, r: 5, color: shimmerColor),
//                   const Spacer(),
//                   _ShimmerBox(w: 64, h: 14, r: 5, color: shimmerColor),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// /// Rounded rectangle placeholder block used inside the shimmer.
// class _ShimmerBox extends StatelessWidget {
//   final double w, h, r;
//   final Color color;
//   const _ShimmerBox({
//     required this.w,
//     required this.h,
//     required this.r,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//         width: w,
//         height: h,
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(r),
//         ),
//       );
// }


import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:e_commerce/data/models/order_model.dart'; // تأكد من استيراد الموديل
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/data/providers/orders_provider.dart';
import 'package:e_commerce/features/orders/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class MyOrdersScreen extends StatefulWidget {
  final String? highlightOrderId; // لاستقبال الأوردر الجديد من التتبع
  
  const MyOrdersScreen({super.key, this.highlightOrderId});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _fetchedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fetchedOnce) return;

    final auth = context.watch<AuthProvider>();

    // الانتظار حتى ينتهي الـ Auth من تحميل التوكن
    if (!auth.isInitialized) return;

    _fetchedOnce = true;
    Future.microtask(() async {
      if (mounted) {
        await context.read<OrdersProvider>().fetchOrders();
        
        // إذا كان هناك أوردر نريد تتبعه فور الدخول
        if (widget.highlightOrderId != null && mounted) {
          _navigateToSpecificOrder(widget.highlightOrderId!);
        }
      }
    });
  }

  void _navigateToSpecificOrder(String orderId) {
    final provider = context.read<OrdersProvider>();
    final order = provider.orders.cast<Order?>().firstWhere(
      (o) => o?.id == orderId,
      orElse: () => null,
    );

    if (order != null) {
      Navigator.of(context).pushNamed('/order-detail', arguments: order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = R.isDesktop(context) || R.isTablet(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkAppBar : Colors.white,
        // elevation: 0,
        // leading: IconButton(
        //   icon: Icon(
        //     LucideIcons.arrowLeft,
        //     color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
        //   ),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        // title: Text(
        //   'My Orders',
        //   style: TextStyle(
        //     fontSize: 18,
        //     fontWeight: FontWeight.w800,
        //     color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
        //   ),
        // ),
        actions: [
          Consumer<OrdersProvider>(
            builder: (_, provider, __) => IconButton(
              tooltip: 'Refresh orders',
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: provider.isLoading
                    ? SizedBox(
                        key: const ValueKey('spin'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                        ),
                      )
                    : Icon(
                        LucideIcons.refreshCw,
                        key: const ValueKey('icon'),
                        size: 20,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                      ),
              ),
              onPressed: provider.isLoading
                  ? null
                  : () => context.read<OrdersProvider>().fetchOrders(),
            ),
          ),
          const SizedBox(width: 4),
        ],
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(1),
        //   child: Divider(
        //     height: 1,
        //     color: isDark ? AppColors.darkBorder : AppColors.dividerGrey,
        //   ),
        // ),
      ),
      body: Consumer<OrdersProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return _buildShimmer(isDark);
          }

          if (provider.error != null && provider.orders.isEmpty) {
            return _buildError(context, provider, isDark);
          }

          if (provider.orders.isEmpty) {
            return _buildEmpty(context, isDark);
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            strokeWidth: 2.5,
            onRefresh: provider.fetchOrders,
            child: isDesktop
                ? _buildGrid(context, provider, isDark)
                : _buildList(context, provider, isDark),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, OrdersProvider provider, bool isDark) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      itemCount: provider.orders.length,
      itemBuilder: (_, i) => OrderCard(
        order: provider.orders[i],
        onTap: () => Navigator.of(context)
            .pushNamed('/order-detail', arguments: provider.orders[i]),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, OrdersProvider provider, bool isDark) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 480,
        childAspectRatio: 1.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 0,
      ),
      itemCount: provider.orders.length,
      itemBuilder: (_, i) => OrderCard(
        order: provider.orders[i],
        onTap: () => Navigator.of(context)
            .pushNamed('/order-detail', arguments: provider.orders[i]),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - kToolbarHeight - 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.packageX, size: 54, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'No orders yet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your completed orders will appear here.\nBrowse and place your first order!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textMuted),
                ),
                const SizedBox(height: 32),
                _buildCTAButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCTAButton(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFC200)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
          icon: const Icon(LucideIcons.shoppingBag, color: Colors.white, size: 18),
          label: const Text(
            'Start Shopping',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size(220, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, OrdersProvider provider, bool isDark) {
    final isAuthError = provider.error?.toLowerCase().contains('not logged in') == true;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAuthError ? LucideIcons.lockKeyhole : LucideIcons.cloudOff,
                size: 34,
                color: AppColors.errorRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAuthError ? 'Session Expired' : 'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAuthError ? 'Please log in again to view your orders.' : (provider.error ?? 'Could not load orders.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 28),
            if (isAuthError)
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false),
                icon: const Icon(LucideIcons.logIn, size: 16),
                label: const Text('Log In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: provider.fetchOrders,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: 5,
      itemBuilder: (_, __) => _OrderShimmer(isDark: isDark),
    );
  }
}

// ─── Shimmer Component ───────────────────────────────────────────────────────
class _OrderShimmer extends StatefulWidget {
  final bool isDark;
  const _OrderShimmer({required this.isDark});
  @override
  State<_OrderShimmer> createState() => _OrderShimmerState();
}

class _OrderShimmerState extends State<_OrderShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? AppColors.darkSurface : Colors.white;
    final pulse = widget.isDark ? AppColors.darkBorder : AppColors.dividerGrey;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmerColor = Color.lerp(pulse, base, _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.isDark ? AppColors.darkBorder : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ShimmerBox(w: 40, h: 40, r: 11, color: shimmerColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(w: 130, h: 13, r: 6, color: shimmerColor),
                        const SizedBox(height: 6),
                        _ShimmerBox(w: 90, h: 10, r: 5, color: shimmerColor),
                      ],
                    ),
                  ),
                  _ShimmerBox(w: 72, h: 24, r: 6, color: shimmerColor),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ShimmerBox(w: 80, h: 10, r: 5, color: shimmerColor),
                  const Spacer(),
                  _ShimmerBox(w: 64, h: 14, r: 5, color: shimmerColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  
  final double w, h, r;
  final Color color;
  const _ShimmerBox({required this.w, required this.h, required this.r, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)),
  );
}