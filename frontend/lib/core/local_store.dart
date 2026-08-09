import 'package:shared_preferences/shared_preferences.dart';

/// Persists small bits of non-sensitive UI state locally, mirroring what
/// zustand's `persist` middleware does for auth.store.ts / UILayout.store.ts
/// on the web app (the actual session lives in the HttpOnly cookie — this
/// is just enough to fast-path "was probably logged in" on cold start and
/// to remember the user's last-selected branch).
class LocalStore {
  static const _kWasAuthenticated = 'was_authenticated';
  static const _kActiveBranchId = 'active_branch_id';

  Future<bool> getWasAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWasAuthenticated) ?? false;
  }

  Future<void> setWasAuthenticated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWasAuthenticated, value);
  }

  Future<String?> getActiveBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kActiveBranchId);
  }

  Future<void> setActiveBranchId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_kActiveBranchId);
    } else {
      await prefs.setString(_kActiveBranchId, id);
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWasAuthenticated);
    await prefs.remove(_kActiveBranchId);
  }
}
