class User {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? university;
  final String? studentId;
  final String role;
  final double rating;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.university,
    this.studentId,
    required this.role,
    required this.rating,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      university: json['university'],
      studentId: json['studentId'],
      role: json['role'] ?? 'PASSENGER',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0,
    );
  }
}
