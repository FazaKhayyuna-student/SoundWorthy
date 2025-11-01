class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String passwordHash; // Password yang sudah di-enkripsi

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passwordHash,
  });

  // Konversi Objek User menjadi Map (untuk disimpan ke DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'passwordHash': passwordHash,
    };
  }

  // Konversi Map dari DB menjadi Objek User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      passwordHash: map['passwordHash'],
    );
  }
}

