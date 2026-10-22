// Kiểm tra FirestoreRepository<T> trên Firestore giả (fake_cloud_firestore)
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/models/flashcard_set.dart';
import 'package:flashcard_app/services/firestore_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreRepository<FlashcardSet> repo;

  FlashcardSet deck(String id, {String visibility = 'private', String title = 'Bộ'}) => FlashcardSet(
        id: id,
        userId: 'u1',
        ownerName: 'An',
        title: title,
        visibility: visibility,
        cards: [],
        createdAt: DateTime(2026, 10, 1, 8),
        updatedAt: DateTime(2026, 10, 2, 9),
      );

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreRepository(db.collection('decks'), FlashcardSet.fromMap);
  });

  test('thêm rồi đọc: getAll, getById', () async {
    await repo.add(deck('a', title: 'Dart'));
    await repo.add(deck('b', title: 'SQL', visibility: 'public'));
    expect((await repo.getAll()).map((d) => d.id).toSet(), {'a', 'b'});
    expect((await repo.getById('a'))!.title, 'Dart');
    expect(await repo.getById('khong-co'), isNull);
    // Truy vấn có điều kiện
    final pub = await repo.getAll(query: (q) => q.where('visibility', isEqualTo: 'public'));
    expect(pub.single.id, 'b');
  });

  test('sửa: chỉ đổi trường của đối tượng, giữ trường thêm trong document', () async {
    final cards = FirestoreRepository<Flashcard>(db.collection('decks/a/cards'), Flashcard.fromMap);
    final c = Flashcard(id: 'c1', term: 'const', meaning: 'hằng');
    await cards.add(c, extra: {'order': 3});
    c.meaning = 'hằng số';
    await cards.update(c);
    final doc = await db.doc('decks/a/cards/c1').get();
    expect(doc.data()!['meaning'], 'hằng số');
    expect(doc.data()!['order'], 3);
  });

  test('xóa', () async {
    await repo.add(deck('a'));
    await repo.delete('a');
    expect(await repo.getById('a'), isNull);
    expect(await repo.getAll(), isEmpty);
  });

  test('watchAll phát danh sách mới khi dữ liệu đổi', () async {
    final emitted = <List<String>>[];
    final sub = repo.watchAll().listen((list) => emitted.add(list.map((d) => d.id).toList()..sort()));
    await Future<void>.delayed(Duration.zero);
    await repo.add(deck('a'));
    await Future<void>.delayed(Duration.zero);
    await repo.add(deck('b'));
    await Future<void>.delayed(Duration.zero);
    await repo.delete('a');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(emitted.first, isEmpty);
    expect(emitted, anyElement(equals(['a', 'b'])));
    expect(emitted.last, ['b']);
  });
}
