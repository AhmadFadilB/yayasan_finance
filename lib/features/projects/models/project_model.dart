class ProjectModel {
  final String id;
  final String foundationId;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status; // 'active', 'completed', 'planned'
  final DateTime createdAt;

  // Agregasi Keuangan Proyek (dihitung secara dinamis)
  final double totalIncome;
  final double totalExpense;

  ProjectModel({
    required this.id,
    required this.foundationId,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
  });

  double get balance => totalIncome - totalExpense;

  factory ProjectModel.fromJson(Map<String, dynamic> json, {double totalIncome = 0.0, double totalExpense = 0.0}) {
    return ProjectModel(
      id: json['id'] as String,
      foundationId: json['foundation_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foundation_id': foundationId,
      'name': name,
      'description': description,
      if (startDate != null) 'start_date': startDate!.toIso8601String().substring(0, 10),
      if (endDate != null) 'end_date': endDate!.toIso8601String().substring(0, 10),
      'status': status,
    };
  }

  ProjectModel copyWith({
    String? id,
    String? foundationId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? createdAt,
    double? totalIncome,
    double? totalExpense,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      foundationId: foundationId ?? this.foundationId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }
}
