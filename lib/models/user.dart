// models/user.dart - HỒ SƠ NGƯỜI DÙNG (users/{uid}); mật khẩu do Firebase Auth quản lý
import 'base_entity.dart';

// Hồ sơ người dùng; id là uid của Firebase Auth
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

  // Tạo bản sao với tên hiển thị mới, các trường khác giữ nguyên
  User copyWith({String? username}) => User(
        id: id,
        username: username ?? this.username,
        email: email,
        createdAt: createdAt,
      );

  // Dữ liệu ghi vào document users/{uid} (id là tên document nên không lưu lặp)
  Map<String, dynamic> toFirestore() => {
        'username': username,
        'email': email,
        'createdAt': toTimestamp(createdAt),
      };

  // Dựng đối tượng từ document; trường thiếu nhận giá trị mặc định
  factory User.fromFirestore(Map<String, dynamic> data, String id) => User(
        id: id,
        username: data['username'] ?? '',
        email: data['email'] ?? '',
        createdAt: fromTimestamp(data['createdAt']),
      );

  // Chuyển sang JSON, ngày giờ lưu dạng chuỗi ISO 8601
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };

  // Đọc lại từ JSON do toJson() tạo ra
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      );
}
