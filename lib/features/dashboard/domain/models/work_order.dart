
enum WorkStatus { pending, inProgress, completed }
enum PriorityLevel { high, medium, low }

class WorkOrder {
  final String id;
  final String? clientId;
  final String? clientName;
  final String? clientPhoneNumber;
  final String? nationality;
  final String? serviceId;
  final String? serviceType;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? assignedOfficeId;
  final String? assignedOfficeName;
  final String? agentId;
  final String? agentName;
  final double? agentFee;
  final PriorityLevel priority;
  final WorkStatus status;
  final String? finalStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Payment summary (from the linked payments row, when fetched).
  final double? totalAmount;
  final double? paidAmount;
  final String? paymentStatus;
  final String? enquiryId; // source enquiry, if this order was converted from one

  WorkOrder({
    required this.id,
    this.clientId,
    this.clientName,
    this.clientPhoneNumber,
    this.nationality,
    this.serviceId,
    this.serviceType,
    this.assignedStaffId,
    this.assignedStaffName,
    this.assignedOfficeId,
    this.assignedOfficeName,
    this.agentId,
    this.agentName,
    this.agentFee,
    required this.priority,
    required this.status,
    this.finalStatus,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.totalAmount,
    this.paidAmount,
    this.paymentStatus,
    this.enquiryId,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      clientPhoneNumber: json['client_phone_number'] ?? json['client_phone'],
      nationality: json['nationality'],
      serviceId: json['service_id'],
      serviceType: json['service_type'],
      assignedStaffId: json['assigned_staff_id'],
      assignedStaffName: json['profiles']?['name'],
      assignedOfficeId: json['assigned_office_id'],
      assignedOfficeName: json['offices']?['name'] ?? json['profiles']?['offices']?['name'],
      agentId: json['agent_id'],
      agentName: json['agent_profiles']?['name'],
      agentFee: json['agent_fee'] != null ? (json['agent_fee'] as num).toDouble() : null,
      priority: _parsePriority(json['priority']),
      status: _parseStatus(json['status']),
      finalStatus: json['final_status'],
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      totalAmount: _firstPayment(json['payments'], 'total_amount'),
      paidAmount: _firstPayment(json['payments'], 'paid_amount'),
      paymentStatus: _firstPaymentStatus(json['payments']),
      enquiryId: json['enquiry_id'],
    );
  }

  static double? _firstPayment(dynamic payments, String key) {
    if (payments is List && payments.isNotEmpty && payments.first is Map) {
      final v = (payments.first as Map)[key];
      return v != null ? (v as num).toDouble() : null;
    }
    return null;
  }

  static String? _firstPaymentStatus(dynamic payments) {
    if (payments is List && payments.isNotEmpty && payments.first is Map) {
      return (payments.first as Map)['status'] as String?;
    }
    return null;
  }

  static PriorityLevel _parsePriority(String? priority) {
    switch (priority) {
      case 'High':
        return PriorityLevel.high;
      case 'Low':
        return PriorityLevel.low;
      default:
        return PriorityLevel.medium;
    }
  }

  static WorkStatus _parseStatus(String? status) {
    switch (status) {
      case 'In-Progress':
        return WorkStatus.inProgress;
      case 'Completed':
        return WorkStatus.completed;
      default:
        return WorkStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'client_name': clientName,
      'client_phone_number': clientPhoneNumber,
      'nationality': nationality,
      'service_id': serviceId,
      'service_type': serviceType,
      'assigned_staff_id': assignedStaffId,
      'assigned_office_id': assignedOfficeId,
      'agent_id': agentId,
      'agent_fee': agentFee,
      'priority': priority.name,
      'status': status.name,
      'final_status': finalStatus,
      'rejection_reason': rejectionReason,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
