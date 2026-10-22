import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_app/logic/learn_engine.dart';
import 'package:flashcard_app/logic/progress_lifecycle.dart';
import 'package:flashcard_app/logic/quiz_engine.dart';
import 'package:flashcard_app/logic/stats_calculator.dart';
import 'package:flashcard_app/models/card_progress.dart';
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/models/flashcard_set.dart';
import 'package:flashcard_app/models/quiz.dart';
import 'package:flashcard_app/models/user_data.dart';
import 'package:flashcard_app/utils/date_utils.dart';

FlashcardSet deckOf(int n, {String id = 'd1'}) => FlashcardSet(
      id: id,
      userId: 'u1',
      title: 'Deck',
      cards: List.generate(n, (i) => Flashcard(id: 'c$i', term: 'term $i', meaning: 'meaning $i')),
    );

void main() {
  final today = DateTime(2026, 10, 21);

  group('Vòng đời tiến độ', () {
    test('lật thẻ: Chưa học -> Đang học, đến hạn ngày mai', () {
      final p = onFlashcardSeen(null, today);
      expect(stageOf(null), CardStage.notStudied);
      expect(stageOf(p), CardStage.learning);
      expect(p.due, addDays(today, 1));
      // Lật lại không thay đổi tiến độ đã có
      final known = CardProgress(due: today, known: true, interval: 5);
      expect(onFlashcardSeen(known, today).known, isTrue);
    });

    test('Học: đạt 2 lần đúng -> Thành thạo; sai -> về Đang học, đến hạn hôm nay', () {
      var p = onLearnAnswer(null, correct: true, reachedMastery: false, today: today);
      expect(p.known, isFalse);
      p = onLearnAnswer(p, correct: true, reachedMastery: true, today: today);
      expect(stageOf(p), CardStage.mastered);
      expect(p.due.isAfter(today), isTrue);
      p = onLearnAnswer(p, correct: false, reachedMastery: false, today: today);
      expect(stageOf(p), CardStage.learning);
      expect(p.interval, 0);
      expect(p.due, today);
    });

    test('Quiz sai đưa thẻ thành thạo về Đang học', () {
      final p = onQuizMissed(CardProgress(due: addDays(today, 9), known: true, interval: 9), today);
      expect(p.known, isFalse);
      expect(p.isDue(today), isTrue);
    });

    test('SM-2: Quên / Khó / Được / Dễ', () {
      final base = CardProgress(due: today, interval: 4, ease: 2.5, known: true);
      final again = applyReviewGrade(base, ReviewGrade.again, today);
      expect(again.interval, 0);
      expect(again.ease, closeTo(2.3, 1e-9));
      expect(again.known, isFalse);
      expect(again.due, today);

      final hard = applyReviewGrade(base, ReviewGrade.hard, today);
      expect(hard.interval, 5); // round(4 * 1.2)
      expect(hard.ease, closeTo(2.35, 1e-9));

      final good = applyReviewGrade(base, ReviewGrade.good, today);
      expect(good.interval, 10); // round(4 * 2.5)
      expect(good.due, addDays(today, 10));

      final easy = applyReviewGrade(base, ReviewGrade.easy, today);
      expect(easy.interval, 13); // round(4 * 2.5 * 1.3)
      expect(easy.ease, closeTo(2.65, 1e-9));

      // Thẻ mới
      expect(applyReviewGrade(null, ReviewGrade.good, today).interval, 1);
      expect(applyReviewGrade(null, ReviewGrade.easy, today).interval, 3);
      expect(applyReviewGrade(CardProgress(due: today, interval: 1), ReviewGrade.good, today).interval, 3);
      // ease không xuống dưới 1.3
      expect(applyReviewGrade(CardProgress(due: today, ease: 1.3), ReviewGrade.again, today).ease, 1.3);
    });

    test('nhãn khoảng ôn', () {
      expect(intervalLabel(0), '< 10 phút');
      expect(intervalLabel(1), '1 ngày');
      expect(intervalLabel(12), '12 ngày');
      expect(intervalLabel(60), '2 tháng');
    });
  });

  group('Quiz engine', () {
    test('số lựa chọn phụ thuộc số thẻ và phương án sai', () {
      expect(optionCount(deckOf(1)), 0);
      expect(optionCount(deckOf(2)), 2);
      expect(optionCount(deckOf(3)), 3);
      expect(optionCount(deckOf(8)), 4);
      final d = deckOf(2);
      d.cards[0].wrongOptions = ['x', 'y'];
      d.cards[1].wrongOptions = ['z', 'w'];
      expect(optionCount(d), 4);
    });

    test('câu hỏi có đáp án đúng nằm trong lựa chọn, không trùng', () {
      final d = deckOf(6);
      final qs = buildQuestions(d, count: 5, random: Random(1));
      expect(qs.length, 5);
      for (final q in qs) {
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        final card = d.cards.firstWhere((c) => c.id == q.cardId);
        expect(q.options[q.correctIndex], card.meaning);
      }
    });

    test('chấm điểm: đúng / sai / bỏ trống', () {
      final d = deckOf(4);
      final qs = buildQuestions(d, count: 4, shuffleQuestions: false, random: Random(2));
      final answers = {0: qs[0].correctIndex, 1: (qs[1].correctIndex + 1) % 4};
      final a = gradeAttempt(id: 'a', deck: d, questions: qs, answers: answers, durationSeconds: 30, takenAt: today);
      expect(a.correct, 1);
      expect(a.wrong, 1);
      expect(a.blank, 2);
      expect(a.percent, 25);
      expect(a.missedCardIds.length, 3);
      // Lưu / đọc lại không mất dữ liệu
      final back = QuizAttempt.fromJson(a.toJson());
      expect(back.correct, 1);
      expect(back.blank, 2);
    });
  });

  group('Học theo lượt', () {
    test('mỗi thẻ cần đúng 2 lần liên tiếp; sai đặt điểm về 0', () {
      final d = deckOf(3);
      final s = LearnSession(d, random: Random(3));
      expect(s.target, 6);
      var guard = 0;
      String? missedOnce;
      while (s.phase != LearnPhase.done && guard++ < 100) {
        if (s.phase == LearnPhase.roundSummary) {
          s.nextRound();
          continue;
        }
        final q = s.question!;
        // Trả lời sai đúng một lần với thẻ đầu tiên gặp phải
        if (missedOnce == null) {
          missedOnce = q.cardId;
          final r = s.answer((q.correctIndex + 1) % q.options.length);
          expect(r.correct, isFalse);
          expect(s.score[q.cardId], 0);
        } else {
          final before = s.score[q.cardId] ?? 0;
          final r = s.answer(q.correctIndex);
          expect(r.reachedMastery, before + 1 == 2);
        }
        s.next();
      }
      expect(s.phase, LearnPhase.done);
      expect(s.achieved, s.target);
      expect(s.round, greaterThanOrEqualTo(2)); // Cần lượt mới vì mỗi thẻ chỉ hỏi 1 lần mỗi lượt
      expect(s.wrongs, 1);
    });

    test('tiếp tục phần Học làm dở từ điểm đã lưu', () {
      final d = deckOf(4);
      final ids = d.validCards.map((c) => c.id).toList();
      final saved = {ids[0]: 2, ids[1]: 1};
      expect(LearnSession.completion(ids, saved), 3 / 8);
      final s = LearnSession(d, random: Random(6), savedScore: saved, savedRound: 3);
      expect(s.round, 3);
      expect(s.achieved, 3);
      expect(s.queue, isNot(contains(ids[0]))); // Thẻ đã thành thạo không hỏi lại
    });

    test('bài kiểm tra: đúng/sai, tự luận, trả lời bằng thuật ngữ', () {
      final d = deckOf(6);
      final qs = buildQuestions(d, count: 6, random: Random(7),
          types: {QuestionType.trueFalse, QuestionType.written}, answerWith: AnswerWith.term);
      expect(qs.where((q) => q.isTrueFalse).length, 3);
      expect(qs.where((q) => q.isWritten).length, 3);
      for (final q in qs) {
        final card = d.cards.firstWhere((c) => c.id == q.cardId);
        expect(q.question, card.meaning); // Hỏi định nghĩa, trả lời thuật ngữ
        if (q.isWritten) expect(q.correctText, card.term);
        if (q.isTrueFalse) expect(q.correctIndex, q.statement == card.term ? 0 : 1);
      }
      expect(writtenMatches('  Const. ', 'const'), isTrue);
      expect(writtenMatches('', 'const'), isFalse);
    });

    test('Học: thẻ sai lượt trước được hỏi trước; tự luận khi đã đúng 1 lần', () {
      final d = deckOf(10);
      final s = LearnSession(d, random: Random(8), written: true);
      final firstId = s.question!.cardId;
      s.answer(-1); // Sai thẻ đầu
      while (s.phase == LearnPhase.question) {
        if (!s.isAnswered) s.answer(s.question!.correctIndex);
        s.next();
      }
      s.nextRound();
      expect(s.queue.first, firstId);
      // Các thẻ đã đúng 1 lần ở lượt trước nay hỏi tự luận
      final q = s.question!;
      expect(q.cardId, firstId);
      expect(q.isWritten, isFalse); // Thẻ vừa sai (điểm 0) vẫn hỏi trắc nghiệm
      expect(LearnSession(d, onlyCardIds: {d.cards[0].id, d.cards[1].id}).cardIds.length, 2);
    });

    test('lượt tối đa 7 thẻ', () {
      final s = LearnSession(deckOf(10), random: Random(4));
      expect(s.queue.length, 7);
    });

    test('"Bạn không biết?" tính là sai', () {
      final s = LearnSession(deckOf(2), random: Random(5));
      final r = s.answer(-1);
      expect(r.correct, isFalse);
      expect(s.wrongs, 1);
    });
  });

  group('Thống kê', () {
    test('chuỗi ngày, lượt học, tỷ lệ ghi nhớ, điểm trung bình', () {
      final data = UserData(dailyGoal: 10);
      data.activity[dayKey(today)] = 4;
      data.activity[dayKey(addDays(today, -1))] = 6;
      data.activity[dayKey(addDays(today, -3))] = 2; // Ngắt chuỗi
      data.progress['a'] = CardProgress(due: today, known: true);
      data.progress['b'] = CardProgress(due: today);
      final s = computeStats(data, today);
      expect(s.streak, 2);
      expect(s.totalCardViews, 12);
      expect(s.todayCount, 4);
      expect(s.retentionRate, 50);
      expect(s.averageScore, isNull);
      expect(s.last7Days.last.value, 4);
      expect(s.last7Days.length, 7);
      expect(s.last4Weeks.last.value, 12);
    });

    test('chưa học hôm nay thì chuỗi = 0', () {
      final data = UserData();
      data.activity[dayKey(addDays(today, -1))] = 3;
      expect(computeStreak(data, today), 0);
    });

    test('học liên tiếp hôm nay và hôm qua thì chuỗi = 2', () {
      final data = UserData(activity: {dayKey(today): 1, dayKey(addDays(today, -1)): 4});
      expect(computeStreak(data, today), 2);
    });
  });
}
