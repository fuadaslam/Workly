enum AppRole { super_admin, admin, staff }

class Profile {
  final String id;
  final String? email;
  final String? name;
  final AppRole role;
  final String? whatsappNo;
  final String? phoneNumber;
  final String? officeId;
  final String? officeName;
  final DateTime? createdAt;

  Profile({
    required this.id,
    this.email,
    this.name,
    required this.role,
    this.whatsappNo,
    this.phoneNumber,
    this.officeId,
    this.officeName,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      name: json['name'], // matched to updated schema
      role: _parseRole(json['role']),
      whatsappNo: json['whatsapp_no'],
      phoneNumber: json['phone_number'],
      officeId: json['office_id'],
      officeName: json['offices']?['name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  static AppRole _parseRole(String? roleStr) {
    if (roleStr == null) return AppRole.staff;
    final normalized = roleStr.trim().toLowerCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'super_admin':
      case 'superadmin':
        return AppRole.super_admin;
      case 'admin':
      case 'administrator':
        return AppRole.admin;
      default:
        return AppRole.staff;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name, // enum to string
      'whatsapp_no': whatsappNo,
      'phone_number': phoneNumber,
      'office_id': officeId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
