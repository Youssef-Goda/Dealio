import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user's favorites / wishlist.
/// State is persisted locally via SharedPreferences so it survives restarts.
class WishlistProvider with ChangeNotifier {
  static const _key = 'wishlist_product_ids';

  final Set<String> _ids = {};

  /// Immutable snapshot of favorited product IDs.
  Set<String> get ids => Set.unmodifiable(_ids);

  int get count => _ids.length;

  bool isFavorite(String productId) => _ids.contains(productId);

  // ─── Persistence ──────────────────────────────────────────────────────────

  /// Call once at startup (e.g. in main.dart or lazily on first use).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? [];
    _ids
      ..clear()
      ..addAll(stored);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ids.toList());
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> toggle(String productId) async {
    if (_ids.contains(productId)) {
      _ids.remove(productId);
    } else {
      _ids.add(productId);
    }
    notifyListeners();
    await _save();
  }

  Future<void> add(String productId) async {
    if (_ids.add(productId)) {
      notifyListeners();
      await _save();
    }
  }

  Future<void> remove(String productId) async {
    if (_ids.remove(productId)) {
      notifyListeners();
      await _save();
    }
  }

  Future<void> clear() async {
    _ids.clear();
    notifyListeners();
    await _save();
  }

  // ─── Sync on login ────────────────────────────────────────────────────────

  /// Called after a successful login to persist any locally-favourited IDs.
  /// [userId] is accepted to match call-sites but is not needed for local
  /// SharedPreferences storage.
  Future<void> syncGuestWishlist(String userId) async {
    // The local set already holds guest favourites — just persist so they
    // survive the next restart after the user logs in.
    await _save();
  }

  // ─── Alias ────────────────────────────────────────────────────────────────

  /// Alias for [toggle] – used by screens that reference `toggleFavorite`.
  Future<void> toggleFavorite(String productId) => toggle(productId);
}
