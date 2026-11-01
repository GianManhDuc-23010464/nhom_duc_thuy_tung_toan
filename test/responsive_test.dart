// Kiểm tra bố cục các màn hình chính ở nhiều kích thước điện thoại / máy tính bảng,
// chế độ sáng và tối: không được có lỗi tràn (RenderFlex overflow) hay ngoại lệ.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flashcard_app/logic/quiz_engine.dart';
import 'package:flashcard_app/main.dart' show TabNavigator, ThemeProvider;
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/models/quiz.dart';
import 'package:flashcard_app/models/user.dart';
import 'package:flashcard_app/pages/home_page.dart';
import 'package:flashcard_app/pages/learn_page.dart';
import 'package:flashcard_app/pages/library_page.dart';
import 'package:flashcard_app/pages/quiz_result_page.dart';
import 'package:flashcard_app/pages/set_detail_page.dart';
import 'package:flashcard_app/pages/stats_page.dart';
import 'package:flashcard_app/pages/test_page.dart';
import 'package:flashcard_app/services/connectivity_service.dart';
import 'package:flashcard_app/services/flashcard_service.dart';
import 'package:flashcard_app/theme/app_theme.dart';
import 'package:flashcard_app/services/data_store.dart';

const sizes = <String, Size>{
  '320': Size(320, 568),
  '375': Size(375, 667),
  '390': Size(390, 844),
  '430': Size(430, 932),
  '768': Size(768, 1024),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = FlashcardService();
  final themeProvider = ThemeProvider(() async {});
  late String deckId;
  late String attemptId;
  late QuizDraft draft;

  setUp(() async {
    service.useStore(LocalDataStore());
    await service.loadForUser(
        User(id: 'r', username: 'Nguyễn Văn Kiểm Thử', email: 'r@x.vn', createdAt: DateTime(2026)));
    final d = (await service.createDeck(title: 'Từ vựng tiếng Anh chuyên ngành Công nghệ thông tin – học kỳ 2', subject: 'Tiếng Anh'))!;
    for (var i = 0; i < 6; i++) {
      await service.addCard(d.id, Flashcard(
        term: 'Thuật ngữ khá dài số $i dùng để kiểm tra xuống dòng',
        meaning: 'Định nghĩa tương đối dài của thuật ngữ số $i',
        note: 'Giải thích thêm $i',
      ));
    }
    await service.finishDeck(d.id);
    deckId = d.id;
    final deck = service.deckById(deckId)!;
    await service.recordFlashcardSeen(deck.cards[0].id);
    final qs = buildQuestions(deck, count: 6);
    final attempt = gradeAttempt(id: 'a1', deck: deck, questions: qs, answers: {0: qs[0].correctIndex}, durationSeconds: 75, takenAt: DateTime.now());
    await service.submitQuiz(attempt);
    attemptId = attempt.id;
    draft = QuizDraft(deckId: deckId, questions: qs, limitSeconds: 180);
  });

  final pages = <String, Widget Function()>{
    'home': () => const HomePage(),
    'library': () => const LibraryPage(),
    'detail': () => SetDetailPage(deckId: deckId),
    'flashcard': () => LearnPage(deckId: deckId),
    'quiz': () => TestPage(draft: draft),
    'result': () => QuizResultPage(attemptId: attemptId),
    'stats': () => const StatsPage(),
  };

  for (final dark in [false, true]) {
    for (final size in sizes.entries) {
      for (final page in pages.entries) {
        testWidgets('${page.key} @ ${size.key}px ${dark ? "tối" : "sáng"}', (tester) async {
          tester.view.physicalSize = size.value * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: service),
              ChangeNotifierProvider.value(value: ConnectivityService()),
              ChangeNotifierProvider(create: (_) => TabNavigator()),
              ChangeNotifierProvider.value(value: themeProvider),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              home: page.value(),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox()); // Hủy đồng hồ của màn Quiz
        });
      }
    }
  }
}
