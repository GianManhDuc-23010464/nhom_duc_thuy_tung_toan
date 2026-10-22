// services/flashcard_service.dart - NGUỒN DỮ LIỆU DUY NHẤT CỦA ỨNG DỤNG
// Trang chủ, Thư viện, Chi tiết bộ thẻ, Thống kê... đều đọc từ đây nên số liệu luôn khớp nhau.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:uuid/uuid.dart';
import '../logic/learn_engine.dart';
import '../logic/progress_lifecycle.dart';
import '../logic/stats_calculator.dart';
import '../models/card_progress.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../models/quiz.dart';
import '../models/user.dart';
import '../models/user_data.dart';
import '../utils/date_utils.dart';
import 'data_store.dart';

class DueItem {
  final String deckId;
  final String cardId;
  const DueItem(this.deckId, this.cardId);
}

class FlashcardService with ChangeNotifier {
  static final FlashcardService _instance = FlashcardService._internal();
  factory FlashcardService() => _instance;
  FlashcardService._internal();

  DataStore _store = LocalDataStore();
  DateTime Function() clock = DateTime.now;
  StreamSubscription<Set<String>>? _pendingSub;
  void Function(int synced)? onSynced; // Báo khi kết quả kiểm tra làm lúc mất mạng đã đồng bộ xong

  User? _user;
  List<FlashcardSet> _decks = [];
  UserData _data = UserData();
  bool _isLoaded = false;
  Future<void> _writeQueue = Future.value();
  int _pendingWrites = 0;

  bool get isLoaded => _isLoaded;
  User? get user => _user;
  String? get userId => _user?.id;
  DateTime get today => dayOnly(clock());

  void useStore(DataStore store) => _store = store;

  // === TẢI / ĐĂNG XUẤT ===
  Future<void> loadForUser(User user) async {
    _user = user;
    _decks = await _store.loadDecks(user.id);
    _data = await _store.loadUserData(user.id);
    _isLoaded = true;
    _watchPending(user.id);
    notifyListeners();
  }

  // Trạng thái "chờ đồng bộ" của kết quả kiểm tra lấy từ metadata.hasPendingWrites của Firestore
  void _watchPending(String uid) {
    _pendingSub?.cancel();
    _pendingSub = _store.watchPendingAttempts(uid).listen((pending) {
      var synced = 0;
      for (final a in _data.quizHistory) {
        final now = pending.contains(a.id);
        if (a.pendingSync && !now) synced++;
        a.pendingSync = now;
      }
      if (synced > 0) onSynced?.call(synced);
      _notify();
    });
  }

  void clear() {
    _pendingSub?.cancel();
    _pendingSub = null;
    _user = null;
    _decks = [];
    _data = UserData();
    _isLoaded = false;
    notifyListeners();
  }

  // Báo thay đổi; nếu đang trong lúc dựng giao diện thì dời sang sau khung hình
  void _notify() {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  // Áp dụng thay đổi rồi ghi xuống bộ lưu trữ. [write] chỉ ghi các document liên quan.
  // Ghi tuần tự để tránh ghi chồng; nếu ghi lỗi thì khôi phục trạng thái trước đó và trả về false.
  Future<bool> _commit(void Function() change, Future<void> Function(DataStore s, String uid) write,
      {bool decks = false}) async {
    final uid = userId;
    if (uid == null) return false;
    final userSnapshot = jsonEncode(_data.toJson());
    final decksSnapshot = decks ? jsonEncode(_decks.map((d) => d.toJson()).toList()) : null;
    change();
    _notify();
    // Chỉ nối vào lần ghi trước khi nó còn đang chạy; nếu đã xong thì bắt đầu chuỗi mới
    final previous = _pendingWrites == 0 ? Future<void>.value() : _writeQueue;
    _pendingWrites++;
    final pending = previous.then((_) async {
      try {
        await write(_store, uid);
      } finally {
        _pendingWrites--;
      }
    });
    _writeQueue = pending.catchError((_) {});
    try {
      await pending;
      return true;
    } catch (e) {
      debugPrint('❌ Lỗi ghi dữ liệu: $e');
      _data = UserData.fromJson(jsonDecode(userSnapshot));
      if (decksSnapshot != null) {
        _decks = (jsonDecode(decksSnapshot) as List).map((e) => FlashcardSet.fromJson(e)).toList();
      }
      _notify();
      return false;
    }
  }

  // Các kiểu ghi hay dùng
  Future<void> _profile(DataStore s, String uid) => s.saveProfile(uid, _data);
  Future<void> _learnState(DataStore s, String uid) => s.saveLearnState(uid, _data);
  Future<void> Function(DataStore, String) _progressOf(String cardId, {bool profile = false}) => (s, uid) async {
        await s.saveProgress(uid, cardId, _data.progress[cardId]);
        if (profile) await s.saveProfile(uid, _data);
      };

  // === BỘ THẺ ===
  FlashcardSet? deckById(String? id) {
    if (id == null) return null;
    for (final d in _decks) {
      if (d.id == id) return d;
    }
    return null;
  }

  bool isOwner(FlashcardSet? d) => d != null && d.userId == userId;
  bool isAvailable(FlashcardSet? d) => d != null && (isOwner(d) || d.isPublic);

  List<FlashcardSet> get myDecks => _decks.where(isOwner).toList();
  List<String> get savedIds => List.unmodifiable(_data.savedDeckIds);
  bool isSaved(String deckId) => _data.savedDeckIds.contains(deckId);
  List<FlashcardSet> get exploreDecks => _decks.where((d) => d.isPublic && !isOwner(d)).toList();

  // Bộ thẻ của tôi và đã lưu, mới cập nhật trước
  List<FlashcardSet> get recentDecks {
    final list = _decks.where((d) => isAvailable(d) && (isOwner(d) || isSaved(d.id))).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  // Bộ thẻ cho thẻ "Học tiếp" ở Trang chủ
  FlashcardSet? get continueDeck {
    final last = deckById(_data.lastDeckId);
    if (isAvailable(last) && last!.validCards.isNotEmpty) return last;
    for (final d in recentDecks) {
      if (d.validCards.isNotEmpty) return d;
    }
    return null;
  }

  bool get isNewUser =>
      myDecks.isEmpty && _data.savedDeckIds.isEmpty && _data.quizHistory.isEmpty && _data.progress.isEmpty;

  bool hasDuplicateTitle(String title, {String? exceptId}) {
    final t = title.trim().toLowerCase();
    return myDecks.any((d) => d.id != exceptId && d.title.trim().toLowerCase() == t);
  }

  Future<FlashcardSet?> createDeck({
    required String title,
    String description = '',
    String subject = 'Khác',
    String visibility = 'private',
  }) async {
    final now = clock();
    final deck = FlashcardSet(
      id: const Uuid().v4(),
      userId: userId!,
      ownerName: _user!.username,
      title: title.trim(),
      description: description.trim(),
      subject: subject,
      visibility: visibility,
      status: 'draft', // Bản nháp cho đến khi có thẻ hợp lệ và bấm Hoàn tất
      cards: [],
      createdAt: now,
      updatedAt: now,
    );
    final ok = await _commit(() => _decks.add(deck), (s, _) => s.saveDeck(deck), decks: true);
    return ok ? deck : null;
  }

  Future<bool> updateDeckInfo(String deckId, {
    required String title,
    required String description,
    required String subject,
    required String visibility,
  }) {
    return _commit(() {
      final d = deckById(deckId)!;
      d.title = title.trim();
      d.description = description.trim();
      d.subject = subject;
      d.visibility = visibility;
      d.updatedAt = clock();
    }, (s, _) => s.saveDeckInfo(deckById(deckId)!), decks: true);
  }

  Future<bool> finishDeck(String deckId) => _commit(() {
    final d = deckById(deckId)!;
    d.status = 'ready';
    d.updatedAt = clock();
  }, (s, _) => s.saveDeckInfo(deckById(deckId)!), decks: true);

  // Xóa bộ thẻ cùng tiến độ các thẻ; lịch sử kiểm tra được giữ (hiển thị bằng deckTitle đã lưu)
  Future<bool> deleteDeck(String deckId) {
    final d = deckById(deckId);
    if (d == null) return Future.value(true);
    final ids = d.cards.map((c) => c.id).toSet();
    final withProgress = ids.where(_data.progress.containsKey).toList();
    return _commit(() {
      _decks.removeWhere((x) => x.id == deckId);
      _data.progress.removeWhere((k, _) => ids.contains(k));
      _data.starredCardIds.removeWhere(ids.contains);
      _data.savedDeckIds.remove(deckId);
      _data.positions.remove(deckId);
      _data.learnScores.remove(deckId);
      _data.learnRounds.remove(deckId);
      _data.flashSort.remove(deckId);
      if (_data.quizDraft?.deckId == deckId) _data.quizDraft = null;
      if (_data.lastDeckId == deckId) _data.lastDeckId = null;
    }, (s, uid) async {
      await s.deleteDeck(d);
      for (final id in withProgress) {
        await s.saveProgress(uid, id, null);
      }
      await s.saveProfile(uid, _data);
      await s.saveLearnState(uid, _data);
    }, decks: true);
  }

  // Sao chép thành bộ thẻ riêng tư của tôi (thẻ có ID mới, tiến độ bắt đầu lại)
  Future<FlashcardSet?> copyDeck(String deckId) async {
    final src = deckById(deckId);
    if (src == null) return null;
    final now = clock();
    final copy = FlashcardSet(
      id: const Uuid().v4(),
      userId: userId!,
      ownerName: _user!.username,
      title: '${src.title} (bản sao)',
      description: src.description,
      subject: src.subject,
      visibility: 'private',
      cards: src.cards.map((c) => c.copyWith(id: const Uuid().v4())).toList(),
      createdAt: now,
      updatedAt: now,
    );
    final ok = await _commit(() => _decks.add(copy), (s, _) => s.saveDeck(copy), decks: true);
    return ok ? copy : null;
  }

  // Lưu chỉ là đánh dấu, không tạo bản sao
  Future<bool> toggleSave(String deckId) => _commit(() {
    if (!_data.savedDeckIds.remove(deckId)) _data.savedDeckIds.add(deckId);
  }, _profile);

  // === THẺ ===
  // Ghi thẻ (kèm thứ tự) và thời điểm cập nhật của bộ thẻ
  Future<void> Function(DataStore, String) _cardWrite(String deckId, String cardId) => (s, _) async {
        final d = deckById(deckId)!;
        final i = d.cards.indexWhere((c) => c.id == cardId);
        if (i >= 0) await s.saveCard(deckId, d.cards[i], i);
        await s.saveDeckInfo(d);
      };

  Future<bool> addCard(String deckId, Flashcard card) => _commit(() {
    final d = deckById(deckId)!;
    d.cards.add(card);
    d.updatedAt = clock();
  }, _cardWrite(deckId, card.id), decks: true);

  Future<bool> updateCard(String deckId, Flashcard card) => _commit(() {
    final d = deckById(deckId)!;
    final i = d.cards.indexWhere((c) => c.id == card.id);
    card.updatedAt = clock();
    if (i >= 0) d.cards[i] = card;
    d.updatedAt = clock();
  }, _cardWrite(deckId, card.id), decks: true);

  Future<bool> deleteCard(String deckId, String cardId) {
    final hadProgress = _data.progress.containsKey(cardId);
    return _commit(() {
      final d = deckById(deckId)!;
      d.cards.removeWhere((c) => c.id == cardId);
      d.updatedAt = clock();
      _data.progress.remove(cardId);
      _data.starredCardIds.remove(cardId);
    }, (s, uid) async {
      await s.deleteCard(deckId, cardId);
      await s.saveDeckInfo(deckById(deckId)!);
      if (hadProgress) await s.saveProgress(uid, cardId, null);
      await s.saveProfile(uid, _data);
    }, decks: true);
  }

  // Đổi chỗ hai thẻ: ghi lại thứ tự của đúng hai thẻ đó
  Future<bool> moveCard(String deckId, String cardId, int dir) {
    final d = deckById(deckId)!;
    final i = d.cards.indexWhere((c) => c.id == cardId);
    final j = i + dir;
    if (i < 0 || j < 0 || j >= d.cards.length) return Future.value(true);
    final otherId = d.cards[j].id;
    return _commit(() {
      final tmp = d.cards[i];
      d.cards[i] = d.cards[j];
      d.cards[j] = tmp;
      d.updatedAt = clock();
    }, (s, uid) async {
      await s.saveCard(deckId, d.cards[j], j); // Thẻ vừa di chuyển
      await _cardWrite(deckId, otherId)(s, uid); // Thẻ bị đổi chỗ + thời điểm cập nhật bộ thẻ
    }, decks: true);
  }

  bool isStarred(String cardId) => _data.starredCardIds.contains(cardId);

  Future<bool> toggleStar(String cardId) => _commit(() {
    if (!_data.starredCardIds.remove(cardId)) _data.starredCardIds.add(cardId);
  }, _profile);

  // === TIẾN ĐỘ ===
  CardProgress? progressOf(String cardId) => _data.progress[cardId];
  CardStage stageOfCard(String cardId) => stageOf(_data.progress[cardId]);

  Map<CardStage, int> stageCounts(FlashcardSet d) {
    final counts = {for (final s in CardStage.values) s: 0};
    for (final c in d.validCards) {
      counts[stageOfCard(c.id)] = counts[stageOfCard(c.id)]! + 1;
    }
    return counts;
  }

  int knownIn(FlashcardSet d) => d.validCards.where((c) => _data.progress[c.id]?.known == true).length;
  bool touched(FlashcardSet d) => d.cards.any((c) => _data.progress.containsKey(c.id));

  // Thẻ đến hạn ôn của các bộ thẻ tôi sở hữu, đã lưu hoặc đã từng học
  List<DueItem> dueList({String? deckId}) {
    final out = <DueItem>[];
    for (final d in _decks) {
      if (!isAvailable(d) || (deckId != null && d.id != deckId)) continue;
      if (!isOwner(d) && !isSaved(d.id) && !touched(d)) continue;
      for (final c in d.validCards) {
        final p = _data.progress[c.id];
        if (p != null && p.isDue(today)) out.add(DueItem(d.id, c.id));
      }
    }
    return out;
  }

  // Lọc bộ thẻ giống dueList() để số thẻ đến hạn khớp giữa các màn hình
  int dueOn(DateTime day) {
    var n = 0;
    final target = dayOnly(day);
    for (final d in _decks) {
      if (!isAvailable(d)) continue;
      if (!isOwner(d) && !isSaved(d.id) && !touched(d)) continue;
      for (final c in d.validCards) {
        if (_data.progress[c.id]?.due == target) n++;
      }
    }
    return n;
  }

  void _addActivity(int n) {
    final key = dayKey(today);
    _data.activity[key] = (_data.activity[key] ?? 0) + n;
  }

  // Lật thẻ lần đầu trong phiên Thẻ ghi nhớ
  Future<bool> recordFlashcardSeen(String cardId) => _commit(() {
    _addActivity(1);
    _data.progress[cardId] = onFlashcardSeen(_data.progress[cardId], today);
  }, _progressOf(cardId, profile: true));

  // Lưu kèm điểm từng thẻ của phần Học để thoát ra vẫn làm tiếp được
  Future<bool> recordLearnAnswer(String cardId, LearnAnswerResult r, {LearnSession? session}) => _commit(() {
    if (session != null) {
      _data.learnScores[session.deck.id] = Map.of(session.score);
      _data.learnRounds[session.deck.id] = session.round;
    }
    if (r.firstTimeSeen) _addActivity(1);
    _data.progress[cardId] = onLearnAnswer(
      _data.progress[cardId],
      correct: r.correct,
      reachedMastery: r.reachedMastery,
      today: today,
    );
  }, (s, uid) async {
    await _progressOf(cardId, profile: true)(s, uid);
    if (session != null) await s.saveLearnState(uid, _data);
  });

  Future<bool> gradeReview(String cardId, ReviewGrade grade, {required bool firstTime}) => _commit(() {
    if (firstTime) _addActivity(1);
    _data.progress[cardId] = applyReviewGrade(_data.progress[cardId], grade, today);
  }, _progressOf(cardId, profile: true));

  Future<bool> completeSession() => _commit(() => _data.sessions++, _profile);

  Map<String, int>? learnScoreOf(String deckId) => _data.learnScores[deckId];
  int learnRoundOf(String deckId) => _data.learnRounds[deckId] ?? 1;
  double learnCompletion(FlashcardSet d) =>
      LearnSession.completion(d.validCards.map((c) => c.id).toList(), _data.learnScores[d.id] ?? const {});
  Future<bool> saveLearnRound(String deckId, int round) =>
      _commit(() => _data.learnRounds[deckId] = round, _learnState);
  Future<bool> resetLearn(String deckId) => _commit(() {
    _data.learnScores.remove(deckId);
    _data.learnRounds.remove(deckId);
  }, _learnState);

  // Phân loại Đã biết / Đang học của lượt Thẻ ghi nhớ đang dở
  Map<String, bool> flashSortOf(String deckId) => Map.of(_data.flashSort[deckId] ?? const {});
  Future<bool> saveFlashSort(String deckId, Map<String, bool> sort) => _commit(() {
    if (sort.isEmpty) {
      _data.flashSort.remove(deckId);
    } else {
      _data.flashSort[deckId] = Map.of(sort);
    }
  }, _learnState);

  int positionOf(String deckId) => _data.positions[deckId] ?? 0;

  Future<bool> savePosition(String deckId, int index) => _commit(() => _data.positions[deckId] = index, _learnState);

  Future<bool> setLastDeck(String deckId) => _commit(() => _data.lastDeckId = deckId, _profile);

  // === QUIZ ===
  QuizDraft? get quizDraft => _data.quizDraft;
  List<QuizAttempt> get history => List.unmodifiable(_data.quizHistory);

  QuizAttempt? attemptById(String id) {
    for (final a in _data.quizHistory) {
      if (a.id == id) return a;
    }
    return null;
  }

  // Lưu kết quả; câu sai/bỏ trống đưa thẻ về Đang học và đến hạn ôn hôm nay
  Future<bool> submitQuiz(QuizAttempt attempt) {
    if (_data.quizHistory.any((a) => a.id == attempt.id)) return Future.value(true); // Tránh ghi trùng
    final missed = attempt.items.where((x) => !x.isCorrect).map((x) => x.question.cardId).toSet();
    return _commit(() {
      _data.quizHistory.add(attempt);
      _data.quizDraft = null;
      for (final id in missed) {
        _data.progress[id] = onQuizMissed(_data.progress[id], today);
      }
    }, (s, uid) async {
      await s.saveAttempt(uid, attempt);
      await s.saveLearnState(uid, _data);
      for (final id in missed) {
        await s.saveProgress(uid, id, _data.progress[id]);
      }
    });
  }

  // Xóa một kết quả kiểm tra khỏi lịch sử
  Future<bool> deleteAttempt(String attemptId) =>
      _commit(() => _data.quizHistory.removeWhere((a) => a.id == attemptId), (s, uid) => s.deleteAttempt(uid, attemptId));

  Future<bool> saveQuizDraft(QuizDraft draft) => _commit(() => _data.quizDraft = draft, _learnState);
  Future<bool> clearQuizDraft() => _commit(() => _data.quizDraft = null, _learnState);

  // === THỐNG KÊ / HỒ SƠ ===
  StatsSnapshot get stats => computeStats(_data, clock());
  int get streak => computeStreak(_data, today);
  int get todayCount => countOn(_data, today);
  int get dailyGoal => _data.dailyGoal;
  bool get remindEnabled => _data.remindEnabled;
  String get remindTime => _data.remindTime;

  Future<bool> setDailyGoal(int goal) => _commit(() => _data.dailyGoal = goal, _profile);

  Future<bool> setReminder({required bool enabled, String? time}) => _commit(() {
    _data.remindEnabled = enabled;
    if (time != null) _data.remindTime = time;
  }, _profile);

  // Đổi tên hiển thị (Firebase Auth đã cập nhật ở AuthService): cập nhật tên tác giả trên các bộ thẻ của tôi
  Future<bool> applyProfile(User updated, int goal) {
    final renamed = updated.username != _user?.username;
    _user = updated;
    return _commit(() {
      _data.dailyGoal = goal;
      for (final d in myDecks) {
        d.ownerName = updated.username;
      }
    }, (s, uid) async {
      await s.saveProfile(uid, _data);
      if (renamed) await s.renameOwner(uid, updated.username);
    }, decks: true);
  }
}
