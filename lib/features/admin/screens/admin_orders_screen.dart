import 'package:dealio/data/providers/orders_provider.dart';
import 'package:dealio/features/admin/widgets/orders_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Standalone screen that hosts [OrdersContent].
///
/// Accessible via the `/admin/orders` named route (protected by [GuardedRoute]
/// in main.dart) AND via the sidebar (pageIndex 12).
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-fetch orders so the table is populated immediately on mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrdersProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: OrdersContent(),
    );
  }
}
