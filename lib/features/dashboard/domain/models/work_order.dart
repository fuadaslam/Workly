import 'package:supabase_flutter/supabase_flutter.dart';

enum WorkStatus { pending, inProgress, completed }
enum PriorityLevel { high, medium, low }

class WorkOrder {
  final String id;
  final String? clientId;
  final String? clientName;
  final String? clientPhoneNumber;
  final String? serviceId;
  final String? serviceType;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? assignedOfficeId;
  final String? assignedOfficeName;
  final PriorityLevel priority;
  final WorkStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkOrder({
    required this.id,
    this.clientId,
    this.clientName,
    this.clientPhoneNumber,
    this.serviceId,
    this.serviceType,
    this.assignedStaffId,
    this.assignedStaffName,
    this.assignedOfficeId,
    this.assignedOfficeName,
    required this.priority,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      clientPhoneNumber: json['client_phone_number'] ?? json['client_phone'],
      serviceId: json['service_id'],
      serviceType: json['service_type'],
      assignedStaffId: json['assigned_staff_id'],
      assignedStaffName: json['profiles']?['name'],
      assignedOfficeId: json['assigned_office_id'],
      assignedOfficeName: json['offices']?['name'] ?? json['profiles']?['offices']?['name'],
      priority: _parsePriority(json['priority']),
      status: _parseStatus(json['status']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
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
      'service_id': serviceId,
      'service_type': serviceType,
      'assigned_staff_id': assignedStaffId,
      'assigned_office_id': assignedOfficeId,
      'priority': priority.name,
      'status': status.name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
