import '../../domain/models/work_order.dart';

class TaskHistory {
  final String id;
  final String workOrderId;
  final String title;
  final String? description;
  final WorkStatus? statusAtTime;
  final DateTime createdAt;

  TaskHistory({
    required this.id,
    required this.workOrderId,
    required this.title,
    this.description,
    this.statusAtTime,
    required this.createdAt,
  });

  factory TaskHistory.fromJson(Map<String, dynamic> json) {
    return TaskHistory(
      id: json['id'],
      workOrderId: json['work_order_id'],
      title: json['title'],
      description: json['description'],
      statusAtTime: json['status_at_time'] != null ? _parseStatus(json['status_at_time']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static WorkStatus? _parseStatus(String? status) {
    switch (status) {
      case 'In-Progress':
        return WorkStatus.inProgress;
      case 'Completed':
        return WorkStatus.completed;
      case 'Pending':
        return WorkStatus.pending;
      default:
        return null;
    }
  }
}
