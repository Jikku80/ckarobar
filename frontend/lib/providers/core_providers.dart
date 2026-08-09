import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/local_store.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final branchesApiProvider =
    Provider<BranchesApi>((ref) => BranchesApi(ref.watch(apiClientProvider)));

final rbacApiProvider = Provider<RbacApi>((ref) => RbacApi(ref.watch(apiClientProvider)));

final patientsApiProvider =
    Provider<PatientsApi>((ref) => PatientsApi(ref.watch(apiClientProvider)));

final appointmentsApiProvider =
    Provider<AppointmentsApi>((ref) => AppointmentsApi(ref.watch(apiClientProvider)));

final usersApiProvider = Provider<UsersApi>((ref) => UsersApi(ref.watch(apiClientProvider)));

final branchDoctorsApiProvider =
    Provider<BranchDoctorsApi>((ref) => BranchDoctorsApi(ref.watch(apiClientProvider)));

final billingApiProvider =
    Provider<BillingApi>((ref) => BillingApi(ref.watch(apiClientProvider)));

final clinicalRecordsApiProvider =
    Provider<ClinicalRecordsApi>((ref) => ClinicalRecordsApi(ref.watch(apiClientProvider)));

final recallsApiProvider =
    Provider<RecallsApi>((ref) => RecallsApi(ref.watch(apiClientProvider)));

final filesApiProvider = Provider<FilesApi>((ref) => FilesApi(ref.watch(apiClientProvider)));

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());