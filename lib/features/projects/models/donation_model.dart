class DonationModel {
  final String id;
  final String transactionId;
  final String donorName;
  final bool isAnonymous;
  final String? email;
  final String? phone;
  final int uniqueCode;
  final DateTime createdAt;
  
  // Keuangan donasi (opsional dibaca dari join transaction)
  final double? amount;

  DonationModel({
    required this.id,
    required this.transactionId,
    required this.donorName,
    this.isAnonymous = false,
    this.email,
    this.phone,
    required this.uniqueCode,
    required this.createdAt,
    this.amount,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    double? donationAmount;
    if (json['transactions'] != null) {
      if (json['transactions'] is List) {
        final list = json['transactions'] as List;
        if (list.isNotEmpty) {
          final tx = list.first;
          if (tx is Map) {
            donationAmount = (tx['amount'] as num?)?.toDouble();
          }
        }
      } else if (json['transactions'] is Map) {
        donationAmount = (json['transactions']['amount'] as num?)?.toDouble();
      }
    } else if (json['amount'] != null) {
      donationAmount = (json['amount'] as num?)?.toDouble();
    }

    return DonationModel(
      id: json['id']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? '',
      donorName: json['donor_name']?.toString() ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      uniqueCode: (json['unique_code'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      amount: donationAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'donor_name': donorName,
      'is_anonymous': isAnonymous,
      'email': email,
      'phone': phone,
      'unique_code': uniqueCode,
    };
  }
}
