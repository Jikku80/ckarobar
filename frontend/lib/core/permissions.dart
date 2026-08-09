/// Mirrors dentaldb/lib/permissions.ts so the mobile app gates nav items
/// and screens with the exact same permission keys the backend/RBAC system
/// issues via GET /rbac/me/permissions.
library;

class Permission {
  Permission._();

  static const dashboardView = 'dashboard.view';

  static const queueView = 'queue.view';
  static const queueManage = 'queue.manage';

  static const appointmentView = 'appointment.view';
  static const appointmentCreate = 'appointment.create';
  static const appointmentUpdate = 'appointment.update';
  static const appointmentDelete = 'appointment.delete';

  static const patientView = 'patient.view';
  static const patientCreate = 'patient.create';
  static const patientUpdate = 'patient.update';
  static const patientDelete = 'patient.delete';
  static const patientRecord = 'patient.record';

  static const billingView = 'billing.view';
  static const billingManage = 'billing.manage';

  static const analyticsView = 'analytics.view';

  static const staffView = 'staff.view';
  static const staffManage = 'staff.manage';

  static const branchView = 'branch.view';
  static const branchManage = 'branch.manage';

  static const attendanceView = 'attendance.view';
  static const attendanceManage = 'attendance.manage';

  static const leaveView = 'leave.view';
  static const leaveManage = 'leave.manage';

  static const settingsView = 'settings.view';
  static const settingsManage = 'settings.manage';

  static const rolesView = 'roles.view';
  static const rolesManage = 'roles.manage';

  static const inventoryView = 'inventory.view';
  static const inventoryManage = 'inventory.manage';

  static const servicesView = 'services.view';
  static const servicesManage = 'services.manage';

  static const recordsView = 'records.view';

  static const expenseView = 'expense.view';
  static const payrollView = 'payroll.view';

  static const reportsView = 'reports.view';

  static const tasksView = 'tasks.view';
  static const labView = 'lab.view';
  static const bloodTestView = 'blood_test.view';
}

/// A null/undefined permission means "always allowed" (no gate) — same
/// semantics as hasPermission() in permissions.ts.
bool hasPermission(Set<String>? permissions, String? permission) {
  if (permission == null) return true;
  if (permissions == null) return false;
  return permissions.contains(permission);
}

bool hasAnyPermission(Set<String>? permissions, List<String> required) {
  return required.any((p) => hasPermission(permissions, p));
}

class NavItem {
  final String label;
  final String route;
  final String iconKey;
  final String? permission;

  const NavItem({
    required this.label,
    required this.route,
    required this.iconKey,
    this.permission,
  });
}

/// Subset of dentaldb/lib/permissions.ts NAV_ITEMS relevant to what's been
/// built so far. Modules not yet implemented on mobile still appear (so the
/// nav matches the web app) but route to a "coming soon" placeholder —
/// see coming_soon_screen.dart. Extend this list as later phases land.
const List<NavItem> kNavItems = [
  NavItem(label: 'Dashboard', route: '/dashboard', iconKey: 'dashboard', permission: Permission.dashboardView),
  NavItem(label: 'Patients', route: '/patients', iconKey: 'patients', permission: Permission.patientView),
  NavItem(label: 'Appointments', route: '/appointments', iconKey: 'appointments', permission: Permission.appointmentView),
  NavItem(label: 'Queue', route: '/queue', iconKey: 'queue', permission: Permission.queueView),
  NavItem(label: 'Billing', route: '/billing', iconKey: 'billing', permission: Permission.billingView),
  NavItem(label: 'Recalls', route: '/recalls', iconKey: 'recalls', permission: Permission.appointmentView),
  NavItem(label: 'Records', route: '/records', iconKey: 'records', permission: Permission.recordsView),
  NavItem(label: 'Staff', route: '/staff', iconKey: 'staff', permission: Permission.staffView),
  NavItem(label: 'Branches', route: '/branches', iconKey: 'branches', permission: Permission.branchView),
  NavItem(label: 'Roles', route: '/roles', iconKey: 'roles', permission: Permission.rolesView),
  NavItem(label: 'Inventory', route: '/inventory', iconKey: 'inventory', permission: Permission.inventoryView),
  NavItem(label: 'Reports', route: '/reports', iconKey: 'reports', permission: Permission.reportsView),
  NavItem(label: 'Attendance', route: '/attendance', iconKey: 'attendance', permission: Permission.attendanceView),
  NavItem(label: 'Leave', route: '/leave', iconKey: 'leave', permission: Permission.leaveView),
  NavItem(label: 'Settings', route: '/settings', iconKey: 'settings', permission: null),
];
