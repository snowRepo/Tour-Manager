class ClientModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String otherNames;
  final String gender;
  final String phone;
  final String email;
  final String passportNumber;
  final String dateOfBirth;
  final String notes;
  final String createdAt;
  final String updatedAt;

  const ClientModel({
    this.id,
    required this.firstName,
    required this.lastName,
    this.otherNames = '',
    this.gender = 'Other',
    this.phone = '',
    this.email = '',
    this.passportNumber = '',
    this.dateOfBirth = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    final parts = [
      firstName,
      otherNames,
      lastName,
    ].where((p) => p.trim().isNotEmpty).toList();
    return parts.join(' ');
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'other_names': otherNames,
    'gender': gender,
    'phone': phone,
    'email': email,
    'passport_number': passportNumber,
    'date_of_birth': dateOfBirth,
    'notes': notes,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
    id: map['id'] as int?,
    firstName: map['first_name'] as String,
    lastName: map['last_name'] as String,
    otherNames: map['other_names'] as String? ?? '',
    gender: map['gender'] as String? ?? 'Other',
    phone: map['phone'] as String? ?? '',
    email: map['email'] as String? ?? '',
    passportNumber: map['passport_number'] as String? ?? '',
    dateOfBirth: map['date_of_birth'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
  );

  ClientModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? otherNames,
    String? gender,
    String? phone,
    String? email,
    String? passportNumber,
    String? dateOfBirth,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) => ClientModel(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    otherNames: otherNames ?? this.otherNames,
    gender: gender ?? this.gender,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    passportNumber: passportNumber ?? this.passportNumber,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
