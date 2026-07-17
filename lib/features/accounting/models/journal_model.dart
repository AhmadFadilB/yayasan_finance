class JournalItemModel {
  final String id;
  final String entryId;
  final String accountId;
  final String? accountCode;
  final String? accountName;
  final double debit;
  final double credit;
  final String? projectId;
  final String? projectName;
  final String? memo;

  JournalItemModel({
    required this.id,
    required this.entryId,
    required this.accountId,
    this.accountCode,
    this.accountName,
    required this.debit,
    required this.credit,
    this.projectId,
    this.projectName,
    this.memo,
  });

  factory JournalItemModel.fromJson(Map<String, dynamic> json) {
    // Joins handling for Account details
    String? accCode;
    String? accName;
    if (json['chart_of_accounts'] != null) {
      accCode = json['chart_of_accounts']['code'] as String?;
      accName = json['chart_of_accounts']['name'] as String?;
    }

    // Joins handling for Project name
    String? projName;
    if (json['projects'] != null) {
      projName = json['projects']['name'] as String?;
    }

    return JournalItemModel(
      id: json['id'] as String,
      entryId: json['entry_id'] as String,
      accountId: json['account_id'] as String,
      accountCode: accCode ?? json['account_code'] as String?,
      accountName: accName ?? json['account_name'] as String?,
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      projectId: json['project_id'] as String?,
      projectName: projName ?? json['project_name'] as String?,
      memo: json['memo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (entryId.isNotEmpty) 'entry_id': entryId,
      'account_id': accountId,
      'debit': debit,
      'credit': credit,
      'project_id': projectId,
      'memo': memo,
    };
  }

  JournalItemModel copyWith({
    String? id,
    String? entryId,
    String? accountId,
    String? accountCode,
    String? accountName,
    double? debit,
    double? credit,
    String? projectId,
    String? projectName,
    String? memo,
  }) {
    return JournalItemModel(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      accountId: accountId ?? this.accountId,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      memo: memo ?? this.memo,
    );
  }
}

class JournalEntryModel {
  final String id;
  final String foundationId;
  final String proofNumber;
  final DateTime transactionDate;
  final String? description;
  final String? changeReason;
  final String? createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final List<JournalItemModel> items;

  JournalEntryModel({
    required this.id,
    required this.foundationId,
    required this.proofNumber,
    required this.transactionDate,
    this.description,
    this.changeReason,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    this.items = const [],
  });

  double get totalDebit => items.fold(0.0, (sum, item) => sum + item.debit);
  double get totalCredit => items.fold(0.0, (sum, item) => sum + item.credit);
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;

  factory JournalEntryModel.fromJson(Map<String, dynamic> json, {List<JournalItemModel> items = const []}) {
    // Joins handling for creator profile name
    String? creator;
    if (json['profiles'] != null) {
      creator = json['profiles']['name'] as String?;
    }

    return JournalEntryModel(
      id: json['id'] as String,
      foundationId: json['foundation_id'] as String,
      proofNumber: json['proof_number'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      description: json['description'] as String?,
      changeReason: json['change_reason'] as String?,
      createdBy: json['created_by'] as String?,
      createdByName: creator ?? json['creator_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'foundation_id': foundationId,
      'proof_number': proofNumber,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
      'description': description,
      'change_reason': changeReason,
      'created_by': createdBy,
    };
  }

  JournalEntryModel copyWith({
    String? id,
    String? foundationId,
    String? proofNumber,
    DateTime? transactionDate,
    String? description,
    String? changeReason,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    List<JournalItemModel>? items,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      foundationId: foundationId ?? this.foundationId,
      proofNumber: proofNumber ?? this.proofNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      changeReason: changeReason ?? this.changeReason,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
