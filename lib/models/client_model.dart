class ClientModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String otherNames;
  final String phone;
  final String email;
  final String notes;
  final String createdAt;
  final String updatedAt;

  const ClientModel({
    this.id,
    required this.firstName,
    required this.lastName,
    this.otherNames = '',
    this.phone = '',
    this.email = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    final parts = [firstName, otherNames, lastName]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'other_names': otherNames,
        'phone': phone,
        'email': email,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
        id: map['id'] as int?,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        otherNames: map['other_names'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  ClientModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? otherNames,
    String? phone,
    String? email,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) =>
      ClientModel(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        otherNames: otherNames ?? this.otherNames,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
