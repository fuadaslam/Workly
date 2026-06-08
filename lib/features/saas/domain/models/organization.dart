class Organization {
  final String id;
  final String name;
  final String slug;
  final String? ownerId;
  final String? ownerName;
  final String? logoUrl;
  final String? website;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  // subscription snapshot (joined)
  final String? planName;
  final String? planDisplayName;
  final String? subStatus;
  final double? priceMonthly;
  final int? maxUsers;
  final int? maxOffices;
  final DateTime? periodEnd;
  final DateTime? trialEndsAt;

  // usage (aggregated)
  final int memberCount;
  final int workOrderCount;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.ownerId,
    this.ownerName,
    this.logoUrl,
    this.website,
    this.phone,
    this.address,
    required this.createdAt,
    this.planName,
    this.planDisplayName,
    this.subStatus,
    this.priceMonthly,
    this.maxUsers,
    this.maxOffices,
    this.periodEnd,
    this.trialEndsAt,
    this.memberCount = 0,
    this.workOrderCount = 0,
  });

  factory Organization.fromJson(Map<String, dynamic> j) => Organization(
        id: j['id'],
        name: j['name'] ?? '',
        slug: j['slug'] ?? '',
        ownerId: j['owner_id'],
        ownerName: j['owner_name'],
        logoUrl: j['logo_url'],
        website: j['website'],
        phone: j['phone'],
        address: j['address'],
        createdAt: DateTime.parse(j['created_at']),
        planName: j['plan_name'],
        planDisplayName: j['plan_display_name'],
        subStatus: j['sub_status'],
        priceMonthly: j['price_monthly'] != null ? (j['price_monthly'] as num).toDouble() : null,
        maxUsers: j['max_users'],
        maxOffices: j['max_offices'],
        periodEnd: j['period_end'] != null ? DateTime.parse(j['period_end']) : null,
        trialEndsAt: j['trial_ends_at'] != null ? DateTime.parse(j['trial_ends_at']) : null,
        memberCount: (j['member_count'] as num? ?? 0).toInt(),
        workOrderCount: (j['work_order_count'] as num? ?? 0).toInt(),
      );

  bool get isTrialing => subStatus == 'trialing';
  bool get isActive => subStatus == 'active';
  bool get isPastDue => subStatus == 'past_due';
  bool get isCancelled => subStatus == 'cancelled';
  bool get isUnlimitedUsers => maxUsers == -1;
}

class OrgPlan {
  final String id;
  final String name;
  final String displayName;
  final int maxUsers;
  final int maxOffices;
  final int maxWorkOrdersPerMonth;
  final double priceMonthly;
  final double priceYearly;
  final Map<String, dynamic> features;

  const OrgPlan({
    required this.id,
    required this.name,
    required this.displayName,
    required this.maxUsers,
    required this.maxOffices,
    required this.maxWorkOrdersPerMonth,
    required this.priceMonthly,
    required this.priceYearly,
    required this.features,
  });

  factory OrgPlan.fromJson(Map<String, dynamic> j) => OrgPlan(
        id: j['id'],
        name: j['name'],
        displayName: j['display_name'],
        maxUsers: j['max_users'],
        maxOffices: j['max_offices'],
        maxWorkOrdersPerMonth: j['max_work_orders_per_month'],
        priceMonthly: (j['price_monthly'] as num).toDouble(),
        priceYearly: (j['price_yearly'] as num).toDouble(),
        features: Map<String, dynamic>.from(j['features'] ?? {}),
      );

  String limitLabel(int val) => val == -1 ? 'Unlimited' : '$val';
}

class OrgMember {
  final String id;
  final String? name;
  final String? email;
  final String role;
  final bool isActive;
  final String? officeName;
  final DateTime? createdAt;

  const OrgMember({
    required this.id,
    this.name,
    this.email,
    required this.role,
    this.isActive = true,
    this.officeName,
    this.createdAt,
  });

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        role: j['role'] ?? 'staff',
        isActive: j['is_active'] ?? true,
        officeName: j['offices']?['name'],
        createdAt: j['created_at'] != null ? DateTime.parse(j['created_at']) : null,
      );
}

class OrgInvitation {
  final String id;
  final String orgId;
  final String email;
  final String role;
  final String? invitedByName;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;

  const OrgInvitation({
    required this.id,
    required this.orgId,
    required this.email,
    required this.role,
    this.invitedByName,
    required this.expiresAt,
    this.acceptedAt,
    required this.createdAt,
  });

  factory OrgInvitation.fromJson(Map<String, dynamic> j) => OrgInvitation(
        id: j['id'],
        orgId: j['org_id'],
        email: j['email'],
        role: j['role'],
        invitedByName: j['invited_by_profile']?['name'],
        expiresAt: DateTime.parse(j['expires_at']),
        acceptedAt: j['accepted_at'] != null ? DateTime.parse(j['accepted_at']) : null,
        createdAt: DateTime.parse(j['created_at']),
      );

  bool get isAccepted => acceptedAt != null;
  bool get isExpired => !isAccepted && expiresAt.isBefore(DateTime.now());
  bool get isPending => !isAccepted && !isExpired;
}
