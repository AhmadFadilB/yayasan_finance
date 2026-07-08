class CoaModel {
  final String id;
  final String foundationId;
  final String code;
  final String name;
  final String category;
  final String? parentCode;
  final bool isActive;
  final DateTime createdAt;

  CoaModel({
    required this.id,
    required this.foundationId,
    required this.code,
    required this.name,
    required this.category,
    this.parentCode,
    required this.isActive,
    required this.createdAt,
  });

  factory CoaModel.fromJson(Map<String, dynamic> json) {
    return CoaModel(
      id: json['id'] as String,
      foundationId: json['foundation_id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      parentCode: json['parent_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foundation_id': foundationId,
      'code': code,
      'name': name,
      'category': category,
      'parent_code': parentCode,
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  CoaModel copyWith({
    String? id,
    String? foundationId,
    String? code,
    String? name,
    String? category,
    String? parentCode,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CoaModel(
      id: id ?? this.id,
      foundationId: foundationId ?? this.foundationId,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      parentCode: parentCode ?? this.parentCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get friendly name of the account category in Indonesian
  String get friendlyCategoryName {
    switch (category) {
      case 'asset':
        return 'Aset';
      case 'liability':
        return 'Liabilitas';
      case 'net_asset':
        return 'Aset Neto';
      case 'revenue':
        return 'Penerimaan';
      case 'expense':
        return 'Beban';
      default:
        return category;
    }
  }
}
