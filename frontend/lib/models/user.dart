/// Mirrors dentaldb/types/index.ts `UserRole` / `User`.
enum UserRole {
  superAdmin,
  owner,
  dentist,
  doctor,
  receptionist,
  accountant,
  staff,
  unknown;

  static UserRole fromJson(String? value) {
    switch (value) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'owner':
        return UserRole.owner;
      case 'dentist':
        return UserRole.dentist;
      case 'doctor':
        return UserRole.doctor;
      case 'receptionist':
        return UserRole.receptionist;
      case 'accountant':
        return UserRole.accountant;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.unknown;
    }
  }

  String get wireValue => switch (this) {
        UserRole.superAdmin => 'super_admin',
        UserRole.owner => 'owner',
        UserRole.dentist => 'dentist',
        UserRole.doctor => 'doctor',
        UserRole.receptionist => 'receptionist',
        UserRole.accountant => 'accountant',
        UserRole.staff => 'staff',
        UserRole.unknown => 'unknown',
      };

  String get label => switch (this) {
        UserRole.superAdmin => 'Super Admin',
        UserRole.owner => 'Owner',
        UserRole.dentist => 'Dentist',
        UserRole.doctor => 'Doctor',
        UserRole.receptionist => 'Receptionist',
        UserRole.accountant => 'Accountant',
        UserRole.staff => 'Staff',
        UserRole.unknown => 'Unknown',
      };

  /// Owner-tier roles — matches OWNER_ROLES in auth.store.ts / AuthProvider.tsx.
  bool get isOwnerTier => this == UserRole.owner || this == UserRole.superAdmin;
}

class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatar;
  final String? clinicId;
  final bool isActive;
  final String? nmcNo;
  final String? lastLoginAt;
  final String createdAt;

  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.clinicId,
    required this.isActive,
    this.nmcNo,
    this.lastLoginAt,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromJson(json['role'] as String?),
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      clinicId: json['clinicId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      nmcNo: json['nmcNo'] as String?,
      lastLoginAt: json['lastLoginAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role.wireValue,
        'phone': phone,
        'avatar': avatar,
        'clinicId': clinicId,
        'isActive': isActive,
        'nmcNo': nmcNo,
        'lastLoginAt': lastLoginAt,
        'createdAt': createdAt,
      };
}
