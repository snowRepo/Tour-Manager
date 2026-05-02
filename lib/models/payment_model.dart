class PaymentModel {
  final int? id;
  final int tripId;
  final double amount; // negative = refund
  final String paymentMethod;
  final String? note;
  final String createdAt;

  const PaymentModel({
    this.id,
    required this.tripId,
    required this.amount,
    required this.paymentMethod,
    this.note,
    required this.createdAt,
  });

  bool get isRefund => amount < 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'trip_id': tripId,
        'amount': amount,
        'payment_method': paymentMethod,
        'note': note,
        'created_at': createdAt,
      };

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
        id: map['id'] as int?,
        tripId: map['trip_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        paymentMethod: map['payment_method'] as String,
        note: map['note'] as String?,
        createdAt: map['created_at'] as String,
      );

  PaymentModel copyWith({
    int? id,
    int? tripId,
    double? amount,
    String? paymentMethod,
    String? note,
    String? createdAt,
  }) =>
      PaymentModel(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );
}
