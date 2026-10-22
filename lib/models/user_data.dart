// models/user_data.dart - DỮ LIỆU HỌC TẬP RIÊNG CỦA TỪNG NGƯỜI DÙNG
// Tách khỏi nội dung bộ thẻ: cùng một bộ thẻ công khai, mỗi người có tiến độ riêng.
import 'card_progress.dart';
import 'quiz.dart';

class UserData {
  Map<String, CardProgress> progress; // cardId -> tiến độ
  List<String> savedDeckIds; // Thư viện › Đã lưu
  List<String> starredCardIds; // Thẻ gắn sao
  List<QuizAttempt> quizHistory;
  Map<String, int> activity; // 'yyyy-MM-dd' -> số lượt học thẻ trong ngày
  int sessions; // Số phiên học đã hoàn thành
  QuizDraft? quizDraft;
  String? lastDeckId;
  Map<String, int> positions; // deckId -> vị trí thẻ đang học dở
  Map<String, Map<String, int>> learnScores; // deckId -> (cardId -> số lần đúng liên tiếp) của phần Học dở
  Map<String, int> learnRounds; // deckId -> lượt đang làm của phần Học
  Map<String, Map<String, bool>> flashSort; // deckId -> (cardId -> true: Đã biết, false: Đang học) của lượt Thẻ ghi nhớ dở
  int dailyGoal;
  bool remindEnabled;
  String remindTime;

  UserData({
    Map<String, CardProgress>? progress,
    List<String>? savedDeckIds,
    List<String>? starredCardIds,
    List<QuizAttempt>? quizHistory,
    Map<String, int>? activity,
    this.sessions = 0,
    this.quizDraft,
    this.lastDeckId,
    Map<String, int>? positions,
    Map<String, Map<String, int>>? learnScores,
    Map<String, int>? learnRounds,
    Map<String, Map<String, bool>>? flashSort,
    this.dailyGoal = 20,
    this.remindEnabled = false,
    this.remindTime = '20:00',
  })  : progress = progress ?? {},
        savedDeckIds = savedDeckIds ?? [],
        starredCardIds = starredCardIds ?? [],
        quizHistory = quizHistory ?? [],
        activity = activity ?? {},
        positions = positions ?? {},
        learnScores = learnScores ?? {},
        learnRounds = learnRounds ?? {},
        flashSort = flashSort ?? {};

  Map<String, dynamic> toJson() => {
    'progress': progress.map((k, v) => MapEntry(k, v.toJson())),
    'savedDeckIds': savedDeckIds,
    'starredCardIds': starredCardIds,
    'quizHistory': quizHistory.map((a) => a.toJson()).toList(),
    'activity': activity,
    'sessions': sessions,
    'quizDraft': quizDraft?.toJson(),
    'lastDeckId': lastDeckId,
    'positions': positions,
    'learnScores': learnScores,
    'learnRounds': learnRounds,
    'flashSort': flashSort,
    'dailyGoal': dailyGoal,
    'remindEnabled': remindEnabled,
    'remindTime': remindTime,
  };

  // === FIRESTORE ===
  // users/{uid}: cài đặt và số liệu (ghi merge, không đụng username/email do AuthService quản lý)
  Map<String, dynamic> toFirestore() => {
    'dailyGoal': dailyGoal,
    'remindEnabled': remindEnabled,
    'remindTime': remindTime,
    'savedDeckIds': savedDeckIds,
    'starredCardIds': starredCardIds,
    'lastDeckId': lastDeckId,
    'sessions': sessions,
    'activity': activity,
  };

  // users/{uid}/state/learn: vị trí và phiên học đang dở
  Map<String, dynamic> learnStateToFirestore() => {
    'positions': positions,
    'learnScores': learnScores,
    'learnRounds': learnRounds,
    'flashSort': flashSort,
    'quizDraft': quizDraft?.toJson(),
  };

  // Ghép lại từ users/{uid}, state/learn, progress và quizAttempts
  factory UserData.fromFirestore(
    Map<String, dynamic>? profile, {
    Map<String, dynamic>? learnState,
    Map<String, CardProgress> progress = const {},
    List<QuizAttempt> attempts = const [],
  }) {
    final p = profile ?? const {};
    final l = learnState ?? const {};
    Map<String, int> ints(Object? v) => (v as Map? ?? {}).map((k, n) => MapEntry('$k', (n as num).toInt()));
    return UserData(
      progress: Map.of(progress),
      savedDeckIds: (p['savedDeckIds'] as List?)?.cast<String>().toList() ?? [],
      starredCardIds: (p['starredCardIds'] as List?)?.cast<String>().toList() ?? [],
      quizHistory: List.of(attempts)..sort((a, b) => a.takenAt.compareTo(b.takenAt)),
      activity: ints(p['activity']),
      sessions: p['sessions'] ?? 0,
      quizDraft: l['quizDraft'] == null ? null : QuizDraft.fromJson(Map<String, dynamic>.from(l['quizDraft'])),
      lastDeckId: p['lastDeckId'],
      positions: ints(l['positions']),
      learnScores: (l['learnScores'] as Map? ?? {}).map((k, v) => MapEntry('$k', ints(v))),
      learnRounds: ints(l['learnRounds']),
      flashSort: (l['flashSort'] as Map? ?? {})
          .map((k, v) => MapEntry('$k', (v as Map).map((c, b) => MapEntry('$c', b as bool)))),
      dailyGoal: p['dailyGoal'] ?? 20,
      remindEnabled: p['remindEnabled'] ?? false,
      remindTime: p['remindTime'] ?? '20:00',
    );
  }

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    progress: (json['progress'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, CardProgress.fromJson(v))),
    savedDeckIds: (json['savedDeckIds'] as List?)?.cast<String>() ?? [],
    starredCardIds: (json['starredCardIds'] as List?)?.cast<String>() ?? [],
    quizHistory: (json['quizHistory'] as List? ?? []).map((a) => QuizAttempt.fromJson(a)).toList(),
    activity: (json['activity'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as int)),
    sessions: json['sessions'] ?? 0,
    quizDraft: json['quizDraft'] == null ? null : QuizDraft.fromJson(json['quizDraft']),
    lastDeckId: json['lastDeckId'],
    positions: (json['positions'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as int)),
    learnScores: (json['learnScores'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((c, n) => MapEntry(c, n as int)))),
    learnRounds: (json['learnRounds'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as int)),
    flashSort: (json['flashSort'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((c, b) => MapEntry(c, b as bool)))),
    dailyGoal: json['dailyGoal'] ?? 20,
    remindEnabled: json['remindEnabled'] ?? false,
    remindTime: json['remindTime'] ?? '20:00',
  );
}
