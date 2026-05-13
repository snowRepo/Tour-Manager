import 'package:decimal/decimal.dart';

class TripModel {
  final int? id;
  final int clientId;
  final String destination;
  final String departureDate;
  final String returnDate;
  final Decimal totalCost;
  final String status;
  final String createdAt;
  final String updatedAt;

  const TripModel({
    this.id,
    required this.clientId,
    required this.destination,
    required this.departureDate,
    required this.returnDate,
    required this.totalCost,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'client_id': clientId,
    'destination': destination,
    'departure_date': departureDate,
    'return_date': returnDate,
    'total_cost': totalCost.toString(),
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory TripModel.fromMap(Map<String, dynamic> map) => TripModel(
    id: map['id'] as int?,
    clientId: map['client_id'] as int,
    destination: map['destination'] as String,
    departureDate: map['departure_date'] as String,
    returnDate: map['return_date'] as String,
    totalCost: Decimal.parse(map['total_cost'].toString()),
    status: map['status'] as String,
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
  );

  TripModel copyWith({
    int? id,
    int? clientId,
    String? destination,
    String? departureDate,
    String? returnDate,
    Decimal? totalCost,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) => TripModel(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    destination: destination ?? this.destination,
    departureDate: departureDate ?? this.departureDate,
    returnDate: returnDate ?? this.returnDate,
    totalCost: totalCost ?? this.totalCost,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
