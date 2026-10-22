// services/firestore_repository.dart - CRUD CHUNG CHO MỘT COLLECTION FIRESTORE
// Dùng cho bộ thẻ (decks), thẻ (decks/{id}/cards) và kết quả kiểm tra (users/{uid}/quizAttempts).
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/base_entity.dart';

class FirestoreRepository<T extends BaseEntity> {
  final CollectionReference<Map<String, dynamic>> collection;
  final T Function(Map<String, dynamic> data, String id) fromMap;

  FirestoreRepository(this.collection, this.fromMap);

  DocumentReference<Map<String, dynamic>> doc(String id) => collection.doc(id);

  T _read(DocumentSnapshot<Map<String, dynamic>> d) => fromMap(d.data()!, d.id);

  // query: lọc / sắp xếp thêm (ví dụ where visibility == 'public')
  Future<List<T>> getAll({Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> q)? query}) async {
    final snap = await (query == null ? collection : query(collection)).get();
    return snap.docs.map(_read).toList();
  }

  Future<T?> getById(String id) async {
    final d = await collection.doc(id).get();
    return d.exists ? _read(d) : null;
  }

  // Ghi document theo id của đối tượng; extra: trường thêm không thuộc model (ví dụ order)
  Future<void> add(T item, {Map<String, dynamic> extra = const {}}) =>
      collection.doc(item.id).set({...item.toMap(), ...extra});

  // Cập nhật các trường của đối tượng, giữ nguyên trường khác trong document
  Future<void> update(T item, {Map<String, dynamic> extra = const {}}) =>
      collection.doc(item.id).set({...item.toMap(), ...extra}, SetOptions(merge: true));

  Future<void> delete(String id) => collection.doc(id).delete();

  Stream<List<T>> watchAll({Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> q)? query}) =>
      (query == null ? collection : query(collection)).snapshots().map((s) => s.docs.map(_read).toList());
}
