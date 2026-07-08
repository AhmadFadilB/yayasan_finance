class AuditLog {
  final String id;
  final String foundationId;
  final String tableName;
  final String action;
  final String recordId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? performedBy;
  final String? performedByName;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.foundationId,
    required this.tableName,
    required this.action,
    required this.recordId,
    this.oldValues,
    this.newValues,
    this.performedBy,
    this.performedByName,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      foundationId: json['foundation_id'] as String,
      tableName: json['table_name'] as String,
      action: json['action'] as String,
      recordId: json['record_id'] as String,
      oldValues: json['old_values'] != null ? Map<String, dynamic>.from(json['old_values'] as Map) : null,
      newValues: json['new_values'] != null ? Map<String, dynamic>.from(json['new_values'] as Map) : null,
      performedBy: json['performed_by'] as String?,
      performedByName: json['performed_by_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foundation_id': foundationId,
      'table_name': tableName,
      'action': action,
      'record_id': recordId,
      'old_values': oldValues,
      'new_values': newValues,
      'performed_by': performedBy,
      'performed_by_name': performedByName,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
