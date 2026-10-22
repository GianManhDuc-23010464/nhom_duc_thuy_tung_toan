// models/quiz.dart - CÂU HỎI, LẦN LÀM BÀI VÀ BẢN NHÁP QUIZ
import 'base_entity.dart';

// Dạng câu hỏi trong bài kiểm tra
class QuestionType {
  static const multipleChoice = 'mc';
  static const trueFalse = 'tf'; // options: ['Đúng', 'Sai'], statement: đáp án đưa ra để xét
  static const written = 'written'; // options: [đáp án đúng], người làm tự gõ
}

class QuizQuestion {
  final String cardId;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explain;
  final String type;
  final String? statement;

  const QuizQuestion({
    required this.cardId,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explain,
    this.type = QuestionType.multipleChoice,
    this.statement,
  });

  bool get isTrueFalse => type == QuestionType.trueFalse;
  bool get isWritten => type == QuestionType.written;

  // Đáp án đúng dạng chữ (câu Đúng/sai: đáp án thật của thẻ không lưu nên hiện Đúng/Sai)
  String get correctText => options[correctIndex];

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'explain': explain,
    'type': type,
    'statement': statement,
  };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    cardId: json['cardId'],
    question: json['question'],
    options: (json['options'] as List).cast<String>(),
    correctIndex: json['correctIndex'],
    explain: json['explain'],
    type: json['type'] ?? QuestionType.multipleChoice,
    statement: json['statement'],
  );
}

// So đáp án tự luận: không phân biệt hoa thường, khoảng trắng thừa, dấu câu ở cuối
bool writtenMatches(String typed, String answer) {
  String norm(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[.!?;,]+$'), '');
  return norm(typed).isNotEmpty && norm(typed) == norm(answer);
}

class QuizAnswerItem {
  final QuizQuestion question;
  final int? chosen; // null: bỏ trống; câu tự luận: 0 đúng, 1 sai
  final String? typed; // Câu tự luận: nội dung đã gõ

  const QuizAnswerItem(this.question, this.chosen, {this.typed});

  bool get isBlank => chosen == null;
  bool get isCorrect => chosen == question.correctIndex;
  bool get isWrong => !isBlank && !isCorrect;

  // Câu trả lời của người làm dạng chữ
  String? get chosenText {
    if (question.isWritten) return typed;
    final c = chosen;
    return c == null || c < 0 || c >= question.options.length ? null : question.options[c];
  }

  Map<String, dynamic> toJson() => {...question.toJson(), 'chosen': chosen, 'typed': typed};

  factory QuizAnswerItem.fromJson(Map<String, dynamic> json) =>
      QuizAnswerItem(QuizQuestion.fromJson(json), json['chosen'], typed: json['typed']);
}

class QuizAttempt implements BaseEntity {
  @override
  final String id;
  final String deckId;
  final String deckTitle;
  final DateTime takenAt;
  final int durationSeconds;
  final List<QuizAnswerItem> items;
  bool pendingSync; // Làm khi mất mạng, chờ đồng bộ

  QuizAttempt({
    required this.id,
    required this.deckId,
    required this.deckTitle,
    required this.takenAt,
    required this.durationSeconds,
    required this.items,
    this.pendingSync = false,
  });

  @override
  String get name => deckTitle;
  @override
  String get description => "$correct/$total câu đúng";
  @override
  DateTime get createdAt => takenAt;
  @override
  DateTime get updatedAt => takenAt;

  int get total => items.length;
  int get correct => items.where((x) => x.isCorrect).length;
  int get wrong => items.where((x) => x.isWrong).length;
  int get blank => items.where((x) => x.isBlank).length;
  double get ratio => total == 0 ? 0 : correct / total;
  int get percent => (ratio * 100).round();
  List<String> get missedCardIds =>
      items.where((x) => !x.isCorrect).map((x) => x.question.cardId).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'deckId': deckId,
    'deckTitle': deckTitle,
    'takenAt': takenAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'items': items.map((x) => x.toJson()).toList(),
    'pendingSync': pendingSync,
  };

  // Firestore: users/{uid}/quizAttempts/{id}. pendingSync không lưu: lấy từ metadata.hasPendingWrites
  @override
  Map<String, dynamic> toMap() => toFirestore();

  Map<String, dynamic> toFirestore() => {
    'deckId': deckId,
    'deckTitle': deckTitle,
    'takenAt': toTimestamp(takenAt),
    'durationSeconds': durationSeconds,
    'items': items.map((x) => x.toJson()).toList(),
  };

  factory QuizAttempt.fromMap(Map<String, dynamic> data, String id) => QuizAttempt.fromFirestore(data, id);

  factory QuizAttempt.fromFirestore(Map<String, dynamic> data, String id, {bool pendingSync = false}) => QuizAttempt(
    id: id,
    deckId: data['deckId'] ?? '',
    deckTitle: data['deckTitle'] ?? '',
    takenAt: fromTimestamp(data['takenAt']) ?? DateTime.now(),
    durationSeconds: data['durationSeconds'] ?? 0,
    items: (data['items'] as List? ?? []).map((x) => QuizAnswerItem.fromJson(Map<String, dynamic>.from(x))).toList(),
    pendingSync: pendingSync,
  );

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
    id: json['id'],
    deckId: json['deckId'],
    deckTitle: json['deckTitle'] ?? '',
    takenAt: DateTime.parse(json['takenAt']),
    durationSeconds: json['durationSeconds'] ?? 0,
    items: (json['items'] as List).map((x) => QuizAnswerItem.fromJson(x)).toList(),
    pendingSync: json['pendingSync'] ?? false,
  );
}

// Bài quiz đang làm dở, được lưu để làm tiếp
class QuizDraft {
  final String deckId;
  final List<QuizQuestion> questions;
  final Map<int, int> answers;
  final Map<int, String> typed; // Câu tự luận: nội dung đã gõ
  int currentIndex; // Bằng số câu hỏi: đang ở màn nộp bài
  int elapsedSeconds;
  final int? limitSeconds; // null: không giới hạn thời gian
  final bool instantFeedback; // Hiện đúng/sai ngay sau khi chọn

  QuizDraft({
    required this.deckId,
    required this.questions,
    Map<int, int>? answers,
    Map<int, String>? typed,
    this.currentIndex = 0,
    this.elapsedSeconds = 0,
    this.limitSeconds,
    this.instantFeedback = false,
  })  : answers = answers ?? {},
        typed = typed ?? {};

  int get answeredCount => answers.length;
  int? get remainingSeconds =>
      limitSeconds == null ? null : (limitSeconds! - elapsedSeconds).clamp(0, limitSeconds!);

  Map<String, dynamic> toJson() => {
    'deckId': deckId,
    'questions': questions.map((q) => q.toJson()).toList(),
    'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
    'typed': typed.map((k, v) => MapEntry(k.toString(), v)),
    'currentIndex': currentIndex,
    'elapsedSeconds': elapsedSeconds,
    'limitSeconds': limitSeconds,
    'instantFeedback': instantFeedback,
  };

  factory QuizDraft.fromJson(Map<String, dynamic> json) => QuizDraft(
    deckId: json['deckId'],
    questions: (json['questions'] as List).map((q) => QuizQuestion.fromJson(q)).toList(),
    answers: (json['answers'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(int.parse(k), v as int)),
    typed: (json['typed'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(int.parse(k), v as String)),
    currentIndex: json['currentIndex'] ?? 0,
    elapsedSeconds: json['elapsedSeconds'] ?? 0,
    limitSeconds: json['limitSeconds'],
    instantFeedback: json['instantFeedback'] ?? false,
  );
}
