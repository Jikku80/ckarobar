import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../models/clinic.dart';
import '../models/user.dart';
import 'branch_provider.dart';
import 'core_providers.dart';
import 'permissions_provider.dart';

enum AuthStatus { bootstrapping, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final Clinic? clinic;
  final String? error;

  const AuthState({required this.status, this.user, this.clinic, this.error});

  const AuthState.bootstrapping() : this(status: AuthStatus.bootstrapping);
  const AuthState.unauthenticated({String? error})
      : this(status: AuthStatus.unauthenticated, error: error);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Mirrors contexts/AuthProvider.tsx: on cold start, verify the session via
/// /auth/me (falling back to /auth/refresh + /auth/me once), then load
/// permissions and branches, then start a silent refresh timer. login()
/// mirrors the login page's onSubmit flow.
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  Timer? _refreshTimer;

  AuthNotifier(this.ref) : super(const AuthState.bootstrapping()) {
    ref.read(apiClientProvider).onSessionExpired = _forceLogout;
  }

  Future<void> bootstrap() async {
    final localStore = ref.read(localStoreProvider);
    try {
      final res = await ref.read(authApiProvider).me();
      await _onVerified(res.data);
      return;
    } on ApiException catch (e) {
      if (e.isRateLimited) {
        state = const AuthState.unauthenticated();
        await localStore.setWasAuthenticated(false);
        return;
      }
      // Fall through to refresh+retry, like the web app.
    } catch (_) {
      // fall through
    }

    try {
      await ref.read(authApiProvider).refresh();
      final res = await ref.read(authApiProvider).me();
      await _onVerified(res.data);
    } catch (_) {
      state = const AuthState.unauthenticated();
      await localStore.setWasAuthenticated(false);
    }
  }

  Future<void> _onVerified(dynamic data) async {
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    final clinic =
        data['clinic'] != null ? Clinic.fromJson(data['clinic'] as Map<String, dynamic>) : null;
    state = AuthState(status: AuthStatus.authenticated, user: user, clinic: clinic);

    final perms = data['permissions'];
    if (perms is List) {
      ref.read(permissionsProvider.notifier).setAll(perms.cast<String>());
    } else {
      await ref.read(permissionsProvider.notifier).load();
    }

    final localStore = ref.read(localStoreProvider);
    await localStore.setWasAuthenticated(true);
    final persistedBranchId = await localStore.getActiveBranchId();
    await ref.read(branchProvider.notifier).loadForUser(user, persistedActiveBranchId: persistedBranchId);

    _startRefreshTimer();
  }

  Future<void> login({required String email, required String password}) async {
    final res = await ref.read(authApiProvider).login(email: email, password: password);
    final data = res.data as Map<String, dynamic>;
    await _onVerified(data);
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    try {
      await ref.read(authApiProvider).logout();
    } catch (_) {
      // Best-effort — clear local state regardless.
    }
    await _clearLocalSession();
  }

  Future<void> _forceLogout() async {
    _refreshTimer?.cancel();
    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    ref.read(permissionsProvider.notifier).clear();
    ref.read(branchProvider.notifier).reset();
    await ref.read(localStoreProvider).setWasAuthenticated(false);
    await ref.read(apiClientProvider).clearCookies();
    state = const AuthState.unauthenticated();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppConfig.refreshInterval, (_) async {
      try {
        await ref.read(authApiProvider).refresh();
        await ref.read(permissionsProvider.notifier).load();
      } on ApiException catch (e) {
        if (e.isUnauthorized || e.isForbidden) {
          await _forceLogout();
        }
        // 429 / network errors: skip this cycle, next interval retries.
      } catch (_) {
        // ignore — retry next cycle
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));
