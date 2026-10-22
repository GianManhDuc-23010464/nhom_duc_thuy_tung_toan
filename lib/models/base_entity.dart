// models/base_entity.dart - LỚP CHUNG CHO CÁC ĐỐI TƯỢNG LƯU TRÊN FIRESTORE
// Mỗi lớp con cài toMap() và cung cấp factory X.fromMap(Map, id) để FirestoreRepository đọc lại.
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseEntity {
  String get id;
  String get name;
  String get description;
  DateTime get createdAt;
  DateTime get updatedAt;

  // Dữ liệu ghi vào document (không gồm id: id là tên document)
  Map<String, dynamic> toMap();
}

// Chuyển đổi ngày giờ giữa Dart và Firestore; đọc được cả Timestamp lẫn chuỗi ISO (dữ liệu cũ)
Timestamp? toTimestamp(DateTime? d) => d == null ? null : Timestamp.fromDate(d);

DateTime? fromTimestamp(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
