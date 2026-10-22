// logic/learn_engine.dart - HỌC THEO LƯỢT
// Mỗi lượt hỏi tối đa 7 thẻ chưa đạt. Thẻ cần trả lời đúng 2 lần liên tiếp để thành thạo,
// trả lời sai đặt điểm thẻ về 0. Lặp lượt mới cho đến khi toàn bộ thẻ đạt yêu cầu.
// Thẻ sai ở lượt trước được hỏi lại trước. Bật [written]: thẻ đã đúng 1 lần được hỏi dạng tự luận.
import 'dart:math';
import '../models/flashcard_set.dart';
import '../models/quiz.dart';
import 'quiz_engine.dart';

enum LearnPhase { question, roundSummary, done }

class LearnRoundEntry {
  final String cardId;
  final bool correct;
  const LearnRoundEntry(this.cardId, this.correct);
}

class LearnAnswerResult {
  final bool correct;
  final bool reachedMastery; // Vừa đạt đúng 2 lần liên tiếp
  final bool firstTimeSeen; // Lần đầu gặp thẻ trong phiên (tính lượt học)
  const LearnAnswerResult(this.correct, this.reachedMastery, this.firstTimeSeen);
}

class LearnSession {
  static const int roundSize = 7;
  static const int requiredStreak = 2;

  final FlashcardSet deck;
  final Random _random;
  final List<String> cardIds;
  final Map<String, int> score = {};
  final Map<String, int> missedInRound = {};
  final Set<String> _seen = {};
  bool shuffle = true;
  bool written = false; // Câu tự luận cho thẻ đã đúng 1 lần
  bool reverse = false; // Trả lời bằng thuật ngữ
  int round = 1;
  int answers = 0;
  int wrongs = 0;
  LearnPhase phase = LearnPhase.question;
  List<String> queue = [];
  int queueIndex = 0;
  List<LearnRoundEntry> roundLog = [];
  QuizQuestion? question;
  int? answered; // -1: chọn "Bạn không biết?"
  final DateTime startedAt = DateTime.now();

  // savedScore / savedRound: tiếp tục phần Học làm dở
  // onlyCardIds: chỉ học một nhóm thẻ (ví dụ thẻ gắn sao)
  LearnSession(
    this.deck, {
    Random? random,
    Map<String, int>? savedScore,
    int savedRound = 1,
    Set<String>? onlyCardIds,
    this.written = false,
  }) : _random = random ?? Random(),
       cardIds = deck.validCards
           .map((c) => c.id)
           .where((id) => onlyCardIds == null || onlyCardIds.contains(id))
           .toList() {
    cardIds.shuffle(_random);
    if (savedScore != null) {
      for (final id in cardIds) {
        if (savedScore[id] != null) score[id] = savedScore[id]!;
      }
      round = savedRound;
    }
    _startRound();
  }

  // Tỉ lệ câu hỏi đã hoàn thành (0..1) từ điểm từng thẻ
  static double completion(List<String> cardIds, Map<String, int> score) {
    if (cardIds.isEmpty) return 0;
    final got = cardIds.fold(0, (s, id) => s + min(requiredStreak, score[id] ?? 0));
    return got / (cardIds.length * requiredStreak);
  }

  int get target => cardIds.length * requiredStreak;
  int get achieved => cardIds.fold(0, (s, id) => s + min(requiredStreak, score[id] ?? 0));
  bool get isAnswered => answered != null;
  bool get lastAnswerCorrect => question != null && answered == question!.correctIndex;
  int get masteredCount => cardIds.where((id) => (score[id] ?? 0) >= requiredStreak).length;

  List<String> get _remaining => cardIds.where((id) => (score[id] ?? 0) < requiredStreak).toList();

  void _startRound() {
    final left = _remaining;
    if (left.isEmpty) {
      phase = LearnPhase.done;
      return;
    }
    if (shuffle) left.shuffle(_random);
    // Ưu tiên thẻ vừa trả lời sai
    bool missedLast(String id) => missedInRound[id] == round - 1;
    queue = [...left.where(missedLast), ...left.where((id) => !missedLast(id))].take(roundSize).toList();
    queueIndex = 0;
    roundLog = [];
    phase = LearnPhase.question;
    _buildQuestion();
  }

  void _buildQuestion() {
    final card = deck.cards.firstWhere((c) => c.id == queue[queueIndex]);
    question = buildLearnQuestion(
      card,
      deck,
      _random,
      reverse: reverse,
      written: written && (score[card.id] ?? 0) >= 1,
    );
    answered = null;
  }

  // Thẻ đã từng trả lời sai ở lượt trước -> hiện nhãn "Hãy thử lại lần nữa"
  bool get isRetry {
    final id = question?.cardId;
    return id != null && (missedInRound[id] ?? round) < round;
  }

  LearnAnswerResult answer(int choice) {
    final q = question!;
    answered = choice;
    answers++;
    final correct = choice == q.correctIndex;
    final firstSeen = _seen.add(q.cardId);
    var reached = false;
    if (correct) {
      score[q.cardId] = (score[q.cardId] ?? 0) + 1;
      reached = score[q.cardId] == requiredStreak;
    } else {
      wrongs++;
      score[q.cardId] = 0;
      missedInRound[q.cardId] = round;
    }
    roundLog.add(LearnRoundEntry(q.cardId, correct));
    return LearnAnswerResult(correct, reached, firstSeen);
  }

  // Sang câu tiếp theo; trả về true nếu phiên vừa hoàn thành
  bool next() {
    if (!isAnswered) return false;
    queueIndex++;
    if (queueIndex < queue.length) {
      _buildQuestion();
      return false;
    }
    if (_remaining.isEmpty) {
      phase = LearnPhase.done;
      return true;
    }
    phase = LearnPhase.roundSummary;
    return false;
  }

  void nextRound() {
    round++;
    _startRound();
  }
}
