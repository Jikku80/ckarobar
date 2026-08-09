import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/patient.dart';
import 'branch_provider.dart';
import 'core_providers.dart';

class PatientsListState {
  final List<Patient> patients;
  final int total;
  final int page;
  final String search;
  final bool loading;
  final bool loadingMore;
  final String? error;

  const PatientsListState({
    this.patients = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  bool get hasMore => patients.length < total;

  PatientsListState copyWith({
    List<Patient>? patients,
    int? total,
    int? page,
    String? search,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) {
    return PatientsListState(
      patients: patients ?? this.patients,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PatientsListNotifier extends StateNotifier<PatientsListState> {
  final Ref ref;
  static const _limit = 20;

  PatientsListNotifier(this.ref) : super(const PatientsListState());

  Future<void> search(String query) async {
    state = state.copyWith(search: query);
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, page: 1, clearError: true);
    try {
      final branchId = ref.read(branchProvider).activeBranch?.id;
      final res = await ref.read(patientsApiProvider).list(
            page: 1,
            limit: _limit,
            search: state.search,
            branchId: branchId,
          );
      final data = res.data;
      final list = (data?['data'] as List? ?? const [])
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        patients: list,
        total: (data?['total'] as num?)?.toInt() ?? list.length,
        page: 1,
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Failed to load patients');
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final nextPage = state.page + 1;
      final branchId = ref.read(branchProvider).activeBranch?.id;
      final res = await ref.read(patientsApiProvider).list(
            page: nextPage,
            limit: _limit,
            search: state.search,
            branchId: branchId,
          );
      final data = res.data;
      final list = (data?['data'] as List? ?? const [])
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        patients: [...state.patients, ...list],
        page: nextPage,
        loadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}

final patientsListProvider =
    StateNotifierProvider.autoDispose<PatientsListNotifier, PatientsListState>(
        (ref) => PatientsListNotifier(ref));