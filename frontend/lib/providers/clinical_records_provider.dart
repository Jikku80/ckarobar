import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/clinical_record.dart';
import 'core_providers.dart';

class ClinicalRecordsState {
  final List<ClinicalRecord> records;
  final int total;
  final int page;
  final String search;
  final bool loading;
  final bool loadingMore;
  final String? error;

  const ClinicalRecordsState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  bool get hasMore => records.length < total;

  ClinicalRecordsState copyWith({
    List<ClinicalRecord>? records,
    int? total,
    int? page,
    String? search,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) {
    return ClinicalRecordsState(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ClinicalRecordsNotifier extends StateNotifier<ClinicalRecordsState> {
  final Ref ref;
  static const _limit = 20;

  ClinicalRecordsNotifier(this.ref) : super(const ClinicalRecordsState());

  Future<void> search(String query) async {
    state = state.copyWith(search: query);
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, page: 1, clearError: true);
    try {
      final res = await ref
          .read(clinicalRecordsApiProvider)
          .list(page: 1, limit: _limit, search: state.search);
      final data = res.data;
      final list = (data?['data'] as List? ?? const [])
          .map((e) => ClinicalRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        records: list,
        total: (data?['total'] as num?)?.toInt() ?? list.length,
        page: 1,
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Failed to load clinical records');
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final nextPage = state.page + 1;
      final res = await ref
          .read(clinicalRecordsApiProvider)
          .list(page: nextPage, limit: _limit, search: state.search);
      final data = res.data;
      final list = (data?['data'] as List? ?? const [])
          .map((e) => ClinicalRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(records: [...state.records, ...list], page: nextPage, loadingMore: false);
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}

final clinicalRecordsListProvider =
    StateNotifierProvider.autoDispose<ClinicalRecordsNotifier, ClinicalRecordsState>(
        (ref) => ClinicalRecordsNotifier(ref));

/// Records scoped to a single patient — used on the patient detail screen.
final patientClinicalRecordsProvider =
    FutureProvider.autoDispose.family<List<ClinicalRecord>, String>((ref, patientId) async {
  final res = await ref.read(clinicalRecordsApiProvider).list(patientId: patientId, limit: 50);
  final data = res.data;
  final list = (data?['data'] as List? ?? const []);
  return list.map((e) => ClinicalRecord.fromJson(e as Map<String, dynamic>)).toList();
});