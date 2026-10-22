// services/data_store.dart - LỚP LƯU TRỮ DỮ LIỆU
// DataStore là ranh giới với backend. Mỗi thao tác chỉ ghi đúng document liên quan.
// - FirestoreDataStore: dùng trong app (Firestore, có cache offline và tự đồng bộ).
// - LocalDataStore: lưu trong bộ nhớ, dùng cho test.
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/card_progress.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../models/quiz.dart';
import '../models/user_data.dart';
import 'firestore_repository.dart';

abstract class DataStore {
  // Bộ thẻ của tôi + bộ thẻ công khai của mọi người (kèm thẻ)
  Future<List<FlashcardSet>> loadDecks(String userId);
  Future<UserData> loadUserData(String userId);
  // ID các kết quả kiểm tra chưa đồng bộ lên máy chủ
  Stream<Set<String>> watchPendingAttempts(String userId);

  Future<void> saveDeck(FlashcardSet deck); // Thông tin + toàn bộ thẻ (tạo mới, sao chép)
  Future<void> saveDeckInfo(FlashcardSet deck); // Chỉ decks/{id}
  Future<void> saveCard(String deckId, Flashcard card, int order);
  Future<void> deleteCard(String deckId, String cardId);
  Future<void> deleteDeck(FlashcardSet deck); // Xóa cả subcollection cards
  Future<void> renameOwner(String userId, String ownerName); // Tên tác giả trên các bộ thẻ của người dùng

  Future<void> saveProfile(String userId, UserData data); // users/{uid}
  Future<void> saveLearnState(String userId, UserData data); // users/{uid}/state/learn
  Future<void> saveProgress(String userId, String cardId, CardProgress? progress); // null: xóa
  Future<void> saveAttempt(String userId, QuizAttempt attempt);
  Future<void> deleteAttempt(String userId, String attemptId);
}

// === FIRESTORE ===
class FirestoreDataStore implements DataStore {
  final FirebaseFirestore db;
  final bool Function() isOnline;
  final Duration writeTimeout;

  FirestoreDataStore(this.db, {bool Function()? isOnline, this.writeTimeout = const Duration(seconds: 8)})
      : isOnline = isOnline ?? (() => true);

  late final FirestoreRepository<FlashcardSet> decks =
      FirestoreRepository(db.collection('decks'), FlashcardSet.fromMap);

  FirestoreRepository<Flashcard> cards(String deckId) =>
      FirestoreRepository(db.collection('decks').doc(deckId).collection('cards'), Flashcard.fromMap);

  FirestoreRepository<QuizAttempt> attempts(String userId) =>
      FirestoreRepository(_user(userId).collection('quizAttempts'), QuizAttempt.fromMap);

  DocumentReference<Map<String, dynamic>> _user(String userId) => db.collection('users').doc(userId);
  DocumentReference<Map<String, dynamic>> _learn(String userId) => _user(userId).collection('state').doc('learn');
  CollectionReference<Map<String, dynamic>> _progress(String userId) => _user(userId).collection('progress');

  // Firestore chỉ hoàn tất lệnh ghi khi máy chủ xác nhận. Khi mất mạng (hoặc chờ quá lâu) dữ liệu đã nằm
  // trong cache cục bộ và sẽ tự đồng bộ, nên không chờ tiếp; lỗi thật (ví dụ bị từ chối quyền) vẫn được báo.
  Future<void> _write(Future<void> Function() op) async {
    final f = op();
    void log(Object e) => debugPrint('❌ Lỗi đồng bộ Firestore: $e');
    if (!isOnline()) {
      unawaited(f.catchError(log));
      return;
    }
    try {
      await f.timeout(writeTimeout);
    } on TimeoutException {
      unawaited(f.catchError(log));
    }
  }

  @override
  Future<List<FlashcardSet>> loadDecks(String userId) async {
    final mine = await decks.getAll(query: (q) => q.where('userId', isEqualTo: userId));
    final public = await decks.getAll(query: (q) => q.where('visibility', isEqualTo: 'public'));
    final all = [...mine, ...public.where((d) => d.userId != userId)];
    await Future.wait(all.map((d) async {
      d.cards = await cards(d.id).getAll(query: (q) => q.orderBy('order'));
    }));
    return all;
  }

  @override
  Future<UserData> loadUserData(String userId) async {
    final results = await Future.wait([
      _user(userId).get(),
      _learn(userId).get(),
      _progress(userId).get(),
      _user(userId).collection('quizAttempts').get(),
    ]);
    final profile = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final learn = results[1] as DocumentSnapshot<Map<String, dynamic>>;
    final progress = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final attemptDocs = results[3] as QuerySnapshot<Map<String, dynamic>>;
    return UserData.fromFirestore(
      profile.data(),
      learnState: learn.data(),
      progress: {for (final d in progress.docs) d.id: CardProgress.fromFirestore(d.data())},
      attempts: [
        for (final d in attemptDocs.docs)
          QuizAttempt.fromFirestore(d.data(), d.id, pendingSync: d.metadata.hasPendingWrites),
      ],
    );
  }

  @override
  Stream<Set<String>> watchPendingAttempts(String userId) => _user(userId)
      .collection('quizAttempts')
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.where((d) => d.metadata.hasPendingWrites).map((d) => d.id).toSet());

  // Batch tối đa 500 thao tác; chia nhỏ khi bộ thẻ lớn
  Future<void> _commitInChunks(List<void Function(WriteBatch b)> ops) async {
    for (var i = 0; i < ops.length; i += 450) {
      final batch = db.batch();
      for (final op in ops.skip(i).take(450)) {
        op(batch);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> saveDeck(FlashcardSet deck) => _write(() => _commitInChunks([
        (b) => b.set(decks.doc(deck.id), deck.toFirestore()),
        for (var i = 0; i < deck.cards.length; i++)
          (b) => b.set(cards(deck.id).doc(deck.cards[i].id), deck.cards[i].toFirestore(order: i)),
      ]));

  @override
  Future<void> saveDeckInfo(FlashcardSet deck) => _write(() => decks.update(deck));

  @override
  Future<void> saveCard(String deckId, Flashcard card, int order) =>
      _write(() => cards(deckId).add(card, extra: {'order': order}));

  @override
  Future<void> deleteCard(String deckId, String cardId) => _write(() => cards(deckId).delete(cardId));

  @override
  Future<void> deleteDeck(FlashcardSet deck) => _write(() async {
        // Lấy cả thẻ trên máy chủ để không sót thẻ nào trong subcollection
        final ids = {...deck.cards.map((c) => c.id)};
        try {
          ids.addAll((await cards(deck.id).collection.get()).docs.map((d) => d.id));
        } catch (_) {}
        await _commitInChunks([
          for (final id in ids) (b) => b.delete(cards(deck.id).doc(id)),
          (b) => b.delete(decks.doc(deck.id)),
        ]);
      });

  @override
  Future<void> renameOwner(String userId, String ownerName) => _write(() async {
        final mine = await decks.collection.where('userId', isEqualTo: userId).get();
        await _commitInChunks([
          for (final d in mine.docs) (b) => b.update(d.reference, {'ownerName': ownerName}),
        ]);
      });

  @override
  Future<void> saveProfile(String userId, UserData data) =>
      _write(() => _user(userId).set(data.toFirestore(), SetOptions(merge: true)));

  @override
  Future<void> saveLearnState(String userId, UserData data) =>
      _write(() => _learn(userId).set(data.learnStateToFirestore()));

  @override
  Future<void> saveProgress(String userId, String cardId, CardProgress? progress) => _write(() => progress == null
      ? _progress(userId).doc(cardId).delete()
      : _progress(userId).doc(cardId).set(progress.toFirestore()));

  @override
  Future<void> saveAttempt(String userId, QuizAttempt attempt) => _write(() => attempts(userId).add(attempt));

  @override
  Future<void> deleteAttempt(String userId, String attemptId) =>
      _write(() => attempts(userId).delete(attemptId));
}

// === BỘ NHỚ (TEST) ===
// Giữ bản sao JSON để thay đổi trên đối tượng trong app không lọt vào "kho" khi chưa ghi.
class LocalDataStore implements DataStore {
  final Map<String, Map<String, dynamic>> decks = {};
  final Map<String, Map<String, dynamic>> users = {};
  final Set<String> pendingAttempts = {};
  bool failWrites = false; // Giả lập lỗi ghi

  Map<String, dynamic> _copy(Object json) => jsonDecode(jsonEncode(json));

  Future<void> _write(void Function() op) async {
    if (failWrites) throw Exception('disk full');
    op();
  }

  UserData _userData(String userId) =>
      users[userId] == null ? UserData() : UserData.fromJson(_copy(users[userId]!));

  Future<void> _updateUser(String userId, void Function(UserData d) change) => _write(() {
        final d = _userData(userId);
        change(d);
        users[userId] = _copy(d.toJson());
      });

  @override
  Future<List<FlashcardSet>> loadDecks(String userId) async => decks.values
      .map((j) => FlashcardSet.fromJson(_copy(j)))
      .where((d) => d.userId == userId || d.isPublic)
      .toList();

  @override
  Future<UserData> loadUserData(String userId) async => _userData(userId);

  @override
  Stream<Set<String>> watchPendingAttempts(String userId) => Stream.value(Set.of(pendingAttempts));

  @override
  Future<void> saveDeck(FlashcardSet deck) => _write(() => decks[deck.id] = _copy(deck.toJson()));

  @override
  Future<void> saveDeckInfo(FlashcardSet deck) => _write(() {
        final cards = decks[deck.id]?['cards'] ?? [];
        decks[deck.id] = {..._copy(deck.toJson()), 'cards': cards};
      });

  @override
  Future<void> saveCard(String deckId, Flashcard card, int order) => _write(() {
        final cards = List.of(decks[deckId]!['cards'] as List)..removeWhere((c) => c['id'] == card.id);
        cards.insert(order.clamp(0, cards.length), _copy(card.toJson()));
        decks[deckId]!['cards'] = cards;
      });

  @override
  Future<void> deleteCard(String deckId, String cardId) =>
      _write(() => (decks[deckId]!['cards'] as List).removeWhere((c) => c['id'] == cardId));

  @override
  Future<void> deleteDeck(FlashcardSet deck) => _write(() => decks.remove(deck.id));

  @override
  Future<void> renameOwner(String userId, String ownerName) => _write(() {
        for (final d in decks.values.where((d) => d['userId'] == userId)) {
          d['ownerName'] = ownerName;
        }
      });

  @override
  Future<void> saveProfile(String userId, UserData data) => _updateUser(userId, (d) {
        final p = UserData.fromFirestore(data.toFirestore());
        d
          ..dailyGoal = p.dailyGoal
          ..remindEnabled = p.remindEnabled
          ..remindTime = p.remindTime
          ..savedDeckIds = p.savedDeckIds
          ..starredCardIds = p.starredCardIds
          ..lastDeckId = p.lastDeckId
          ..sessions = p.sessions
          ..activity = p.activity;
      });

  @override
  Future<void> saveLearnState(String userId, UserData data) => _updateUser(userId, (d) {
        final l = UserData.fromJson(_copy(data.toJson()));
        d
          ..positions = l.positions
          ..learnScores = l.learnScores
          ..learnRounds = l.learnRounds
          ..flashSort = l.flashSort
          ..quizDraft = l.quizDraft;
      });

  @override
  Future<void> saveProgress(String userId, String cardId, CardProgress? progress) => _updateUser(userId, (d) {
        if (progress == null) {
          d.progress.remove(cardId);
        } else {
          d.progress[cardId] = progress.copy();
        }
      });

  @override
  Future<void> saveAttempt(String userId, QuizAttempt attempt) => _updateUser(userId, (d) {
        d.quizHistory
          ..removeWhere((a) => a.id == attempt.id)
          ..add(QuizAttempt.fromJson(_copy(attempt.toJson())));
      });

  @override
  Future<void> deleteAttempt(String userId, String attemptId) =>
      _updateUser(userId, (d) => d.quizHistory.removeWhere((a) => a.id == attemptId));
}
