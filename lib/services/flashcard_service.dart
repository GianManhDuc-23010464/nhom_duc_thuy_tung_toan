import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'auth_service.dart';

class FlashcardService with ChangeNotifier {
  static final FlashcardService _instance = FlashcardService._internal();

  factory FlashcardService() => _instance;

  FlashcardService._internal()
    : _firestore = FirebaseFirestore.instance,
      _storage = FirebaseStorage.instance,
      _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen((user) {
      final nextUserId = user?.uid;
      if (_activeUserId != nextUserId) {
        _clearCache(nextUserId);
        _notifySafely();
      }
    });
  }

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final AuthService _authService = AuthService();

  final List<FlashcardSet> _sets = [];
  List<FlashcardSet> get sets => List.unmodifiable(_sets);

  String? _activeUserId;
  bool _isDataLoaded = false;
  Future<void>? _loadingFuture;
  bool _isNotifying = false;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _setsRef(String uid) =>
      _userRef(uid).collection('flashcardSets');

  CollectionReference<Map<String, dynamic>> _cardsRef(
    String uid,
    String setId,
  ) => _setsRef(uid).doc(setId).collection('cards');

  DocumentReference<Map<String, dynamic>> _statsRef(String uid) =>
      _userRef(uid).collection('stats').doc('summary');

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Người dùng chưa đăng nhập.');
    }
    return uid;
  }

  void _clearCache(String? nextUserId) {
    _sets.clear();
    _activeUserId = nextUserId;
    _isDataLoaded = false;
    _loadingFuture = null;
  }

  void _notifySafely() {
    if (_isNotifying) return;
    _isNotifying = true;
    notifyListeners();
    _isNotifying = false;
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    final uid = _requireUserId();
    if (_activeUserId != uid) {
      _clearCache(uid);
    }

    if (_isDataLoaded && !forceRefresh) return;

    final currentLoad = _loadingFuture;
    if (currentLoad != null) {
      await currentLoad;
      return;
    }

    final load = _loadFromFirestore(uid);
    _loadingFuture = load;
    try {
      await load;
    } finally {
      if (identical(_loadingFuture, load)) {
        _loadingFuture = null;
      }
    }
  }

  Future<void> _loadFromFirestore(String uid) async {
    final loadedSets = <FlashcardSet>[];
    final setSnapshots = await _setsRef(uid).orderBy('createdAt').get();

    for (final setDocument in setSnapshots.docs) {
      final cardSnapshots = await setDocument.reference
          .collection('cards')
          .orderBy('createdAt')
          .get();
      final cards = cardSnapshots.docs
          .map(
            (document) => Flashcard.fromFirestore(document.id, document.data()),
          )
          .toList();
      loadedSets.add(
        FlashcardSet.fromFirestore(
          setDocument.id,
          uid,
          setDocument.data(),
          cards,
        ),
      );
    }

    // Không cho request cũ ghi dữ liệu vào cache sau khi user đã đổi/logout.
    if (_auth.currentUser?.uid != uid || _activeUserId != uid) return;
    _sets
      ..clear()
      ..addAll(loadedSets);
    _isDataLoaded = true;
  }

  Future<List<Map<String, dynamic>>> getFlashcardsBySetId(String setId) async {
    await loadData();
    final index = _sets.indexWhere((set) => set.id == setId);
    if (index == -1) return [];

    return _sets[index].cards
        .map(
          (card) => {
            'id': card.id,
            'setId': setId,
            'front': card.term,
            'back': card.meaning,
            'note': card.note,
            'imageUrl': card.imageUrl,
            'mastered': card.mastered,
            'correctCount': card.correctCount,
          },
        )
        .toList();
  }

  Future<void> updateLearningProgress({
    required String setId,
    required String cardId,
    required bool isCorrect,
  }) async {
    await loadData();
    final uid = _requireUserId();
    final setIndex = _sets.indexWhere((set) => set.id == setId);
    if (setIndex == -1) return;
    final cardIndex = _sets[setIndex].cards.indexWhere(
      (card) => card.id == cardId,
    );
    if (cardIndex == -1) return;

    final card = _sets[setIndex].cards[cardIndex];
    final wasMastered = card.mastered;
    final nextCorrectCount = isCorrect ? card.correctCount + 1 : 0;
    final nextMastered = isCorrect ? nextCorrectCount >= 3 : false;
    final updatedCard = card.copyWith(
      correctCount: nextCorrectCount,
      mastered: nextMastered,
      updatedAt: DateTime.now(),
    );

    await _cardsRef(uid, setId).doc(cardId).update({
      'correctCount': nextCorrectCount,
      'mastered': nextMastered,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _sets[setIndex].cards[cardIndex] = updatedCard;

    if (wasMastered != nextMastered) {
      await _changeMasteredTotal(uid, nextMastered ? 1 : -1);
    }
    _notifySafely();
  }

  Future<Map<String, dynamic>> getStats({bool forceRefresh = false}) async {
    try {
      await loadData(forceRefresh: forceRefresh);
      final uid = _requireUserId();
      final snapshots = await Future.wait([
        _userRef(uid).get(),
        _statsRef(uid).get(),
      ]);
      final userData = snapshots[0].data() ?? <String, dynamic>{};
      final statsData = snapshots[1].data() ?? <String, dynamic>{};

      final totalSets = _sets.length;
      final totalCards = _sets.fold<int>(
        0,
        (total, set) => total + set.cards.length,
      );
      final totalMastered = getMasteredCardCount();
      final dailyGoal = (userData['dailyGoal'] as num?)?.toInt() ?? 20;
      final today = _dateKey(DateTime.now());
      final todayStudied = statsData['todayDate'] == today
          ? (statsData['todayStudied'] as num?)?.toInt() ?? 0
          : 0;
      final streak = (statsData['streak'] as num?)?.toInt() ?? 0;
      final totalTests = (statsData['totalTests'] as num?)?.toInt() ?? 0;
      final progress = dailyGoal > 0
          ? (todayStudied / dailyGoal * 100).clamp(0, 100)
          : 0;
      final rememberRate = _calculateRememberRate();
      final masteredRate = totalCards > 0
          ? ((totalMastered / totalCards) * 100).round()
          : 0;

      if ((statsData['totalMastered'] as num?)?.toInt() != totalMastered) {
        await _statsRef(uid).set({
          'totalMastered': totalMastered,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return {
        'totalSets': totalSets,
        'totalCards': totalCards,
        'todayStudied': todayStudied,
        'streak': streak,
        'dailyGoal': dailyGoal,
        'progress': progress.toStringAsFixed(0),
        'rememberRate': rememberRate,
        'totalTests': totalTests,
        'totalMastered': totalMastered,
        'masteredRate': masteredRate,
      };
    } catch (error) {
      debugPrint('Lỗi tải thống kê Firestore: $error');
      return _defaultStats();
    }
  }

  Map<String, dynamic> _defaultStats() => {
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

  int _calculateRememberRate() {
    final totalCards = _sets.fold<int>(
      0,
      (total, set) => total + set.cards.length,
    );
    if (totalCards == 0) return 0;
    final masteredCards = getMasteredCardCount();
    return ((masteredCards / totalCards) * 100).round();
  }

  Future<void> recordStudySession(int cardCount) async {
    if (cardCount <= 0) return;
    final uid = _requireUserId();
    final reference = _statsRef(uid);
    final now = DateTime.now();
    final today = _dateKey(now);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data() ?? <String, dynamic>{};
      final lastStudyDate = data['lastStudyDate'] as String? ?? '';
      final storedToday = data['todayDate'] as String? ?? '';
      var streak = (data['streak'] as num?)?.toInt() ?? 0;
      var todayStudied = (data['todayStudied'] as num?)?.toInt() ?? 0;

      if (storedToday == today) {
        todayStudied += cardCount;
      } else {
        todayStudied = cardCount;
        if (lastStudyDate.isEmpty) {
          streak = 1;
        } else {
          final lastDate = DateTime.tryParse(lastStudyDate);
          final difference = lastDate == null
              ? 2
              : DateTime(now.year, now.month, now.day)
                    .difference(
                      DateTime(lastDate.year, lastDate.month, lastDate.day),
                    )
                    .inDays;
          if (difference == 1) {
            streak += 1;
          } else if (difference > 1) {
            streak = 1;
          }
        }
      }

      transaction.set(reference, {
        'streak': streak,
        'todayStudied': todayStudied,
        'todayDate': today,
        'lastStudyDate': today,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> recordTestSession(
    int correctAnswers,
    int totalQuestions,
    int newMasteredCards,
  ) async {
    if (totalQuestions <= 0) return;
    final uid = _requireUserId();
    final update = <String, dynamic>{
      'totalTests': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (newMasteredCards > 0) {
      update['totalMastered'] = FieldValue.increment(newMasteredCards);
    }
    await _statsRef(uid).set(update, SetOptions(merge: true));
    await recordStudySession(totalQuestions);
    _notifySafely();
  }

  Future<void> markCardAsMastered(String setId, String cardId) async {
    await _setMastered(setId, cardId, true);
  }

  Future<void> unmarkCardAsMastered(String setId, String cardId) async {
    await _setMastered(setId, cardId, false);
  }

  Future<void> _setMastered(String setId, String cardId, bool mastered) async {
    await loadData();
    final uid = _requireUserId();
    final setIndex = _sets.indexWhere((set) => set.id == setId);
    if (setIndex == -1) return;
    final cardIndex = _sets[setIndex].cards.indexWhere(
      (card) => card.id == cardId,
    );
    if (cardIndex == -1) return;

    final card = _sets[setIndex].cards[cardIndex];
    if (card.mastered == mastered) return;
    await _cardsRef(uid, setId).doc(cardId).update({
      'mastered': mastered,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _sets[setIndex].cards[cardIndex] = card.copyWith(
      mastered: mastered,
      updatedAt: DateTime.now(),
    );
    await _changeMasteredTotal(uid, mastered ? 1 : -1);
    _notifySafely();
  }

  Future<void> _changeMasteredTotal(String uid, int difference) async {
    final reference = _statsRef(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final current = (snapshot.data()?['totalMastered'] as num?)?.toInt() ?? 0;
      transaction.set(reference, {
        'totalMastered': max(0, current + difference),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  int getMasteredCardCount() {
    return _sets.fold<int>(
      0,
      (total, set) => total + set.cards.where((card) => card.mastered).length,
    );
  }

  List<Flashcard> getUnmasteredCards() =>
      getAllCards().where((card) => !card.mastered).toList(growable: false);

  List<Flashcard> getMasteredCards() =>
      getAllCards().where((card) => card.mastered).toList(growable: false);

  Future<void> addSet(String title) async {
    final uid = _requireUserId();
    await loadData();
    final reference = _setsRef(uid).doc();
    final now = DateTime.now();
    final set = FlashcardSet(
      id: reference.id,
      userId: uid,
      title: title.trim(),
      cards: [],
      createdAt: now,
      updatedAt: now,
    );
    await reference.set(set.toFirestore());
    _sets.add(set);
    _notifySafely();
  }

  Future<void> updateSet(String id, String newTitle) async {
    await loadData();
    final uid = _requireUserId();
    final index = _sets.indexWhere((set) => set.id == id);
    if (index == -1) return;
    final now = DateTime.now();
    await _setsRef(uid).doc(id).update({
      'title': newTitle.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _sets[index] = _sets[index].copyWith(
      title: newTitle.trim(),
      updatedAt: now,
    );
    _notifySafely();
  }

  Future<void> deleteSet(String id) async {
    await loadData();
    final uid = _requireUserId();
    final index = _sets.indexWhere((set) => set.id == id);
    if (index == -1) return;
    final set = _sets[index];

    for (final card in set.cards) {
      await _deleteCardImage(uid, card.id, card.imageUrl);
    }

    final cardDocuments = await _cardsRef(uid, id).get();
    for (final document in cardDocuments.docs) {
      await document.reference.delete();
    }
    await _setsRef(uid).doc(id).delete();
    _sets.removeAt(index);

    final masteredCount = set.cards.where((card) => card.mastered).length;
    if (masteredCount > 0) {
      await _changeMasteredTotal(uid, -masteredCount);
    }
    _notifySafely();
  }

  Future<void> addCard(
    String setId,
    Flashcard card, {
    String? imageFilePath,
  }) async {
    await loadData();
    final uid = _requireUserId();
    final setIndex = _sets.indexWhere((set) => set.id == setId);
    if (setIndex == -1) throw StateError('Không tìm thấy bộ thẻ.');

    final imageUrl = imageFilePath == null
        ? card.imageUrl
        : await _uploadCardImage(uid, card.id, imageFilePath);
    final now = DateTime.now();
    final savedCard = card.copyWith(imageUrl: imageUrl, updatedAt: now);
    final batch = _firestore.batch();
    batch.set(_cardsRef(uid, setId).doc(savedCard.id), savedCard.toFirestore());
    batch.update(_setsRef(uid).doc(setId), {
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    _sets[setIndex].cards.add(savedCard);
    _notifySafely();
  }

  Future<void> updateCard(
    String setId,
    String cardId,
    Flashcard newCard, {
    String? imageFilePath,
  }) async {
    await loadData();
    final uid = _requireUserId();
    final setIndex = _sets.indexWhere((set) => set.id == setId);
    if (setIndex == -1) throw StateError('Không tìm thấy bộ thẻ.');
    final cardIndex = _sets[setIndex].cards.indexWhere(
      (card) => card.id == cardId,
    );
    if (cardIndex == -1) throw StateError('Không tìm thấy flashcard.');

    final oldCard = _sets[setIndex].cards[cardIndex];
    final imageUrl = imageFilePath == null
        ? oldCard.imageUrl
        : await _uploadCardImage(uid, cardId, imageFilePath);
    final savedCard = Flashcard(
      id: cardId,
      term: newCard.term,
      meaning: newCard.meaning,
      note: newCard.note,
      imageUrl: imageUrl,
      mastered: oldCard.mastered,
      correctCount: oldCard.correctCount,
      createdAt: oldCard.createdAt,
      updatedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(_cardsRef(uid, setId).doc(cardId), savedCard.toFirestore());
    batch.update(_setsRef(uid).doc(setId), {
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    _sets[setIndex].cards[cardIndex] = savedCard;
    _notifySafely();
  }

  Future<void> deleteCard(String setId, String cardId) async {
    await loadData();
    final uid = _requireUserId();
    final setIndex = _sets.indexWhere((set) => set.id == setId);
    if (setIndex == -1) return;
    final cardIndex = _sets[setIndex].cards.indexWhere(
      (card) => card.id == cardId,
    );
    if (cardIndex == -1) return;
    final card = _sets[setIndex].cards[cardIndex];

    await _deleteCardImage(uid, cardId, card.imageUrl);
    final batch = _firestore.batch();
    batch.delete(_cardsRef(uid, setId).doc(cardId));
    batch.update(_setsRef(uid).doc(setId), {
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    _sets[setIndex].cards.removeAt(cardIndex);
    if (card.mastered) await _changeMasteredTotal(uid, -1);
    _notifySafely();
  }

  Future<String> _uploadCardImage(
    String uid,
    String cardId,
    String filePath,
  ) async {
    final reference = _storage.ref('users/$uid/flashcards/$cardId/image.jpg');
    await reference.putFile(
      File(filePath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return reference.getDownloadURL();
  }

  Future<void> _deleteCardImage(
    String uid,
    String cardId,
    String? imageUrl,
  ) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      await _storage.ref('users/$uid/flashcards/$cardId/image.jpg').delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  Future<String> getUserName() async {
    return (await _authService.getCurrentUser())?.username ?? 'Người dùng';
  }

  Future<void> setUserName(String name) async {
    final uid = _requireUserId();
    await _userRef(uid).update({'username': name.trim()});
    await _auth.currentUser?.updateDisplayName(name.trim());
    _notifySafely();
  }

  Future<int> getDailyGoal() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 20;
    final snapshot = await _userRef(uid).get();
    return (snapshot.data()?['dailyGoal'] as num?)?.toInt() ?? 20;
  }

  Future<void> setDailyGoal(int goal) async {
    final uid = _requireUserId();
    await _userRef(uid).set({'dailyGoal': goal}, SetOptions(merge: true));
    _notifySafely();
  }

  Future<bool> isDarkMode() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final snapshot = await _userRef(uid).get();
    return snapshot.data()?['darkMode'] as bool? ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _userRef(uid).set({'darkMode': value}, SetOptions(merge: true));
    _notifySafely();
  }

  void resetLoadState() {
    _isDataLoaded = false;
    _loadingFuture = null;
  }

  void clearUserData() {
    _clearCache(_auth.currentUser?.uid);
    _notifySafely();
  }

  Future<void> switchUserData() async {
    clearUserData();
    if (_auth.currentUser != null) {
      await loadData(forceRefresh: true);
    }
  }

  List<Flashcard> getAllCards() => [for (final set in _sets) ...set.cards];

  List<Flashcard> getRandomCardsForTest(int count) {
    final shuffled = List<Flashcard>.from(getAllCards())..shuffle(Random());
    return shuffled.take(count).toList();
  }

  List<Flashcard> getUnmasteredCardsForTest(int count) {
    final shuffled = List<Flashcard>.from(getUnmasteredCards())
      ..shuffle(Random());
    return shuffled.take(count).toList();
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
