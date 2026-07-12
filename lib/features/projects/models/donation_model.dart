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
      donationAmount = (json['transactions']['amount'] as num?)?.toDouble();
    } else if (json['amount'] != null) {
      donationAmount = (json['amount'] as num).toDouble();
    }

    return DonationModel(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      donorName: json['donor_name'] as String,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      uniqueCode: json['unique_code'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
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
