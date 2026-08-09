import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/invoice.dart';
import 'branch_provider.dart';
import 'core_providers.dart';

class InvoicesState {
  final List<Invoice> invoices;
  final int total;
  final int page;
  final String search;
  final String? statusFilter;
  final bool loading;
  final bool loadingMore;
  final String? error;

  const InvoicesState({
    this.invoices = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.statusFilter,
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  bool get hasMore => invoices.length < total;

  InvoicesState copyWith({
    List<Invoice>? invoices,
    int? total,
    int? page,
    String? search,
    String? statusFilter,
    bool clearStatusFilter = false,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) {
    return InvoicesState(
      invoices: invoices ?? this.invoices,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class InvoicesNotifier extends StateNotifier<InvoicesState> {
  final Ref ref;
  static const _limit = 20;

  InvoicesNotifier(this.ref) : super(const InvoicesState());

  Future<void> search(String query) async {
    state = state.copyWith(search: query);
    await refresh();
  }

  Future<void> setStatusFilter(String? status) async {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, page: 1, clearError: true);
    try {
      final branchId = ref.read(branchProvider).activeBranch?.id;
      final res = await ref.read(billingApiProvider).listInvoices(
            page: 1,
            limit: _limit,
            search: state.search,
            status: state.statusFilter,
            branchId: branchId,
          );
      final data = res.data;
      final list = (data?['data'] as List? ?? const [])
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        invoices: list,
        total: (data?['total'] as num?)?.toInt() ?? list.length,
        page: 1,
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Failed to load invoices');
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final nextPage = state.page + 1;
      final branchId = ref.read(branchProvider).activeBranch?.id;
      final res = await ref.read(billingApiProvider).listInvoices(
            page: nextPage,
            limit: _limit,
            search: state.search,
            status: state.statusFilter,
            branchId: branchId,
          );
      final data = res.data;
      final list = (data?['data'] as List? ?? const [])
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(invoices: [...state.invoices, ...list], page: nextPage, loadingMore: false);
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}

final invoicesListProvider =
    StateNotifierProvider.autoDispose<InvoicesNotifier, InvoicesState>((ref) => InvoicesNotifier(ref));

/// Invoices scoped to a single patient — used on the patient detail screen.
final patientInvoicesProvider =
    FutureProvider.autoDispose.family<List<Invoice>, String>((ref, patientId) async {
  final res = await ref.read(billingApiProvider).listInvoices(patientId: patientId, limit: 50);
  final data = res.data;
  final list = (data?['data'] as List? ?? const []);
  return list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
});