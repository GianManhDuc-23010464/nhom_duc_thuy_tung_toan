import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flashcard_app/logic/quiz_engine.dart';
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/models/quiz.dart';
import 'package:flashcard_app/models/user.dart';
import 'package:flashcard_app/pages/learn_page.dart';
import 'package:flashcard_app/pages/login_page.dart';
import 'package:flashcard_app/pages/set_detail_page.dart';
import 'package:flashcard_app/pages/test_page.dart';
import 'package:flashcard_app/services/connectivity_service.dart';
import 'package:flashcard_app/services/flashcard_service.dart';
import 'package:flashcard_app/services/data_store.dart';

Widget host(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: FlashcardService()),
        ChangeNotifierProvider.value(value: ConnectivityService()),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  final service = FlashcardService();
  final user = User(id: 'w', username: 'Widget', email: 'w@x.vn', createdAt: DateTime(2026));

  late String detailDeckId, quizDeckId;

  // Chuẩn bị dữ liệu ngoài FakeAsync của testWidgets
  setUp(() async {
    service.useStore(LocalDataStore());
    await service.loadForUser(user);
    final d = (await service.createDeck(title: 'Bộ test'))!;
    for (var i = 0; i < 3; i++) {
      await service.addCard(d.id, Flashcard(term: 'T$i', meaning: 'M$i'));
    }
    await service.finishDeck(d.id);
    detailDeckId = d.id;
    final q = (await service.createDeck(title: 'Quiz'))!;
    for (var i = 0; i < 4; i++) {
      await service.addCard(q.id, Flashcard(term: 'Q$i', meaning: 'A$i'));
    }
    quizDeckId = q.id;
  });

  testWidgets('Đăng nhập: kiểm tra biểu mẫu và có Quên mật khẩu', (tester) async {
    await tester.pumpWidget(host(LoginPage(onLoginSuccess: () {}, onNavigateToRegister: () {})));
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pump();
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'sai-dinh-dang');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pump();
    expect(find.text('Email chưa đúng định dạng, ví dụ ban@email.com'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
  });

  testWidgets('Chi tiết bộ thẻ: các chế độ học và 3 trạng thái tiến độ', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556); // Điện thoại 393×852
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(SetDetailPage(deckId: detailDeckId)));
    await tester.pump();
    expect(find.text('Học ngay'), findsOneWidget); // Thẻ ghi nhớ: nút chính ở đáy
    expect(find.text('Kiểm tra'), findsWidgets);
    expect(find.text('Thẻ ghi nhớ'), findsOneWidget);
    expect(find.text('Học'), findsOneWidget);
    expect(find.text('Chưa học'), findsOneWidget);
    expect(find.text('Đang học'), findsOneWidget);
    expect(find.text('Thành thạo'), findsOneWidget);
  });

  testWidgets('Thẻ ghi nhớ: gạt phải tính Đã biết, hoàn tác bỏ phân loại', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(LearnPage(deckId: detailDeckId)));
    await tester.pump();
    expect(find.text('1 / ${service.deckById(detailDeckId)!.validCards.length}'), findsOneWidget);
    // Kéo ngắn rồi thả: thẻ bật về, vẫn ở thẻ 1
    await tester.drag(find.byType(SwipeCard), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / ${service.deckById(detailDeckId)!.validCards.length}'), findsOneWidget);
    await tester.fling(find.byType(SwipeCard), const Offset(500, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('2 / ${service.deckById(detailDeckId)!.validCards.length}'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // Ô Đã biết
    expect(service.flashSortOf(detailDeckId).values, [true]); // Đã lưu để học tiếp
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();
    expect(find.text('1 / ${service.deckById(detailDeckId)!.validCards.length}'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('Quiz: chọn đáp án không hiện đúng/sai trước khi nộp', (tester) async {
    final draft = QuizDraft(deckId: quizDeckId, questions: buildQuestions(service.deckById(quizDeckId)!, count: 4));
    await tester.pumpWidget(host(TestPage(draft: draft)));
    await tester.tap(find.text(draft.questions[0].options[(draft.questions[0].correctIndex + 1) % 4]));
    await tester.pump();
    expect(draft.answers[0], isNotNull);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.cancel), findsNothing);
    expect(find.textContaining('Chính xác'), findsNothing);
    // Chọn xong tự trượt sang câu 2
    await tester.pump(const Duration(milliseconds: 1300)); // Chờ hết thời gian xem đáp án
    await tester.pumpAndSettle();
    expect(draft.currentIndex, 1);
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // Hủy đồng hồ
  });

  testWidgets('Kiểm tra: hiện đáp án ngay thì tô đúng/sai và khóa câu đã trả lời', (tester) async {
    final qs = buildQuestions(service.deckById(quizDeckId)!, count: 4);
    final draft = QuizDraft(deckId: quizDeckId, questions: qs, instantFeedback: true);
    await tester.pumpWidget(host(TestPage(draft: draft)));
    final wrong = (qs[0].correctIndex + 1) % qs[0].options.length;
    await tester.tap(find.text(qs[0].options[wrong]));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300)); // Chờ hết thời gian xem đáp án
    await tester.pumpAndSettle();
    expect(draft.currentIndex, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
