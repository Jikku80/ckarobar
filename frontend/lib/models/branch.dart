import 'user.dart';

class Branch {
  final String id;
  final String clinicId;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final bool? isPubliclyListed;

  /// Driven by subscription quota — see Branch in types/index.ts.
  final bool isActive;

  /// Hard quota lock: fully read-only, cannot be activated until upgrade.
  final bool isLocked;

  final List<AppUser>? staff;
  final String createdAt;
  final String updatedAt;

  const Branch({
    required this.id,
    required this.clinicId,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.isPubliclyListed,
    required this.isActive,
    this.isLocked = false,
    this.staff,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isPubliclyListed: json['isPubliclyListed'] as bool?,
      isActive: json['isActive'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      staff: (json['staff'] as List?)
          ?.map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
