
enum LeaveType {
  annual,
  sick,
  unpaid,
  emergency,
  other
}

enum LeaveStatus {
  pending,
  approved,
  rejected
}

class LeaveRequest {
  final String id;
  final String userId;
  final String? userName;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final DateTime requestedAt;

  LeaveRequest({
    required this.id,
    required this.userId,
    this.userName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.requestedAt,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      userId: json['user_id'],
      userName: json['profiles']?['name'],
      type: _parseType(json['leave_type']),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : DateTime.now(),
      reason: json['reason'] ?? '',
      status: _parseStatus(json['status']),
      requestedAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'leave_type': type.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'reason': reason,
      'status': status.name,
    };
  }

  static LeaveType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'annual': return LeaveType.annual;
      case 'sick': return LeaveType.sick;
      case 'unpaid': return LeaveType.unpaid;
      case 'emergency': return LeaveType.emergency;
      default: return LeaveType.other;
    }
  }

  static LeaveStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return LeaveStatus.approved;
      case 'rejected': return LeaveStatus.rejected;
      default: return LeaveStatus.pending;
    }
  }
}
