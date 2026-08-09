/// Mirrors dentaldb/types/index.ts `Appointment` / `AppointmentStatus` /
/// `AppointmentType`.
library;

import 'recall.dart' show RecallPatientRef;

enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
  rescheduled;

  static AppointmentStatus fromJson(String? value) {
    switch (value) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'in_progress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      case 'rescheduled':
        return AppointmentStatus.rescheduled;
      case 'scheduled':
      default:
        return AppointmentStatus.scheduled;
    }
  }

  String get wireValue => switch (this) {
        AppointmentStatus.scheduled => 'scheduled',
        AppointmentStatus.confirmed => 'confirmed',
        AppointmentStatus.inProgress => 'in_progress',
        AppointmentStatus.completed => 'completed',
        AppointmentStatus.cancelled => 'cancelled',
        AppointmentStatus.noShow => 'no_show',
        AppointmentStatus.rescheduled => 'rescheduled',
      };

  String get label => switch (this) {
        AppointmentStatus.scheduled => 'Scheduled',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.inProgress => 'In progress',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.cancelled => 'Cancelled',
        AppointmentStatus.noShow => 'No show',
        AppointmentStatus.rescheduled => 'Rescheduled',
      };
}

enum AppointmentType {
  consultation,
  cleaning,
  filling,
  extraction,
  rootCanal,
  crown,
  orthodontics,
  whitening,
  xray,
  emergency,
  followup,
  other;

  static AppointmentType fromJson(String? value) {
    switch (value) {
      case 'cleaning':
        return AppointmentType.cleaning;
      case 'filling':
        return AppointmentType.filling;
      case 'extraction':
        return AppointmentType.extraction;
      case 'root_canal':
        return AppointmentType.rootCanal;
      case 'crown':
        return AppointmentType.crown;
      case 'orthodontics':
        return AppointmentType.orthodontics;
      case 'whitening':
        return AppointmentType.whitening;
      case 'xray':
        return AppointmentType.xray;
      case 'emergency':
        return AppointmentType.emergency;
      case 'followup':
        return AppointmentType.followup;
      case 'other':
        return AppointmentType.other;
      case 'consultation':
      default:
        return AppointmentType.consultation;
    }
  }

  String get wireValue => switch (this) {
        AppointmentType.consultation => 'consultation',
        AppointmentType.cleaning => 'cleaning',
        AppointmentType.filling => 'filling',
        AppointmentType.extraction => 'extraction',
        AppointmentType.rootCanal => 'root_canal',
        AppointmentType.crown => 'crown',
        AppointmentType.orthodontics => 'orthodontics',
        AppointmentType.whitening => 'whitening',
        AppointmentType.xray => 'xray',
        AppointmentType.emergency => 'emergency',
        AppointmentType.followup => 'followup',
        AppointmentType.other => 'other',
      };

  String get label => switch (this) {
        AppointmentType.consultation => 'Consultation',
        AppointmentType.cleaning => 'Cleaning',
        AppointmentType.filling => 'Filling',
        AppointmentType.extraction => 'Extraction',
        AppointmentType.rootCanal => 'Root canal',
        AppointmentType.crown => 'Crown',
        AppointmentType.orthodontics => 'Orthodontics',
        AppointmentType.whitening => 'Whitening',
        AppointmentType.xray => 'X-ray',
        AppointmentType.emergency => 'Emergency',
        AppointmentType.followup => 'Follow-up',
        AppointmentType.other => 'Other',
      };
}

class Appointment {
  final String id;
  final String clinicId;
  final String? branchId;
  final String patientId;
  final RecallPatientRef? patient;
  final String dentistId;
  final String? dentistName;
  final AppointmentType type;
  final AppointmentStatus status;
  final String scheduledAt;
  final String endsAt;
  final int durationMinutes;
  final String? notes;
  final String? chiefComplaint;
  final String? diagnosis;
  final String? treatment;
  final double? fee;
  final bool isPaid;
  final String createdAt;
  final String updatedAt;

  const Appointment({
    required this.id,
    required this.clinicId,
    this.branchId,
    required this.patientId,
    this.patient,
    required this.dentistId,
    this.dentistName,
    this.type = AppointmentType.consultation,
    this.status = AppointmentStatus.scheduled,
    required this.scheduledAt,
    required this.endsAt,
    this.durationMinutes = 30,
    this.notes,
    this.chiefComplaint,
    this.diagnosis,
    this.treatment,
    this.fee,
    this.isPaid = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final dentist = json['dentist'] as Map<String, dynamic>?;
    return Appointment(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String? ?? '',
      branchId: json['branchId'] as String?,
      patientId: json['patientId'] as String? ?? '',
      patient: json['patient'] != null
          ? RecallPatientRef.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      dentistId: json['dentistId'] as String? ?? '',
      dentistName: dentist != null
          ? ['${dentist['firstName'] ?? ''}', '${dentist['lastName'] ?? ''}'].join(' ').trim()
          : null,
      type: AppointmentType.fromJson(json['type'] as String?),
      status: AppointmentStatus.fromJson(json['status'] as String?),
      scheduledAt: json['scheduledAt'] as String? ?? '',
      endsAt: json['endsAt'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      notes: json['notes'] as String?,
      chiefComplaint: json['chiefComplaint'] as String?,
      diagnosis: json['diagnosis'] as String?,
      treatment: json['treatment'] as String?,
      fee: (json['fee'] as num?)?.toDouble(),
      isPaid: json['isPaid'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
