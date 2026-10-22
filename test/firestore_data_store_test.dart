// FirestoreDataStore + FlashcardService trên Firestore giả: ghi đúng document, xóa subcollection, Khám phá
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/models/user.dart';
import 'package:flashcard_app/services/data_store.dart';
import 'package:flashcard_app/services/flashcard_service.dart';
import 'package:flashcard_app/services/seed_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = DateTime(2026, 10, 21, 9);
  final alice = User(id: 'alice', username: 'Alice', email: 'a@x.vn');
  final bob = User(id: 'bob', username: 'Bob', email: 'b@x.vn');
  late FakeFirebaseFirestore db;
  final service = FlashcardService();

  setUp(() async {
    db = FakeFirebaseFirestore();
    service.useStore(FirestoreDataStore(db));
    service.clock = () => today;
    await service.loadForUser(alice);
  });

  Future<String> makeDeck({String visibility = 'private'}) async {
    final d = (await service.createDeck(title: 'Dart', visibility: visibility))!;
    for (var i = 0; i < 3; i++) {
      await service.addCard(d.id, Flashcard(term: 'T$i', meaning: 'M$i'));
    }
    return d.id;
  }

  test('tạo bộ thẻ: decks/{id} và decks/{id}/cards/{cardId} có thứ tự', () async {
    final id = await makeDeck();
    final deckDoc = await db.doc('decks/$id').get();
    expect(deckDoc.data()!['userId'], 'alice');
    final cards = await db.collection('decks/$id/cards').orderBy('order').get();
    expect(cards.docs.map((d) => d.data()['term']), ['T0', 'T1', 'T2']);

    // Đọc lại từ Firestore ra đúng bộ thẻ
    await service.loadForUser(alice);
    expect(service.deckById(id)!.cards.map((c) => c.term), ['T0', 'T1', 'T2']);
  });

  test('sửa một thẻ chỉ ghi đúng document thẻ đó', () async {
    final id = await makeDeck();
    final deck = service.deckById(id)!;
    final other = await db.doc('decks/$id/cards/${deck.cards[1].id}').get();
    await service.updateCard(id, deck.cards[0].copyWith()..meaning = 'Mới');
    expect((await db.doc('decks/$id/cards/${deck.cards[0].id}').get()).data()!['meaning'], 'Mới');
    // Thẻ khác không bị ghi lại
    expect((await db.doc('decks/$id/cards/${deck.cards[1].id}').get()).data(), other.data());
  });

  test('đổi chỗ thẻ cập nhật thứ tự; xóa bộ thẻ xóa cả subcollection cards', () async {
    final id = await makeDeck();
    final first = service.deckById(id)!.cards[0].id;
    await service.moveCard(id, first, 1);
    await service.loadForUser(alice);
    expect(service.deckById(id)!.cards[1].id, first);

    await service.deleteDeck(id);
    expect((await db.doc('decks/$id').get()).exists, isFalse);
    expect((await db.collection('decks/$id/cards').get()).docs, isEmpty);
  });

  test('tiến độ, hồ sơ, trạng thái học lưu ở users/{uid}', () async {
    final id = await makeDeck();
    final card = service.deckById(id)!.cards[0].id;
    await service.recordFlashcardSeen(card);
    await service.toggleStar(card);
    await service.savePosition(id, 2);
    expect((await db.doc('users/alice/progress/$card').get()).exists, isTrue);
    expect((await db.doc('users/alice').get()).data()!['starredCardIds'], [card]);
    expect((await db.doc('users/alice/state/learn').get()).data()!['positions'], {id: 2});
  });

  test('Khám phá: bộ công khai của người khác, không gồm bộ của chính mình', () async {
    final pub = await makeDeck(visibility: 'public');
    final priv = await makeDeck();
    expect(service.exploreDecks, isEmpty);
    await service.loadForUser(bob);
    expect(service.exploreDecks.map((d) => d.id), [pub]);
    expect(service.deckById(priv), isNull);
  });

  test('seed bộ thẻ mẫu chạy một lần, bỏ qua bộ đã có', () async {
    final n = communityDecks().length;
    expect(await seedCommunityDecks(db), n);
    expect(await seedCommunityDecks(db), 0);
    await service.loadForUser(bob);
    expect(service.exploreDecks.length, n);
    expect(service.deckById('seed_sql')!.cards, isNotEmpty);
  });
}
