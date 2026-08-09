enum SubscriptionPlan {
  free,
  pro,
  enterprise,
  unknown;

  static SubscriptionPlan fromJson(String? value) {
    switch (value) {
      case 'free':
        return SubscriptionPlan.free;
      case 'pro':
        return SubscriptionPlan.pro;
      case 'enterprise':
        return SubscriptionPlan.enterprise;
      default:
        return SubscriptionPlan.unknown;
    }
  }
}

class Clinic {
  final String id;
  final String name;
  final String slug;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? logo;
  final SubscriptionPlan plan;
  final bool isActive;
  final String? trialEndsAt;
  final String? subscriptionEndsAt;
  final String createdAt;

  const Clinic({
    required this.id,
    required this.name,
    required this.slug,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.logo,
    required this.plan,
    required this.isActive,
    this.trialEndsAt,
    this.subscriptionEndsAt,
    required this.createdAt,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      logo: json['logo'] as String?,
      plan: SubscriptionPlan.fromJson(json['plan'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      trialEndsAt: json['trialEndsAt'] as String?,
      subscriptionEndsAt: json['subscriptionEndsAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
