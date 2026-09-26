import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;
  final int dailyGoal;
  final bool darkMode;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.dailyGoal = 20,
    this.darkMode = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': id,
      'username': username,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'dailyGoal': dailyGoal,
      'darkMode': darkMode,
    };
  }

  factory User.fromFirestore(String uid, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return User(
      id: uid,
      username: data['username'] as String? ?? 'Người dùng',
      email: data['email'] as String? ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse(createdAt?.toString() ?? '') ?? DateTime.now(),
      dailyGoal: (data['dailyGoal'] as num?)?.toInt() ?? 20,
      darkMode: data['darkMode'] as bool? ?? false,
    );
  }
}
