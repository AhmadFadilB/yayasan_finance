class TransactionModel {
  final String id;
  final String foundationId;
  final String? projectId;
  final String? projectName; // Diambil dari join query table projects
  final String? accountId;
  final String type; // 'income' atau 'expense'
  final double amount;
  final String category;
  final String? description;
  final DateTime transactionDate;
  final String? createdBy;
  final String? creatorName; // Diambil dari join query table profiles
  final DateTime createdAt;
  final String? receiptUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? approverName; // Diambil dari join query table profiles (as approver)

  TransactionModel({
    required this.id,
    required this.foundationId,
    this.projectId,
    this.projectName,
    this.accountId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.transactionDate,
    this.createdBy,
    this.creatorName,
    required this.createdAt,
    this.receiptUrl,
    this.status = 'approved',
    this.approvedBy,
    this.approvedAt,
    this.approverName,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Penanganan join untuk nama proyek
    String? pName;
    if (json['projects'] != null) {
      pName = json['projects']['name'] as String?;
    }

    // Penanganan join untuk nama pembuat
    String? cName;
    if (json['profiles'] != null) {
      cName = json['profiles']['name'] as String?;
    }

    // Penanganan join untuk nama penyetuju
    String? aName;
    if (json['approver'] != null) {
      aName = json['approver']['name'] as String?;
    }

    return TransactionModel(
      id: json['id'] as String,
      foundationId: json['foundation_id'] as String,
      projectId: json['project_id'] as String?,
      projectName: pName,
      accountId: json['account_id'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdBy: json['created_by'] as String?,
      creatorName: cName,
      createdAt: DateTime.parse(json['created_at'] as String),
      receiptUrl: json['receipt_url'] as String?,
      status: json['status'] as String? ?? 'approved',
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at'] as String) : null,
      approverName: aName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foundation_id': foundationId,
      'project_id': projectId,
      'account_id': accountId,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10), // yyyy-MM-dd
      'created_by': createdBy,
      'receipt_url': receiptUrl,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? foundationId,
    String? projectId,
    String? projectName,
    String? accountId,
    String? type,
    double? amount,
    String? category,
    String? description,
    DateTime? transactionDate,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
    String? receiptUrl,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? approverName,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      foundationId: foundationId ?? this.foundationId,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      approverName: approverName ?? this.approverName,
    );
  }
}
