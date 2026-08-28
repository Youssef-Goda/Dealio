import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Counts the active orders ('pending' or 'processing') for a given user.
  /// Admins, owners and moderators skip this check entirely.
  /// If the count is 3 or more, it throws a user-friendly exception in English.
  Future<void> verifyActiveOrderLimit(String userId, {String userRole = 'user'}) async {
    try {
      if (userId.isEmpty) {
        throw Exception("User ID is empty. Please log in first.");
      }

      // Privileged roles (admin, owner, moderator) are not subject to the limit
      final role = userRole.toLowerCase().trim();
      if (role == 'admin' || role == 'owner' || role == 'moderator' || role == 'super_admin') {
        return; // Skip check
      }

      // Query the orders table for orders of this user that are pending or processing
      final response = await _client
          .from('orders')
          .select('id')
          .eq('user_id', userId)
          .inFilter('status', ['pending', 'processing']);

      final List<dynamic> data = response as List<dynamic>;
      final int activeCount = data.length;

      if (activeCount >= 3) {
        throw Exception(
          "Sorry, you have active orders in progress. Please wait until they are delivered first.",
        );
      }
    } catch (e) {
      // Re-throw our custom limit validation exception directly
      if (e.toString().contains("delivered first")) {
        rethrow;
      }
      throw Exception("Failed to check active orders: $e");
    }
  }
}
