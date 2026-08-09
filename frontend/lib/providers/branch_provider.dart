import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branch.dart';
import '../models/user.dart';
import 'core_providers.dart';

class BranchState {
  final List<Branch> branches;
  final Branch? activeBranch;

  const BranchState({this.branches = const [], this.activeBranch});

  BranchState copyWith({List<Branch>? branches, Branch? activeBranch, bool clearActive = false}) {
    return BranchState(
      branches: branches ?? this.branches,
      activeBranch: clearActive ? null : (activeBranch ?? this.activeBranch),
    );
  }
}

/// Mirrors setBranches / setActiveBranch in dentaldb/store/auth.store.ts:
///  1. Single-branch non-owner: always locked to that one branch.
///  2. Multi-branch or owner: keep the persisted active branch if it's
///     still present, active, and not locked; otherwise fall back to the
///     first active branch.
///  3. Locked / inactive branches cannot be set as the active context.
class BranchNotifier extends StateNotifier<BranchState> {
  final Ref ref;
  BranchNotifier(this.ref) : super(const BranchState());

  static const _ownerRoles = {UserRole.owner, UserRole.superAdmin};

  Future<void> loadForUser(AppUser user, {String? persistedActiveBranchId}) async {
    try {
      List<Branch> accessible;
      if (_ownerRoles.contains(user.role)) {
        final res = await ref.read(branchesApiProvider).list();
        accessible = _parseBranchList(res.data);
      } else {
        try {
          final res = await ref.read(branchesApiProvider).myBranches();
          accessible = _parseBranchList(res.data);
        } catch (_) {
          final allRes = await ref.read(branchesApiProvider).list();
          final all = _parseBranchList(allRes.data);
          accessible = all
              .where((b) => b.staff?.any((s) => s.id == user.id) ?? false)
              .toList();
          if (accessible.isEmpty) accessible = all;
        }
      }
      _applyBranches(accessible, user, persistedActiveBranchId: persistedActiveBranchId);
    } catch (_) {
      // Preserve any existing (possibly stale) non-empty list rather than
      // wiping it on a transient failure — same guard as AuthProvider.tsx.
      if (state.branches.isEmpty) state = state.copyWith(branches: []);
    }
  }

  List<Branch> _parseBranchList(dynamic data) {
    if (data is List) {
      return data.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Branch.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  void _applyBranches(List<Branch> branches, AppUser user, {String? persistedActiveBranchId}) {
    final isOwner = _ownerRoles.contains(user.role);

    if (!isOwner && branches.length == 1) {
      state = state.copyWith(branches: branches, activeBranch: branches.first);
      return;
    }

    final currentId = state.activeBranch?.id ?? persistedActiveBranchId;
    Branch? stillValid;
    if (currentId != null) {
      for (final b in branches) {
        if (b.id == currentId && b.isActive && !b.isLocked) {
          stillValid = b;
          break;
        }
      }
    }

    if (stillValid != null) {
      state = state.copyWith(branches: branches, activeBranch: stillValid);
      return;
    }

    Branch? firstActive;
    for (final b in branches) {
      if (b.isActive && !b.isLocked) {
        firstActive = b;
        break;
      }
    }
    state = state.copyWith(branches: branches, activeBranch: firstActive, clearActive: firstActive == null);
  }

  /// Explicit user-driven switch (BranchSwitcher). Refuses locked/inactive
  /// branches and single-branch-locked non-owners, same as the web app.
  bool setActiveBranch(Branch branch, AppUser user) {
    final isOwner = _ownerRoles.contains(user.role);
    if (!isOwner && state.branches.length == 1) return false;
    if (branch.isLocked || !branch.isActive) return false;
    state = state.copyWith(activeBranch: branch);
    return true;
  }

  void reset() => state = const BranchState();
}

final branchProvider = StateNotifierProvider<BranchNotifier, BranchState>((ref) => BranchNotifier(ref));
