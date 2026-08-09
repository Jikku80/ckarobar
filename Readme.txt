# ck_mob — Remaining API Modules to Connect

Cross-referenced `dentaldb/lib/api.ts` (the web app's API contract, i.e. the
source of truth) against `ck_mob/frontend/lib/core/api_client.dart` (what's
actually wired into the mobile app today). Grouped by the mobile app's own
nav items (`core/permissions.dart` → `kNavItems`) so it maps directly onto
what's still a `ComingSoonScreen` placeholder in `router.dart`.

All paths below are relative to `AppConfig.apiUrl` (`<host>/api/v1`), same
convention `ApiClient` already uses for the connected modules.

---

## ✅ Already fully connected
Patients, Billing, Clinical Records, Recalls, Auth, Branch listing +
per-branch doctors, RBAC (read-only "my permissions").

## 🟡 Partially connected — API class exists, no screen/route
**Appointments** — `AppointmentsApi` in `api_client.dart` already mirrors
the web app 1:1, and `providers/appointments_provider.dart` wires a
day-view list. Nothing else uses it yet — no screen, no route (`/appointments`
still resolves to `ComingSoonScreen`).

| Method | Endpoint |
|---|---|
| `get(id)` | `GET /appointments/:id` |
| `create(data)` | `POST /appointments` |
| `update(id, data)` | `PATCH /appointments/:id` |
| `cancel(id, {reason})` | `PATCH /appointments/:id/cancel` |
| `complete(id, data)` | `PATCH /appointments/:id/complete` |
| `delete(id)` | `DELETE /appointments/:id` |
| `suggestSlots(data)` | `POST /appointments/suggest-slots` |

All already have Dart methods — just needs a booking form + detail screen +
route wiring (same pattern as clinical records).

---

## 🔴 Not connected — need both API class and everything above it

### Queue
No `QueueApi` class in mobile at all.

| Method | Endpoint |
|---|---|
| `getQueue(branchId)` | `GET /queue?branchId=` |
| `getStats(branchId)` | `GET /queue/stats?branchId=` |
| `searchAppointments(branchId, q)` | `GET /queue/search-appointments` |
| `addToQueue(branchId, data)` | `POST /queue?branchId=` |
| `walkIn(branchId, data)` | `POST /queue/walk-in?branchId=` |
| `checkIn(branchId, appointmentId)` | `POST /queue/check-in/:appointmentId?branchId=` |
| `callNext(branchId, doctorId?)` | `PATCH /queue/call-next?branchId=&doctorId=` |
| `callEntry(id)` | `PATCH /queue/:id/call` |
| `markInProgress(id)` | `PATCH /queue/:id/in-progress` |
| `markDone(id)` | `PATCH /queue/:id/done` |
| `skipEntry(id)` | `PATCH /queue/:id/skip` |
| `update(id, data)` | `PATCH /queue/:id` |
| `remove(id)` | `DELETE /queue/:id` |
| `createAppointmentForEntry(id, data)` | `POST /queue/:id/create-appointment` (idempotent) |

### Staff (Users — beyond `listStaff`)
`UsersApi` in mobile only has `listStaff`. Missing:

| Method | Endpoint |
|---|---|
| `get(id)` | `GET /users/:id` |
| `create(data)` | `POST /users` |
| `update(id, data)` | `PATCH /users/:id` |
| `deactivate(id)` | `PATCH /users/:id/deactivate` |
| `reactivate(id)` | `PATCH /users/:id/reactivate` |
| `deleteStaff(id)` | `DELETE /users/:id` |
| `getDentistPerformance(id)` | `GET /users/dentists/:id/performance` |
| `getAdminDentistPerformance()` | `GET /users/admin/dentists/performance` |
| `uploadStaffSignature(id, file)` | `POST /users/:id/signature` (multipart, field `file`) |

### Branches (beyond `list` / `myBranches` / `getDoctors`)
Missing on `BranchesApi`:

| Method | Endpoint |
|---|---|
| `getStats(id)` | `GET /branches/:id/stats` |
| `getQuotaStatus()` | `GET /branches/quota-status` |
| `create(data)` | `POST /branches` |
| `update(id, data)` | `PATCH /branches/:id` |
| `setActive(id, isActive)` | `PATCH /branches/:id` (`{isActive}`) |
| `confirmDowngradeSelection(keepIds)` | `POST /branches/confirm-downgrade-selection` |
| `remove(id)` | `DELETE /branches/:id` |
| `assignStaff(id, userId)` | `POST /branches/:id/staff/:userId` |
| `removeStaff(id, userId)` | `DELETE /branches/:id/staff/:userId` |

### Roles (RBAC — beyond `getMyPermissions`)
Missing on `RbacApi`:

| Method | Endpoint |
|---|---|
| `getRoles()` | `GET /rbac/roles` |
| `getRole(id)` | `GET /rbac/roles/:id` |
| `createRole({name, description?})` | `POST /rbac/roles` |
| `updateRole(id, data)` | `PUT /rbac/roles/:id` |
| `deleteRole(id)` | `DELETE /rbac/roles/:id` |
| `setRolePermissions(id, permissionIds)` | `PUT /rbac/roles/:id/permissions` |
| `togglePermission(roleId, permissionId, enabled)` | `PATCH /rbac/roles/:roleId/permissions/toggle` |
| `getAllPermissions()` | `GET /rbac/permissions` |
| `getUserRoles(userId)` | `GET /rbac/users/:userId/roles` |
| `assignUserRoles(userId, roleIds)` | `PUT /rbac/users/:userId/roles` |

### Inventory
No `InventoryApi` class.

| Method | Endpoint |
|---|---|
| `list(params?)` | `GET /inventory` |
| `get(id)` | `GET /inventory/:id` |
| `create(data)` | `POST /inventory` |
| `update(id, data)` | `PATCH /inventory/:id` |
| `delete(id)` | `DELETE /inventory/:id` |
| `lowStock()` | `GET /inventory/low-stock` |
| `uploadImage(id, file)` | `POST /inventory/:id/image` (multipart, field `image`) |
| `listPOs()` | `GET /purchase-orders` |
| `createPO(data)` | `POST /purchase-orders` |
| `updatePO(id, data)` | `PATCH /purchase-orders/:id` |
| `deletePO(id)` | `DELETE /purchase-orders/:id` |

### Reports
No `ReportsApi` class. All under `/analytics` except the aging report.

| Method | Endpoint |
|---|---|
| `getProfitLoss(params?)` | `GET /analytics/profit-loss` |
| `getCashFlow(params?)` | `GET /analytics/cash-flow` |
| `getRevenueByDoctor(params?)` | `GET /analytics/revenue-by-doctor` |
| `getRevenueByService(params?)` | `GET /analytics/revenue-by-service` |
| `getOutstandingReceivables(params?)` | `GET /analytics/outstanding-receivables` |
| `getBranchPerformance(params?)` | `GET /analytics/branch-performance` |
| `getTaxReport(params?)` | `GET /analytics/tax-report` |
| `getAgingReport(params?)` | `GET /billing/aging-report` |

### Attendance
No `AttendanceApi` class.

| Method | Endpoint |
|---|---|
| `checkIn()` | `POST /attendance/check-in` |
| `checkOut()` | `POST /attendance/check-out` |
| `today()` | `GET /attendance/today` |
| `list(params?)` | `GET /attendance` |
| `monthlySummary(year, month)` | `GET /attendance/monthly-summary?year=&month=` |
| `exportCsv(params?)` | `GET /attendance/export` (blob) — low priority on mobile |
| `override(id, data)` *(admin)* | `PATCH /attendance/:id/override` |

### Leave
No `LeaveApi` class.

| Method | Endpoint |
|---|---|
| `apply(data)` | `POST /leave` |
| `list(params?)` | `GET /leave` |
| `approve(id, data?)` | `PATCH /leave/:id/approve` |
| `reject(id, data?)` | `PATCH /leave/:id/reject` |
| `cancel(id)` | `PATCH /leave/:id/cancel` |

### Settings
Maps to `clinicsApi` on web (clinic profile, not the current user's — that's
`profileApi`, not in mobile's nav today either).

| Method | Endpoint |
|---|---|
| `getCurrent()` | `GET /clinics/me` |
| `update(data)` | `PATCH /clinics/me` |
| `updateWorkingHours(data)` | `PATCH /clinics/me/working-hours` |
| `uploadLogo(file)` | `POST /clinics/me/logo` (multipart, field `logo`) |

---

## Not in mobile's nav at all (web-only for now)
These exist on web but aren't in `kNavItems`, so they're out of scope unless
you want to add them: Expenses, Payroll, Commissions, Website Builder,
Public Listing, Messages, SEO, Services, Lab Work, Blood Test, Holidays,
Audit Log, Shifts (`shiftsApi`), Subscriptions, API Keys, Doctor
Affiliations/Profile, Blog, and the medical-visualization modules (Imaging,
Dental Chart, Body Diagram, Timeline, Health Trends, Lab Results,
Dermatology, Clinic Stats).

---

## Suggested build order
Roughly by how much of the pattern is already in place, and how central the
module is to daily clinic use:

1. **Appointments** — API already mirrors web 1:1, just needs the screen +
   route (fastest win, same pattern as Clinical Records).
2. **Queue** — core daily-use screen; branch-scoped, no auth/role UI needed.
3. **Staff** — mostly CRUD on `UsersApi`, same shape as Patients.
4. **Attendance** + **Leave** — small, self-contained API surfaces.
5. **Branches** (full CRUD) + **Roles** (RBAC management) — admin-only, can
   wait until the above are stable.
6. **Inventory** + **Reports** + **Settings** — larger UI surface each
   (image uploads, charts, multi-section forms), good to batch last.
