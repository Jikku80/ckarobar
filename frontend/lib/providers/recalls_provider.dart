import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/recall.dart';
import 'branch_provider.dart';
import 'core_providers.dart';

class RecallsState {
  final RecallGroups groups;
  final RecallStats stats;
  final bool loading;
  final String? error;

  const RecallsState({
    this.groups = const RecallGroups(),
    this.stats = const RecallStats(),
    this.loading = false,
    this.error,
  });

  RecallsState copyWith({
    RecallGroups? groups,
    RecallStats? stats,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return RecallsState(
      groups: groups ?? this.groups,
      stats: stats ?? this.stats,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RecallsNotifier extends StateNotifier<RecallsState> {
  final Ref ref;
  RecallsNotifier(this.ref) : super(const RecallsState());

  Future<void> refresh() async {
    final branchId = ref.read(branchProvider).activeBranch?.id;
    if (branchId == null) {
      state = state.copyWith(groups: const RecallGroups(), stats: const RecallStats());
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(recallsApiProvider);
      final results = await Future.wait([
        api.list(branchId: branchId),
        api.stats(branchId: branchId),
      ]);
      final groups = RecallGroups.fromJson(results[0].data as Map<String, dynamic>);
      final stats = RecallStats.fromJson(results[1].data as Map<String, dynamic>);
      state = state.copyWith(groups: groups, stats: stats, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Failed to load recalls');
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await ref.read(recallsApiProvider).create(data);
    await refresh();
  }

  Future<void> markContacted(String id) async {
    await ref.read(recallsApiProvider).update(id, {'status': 'contacted'});
    await refresh();
  }

  Future<void> cancel(String id) async {
    await ref.read(recallsApiProvider).update(id, {'status': 'cancelled'});
    await refresh();
  }

  Future<void> sendNow(String id) => ref.read(recallsApiProvider).sendNow(id);

  Future<void> bookAppointment(String id, Map<String, dynamic> data) async {
    await ref.read(recallsApiProvider).createAppointment(id, data);
    await refresh();
  }
}

final recallsProvider =
    StateNotifierProvider.autoDispose<RecallsNotifier, RecallsState>((ref) => RecallsNotifier(ref));

/// Recalls scoped to a single patient — used on the patient detail screen.
final patientRecallsProvider =
    FutureProvider.autoDispose.family<List<Recall>, String>((ref, patientId) async {
  final res = await ref.read(recallsApiProvider).byPatient(patientId);
  final list = res.data is List ? res.data as List : (res.data?['data'] as List? ?? const []);
  return list.map((e) => Recall.fromJson(e as Map<String, dynamic>)).toList();
});