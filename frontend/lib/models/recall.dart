/// Mirrors the `Recall` interface in
/// dentaldb/app/(app)/dashboard/recalls/page.tsx.
library;

enum RecallType {
  checkup,
  followup,
  medicationReview,
  other;

  static RecallType fromJson(String? value) {
    switch (value) {
      case 'checkup':
        return RecallType.checkup;
      case 'followup':
        return RecallType.followup;
      case 'medication_review':
        return RecallType.medicationReview;
      default:
        return RecallType.other;
    }
  }

  String get wireValue => switch (this) {
        RecallType.checkup => 'checkup',
        RecallType.followup => 'followup',
        RecallType.medicationReview => 'medication_review',
        RecallType.other => 'other',
      };

  String get label => switch (this) {
        RecallType.checkup => 'Check-up',
        RecallType.followup => 'Follow-up',
        RecallType.medicationReview => 'Medication Review',
        RecallType.other => 'Other',
      };
}

enum RecallStatus {
  pending,
  contacted,
  booked,
  cancelled;

  static RecallStatus fromJson(String? value) {
    switch (value) {
      case 'contacted':
        return RecallStatus.contacted;
      case 'booked':
        return RecallStatus.booked;
      case 'cancelled':
        return RecallStatus.cancelled;
      default:
        return RecallStatus.pending;
    }
  }

  String get wireValue => switch (this) {
        RecallStatus.pending => 'pending',
        RecallStatus.contacted => 'contacted',
        RecallStatus.booked => 'booked',
        RecallStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        RecallStatus.pending => 'Pending',
        RecallStatus.contacted => 'Contacted',
        RecallStatus.booked => 'Booked',
        RecallStatus.cancelled => 'Cancelled',
      };
}

class RecallPatientRef {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;

  const RecallPatientRef({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory RecallPatientRef.fromJson(Map<String, dynamic> json) => RecallPatientRef(
        id: json['id'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );
}

class Recall {
  final String id;
  final String patientId;
  final RecallPatientRef? patient;
  final String dueDate;
  final String? reason;
  final RecallType recallType;
  final RecallStatus status;
  final String? notes;
  final String? appointmentId;
  final String? appointmentStatus;
  final String? appointmentScheduledAt;
  final String createdAt;

  const Recall({
    required this.id,
    required this.patientId,
    this.patient,
    required this.dueDate,
    this.reason,
    required this.recallType,
    required this.status,
    this.notes,
    this.appointmentId,
    this.appointmentStatus,
    this.appointmentScheduledAt,
    required this.createdAt,
  });

  factory Recall.fromJson(Map<String, dynamic> json) {
    final appt = json['appointment'] as Map<String, dynamic>?;
    return Recall(
      id: json['id'] as String,
      patientId: json['patientId'] as String? ?? '',
      patient: json['patient'] != null
          ? RecallPatientRef.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      dueDate: json['dueDate'] as String? ?? '',
      reason: json['reason'] as String?,
      recallType: RecallType.fromJson(json['recallType'] as String?),
      status: RecallStatus.fromJson(json['status'] as String?),
      notes: json['notes'] as String?,
      appointmentId: json['appointmentId'] as String?,
      appointmentStatus: appt?['status'] as String?,
      appointmentScheduledAt: appt?['scheduledAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

/// Response shape of GET /recalls — grouped buckets, not a flat list.
class RecallGroups {
  final List<Recall> overdue;
  final List<Recall> thisWeek;
  final List<Recall> upcoming;

  const RecallGroups({this.overdue = const [], this.thisWeek = const [], this.upcoming = const []});

  factory RecallGroups.fromJson(Map<String, dynamic> json) {
    List<Recall> parse(dynamic v) => (v as List? ?? const [])
        .map((e) => Recall.fromJson(e as Map<String, dynamic>))
        .toList();
    return RecallGroups(
      overdue: parse(json['overdue']),
      thisWeek: parse(json['thisWeek']),
      upcoming: parse(json['upcoming']),
    );
  }
}

class RecallStats {
  final int totalPending;
  final int overdueCount;
  final int bookedThisMonth;

  const RecallStats({this.totalPending = 0, this.overdueCount = 0, this.bookedThisMonth = 0});

  factory RecallStats.fromJson(Map<String, dynamic> json) => RecallStats(
        totalPending: (json['totalPending'] as num?)?.toInt() ?? 0,
        overdueCount: (json['overdueCount'] as num?)?.toInt() ?? 0,
        bookedThisMonth: (json['bookedThisMonth'] as num?)?.toInt() ?? 0,
      );
}