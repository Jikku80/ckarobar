import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/patient_file.dart';
import 'core_providers.dart';

class PatientFilesState {
  final List<PatientFile> files;
  final bool loading;
  final bool uploading;
  final String? error;

  const PatientFilesState({
    this.files = const [],
    this.loading = false,
    this.uploading = false,
    this.error,
  });

  PatientFilesState copyWith({
    List<PatientFile>? files,
    bool? loading,
    bool? uploading,
    String? error,
    bool clearError = false,
  }) {
    return PatientFilesState(
      files: files ?? this.files,
      loading: loading ?? this.loading,
      uploading: uploading ?? this.uploading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PatientFilesNotifier extends StateNotifier<PatientFilesState> {
  final Ref ref;
  final String patientId;

  PatientFilesNotifier(this.ref, this.patientId) : super(const PatientFilesState());

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final res = await ref.read(filesApiProvider).list(patientId);
      final data = res.data;
      final list = data is List ? data : (data?['data'] as List? ?? const []);
      state = state.copyWith(
        files: list.map((e) => PatientFile.fromJson(e as Map<String, dynamic>)).toList(),
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Failed to load files');
    }
  }

  Future<bool> upload({required String filePath, required String fileName, required String category}) async {
    state = state.copyWith(uploading: true, clearError: true);
    try {
      await ref.read(filesApiProvider).upload(
            patientId,
            filePath: filePath,
            fileName: fileName,
            category: category,
          );
      state = state.copyWith(uploading: false);
      await refresh();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(uploading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(uploading: false, error: 'Upload failed');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await ref.read(filesApiProvider).delete(id);
      state = state.copyWith(files: state.files.where((f) => f.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final patientFilesProvider = StateNotifierProvider.autoDispose
    .family<PatientFilesNotifier, PatientFilesState, String>(
        (ref, patientId) => PatientFilesNotifier(ref, patientId));