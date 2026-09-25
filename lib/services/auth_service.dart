import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'currentUser';
  final Uuid _uuid = Uuid();

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<Map<String, User>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) return {};

    final Map<String, dynamic> usersMap = json.decode(usersJson);
    final Map<String, User> users = {};

    usersMap.forEach((email, userJson) {
      users[email] = User.fromJson(userJson);
    });

    return users;
  }

  Future<void> _saveUsers(Map<String, User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> usersMap = {};

    users.forEach((email, user) {
      usersMap[email] = user.toJson();
    });

    await prefs.setString(_usersKey, json.encode(usersMap));
  }

  // Đăng ký user mới - ĐÃ HOÀN THIỆN
  Future<bool> register(String username, String email, String password) async {
    final users = await _getUsers();

    if (users.containsKey(email)) {
      return false;
    }

    final newUser = User(
      username: username,
      email: email,
      passwordHash: _hashPassword(password),
      createdAt: DateTime.now(),
    );

    users[email] = newUser;
    await _saveUsers(users);
    await setCurrentUser(newUser);

    return true;
  }

  // Đăng nhập - ĐÃ HOÀN THIỆN
  Future<bool> login(String email, String password) async {
    final users = await _getUsers();
    final user = users[email];

    if (user == null) return false;

    final passwordHash = _hashPassword(password);
    if (user.passwordHash == passwordHash) {
      await setCurrentUser(user);
      return true;
    }

    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<void> setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);

    if (userJson == null) return null;

    try {
      return User.fromJson(json.decode(userJson));
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    return await getCurrentUser() != null;
  }

  // NEW: Lấy ID của user hiện tại
  Future<String?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?.id;
  }
}