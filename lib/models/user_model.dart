class UserModel {
  final int? id;
  final String username;
  final String firstName;
  final String lastName;
  final String passwordHash;
  final String pinHash;

  const UserModel({
    this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.passwordHash,
    required this.pinHash,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'password_hash': passwordHash,
        'pin_hash': pinHash,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        username: map['username'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        passwordHash: map['password_hash'] as String,
        pinHash: map['pin_hash'] as String,
      );

  UserModel copyWith({
    int? id,
    String? username,
    String? firstName,
    String? lastName,
    String? passwordHash,
    String? pinHash,
  }) =>
      UserModel(
        id: id ?? this.id,
        username: username ?? this.username,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        passwordHash: passwordHash ?? this.passwordHash,
        pinHash: pinHash ?? this.pinHash,
      );
}
