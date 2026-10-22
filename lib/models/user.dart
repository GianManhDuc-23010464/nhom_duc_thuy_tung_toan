// models/user.dart - HỒ SƠ NGƯỜI DÙNG (users/{uid}); mật khẩu do Firebase Auth quản lý
import 'base_entity.dart';

class User {
  final String id; // uid của Firebase Auth
  final String username; // Tên hiển thị
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  User copyWith({String? username}) => User(
        id: id,
        username: username ?? this.username,
        email: email,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'username': username,
        'email': email,
        'createdAt': toTimestamp(createdAt),
      };

  factory User.fromFirestore(Map<String, dynamic> data, String id) => User(
        id: id,
        username: data['username'] ?? '',
        email: data['email'] ?? '',
        createdAt: fromTimestamp(data['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      );
}
