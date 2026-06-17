class TaskDocument {
  final String id;
  final String workOrderId;
  final String title;
  final String? fileUrl;
  final String? iconName; // 'image', 'pdf', 'doc', 'docx'
  final bool isVerified;
  final DateTime createdAt;

  TaskDocument({
    required this.id,
    required this.workOrderId,
    required this.title,
    this.fileUrl,
    this.iconName,
    required this.isVerified,
    required this.createdAt,
  });

  bool get isImage => iconName == 'image';
  bool get isPdf => iconName == 'pdf';

  factory TaskDocument.fromJson(Map<String, dynamic> json) {
    return TaskDocument(
      id: json['id'] as String,
      workOrderId: json['work_order_id'] as String,
      title: json['title'] as String,
      fileUrl: json['file_url'] as String?,
      iconName: json['icon_name'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
