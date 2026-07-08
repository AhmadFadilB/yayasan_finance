class ProfileModel {
  final String id;
  final String name;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    required this.name,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
