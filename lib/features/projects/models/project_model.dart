class ProjectModel {
  final String id;
  final String foundationId;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status; // 'active', 'completed', 'planned'
  final DateTime createdAt;
  final bool isPublic;
  final double? targetAmount;
  final String? coverImageUrl;
  final List<String>? galleryUrls;
  final String? videoUrl;

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
    this.isPublic = false,
    this.targetAmount,
    this.coverImageUrl,
    this.galleryUrls,
    this.videoUrl,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
  });

  double get balance => totalIncome - totalExpense;

  factory ProjectModel.fromJson(Map<String, dynamic> json, {double totalIncome = 0.0, double totalExpense = 0.0}) {
    return ProjectModel(
      id: json['id']?.toString() ?? '',
      foundationId: json['foundation_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'].toString()) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'].toString()) : null,
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      isPublic: json['is_public'] as bool? ?? false,
      targetAmount: json['target_amount'] != null ? (json['target_amount'] as num).toDouble() : null,
      coverImageUrl: json['cover_image_url']?.toString(),
      galleryUrls: json['gallery_urls'] != null 
          ? List<String>.from(json['gallery_urls'] as List) 
          : null,
      videoUrl: json['video_url']?.toString(),
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
      'is_public': isPublic,
      'target_amount': targetAmount,
      'cover_image_url': coverImageUrl,
      'gallery_urls': galleryUrls,
      'video_url': videoUrl,
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
    bool? isPublic,
    double? targetAmount,
    bool setTargetAmountToNull = false,
    String? coverImageUrl,
    bool setCoverImageUrlToNull = false,
    List<String>? galleryUrls,
    bool setGalleryUrlsToNull = false,
    String? videoUrl,
    bool setVideoUrlToNull = false,
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
      isPublic: isPublic ?? this.isPublic,
      targetAmount: setTargetAmountToNull ? null : (targetAmount ?? this.targetAmount),
      coverImageUrl: setCoverImageUrlToNull ? null : (coverImageUrl ?? this.coverImageUrl),
      galleryUrls: setGalleryUrlsToNull ? null : (galleryUrls ?? this.galleryUrls),
      videoUrl: setVideoUrlToNull ? null : (videoUrl ?? this.videoUrl),
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }
}
