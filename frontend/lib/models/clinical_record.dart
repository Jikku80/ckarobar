/// Mirrors dentaldb/types/index.ts `ClinicalRecord` / `ClinicalRecordVisit`
/// / `Prescription`.
library;

import 'recall.dart' show RecallPatientRef;

class Prescription {
  final String? id;
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;

  const Prescription({
    this.id,
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id'] as String?,
        medicineName: json['medicineName'] as String? ?? '',
        dosage: json['dosage'] as String?,
        frequency: json['frequency'] as String?,
        duration: json['duration'] as String?,
        instructions: json['instructions'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'medicineName': medicineName,
        if (dosage != null && dosage!.isNotEmpty) 'dosage': dosage,
        if (frequency != null && frequency!.isNotEmpty) 'frequency': frequency,
        if (duration != null && duration!.isNotEmpty) 'duration': duration,
        if (instructions != null && instructions!.isNotEmpty) 'instructions': instructions,
      };

  Prescription copyWith({
    String? medicineName,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
  }) =>
      Prescription(
        id: id,
        medicineName: medicineName ?? this.medicineName,
        dosage: dosage ?? this.dosage,
        frequency: frequency ?? this.frequency,
        duration: duration ?? this.duration,
        instructions: instructions ?? this.instructions,
      );
}

class ClinicalRecordVisit {
  final String id;
  final String date;
  final String? appointmentId;
  final String? invoiceId;
  final String? doctorId;
  final List<String> services;
  final String? notes;

  const ClinicalRecordVisit({
    required this.id,
    required this.date,
    this.appointmentId,
    this.invoiceId,
    this.doctorId,
    this.services = const [],
    this.notes,
  });

  factory ClinicalRecordVisit.fromJson(Map<String, dynamic> json) => ClinicalRecordVisit(
        id: json['id'] as String? ?? '',
        date: json['date'] as String? ?? '',
        appointmentId: json['appointmentId'] as String?,
        invoiceId: json['invoiceId'] as String?,
        doctorId: json['doctorId'] as String?,
        services: (json['services'] as List? ?? const []).map((e) => e.toString()).toList(),
        notes: json['notes'] as String?,
      );
}

class ClinicalRecordAttachment {
  final String name;
  final String url;
  final String type;

  const ClinicalRecordAttachment({required this.name, required this.url, required this.type});

  factory ClinicalRecordAttachment.fromJson(Map<String, dynamic> json) => ClinicalRecordAttachment(
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        type: json['type'] as String? ?? '',
      );
}

class ClinicalRecord {
  final String id;
  final String clinicId;
  final String patientId;
  final RecallPatientRef? patient;
  final String? doctorId;
  final String? doctorName;
  final String? appointmentId;
  final String? diagnosisNotes;
  final String? treatmentPlan;
  final List<ClinicalRecordVisit> visits;
  final List<ClinicalRecordAttachment> attachments;
  final List<Prescription> prescriptions;
  final String createdAt;
  final String updatedAt;

  const ClinicalRecord({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.patient,
    this.doctorId,
    this.doctorName,
    this.appointmentId,
    this.diagnosisNotes,
    this.treatmentPlan,
    this.visits = const [],
    this.attachments = const [],
    this.prescriptions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClinicalRecord.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>?;
    return ClinicalRecord(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      patient: json['patient'] != null
          ? RecallPatientRef.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      doctorId: json['doctorId'] as String?,
      doctorName: doctor != null
          ? ['${doctor['firstName'] ?? ''}', '${doctor['lastName'] ?? ''}'].join(' ').trim()
          : null,
      appointmentId: json['appointmentId'] as String?,
      diagnosisNotes: json['diagnosisNotes'] as String?,
      treatmentPlan: json['treatmentPlan'] as String?,
      visits: (json['visits'] as List? ?? const [])
          .map((e) => ClinicalRecordVisit.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments: (json['attachments'] as List? ?? const [])
          .map((e) => ClinicalRecordAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      prescriptions: (json['prescriptions'] as List? ?? const [])
          .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}