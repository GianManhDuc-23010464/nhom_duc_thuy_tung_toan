// services/flashcard_service.dart - SỬA LỖI VÒNG LẶP
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class FlashcardService with ChangeNotifier {
  static final FlashcardService _instance = FlashcardService._internal();
  factory FlashcardService() => _instance;
  FlashcardService._internal();

  final AuthService _authService = AuthService();
  final List<FlashcardSet> _sets = [];
  List<FlashcardSet> get sets => List.unmodifiable(_sets);

  bool _isDataLoaded = false;
  bool _isLoading = false;
  bool _isNotifying = false; // THÊM: Ngăn chặn notify lặp

  // === KEYS ===
  Future<String> get _keyData async => 'flashcard_data_${await _getCurrentUserId()}';
  Future<String> get _keyLastStudy async => 'last_study_date_${await _getCurrentUserId()}';
  Future<String> get _keyStreak async => 'study_streak_${await _getCurrentUserId()}';
  Future<String> get _keyTotalStudied async => 'total_studied_today_${await _getCurrentUserId()}';
  Future<String> get _keyUserName async => 'user_name_${await _getCurrentUserId()}';
  Future<String> get _keyDailyGoal async => 'daily_goal_${await _getCurrentUserId()}';
  Future<String> get _keyDarkMode async => 'dark_mode_${await _getCurrentUserId()}';
  Future<String> get _keyTotalTests async => 'total_tests_${await _getCurrentUserId()}';
  Future<String> get _keyTotalMastered async => 'total_mastered_${await _getCurrentUserId()}';

  // Lấy user ID hiện tại
  Future<String> _getCurrentUserId() async {
    final currentUser = await _authService.getCurrentUser();
    return currentUser?.id ?? 'anonymous';
  }

  // === TẢI DỮ LIỆU ===
  Future<void> loadData({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    if (_isDataLoaded && _sets.isNotEmpty && !forceRefresh) return;

    _isLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _keyData;
      final data = prefs.getString(key);

      if (forceRefresh) {
        _sets.clear();
      }

      if (data != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(data);
          _sets.addAll(jsonList.map((e) => FlashcardSet.fromJson(e)).toList());
          _isDataLoaded = true;
        } catch (e) {
          debugPrint('❌ Lỗi decode dữ liệu: $e');
          await _addSampleData();
          await _saveData();
          _isDataLoaded = true;
        }
      } else {
        await _addSampleData();
        await _saveData();
        _isDataLoaded = true;
      }
    } catch (e) {
      debugPrint('❌ Lỗi loadData: $e');
    } finally {
      _isLoading = false;
      // XÓA: Không gọi notifyListeners() ở đây
    }
  }

  // === LƯU DỮ LIỆU ===
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _keyData;
      final jsonList = _sets.map((set) => set.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));

      // SỬA: Chỉ notify khi không đang trong quá trình notify
      if (!_isNotifying) {
        _isNotifying = true;
        notifyListeners();
        _isNotifying = false;
      }
    } catch (e) {
      debugPrint('❌ Lỗi saveData: $e');
    }
  }

  // === PHƯƠNG THỨC MỚI CHO TRANG HỌC ===

  // Lấy flashcards theo setId
  Future<List<Map<String, dynamic>>> getFlashcardsBySetId(String setId) async {
    try {
      await loadData();

      final set = _sets.firstWhere(
            (s) => s.id == setId,
        orElse: () => FlashcardSet(
          id: '',
          userId: '',
          title: 'Not Found',
          cards: [],
        ),
      );

      if (set.id.isEmpty) {
        return [];
      }

      return set.cards.map((card) {
        return {
          'id': '${setId}_${card.term}',
          'setId': setId,
          'front': card.term,
          'back': card.meaning,
          'note': card.note,
          'mastered': card.mastered,
        };
      }).toList();

    } catch (e) {
      debugPrint('❌ Lỗi getFlashcardsBySetId: $e');
      return [];
    }
  }

  // Cập nhật tiến độ học tập
  Future<void> updateLearningProgress({
    required String cardId,
    required bool isCorrect,
  }) async {
    try {
      // cardId có định dạng: setId_term
      final parts = cardId.split('_');
      if (parts.length < 2) return;

      final setId = parts[0];
      final term = parts.sublist(1).join('_');

      final setIndex = _sets.indexWhere((s) => s.id == setId);
      if (setIndex == -1) return;

      final cardIndex = _sets[setIndex].cards.indexWhere((c) => c.term == term);
      if (cardIndex == -1) return;

      // Cập nhật trạng thái học tập
      if (isCorrect) {
        // Nếu đúng, thêm ghi chú để đánh dấu đã học
        if (_sets[setIndex].cards[cardIndex].note?.isEmpty ?? true) {
          _sets[setIndex].cards[cardIndex].note = "Đã học";
        }

        // Tăng số lần đúng
        _sets[setIndex].cards[cardIndex].correctCount =
            (_sets[setIndex].cards[cardIndex].correctCount ?? 0) + 1;

        // Nếu đúng 3 lần liên tiếp, đánh dấu thành thạo
        if ((_sets[setIndex].cards[cardIndex].correctCount ?? 0) >= 3) {
          _sets[setIndex].cards[cardIndex].mastered = true;
        }
      } else {
        // Nếu sai, reset số lần đúng
        _sets[setIndex].cards[cardIndex].correctCount = 0;
        _sets[setIndex].cards[cardIndex].mastered = false;
      }

      await _saveData();

      // Ghi nhận buổi học
      await recordStudySession(1);

      debugPrint('📝 Đã cập nhật tiến độ: $term - ${isCorrect ? "Đúng" : "Sai"}');

    } catch (e) {
      debugPrint('❌ Lỗi updateLearningProgress: $e');
    }
  }

  // === THỐNG KÊ ===
  Future<Map<String, dynamic>> getStats({bool forceRefresh = false}) async {
    try {
      await loadData(forceRefresh: forceRefresh);

      final prefs = await SharedPreferences.getInstance();
      final totalSets = _sets.length;
      final totalCards = _sets.fold(0, (sum, set) => sum + set.cards.length);
      final totalStudiedKey = await _keyTotalStudied;
      final streakKey = await _keyStreak;
      final totalTestsKey = await _keyTotalTests;
      final totalMasteredKey = await _keyTotalMastered;

      final todayStudied = prefs.getInt(totalStudiedKey) ?? 0;
      final streak = prefs.getInt(streakKey) ?? 0;
      final totalTests = prefs.getInt(totalTestsKey) ?? 0;
      final totalMastered = prefs.getInt(totalMasteredKey) ?? 0;
      final goal = await getDailyGoal();
      final progress = goal > 0 ? (todayStudied / goal * 100).clamp(0, 100) : 0;
      final rememberRate = _calculateRememberRate();
      final masteredRate = totalCards > 0 ? ((totalMastered / totalCards) * 100).round() : 0;

      final stats = {
        'totalSets': totalSets,
        'totalCards': totalCards,
        'todayStudied': todayStudied,
        'streak': streak,
        'dailyGoal': goal,
        'progress': progress.toStringAsFixed(0),
        'rememberRate': rememberRate,
        'totalTests': totalTests,
        'totalMastered': totalMastered,
        'masteredRate': masteredRate,
      };

      return stats;
    } catch (e) {
      debugPrint('❌ Lỗi getStats: $e');
      return _getDefaultStats();
    }
  }

  Map<String, dynamic> _getDefaultStats() {
    return {
      'totalSets': 0,
      'totalCards': 0,
      'todayStudied': 0,
      'streak': 0,
      'dailyGoal': 20,
      'progress': '0',
      'rememberRate': 0,
      'totalTests': 0,
      'totalMastered': 0,
      'masteredRate': 0,
    };
  }

  // Hàm tính tỷ lệ nhớ
  int _calculateRememberRate() {
    if (_sets.isEmpty) return 0;

    int totalCards = 0;
    int rememberedCards = 0;

    for (final set in _sets) {
      for (final card in set.cards) {
        totalCards++;
        if (card.note != null && card.note!.isNotEmpty) {
          rememberedCards++;
        }
      }
    }

    return totalCards > 0 ? ((rememberedCards / totalCards) * 100).round() : 0;
  }

  // === GHI NHẬN HỌC ===
  Future<void> recordStudySession(int cardCount) async {
    if (cardCount <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastStudyKey = await _keyLastStudy;
    final streakKey = await _keyStreak;
    final totalStudiedKey = await _keyTotalStudied;

    final lastDate = prefs.getString(lastStudyKey) ?? '';

    int streak = prefs.getInt(streakKey) ?? 0;
    int todayStudied = prefs.getInt(totalStudiedKey) ?? 0;

    if (lastDate == today) {
      todayStudied += cardCount;
    } else {
      todayStudied = cardCount;
      if (lastDate.isNotEmpty) {
        final last = DateTime.parse(lastDate);
        final today = DateTime.now();
        final diff = DateTime(today.year, today.month, today.day)
            .difference(DateTime(last.year, last.month, last.day))
            .inDays;

        if (diff == 1) {
          streak++;
        } else if (diff > 1) {
          streak = 1;
        }
      } else {
        streak = 1;
      }
    }

    await prefs.setString(lastStudyKey, today);
    await prefs.setInt(streakKey, streak);
    await prefs.setInt(totalStudiedKey, todayStudied);

    // SỬA: Không gọi notifyListeners() ở đây để tránh vòng lặp
    debugPrint('📚 Đã ghi nhận học: $cardCount thẻ');
  }

  // === GHI NHẬN KIỂM TRA ===
  Future<void> recordTestSession(int correctAnswers, int totalQuestions, int newMasteredCards) async {
    if (totalQuestions <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final totalTestsKey = await _keyTotalTests;
    final totalMasteredKey = await _keyTotalMastered;

    int totalTests = prefs.getInt(totalTestsKey) ?? 0;
    int totalMastered = prefs.getInt(totalMasteredKey) ?? 0;

    totalTests++;
    totalMastered += newMasteredCards;

    await prefs.setInt(totalTestsKey, totalTests);
    await prefs.setInt(totalMasteredKey, totalMastered);

    await recordStudySession(totalQuestions);

    debugPrint('📊 Đã ghi nhận kiểm tra: $correctAnswers/$totalQuestions, thành thạo: $newMasteredCards');

    // SỬA: Chỉ notify khi không đang trong quá trình notify
    if (!_isNotifying) {
      _isNotifying = true;
      notifyListeners();
      _isNotifying = false;
    }
  }

  // === QUẢN LÝ THẺ THÀNH THẠO ===
  Future<void> markCardAsMastered(String setId, String term) async {
    try {
      final set = _sets.firstWhere((s) => s.id == setId);
      final card = set.cards.firstWhere((c) => c.term == term);
      card.mastered = true;
      await _saveData();
      debugPrint('⭐ Đã đánh dấu thẻ thành thạo: $term');
    } catch (e) {
      debugPrint('❌ Lỗi đánh dấu thẻ thành thạo: $e');
    }
  }

  Future<void> unmarkCardAsMastered(String setId, String term) async {
    try {
      final set = _sets.firstWhere((s) => s.id == setId);
      final card = set.cards.firstWhere((c) => c.term == term);
      card.mastered = false;
      await _saveData();
      debugPrint('🔁 Đã bỏ đánh dấu thành thạo: $term');
    } catch (e) {
      debugPrint('❌ Lỗi bỏ đánh dấu thành thạo: $e');
    }
  }

  int getMasteredCardCount() {
    int count = 0;
    for (final set in _sets) {
      for (final card in set.cards) {
        if (card.mastered) {
          count++;
        }
      }
    }
    return count;
  }

  List<Flashcard> getUnmasteredCards() {
    final List<Flashcard> unmastered = [];
    for (final set in _sets) {
      for (final card in set.cards) {
        if (!card.mastered) {
          unmastered.add(card);
        }
      }
    }
    return unmastered;
  }

  List<Flashcard> getMasteredCards() {
    final List<Flashcard> mastered = [];
    for (final set in _sets) {
      for (final card in set.cards) {
        if (card.mastered) {
          mastered.add(card);
        }
      }
    }
    return mastered;
  }

  // === CRUD OPERATIONS ===
  Future<void> addSet(String title) async {
    final userId = await _getCurrentUserId();
    _sets.add(FlashcardSet(
        id: _generateId(),
        userId: userId,
        title: title,
        cards: []
    ));
    await _saveData();
  }

  Future<void> updateSet(String id, String newTitle) async {
    final index = _sets.indexWhere((s) => s.id == id);
    if (index != -1) {
      final userId = await _getCurrentUserId();
      _sets[index] = FlashcardSet(
          id: id,
          userId: userId,
          title: newTitle,
          cards: _sets[index].cards
      );
      await _saveData();
    }
  }

  Future<void> deleteSet(String id) async {
    _sets.removeWhere((s) => s.id == id);
    await _saveData();
  }

  Future<void> addCard(String setId, Flashcard card) async {
    final set = _sets.firstWhere((s) => s.id == setId);
    set.cards.add(card);
    await _saveData();
  }

  Future<void> updateCard(String setId, String oldTerm, Flashcard newCard) async {
    final set = _sets.firstWhere((s) => s.id == setId);
    final index = set.cards.indexWhere((c) => c.term == oldTerm);
    if (index != -1) {
      set.cards[index] = newCard;
      await _saveData();
    }
  }

  Future<void> deleteCard(String setId, String term) async {
    final set = _sets.firstWhere((s) => s.id == setId);
    final card = set.cards.firstWhere((c) => c.term == term);
    if (card.imagePath != null) {
      final file = File(card.imagePath!);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    set.cards.removeWhere((c) => c.term == term);
    await _saveData();
  }

  // === PROFILE ===
  Future<String> getUserName() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      return currentUser.username;
    }

    final prefs = await SharedPreferences.getInstance();
    final userNameKey = await _keyUserName;
    return prefs.getString(userNameKey) ?? "Người dùng";
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final userNameKey = await _keyUserName;
    await prefs.setString(userNameKey, name);

    // SỬA: Chỉ notify khi không đang trong quá trình notify
    if (!_isNotifying) {
      _isNotifying = true;
      notifyListeners();
      _isNotifying = false;
    }
  }

  Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyGoalKey = await _keyDailyGoal;
    return prefs.getInt(dailyGoalKey) ?? 20;
  }

  Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    final dailyGoalKey = await _keyDailyGoal;
    await prefs.setInt(dailyGoalKey, goal);

    // SỬA: Chỉ notify khi không đang trong quá trình notify
    if (!_isNotifying) {
      _isNotifying = true;
      notifyListeners();
      _isNotifying = false;
    }
  }

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final darkModeKey = await _keyDarkMode;
    return prefs.getBool(darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final darkModeKey = await _keyDarkMode;
    await prefs.setBool(darkModeKey, value);

    // SỬA: Chỉ notify khi không đang trong quá trình notify
    if (!_isNotifying) {
      _isNotifying = true;
      notifyListeners();
      _isNotifying = false;
    }
  }

  // === DỮ LIỆU MẪU ===
  Future<void> _addSampleData() async {
    final userId = await _getCurrentUserId();
    if (userId == 'anonymous') {
      final id1 = _generateId();
      final id2 = _generateId();
      _sets.addAll([
        FlashcardSet(
          id: id1,
          userId: userId,
          title: "Động vật",
          cards: [
            Flashcard(
              term: "cat",
              meaning: "con mèo",
              note: "VD: this is my cat",
              mastered: false,
              correctCount: 0,
            ),
            Flashcard(
              term: "dog",
              meaning: "con chó",
              note: "VD: this is my dog",
              mastered: false,
              correctCount: 0,
            ),
          ],
        ),
        FlashcardSet(
          id: id2,
          userId: userId,
          title: "Trái cây",
          cards: [
            Flashcard(
              term: "Apple",
              meaning: "Quả táo",
              note: "",
              mastered: false,
              correctCount: 0,
            ),
            Flashcard(
              term: "Banana",
              meaning: "Quả chuối",
              note: "",
              mastered: false,
              correctCount: 0,
            ),
          ],
        ),
      ]);
    }
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  // === RESET TRẠNG THÁI ===
  void resetLoadState() {
    _isDataLoaded = false;
    _isLoading = false;
  }

  Future<void> switchUserData() async {
    resetLoadState();
    await loadData();
  }

  // === TIỆN ÍCH ===
  List<Flashcard> getAllCards() {
    final List<Flashcard> allCards = [];
    for (final set in _sets) {
      allCards.addAll(set.cards);
    }
    return allCards;
  }

  List<Flashcard> getRandomCardsForTest(int count) {
    final allCards = getAllCards();
    final shuffled = List<Flashcard>.from(allCards)..shuffle();
    if (shuffled.length <= count) {
      return shuffled;
    }
    return shuffled.sublist(0, count);
  }

  List<Flashcard> getUnmasteredCardsForTest(int count) {
    final unmastered = getUnmasteredCards();
    final shuffled = List<Flashcard>.from(unmastered)..shuffle();
    if (shuffled.length <= count) {
      return shuffled;
    }
    return shuffled.sublist(0, count);
  }
}