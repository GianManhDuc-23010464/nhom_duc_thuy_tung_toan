// logic/quiz_engine.dart - TẠO CÂU HỎI TRẮC NGHIỆM VÀ CHẤM ĐIỂM
import 'dart:math';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../models/quiz.dart';

// Các phương án sai có thể dùng cho một thẻ: phương án tự nhập trước, sau đó là đáp án của thẻ khác
List<String> optionPool(Flashcard card, FlashcardSet deck) {
  final pool = <String>[];
  final correct = card.meaning.trim();
  void add(String? v) {
    final s = (v ?? '').trim();
    if (s.isNotEmpty && s != correct && !pool.contains(s)) pool.add(s);
  }

  card.wrongOptions.forEach(add);
  for (final c in deck.validCards) {
    if (c.id != card.id) add(c.meaning);
  }
  return pool;
}

// Số lựa chọn mỗi câu (tối đa 4). 0 nghĩa là chưa đủ dữ liệu để tạo quiz.
int optionCount(FlashcardSet deck) {
  final cards = deck.validCards;
  if (cards.length < 2) return 0;
  return cards.map((c) => 1 + optionPool(c, deck).length).fold(4, min);
}

List<String> _optionsFor(Flashcard card, FlashcardSet deck, int k, Random r) {
  final own = card.wrongOptions.map((x) => x.trim()).where((x) => x.isNotEmpty && x != card.meaning.trim()).toList();
  final rest = optionPool(card, deck).where((x) => !own.contains(x)).toList()..shuffle(r);
  return [
    card.meaning.trim(),
    ...[...own, ...rest].take(k - 1),
  ];
}

// Trả lời bằng: định nghĩa (mặt sau), thuật ngữ (mặt trước) hoặc trộn cả hai
enum AnswerWith { meaning, term, both }

// Phương án sai khi trả lời bằng thuật ngữ: thuật ngữ của các thẻ khác
List<String> _termPool(Flashcard card, FlashcardSet deck) {
  final answer = card.term.trim();
  return deck.validCards
      .where((c) => c.id != card.id)
      .map((c) => c.term.trim())
      .where((t) => t.isNotEmpty && t != answer)
      .toSet()
      .toList();
}

List<QuizQuestion> buildQuestions(
  FlashcardSet deck, {
  required int count,
  bool shuffleQuestions = true,
  bool shuffleAnswers = true,
  Set<String> types = const {QuestionType.multipleChoice},
  AnswerWith answerWith = AnswerWith.meaning,
  Set<String>? onlyCardIds, // Chỉ hỏi các thẻ này (gắn sao, câu sai...)
  Random? random,
}) {
  final r = random ?? Random();
  var cards = deck.validCards.where((c) => onlyCardIds == null || onlyCardIds.contains(c.id)).toList();
  if (shuffleQuestions) cards.shuffle(r);
  cards = cards.take(count).toList();
  final k = optionCount(deck);
  // Chia đều các dạng câu hỏi đã chọn rồi trộn
  final typeList = types.isEmpty ? [QuestionType.multipleChoice] : types.toList();
  final assigned = List.generate(cards.length, (i) => typeList[i % typeList.length])..shuffle(r);

  return [
    for (var i = 0; i < cards.length; i++)
      _buildQuestion(
        cards[i],
        deck,
        assigned[i],
        reverse: answerWith == AnswerWith.term || (answerWith == AnswerWith.both && r.nextBool()),
        k: k,
        shuffleAnswers: shuffleAnswers,
        r: r,
      ),
  ];
}

QuizQuestion _buildQuestion(
  Flashcard c,
  FlashcardSet deck,
  String type, {
  required bool reverse,
  required int k,
  required bool shuffleAnswers,
  required Random r,
}) {
  final prompt = reverse ? c.meaning.trim() : c.term.trim();
  final answer = reverse ? c.term.trim() : c.meaning.trim();
  final explain = (c.note ?? '').trim().isEmpty ? null : c.note;
  final pool = reverse ? (_termPool(c, deck)..shuffle(r)) : null;

  switch (type) {
    case QuestionType.trueFalse:
      final wrongs = pool ?? (optionPool(c, deck)..shuffle(r));
      final shown = wrongs.isEmpty || r.nextBool() ? answer : wrongs.first;
      return QuizQuestion(
        cardId: c.id,
        question: prompt,
        options: const ['Đúng', 'Sai'],
        correctIndex: shown == answer ? 0 : 1,
        explain: shown == answer ? explain : 'Đáp án đúng: $answer',
        type: QuestionType.trueFalse,
        statement: shown,
      );
    case QuestionType.written:
      return QuizQuestion(
        cardId: c.id,
        question: prompt,
        options: [answer],
        correctIndex: 0,
        explain: explain,
        type: QuestionType.written,
      );
    default:
      final options = pool != null ? [answer, ...pool.take(k - 1)] : _optionsFor(c, deck, k, r);
      if (shuffleAnswers) {
        options.shuffle(r);
      } else {
        options.sort();
      }
      return QuizQuestion(
        cardId: c.id,
        question: prompt,
        options: options,
        correctIndex: options.indexOf(answer),
        explain: explain,
      );
  }
}

// Câu hỏi cho chế độ Học: luôn trộn đáp án; reverse: hỏi định nghĩa, trả lời thuật ngữ
QuizQuestion buildLearnQuestion(
  Flashcard card,
  FlashcardSet deck,
  Random r, {
  bool reverse = false,
  bool written = false,
}) => _buildQuestion(
  card,
  deck,
  written ? QuestionType.written : QuestionType.multipleChoice,
  reverse: reverse,
  k: optionCount(deck),
  shuffleAnswers: true,
  r: r,
);

QuizAttempt gradeAttempt({
  required String id,
  required FlashcardSet deck,
  required List<QuizQuestion> questions,
  required Map<int, int> answers,
  Map<int, String> typed = const {},
  required int durationSeconds,
  required DateTime takenAt,
  bool pendingSync = false,
}) {
  final items = <QuizAnswerItem>[];
  for (var i = 0; i < questions.length; i++) {
    items.add(QuizAnswerItem(questions[i], answers[i], typed: typed[i]));
  }
  return QuizAttempt(
    id: id,
    deckId: deck.id,
    deckTitle: deck.title,
    takenAt: takenAt,
    durationSeconds: durationSeconds,
    items: items,
    pendingSync: pendingSync,
  );
}
