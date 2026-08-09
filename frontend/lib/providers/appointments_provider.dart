import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/appointment.dart';
import 'branch_provider.dart';
import 'core_providers.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');

class AppointmentsListState {
  final List<Appointment> appointments;
  final DateTime selectedDate;
  final bool loading;
  final String? error;

  const AppointmentsListState({
    this.appointments = const [],
    required this.selectedDate,
    this.loading = false,
    this.error,
  });

  AppointmentsListState copyWith({
    List<Appointment>? appointments,
    DateTime? selectedDate,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AppointmentsListState(
      appointments: appointments ?? this.appointments,
      selectedDate: selectedDate ?? this.selectedDate,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Loads appointments for a single selected day (from == to), sorted
/// ascending — the mobile equivalent of the web app's day/list view.
class AppointmentsListNotifier extends StateNotifier<AppointmentsListState> {
  final Ref ref;

  AppointmentsListNotifier(this.ref)
      : super(AppointmentsListState(selectedDate: DateTime.now()));

  Future<void> setDate(DateTime date) async {
    state = state.copyWith(selectedDate: date);
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final branchId = ref.read(branchProvider).activeBranch?.id;
      final dateStr = _dateFmt.format(state.selectedDate);
      final res = await ref.read(appointmentsApiProvider).list(
            branchId: branchId,
            from: dateStr,
            to: dateStr,
            limit: 200,
            order: 'ASC',
          );
      final data = res.data;
      List rawList;
      if (data is List) {
        rawList = data;
      } else {
        rawList = (data?['data'] as List?) ?? const [];
      }
      final list = rawList.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(appointments: list, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Failed to load appointments');
    }
  }
}

final appointmentsListProvider =
    StateNotifierProvider.autoDispose<AppointmentsListNotifier, AppointmentsListState>(
        (ref) => AppointmentsListNotifier(ref));