import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/billing/billing_list_screen.dart';
import '../features/billing/invoice_detail_screen.dart';
import '../features/billing/invoice_form_screen.dart';
import '../features/clinical_record/clinical_record_detail_screen.dart';
import '../features/clinical_record/clinical_record_form_screen.dart';
import '../features/clinical_record/clinical_records_screen.dart';
import '../features/dashboard/dashboard_home_screen.dart';
import '../features/dashboard/dashboard_shell.dart';
import '../features/patient/patient_detail_screen.dart';
import '../features/patient/patient_form_screen.dart';
import '../features/patient/patient_list_screen.dart';
import '../features/recall/recalls_screen.dart';
import '../features/shared/coming_soon_screen.dart';
import '../models/clinical_record.dart';
import '../models/invoice.dart';
import '../models/patient.dart';
import '../providers/auth_provider.dart';

/// Route table for modules not yet built beyond Dashboard/Patients/
/// Appointments/Billing/Clinical Records/Recalls. Admin modules (Staff,
/// Branches, RBAC, Reports, Inventory, etc.) resolve to ComingSoonScreen so
/// the nav/drawer matches the web app from day one until later phases land.
const _placeholderRoutes = {
  '/appointments': 'Appointments',
  '/queue': 'Queue',
  '/staff': 'Staff',
  '/branches': 'Branches',
  '/roles': 'Roles',
  '/inventory': 'Inventory',
  '/reports': 'Reports',
  '/attendance': 'Attendance',
  '/leave': 'Leave',
  '/settings': 'Settings',
};

/// Listenable bridge so GoRouter re-evaluates `redirect` whenever auth
/// status changes (login/logout/bootstrap complete).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.status != next.status) notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      if (auth.status == AuthStatus.bootstrapping) {
        return loc == '/splash' ? null : '/splash';
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return loc == '/login' ? null : '/login';
      }
      // authenticated
      if (loc == '/splash' || loc == '/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardShell(
          currentRoute: '/dashboard',
          child: DashboardHomeScreen(),
        ),
      ),

      // ── Patients ──────────────────────────────────────────────────────
      GoRoute(
        path: '/patients',
        builder: (context, state) => const DashboardShell(
          currentRoute: '/patients',
          child: PatientsListScreen(),
        ),
      ),
      GoRoute(
        path: '/patients/new',
        builder: (context, state) => const PatientFormScreen(),
      ),
      GoRoute(
        path: '/patients/:id',
        builder: (context, state) =>
            PatientDetailScreen(patientId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/patients/:id/edit',
        builder: (context, state) =>
            PatientFormScreen(patient: state.extra as Patient?),
      ),

      // ── Billing ───────────────────────────────────────────────────────
      GoRoute(
        path: '/billing',
        builder: (context, state) => const DashboardShell(
          currentRoute: '/billing',
          child: BillingListScreen(),
        ),
      ),
      GoRoute(
        path: '/billing/new',
        builder: (context, state) => const InvoiceFormScreen(),
      ),
      GoRoute(
        path: '/billing/:id',
        builder: (context, state) =>
            InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/billing/:id/edit',
        builder: (context, state) =>
            InvoiceFormScreen(invoice: state.extra as Invoice?),
      ),

      // ── Clinical Records ──────────────────────────────────────────────
      GoRoute(
        path: '/records',
        builder: (context, state) => const DashboardShell(
          currentRoute: '/records',
          child: ClinicalRecordsScreen(),
        ),
      ),
      GoRoute(
        path: '/records/new',
        builder: (context, state) => const ClinicalRecordFormScreen(),
      ),
      GoRoute(
        path: '/records/:id',
        builder: (context, state) =>
            ClinicalRecordDetailScreen(recordId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/records/:id/edit',
        builder: (context, state) =>
            ClinicalRecordFormScreen(record: state.extra as ClinicalRecord?),
      ),

      // ── Recalls ───────────────────────────────────────────────────────
      GoRoute(
        path: '/recalls',
        builder: (context, state) => const DashboardShell(
          currentRoute: '/recalls',
          child: RecallsScreen(),
        ),
      ),

      ..._placeholderRoutes.entries.map(
        (entry) => GoRoute(
          path: entry.key,
          builder: (context, state) => DashboardShell(
            currentRoute: entry.key,
            child: ComingSoonScreen(title: entry.value),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => const SplashScreen(),
  );
});
