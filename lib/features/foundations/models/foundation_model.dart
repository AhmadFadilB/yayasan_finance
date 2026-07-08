class FoundationModel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String? currentUserRole; // Peran pengguna aktif di yayasan ini

  FoundationModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.currentUserRole,
  });

  factory FoundationModel.fromJson(Map<String, dynamic> json, {String? role}) {
    return FoundationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      currentUserRole: role,
    );
  }

  // Deserialisasi dari relasi join table foundation_members di Supabase
  factory FoundationModel.fromJoinJson(Map<String, dynamic> json) {
    final foundationJson = json['foundations'] as Map<String, dynamic>;
    final role = json['role'] as String;
    return FoundationModel.fromJson(foundationJson, role: role);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FoundationModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    String? currentUserRole,
  }) {
    return FoundationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      currentUserRole: currentUserRole ?? this.currentUserRole,
    );
  }
}

// Model data Anggota Yayasan untuk halaman manajemen anggota
class FoundationMemberModel {
  final String profileId;
  final String name;
  final String role;
  final DateTime createdAt;

  FoundationMemberModel({
    required this.profileId,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  factory FoundationMemberModel.fromJoinJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>;
    return FoundationMemberModel(
      profileId: profile['id'] as String,
      name: profile['name'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
