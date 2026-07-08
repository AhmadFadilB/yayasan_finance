class NotificationModel {
  final String id;
  final String foundationId;
  final String userId;
  final String title;
  final String message;
  final String type; // 'pending_approval', 'status_changed', 'large_income'
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.foundationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      foundationId: json['foundation_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      relatedId: json['related_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foundation_id': foundationId,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? foundationId,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      foundationId: foundationId ?? this.foundationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
