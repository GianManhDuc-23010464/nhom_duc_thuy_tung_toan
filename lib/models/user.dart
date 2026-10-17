import 'package:uuid/uuid.dart';
import '../entities/Genericclass.dart';

/// Lớp User kế thừa Genericclass<String>
/// Kế thừa các thuộc tính chung:
/// - id: mã người dùng
/// - name: tên người dùng (username)
/// - description: mô tả/tiểu sử người dùng
/// Kế thừa các phương thức chung: getId(), getName(), getDescription(), setId(), setName(), setDescription()
class User extends Genericclass<String> {
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  User({
    String? id,
    String? username,
    String? name,
    String description = '',
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  }) : super(
          id: id ?? const Uuid().v4(),
          name: name ?? username ?? '',
          description: description,
        );

  // Getter & Setter cho username để tương thích code cũ
  String get username => name;
  set username(String val) => name = val;

  // Phương thức riêng cho User
  String getEmail() => email;
  DateTime getCreatedAt() => createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'description': description,
      'email': email,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? json['name'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      description: json['description'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['passwordHash'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}