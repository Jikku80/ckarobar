import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';

/// Thrown when the API returns an error response. Mirrors the shape you'd
/// get from an AxiosError's `err.response` on the web app.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic data;

  ApiException({this.statusCode, required this.message, this.data});

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Mirrors dentaldb/lib/api.ts:
///  - withCredentials-equivalent session via a persisted CookieJar (the
///    backend sets HttpOnly auth cookies on /auth/login; PersistCookieJar
///    keeps them across app restarts, same effect as the browser's cookie
///    jar for the web app).
///  - Auto-refresh-on-401 with request queueing while a refresh is in
///    flight, so concurrent 401s don't all hammer /auth/refresh at once.
class ApiClient {
  late final Dio dio;
  late final PersistCookieJar _cookieJar;
  bool _cookieJarReady = false;

  bool _isRefreshing = false;
  final List<Completer<void>> _refreshWaiters = [];

  /// Called when a refresh attempt fails with 401/403 (i.e. the session is
  /// genuinely gone) — the UI should route back to the login screen.
  void Function()? onSessionExpired;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        // We handle non-2xx ourselves via ApiException instead of Dio's
        // default throw-on-any-non-2xx, so callers get consistent errors.
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.next(options),
        onResponse: (response, handler) => handler.next(response),
        onError: (e, handler) => handler.next(e),
      ),
    );
  }

  Future<void> init() async {
    if (_cookieJarReady) return;
    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage('${dir.path}/.cookies/'),
    );
    dio.interceptors.add(CookieManager(_cookieJar));
    _cookieJarReady = true;
  }

  Future<void> clearCookies() async {
    await init();
    await _cookieJar.deleteAll();
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout');
  }

  /// Core request wrapper. Handles: 401 -> silent /auth/refresh -> retry
  /// once (queueing concurrent callers behind a single in-flight refresh),
  /// exactly like the response interceptor in lib/api.ts.
  Future<Response<dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
    bool isRetry = false,
  }) async {
    await init();
    try {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        if (response.statusCode == 401 && !isRetry && !_isAuthEndpoint(path)) {
          final refreshed = await _refreshSession();
          if (refreshed) {
            return _request(
              method,
              path,
              queryParameters: queryParameters,
              data: data,
              options: options,
              isRetry: true,
            );
          }
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: _extractMessage(response.data) ?? 'Request failed',
          data: response.data,
        );
      }
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        throw ApiException(message: 'Network error — check your connection.');
      }
      throw ApiException(
        statusCode: e.response?.statusCode,
        message: _extractMessage(e.response?.data) ?? e.message ?? 'Request failed',
        data: e.response?.data,
      );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      if (m is List) return m.join(', ');
      return m.toString();
    }
    return null;
  }

  /// Mirrors the isRefreshing/queue pattern in lib/api.ts exactly: only one
  /// /auth/refresh in flight at a time, everyone else awaits it.
  Future<bool> _refreshSession() async {
    if (_isRefreshing) {
      final waiter = Completer<void>();
      _refreshWaiters.add(waiter);
      await waiter.future;
      return true;
    }
    _isRefreshing = true;
    try {
      final res = await dio.post('/auth/refresh');
      final ok = res.statusCode != null && res.statusCode! < 400;
      if (ok) {
        for (final w in _refreshWaiters) {
          if (!w.isCompleted) w.complete();
        }
        _refreshWaiters.clear();
        return true;
      }
      _failWaiters();
      final status = res.statusCode;
      if (status == 401 || status == 403) onSessionExpired?.call();
      return false;
    } catch (_) {
      _failWaiters();
      // Network/429 errors: don't force logout, next call will retry.
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _failWaiters() {
    for (final w in _refreshWaiters) {
      if (!w.isCompleted) w.complete();
    }
    _refreshWaiters.clear();
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _request('GET', path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _request('POST', path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _request('PATCH', path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _request('PUT', path, data: data);

  Future<Response> delete(String path, {dynamic data}) =>
      _request('DELETE', path, data: data);
}

/// ── Typed API namespaces (Phase 1: auth, branches, rbac) ──────────────────
/// Mirrors the corresponding exports in dentaldb/lib/api.ts. Later phases
/// add patientsApi, appointmentsApi, usersApi, inventoryApi, reportsApi, etc.
class AuthApi {
  final ApiClient _c;
  AuthApi(this._c);

  Future<Response> login({required String email, required String password}) =>
      _c.post('/auth/login', data: {'email': email, 'password': password});

  Future<Response> logout() => _c.post('/auth/logout');

  Future<Response> refresh() => _c.post('/auth/refresh');

  Future<Response> me() => _c.get('/auth/me');
}

class BranchesApi {
  final ApiClient _c;
  BranchesApi(this._c);

  Future<Response> list() => _c.get('/branches');

  Future<Response> myBranches() => _c.get('/branches/my');

  Future<Response> get(String id) => _c.get('/branches/$id');
}

class RbacApi {
  final ApiClient _c;
  RbacApi(this._c);

  Future<Response> getMyPermissions() => _c.get('/rbac/me/permissions');
}

class PatientsApi {
  final ApiClient _c;
  PatientsApi(this._c);

  Future<Response> list({int? page, int? limit, String? search, String? branchId}) => _c.get(
        '/patients',
        params: {
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (branchId != null) 'branchId': branchId,
        },
      );

  Future<Response> get(String id) => _c.get('/patients/$id');

  Future<Response> create(Map<String, dynamic> data) => _c.post('/patients', data: data);

  Future<Response> update(String id, Map<String, dynamic> data) =>
      _c.patch('/patients/$id', data: data);

  Future<Response> delete(String id) => _c.delete('/patients/$id');

  Future<Response> getHistory(String id) => _c.get('/patients/$id/history');
}

class AppointmentsApi {
  final ApiClient _c;
  AppointmentsApi(this._c);

  Future<Response> list({
    String? branchId,
    String? from,
    String? to,
    int? limit,
    String? order,
  }) =>
      _c.get('/appointments', params: {
        if (branchId != null) 'branchId': branchId,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (limit != null) 'limit': limit,
        if (order != null) 'order': order,
      });

  Future<Response> get(String id) => _c.get('/appointments/$id');

  Future<Response> create(Map<String, dynamic> data) => _c.post('/appointments', data: data);

  Future<Response> update(String id, Map<String, dynamic> data) =>
      _c.patch('/appointments/$id', data: data);

  Future<Response> cancel(String id, {String? reason}) =>
      _c.patch('/appointments/$id/cancel', data: {'reason': reason});

  Future<Response> complete(String id, Map<String, dynamic> data) =>
      _c.patch('/appointments/$id/complete', data: data);

  Future<Response> delete(String id) => _c.delete('/appointments/$id');

  Future<Response> suggestSlots(Map<String, dynamic> data) =>
      _c.post('/appointments/suggest-slots', data: data);
}

class UsersApi {
  final ApiClient _c;
  UsersApi(this._c);

  Future<Response> listStaff({String? roles}) =>
      _c.get('/users/staff', params: {if (roles != null) 'roles': roles});
}

/// Extends branches endpoints used beyond Phase 1 (doctors-per-branch, for
/// the appointment booking form's dentist picker).
class BranchDoctorsApi {
  final ApiClient _c;
  BranchDoctorsApi(this._c);

  Future<Response> getDoctors(String branchId) => _c.get('/branches/$branchId/doctors');
}

/// Mirrors dentaldb/lib/api.ts `billingApi`.
class BillingApi {
  final ApiClient _c;
  BillingApi(this._c);

  Future<Response> listInvoices({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? branchId,
    String? patientId,
  }) =>
      _c.get('/billing/invoices', params: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        if (branchId != null) 'branchId': branchId,
        if (patientId != null) 'patientId': patientId,
      });

  Future<Response> getInvoice(String id) => _c.get('/billing/invoices/$id');

  Future<Response> createInvoice(Map<String, dynamic> data) =>
      _c.post('/billing/invoices', data: data);

  Future<Response> updateInvoice(String id, Map<String, dynamic> data) =>
      _c.patch('/billing/invoices/$id', data: data);

  Future<Response> markPaid(String id, Map<String, dynamic> data) =>
      _c.patch('/billing/invoices/$id/pay', data: data);

  Future<Response> deleteInvoice(String id) => _c.delete('/billing/invoices/$id');

  Future<Response> getRevenueSummary({Map<String, dynamic>? params}) =>
      _c.get('/billing/analytics', params: params);
}

/// Mirrors dentaldb/lib/api.ts `clinicalRecordsApi`.
class ClinicalRecordsApi {
  final ApiClient _c;
  ClinicalRecordsApi(this._c);

  Future<Response> list({
    int? page,
    int? limit,
    String? search,
    String? patientId,
  }) =>
      _c.get('/clinical-records', params: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (patientId != null) 'patientId': patientId,
      });

  Future<Response> get(String id) => _c.get('/clinical-records/$id');

  Future<Response> create(Map<String, dynamic> data) =>
      _c.post('/clinical-records', data: data);

  Future<Response> update(String id, Map<String, dynamic> data) =>
      _c.patch('/clinical-records/$id', data: data);

  Future<Response> delete(String id) => _c.delete('/clinical-records/$id');

  /// Creates the patient's clinical record if none exists yet, or appends a
  /// new dated visit entry to the existing one. No-ops server-side if
  /// `services` is empty.
  Future<Response> upsertFromBilling(Map<String, dynamic> data) =>
      _c.post('/clinical-records/upsert-from-billing', data: data);
}

/// Mirrors dentaldb/lib/api.ts `recallsApi`.
class RecallsApi {
  final ApiClient _c;
  RecallsApi(this._c);

  Future<Response> list({String? branchId}) =>
      _c.get('/recalls', params: {if (branchId != null) 'branchId': branchId});

  Future<Response> stats({String? branchId}) =>
      _c.get('/recalls/stats', params: {if (branchId != null) 'branchId': branchId});

  Future<Response> byPatient(String patientId) => _c.get('/recalls/patient/$patientId');

  Future<Response> create(Map<String, dynamic> data) => _c.post('/recalls', data: data);

  Future<Response> bulkCreate(Map<String, dynamic> data) => _c.post('/recalls/bulk', data: data);

  Future<Response> update(String id, Map<String, dynamic> data) =>
      _c.patch('/recalls/$id', data: data);

  Future<Response> delete(String id) => _c.delete('/recalls/$id');

  Future<Response> createAppointment(String id, Map<String, dynamic> data) =>
      _c.post('/recalls/$id/create-appointment', data: data);

  Future<Response> updateAppointmentOutcome(String id, String outcome) =>
      _c.patch('/recalls/$id/appointment-outcome', data: {'outcome': outcome});

  Future<Response> sendNow(String id) => _c.post('/recalls/$id/send-now');
}

/// Mirrors dentaldb/lib/api.ts `filesApi`. Used by [PatientFilesNotifier]
/// (providers/patient_files_provider.dart).
class FilesApi {
  final ApiClient _c;
  FilesApi(this._c);

  Future<Response> list(String patientId) => _c.get('/files/patients/$patientId');

  Future<Response> upload(
    String patientId, {
    required String filePath,
    required String fileName,
    required String category,
    String? description,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'category': category,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return _c.post('/files/patients/$patientId', data: formData);
  }

  /// Fetched via the authenticated client so the HttpOnly auth cookie is
  /// included — a direct network image URL wouldn't send it.
  Future<Response> preview(String id) async {
    await _c.init();
    return _c.dio.get('/files/$id/preview', options: Options(responseType: ResponseType.bytes));
  }

  Future<Response> download(String id) async {
    await _c.init();
    return _c.dio.get('/files/$id/download', options: Options(responseType: ResponseType.bytes));
  }

  Future<Response> delete(String id) => _c.delete('/files/$id');
}