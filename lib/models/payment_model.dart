import 'package:decimal/decimal.dart';

class PaymentModel {
  final int? id;
  final int tripId;
  final Decimal amount; // negative = refund
  final String paymentMethod;
  final String? referenceNumber;
  final String paymentDate;
  final String? note;
  final String createdAt;

  const PaymentModel({
    this.id,
    required this.tripId,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    required this.paymentDate,
    this.note,
    required this.createdAt,
  });

  bool get isRefund => amount < Decimal.zero;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'trip_id': tripId,
    'amount': amount.toString(),
    'payment_method': paymentMethod,
    'reference_number': referenceNumber,
    'payment_date': paymentDate,
    'note': note,
    'created_at': createdAt,
  };

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
    id: map['id'] as int?,
    tripId: map['trip_id'] as int,
    amount: Decimal.parse(map['amount'].toString()),
    paymentMethod: map['payment_method'] as String,
    referenceNumber: map['reference_number'] as String?,
    paymentDate:
        map['payment_date'] as String? ?? DateTime.now().toIso8601String(),
    note: map['note'] as String?,
    createdAt: map['created_at'] as String,
  );

  PaymentModel copyWith({
    int? id,
    int? tripId,
    Decimal? amount,
    String? paymentMethod,
    String? referenceNumber,
    String? paymentDate,
    String? note,
    String? createdAt,
  }) => PaymentModel(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    amount: amount ?? this.amount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    referenceNumber: referenceNumber ?? this.referenceNumber,
    paymentDate: paymentDate ?? this.paymentDate,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );
}
