// Chuyển từng model sang Firestore rồi đọc lại phải ra đúng dữ liệu ban đầu (gồm trường null và ngày giờ).
// Ghi thật vào Firestore giả để kiểm tra cả việc lưu Timestamp.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_app/logic/quiz_engine.dart';
import 'package:flashcard_app/models/card_progress.dart';
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/models/flashcard_set.dart';
import 'package:flashcard_app/models/quiz.dart';
import 'package:flashcard_app/models/user.dart';
import 'package:flashcard_app/models/user_data.dart';

void main() {
  late FakeFirebaseFirestore db;
  final created = DateTime(2026, 10, 1, 8, 30, 15, 123);
  final updated = DateTime(2026, 10, 21, 22, 5, 1, 999);

  // Ghi map vào document rồi đọc lại
  Future<Map<String, dynamic>> roundTrip(Map<String, dynamic> data) async {
    final ref = db.collection('t').doc();
    await ref.set(data);
    return (await ref.get()).data()!;
  }

  setUp(() => db = FakeFirebaseFirestore());

  test('Flashcard: đủ trường và trường null', () async {
    final full = Flashcard(
      id: 'c1',
      term: 'const',
      meaning: 'hằng',
      note: 'ghi chú',
      imagePath: '/tmp/a.png',
      wrongOptions: ['final', 'var'],
      createdAt: created,
      updatedAt: updated,
    );
    final back = Flashcard.fromFirestore(await roundTrip(full.toFirestore(order: 2)), 'c1');
    expect(back.toJson(), full.toJson());
    expect(back.createdAt, created);
    expect(back.updatedAt, updated);

    final empty = Flashcard(id: 'c2', term: 't', meaning: 'm', createdAt: created);
    final back2 = Flashcard.fromFirestore(await roundTrip(empty.toFirestore()), 'c2');
    expect(back2.note, isNull);
    expect(back2.imagePath, isNull);
    expect(back2.wrongOptions, isEmpty);
  });

  test('FlashcardSet: thông tin bộ thẻ, thẻ ghép từ subcollection', () async {
    final d = FlashcardSet(
      id: 'd1',
      userId: 'u1',
      ownerName: 'An',
      title: 'Dart',
      description: '',
      subject: 'Tin học đại cương',
      visibility: 'public',
      status: 'draft',
      cards: [],
      createdAt: created,
      updatedAt: updated,
    );
    final data = await roundTrip(d.toFirestore());
    expect(data.containsKey('cards'), isFalse); // Thẻ không nằm trong document bộ thẻ
    final card = Flashcard(id: 'c1', term: 't', meaning: 'm', createdAt: created);
    final back = FlashcardSet.fromFirestore(data, 'd1', cards: [card]);
    expect(back.toJson(), {...d.toJson(), 'cards': [card.toJson()]});
  });

  test('CardProgress', () async {
    final p = CardProgress(interval: 6, ease: 2.36, reps: 4, due: DateTime(2026, 10, 25), known: true);
    final back = CardProgress.fromFirestore(await roundTrip(p.toFirestore()));
    expect(back.toJson(), p.toJson());
  });

  test('QuizAttempt: các dạng câu hỏi, câu bỏ trống, câu tự luận', () async {
    final deck = FlashcardSet(
      id: 'd1',
      userId: 'u1',
      title: 'Dart',
      cards: [for (var i = 0; i < 4; i++) Flashcard(id: 'c$i', term: 'T$i', meaning: 'M$i')],
    );
    final qs = buildQuestions(deck,
        count: 4, shuffleQuestions: false, types: {QuestionType.multipleChoice, QuestionType.written});
    final a = gradeAttempt(
      id: 'a1',
      deck: deck,
      questions: qs,
      answers: {0: 0, 2: 1},
      typed: {2: 'sai'},
      durationSeconds: 75,
      takenAt: updated,
    );
    final back = QuizAttempt.fromFirestore(await roundTrip(a.toFirestore()), 'a1');
    expect(back.toJson(), a.toJson());
    expect(back.items[1].chosen, isNull); // Bỏ trống
    expect(back.takenAt, updated);
  });

  test('User', () async {
    final u = User(id: 'u1', username: 'An', email: 'an@x.vn', createdAt: created);
    final back = User.fromFirestore(await roundTrip(u.toFirestore()), 'u1');
    expect(back.toJson(), u.toJson());
  });

  test('UserData: hồ sơ + state/learn + progress + quizAttempts', () async {
    final d = UserData(
      progress: {'c1': CardProgress(due: DateTime(2026, 10, 22), interval: 1, reps: 1)},
      savedDeckIds: ['d2'],
      starredCardIds: ['c1'],
      activity: {'2026-10-21': 6, '2026-10-20': 18},
      sessions: 3,
      lastDeckId: 'd1',
      positions: {'d1': 4},
      learnScores: {
        'd1': {'c1': 2, 'c2': 0},
      },
      learnRounds: {'d1': 2},
      flashSort: {
        'd1': {'c1': true, 'c2': false},
      },
      quizDraft: QuizDraft(deckId: 'd1', questions: [], answers: {0: 1}, typed: {1: 'x'}, instantFeedback: true),
      dailyGoal: 30,
      remindEnabled: true,
      remindTime: '21:15',
    );
    final back = UserData.fromFirestore(
      await roundTrip(d.toFirestore()),
      learnState: await roundTrip(d.learnStateToFirestore()),
      progress: d.progress,
    );
    expect(back.toJson(), d.toJson());

    // Người dùng mới: chưa có document nào
    final fresh = UserData.fromFirestore(null);
    expect(fresh.toJson(), UserData().toJson());
  });
}
