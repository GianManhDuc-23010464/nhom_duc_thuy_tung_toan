import 'package:uuid/uuid.dart';

class User {
  final String id; // NEW
  final String username;
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  User({
    String? id, // NEW
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  }) : id = id ?? const Uuid().v4(); // NEW: Tạo ID nếu chưa có

  Map<String, dynamic> toJson() {
    return {
      'id': id, // NEW
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'], // NEW
      username: json['username'],
      email: json['email'],
      passwordHash: json['passwordHash'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}