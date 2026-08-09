/// Mirrors dentaldb/types/index.ts `Patient` / `Gender` / `BloodGroup`.
library;

enum Gender {
  male,
  female,
  other,
  unspecified;

  static Gender fromJson(String? value) {
    switch (value) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      default:
        return Gender.unspecified;
    }
  }

  /// null on the wire when unspecified — mirrors the optional `gender?`
  /// field on the web app's Patient type.
  String? get wireValue => switch (this) {
        Gender.male => 'male',
        Gender.female => 'female',
        Gender.other => 'other',
        Gender.unspecified => null,
      };

  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
        Gender.unspecified => 'Unspecified',
      };
}

const List<String> kBloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

class Patient {
  final String id;
  final String clinicId;
  final String? branchId;
  final String? opdNo;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final int? ageYears;
  final Gender gender;
  final String? bloodGroup;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> currentMedications;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String? notes;
  final String? avatar;
  final bool isActive;
  final String? lastVisitAt;
  final String createdAt;

  const Patient({
    required this.id,
    required this.clinicId,
    this.branchId,
    this.opdNo,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.ageYears,
    this.gender = Gender.unspecified,
    this.bloodGroup,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.currentMedications = const [],
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.notes,
    this.avatar,
    this.isActive = true,
    this.lastVisitAt,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  /// Backend returns a computed `age` on read; fall back to the stored
  /// `ageYears` (what the form submits) if that's not present yet.
  int? get displayAge => ageYears;

  static List<String> _strList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String? ?? '',
      branchId: json['branchId'] as String?,
      opdNo: json['opdNo'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      ageYears: (json['ageYears'] as num?)?.toInt() ?? (json['age'] as num?)?.toInt(),
      gender: Gender.fromJson(json['gender'] as String?),
      bloodGroup: json['bloodGroup'] as String?,
      address: json['address'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      allergies: _strList(json['allergies']),
      medicalConditions: _strList(json['medicalConditions']),
      currentMedications: _strList(json['currentMedications']),
      insuranceProvider: json['insuranceProvider'] as String?,
      insurancePolicyNumber: json['insurancePolicyNumber'] as String?,
      notes: json['notes'] as String?,
      avatar: json['avatar'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastVisitAt: json['lastVisitAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  /// Minimal shape used when a patient is embedded on another entity
  /// (invoice.patient, recall.patient, etc.) — those responses don't
  /// always include every field.
  factory Patient.fromEmbeddedJson(Map<String, dynamic> json) => Patient.fromJson(json);
}