import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_app/logic/learn_engine.dart';
import 'package:flashcard_app/logic/progress_lifecycle.dart';
import 'package:flashcard_app/logic/quiz_engine.dart';
import 'package:flashcard_app/models/card_progress.dart';
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/models/flashcard_set.dart';
import 'package:flashcard_app/models/quiz.dart';
import 'package:flashcard_app/models/user.dart';
import 'package:flashcard_app/services/data_store.dart';
import 'package:flashcard_app/services/flashcard_service.dart';
import 'package:flashcard_app/utils/date_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = DateTime(2026, 10, 21, 9);
  final alice = User(id: 'alice', username: 'Alice', email: 'a@x.vn', createdAt: today);
  final bob = User(id: 'bob', username: 'Bob', email: 'b@x.vn', createdAt: today);
  late LocalDataStore store;
  final service = FlashcardService();

  setUp(() async {
    store = LocalDataStore();
    service.useStore(store);
    service.clock = () => today;
    await service.loadForUser(alice);
  });

  Future<FlashcardSet> makeDeck({int cards = 4, String visibility = 'private'}) async {
    final d = (await service.createDeck(title: 'Deck ${store.decks.length}', visibility: visibility))!;
    for (var i = 0; i < cards; i++) {
      await service.addCard(d.id, Flashcard(term: 'front $i', meaning: 'back $i'));
    }
    await service.finishDeck(d.id);
    return service.deckById(d.id)!;
  }

  test('tạo bộ thẻ: bản nháp -> sẵn sàng, ID thẻ ổn định khi sửa', () async {
    final d = (await service.createDeck(title: 'Từ vựng'))!;
    expect(d.isDraft, isTrue);
    expect(service.hasDuplicateTitle(' từ VỰNG '), isTrue);
    await service.addCard(d.id, Flashcard(term: 'cat', meaning: 'con mèo'));
    final id = d.cards.first.id;
    await service.recordFlashcardSeen(id);
    await service.updateCard(d.id, Flashcard(id: id, term: 'cat', meaning: 'mèo'));
    expect(service.progressOf(id), isNotNull); // Sửa thẻ không mất tiến độ
    await service.finishDeck(d.id);
    expect(service.deckById(d.id)!.isDraft, isFalse);
  });

  test('một nguồn dữ liệu: Trang chủ, Chi tiết, Thống kê khớp nhau', () async {
    final d = await makeDeck();
    final c0 = d.cards[0].id, c1 = d.cards[1].id;
    await service.recordFlashcardSeen(c0);
    await service.recordLearnAnswer(c1, const LearnAnswerResult(true, false, true));
    await service.recordLearnAnswer(c1, const LearnAnswerResult(true, true, false));

    final counts = service.stageCounts(d);
    expect(counts[CardStage.notStudied], 2);
    expect(counts[CardStage.learning], 1);
    expect(counts[CardStage.mastered], 1);
    expect(service.knownIn(d), 1);
    expect(service.stats.knownCards, 1);
    expect(service.stats.trackedCards, 2);
    expect(service.todayCount, 2); // 1 lần lật + 1 thẻ mới trong Học
    expect(service.stats.streak, 1);
  });

  test('ôn tập: thẻ đến hạn và lịch ôn mới', () async {
    final d = await makeDeck();
    final id = d.cards[0].id;
    await service.recordLearnAnswer(id, const LearnAnswerResult(false, false, true));
    expect(service.dueList().map((e) => e.cardId), contains(id));
    await service.gradeReview(id, ReviewGrade.good, firstTime: true);
    expect(service.dueList(), isEmpty);
    expect(service.progressOf(id)!.due, addDays(today, 1));
    expect(service.dueOn(addDays(today, 1)), 1);
  });

  test('nộp quiz: lưu lịch sử, xóa nháp, câu sai về Đang học, không ghi trùng', () async {
    final d = await makeDeck();
    final qs = buildQuestions(d, count: 4, shuffleQuestions: false);
    await service.saveQuizDraft(QuizDraft(deckId: d.id, questions: qs, answers: {0: qs[0].correctIndex}));
    expect(service.quizDraft, isNotNull);
    final attempt = gradeAttempt(
      id: 'att1', deck: d, questions: qs, answers: {0: qs[0].correctIndex}, durationSeconds: 12, takenAt: today);
    await service.submitQuiz(attempt);
    await service.submitQuiz(attempt);
    expect(service.history.length, 1);
    expect(service.quizDraft, isNull);
    expect(service.stageOfCard(qs[1].cardId), CardStage.learning);
    expect(service.stats.averageScore, 25);
  });

  test('ghi lỗi: khôi phục trạng thái trước đó', () async {
    final d = await makeDeck();
    store.failWrites = true;
    final ok = await service.toggleStar(d.cards[0].id);
    expect(ok, isFalse);
    expect(service.isStarred(d.cards[0].id), isFalse);
    final del = await service.deleteDeck(d.id);
    expect(del, isFalse);
    expect(service.deckById(d.id), isNotNull);
  });

  test('xóa bộ thẻ xóa tiến độ, nháp liên quan; giữ lịch sử kiểm tra', () async {
    final d = await makeDeck();
    await service.recordFlashcardSeen(d.cards[0].id);
    final qs = buildQuestions(d, count: 2, shuffleQuestions: false);
    await service.submitQuiz(gradeAttempt(
        id: 'q1', deck: d, questions: qs, answers: {0: qs[0].correctIndex}, durationSeconds: 5, takenAt: today));
    await service.saveQuizDraft(QuizDraft(deckId: d.id, questions: []));
    await service.deleteDeck(d.id);
    expect(service.deckById(d.id), isNull);
    expect(service.progressOf(d.cards[0].id), isNull);
    expect(service.quizDraft, isNull);
    expect(store.decks.containsKey(d.id), isFalse);
    // Lịch sử vẫn còn, hiển thị bằng tên bộ thẻ đã lưu
    await service.loadForUser(alice);
    expect(service.attemptById('q1')!.deckTitle, d.title);
  });

  test('số thẻ đến hạn ngày mai chỉ tính bộ của tôi / đã lưu / đã học (khớp dueList)', () async {
    final pub = await makeDeck(visibility: 'public');
    await service.recordFlashcardSeen(pub.cards[0].id); // Đến hạn ngày mai
    await service.loadForUser(bob);
    expect(service.dueOn(today.add(const Duration(days: 1))), 0);
  });

  test('tiến độ tách riêng từng người dùng; lưu / sao chép bộ công khai', () async {
    final d = await makeDeck(visibility: 'public');
    await service.recordFlashcardSeen(d.cards[0].id);

    await service.loadForUser(bob);
    expect(service.isOwner(d), isFalse);
    expect(service.exploreDecks.map((x) => x.id), contains(d.id));
    expect(service.progressOf(d.cards[0].id), isNull); // Bob chưa học
    await service.toggleSave(d.id);
    expect(service.isSaved(d.id), isTrue);
    final copy = (await service.copyDeck(d.id))!;
    expect(copy.userId, 'bob');
    expect(copy.visibility, 'private');
    expect(copy.cards.first.id, isNot(d.cards.first.id));

    await service.loadForUser(alice);
    expect(service.progressOf(d.cards[0].id), isNotNull);
  });


}
