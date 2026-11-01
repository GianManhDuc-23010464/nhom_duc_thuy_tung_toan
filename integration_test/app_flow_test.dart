// Kiểm thử toàn bộ luồng trên thiết bị / simulator thật:
// flutter test integration_test/app_flow_test.dart -d <device>
// In "SCREEN:<tên>" và dừng 2 giây ở mỗi màn hình để có thể chụp ảnh.
// Dùng Firebase giả (firebase_auth_mocks, fake_cloud_firestore): không gọi Firebase thật.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flashcard_app/pages/learn_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flashcard_app/main.dart' as app;
import 'package:flashcard_app/services/auth_service.dart';
import 'package:flashcard_app/services/connectivity_service.dart';
import 'package:flashcard_app/services/data_store.dart';
import 'package:flashcard_app/services/flashcard_service.dart';
import 'package:flashcard_app/services/seed_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester t, [int ms = 600]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> screen(WidgetTester t, String name) async {
    await settle(t, 800);
    // ignore: avoid_print
    print('SCREEN:$name');
    await settle(t, 2000);
  }

  Future<void> tapText(WidgetTester t, String text, {bool last = false}) async {
    final f = find.text(text);
    await t.ensureVisible(last ? f.last : f.first);
    await settle(t, 300);
    await t.tap(last ? f.last : f.first);
    await settle(t);
  }

  testWidgets('Các luồng học tập Flashcard And Quizz', (t) async {
    // Firestore giả có sẵn các bộ thẻ công khai mẫu cho tab Khám phá
    final db = FakeFirebaseFirestore();
    await seedCommunityDecks(db);
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'integration-user',
        email: 'integration@flashcardquizz.vn',
        displayName: 'Kiểm Thử',
      ),
    );
    await t.pumpWidget(app.FlashcardApp(
      authService: AuthService(auth: auth, db: db),
      dataStore: FirestoreDataStore(db),
      connectivity: ConnectivityService(),
    ));
    // Test các luồng học tập bằng một phiên Firebase giả đã đăng nhập sẵn.
    for (var i = 0; i < 100 && find.text('Bắt đầu với bộ thẻ đầu tiên').evaluate().isEmpty; i++) {
      await settle(t, 200);
    }
    expect(find.text('Bắt đầu với bộ thẻ đầu tiên'), findsOneWidget);
    await screen(t, '01_home_new_user');

    // ===== Luồng 3: Thư viện › Khám phá, lưu bộ thẻ =====
    await tapText(t, 'Khám phá thư viện công khai');
    await settle(t, 1000);
    await screen(t, '03_library_explore');
    await t.tap(find.byIcon(Icons.bookmark_border).first);
    await settle(t);

    // ===== Luồng 5: Chi tiết bộ thẻ =====
    await tapText(t, 'Lập trình Dart cơ bản');
    await settle(t, 1000);
    await screen(t, '05_deck_detail_top');
    await t.drag(find.byType(ListView).first, const Offset(0, -500));
    await screen(t, '05_deck_detail_modes');

    // ===== Luồng 6: Thẻ ghi nhớ =====
    await tapText(t, 'Học ngay');
    await settle(t, 800);
    await t.tap(find.text('Từ khóa nào khai báo hằng số xác định lúc biên dịch?'));
    await settle(t, 1000);
    await screen(t, '06_flashcard_flipped');
    await t.fling(find.byType(SwipeCard), const Offset(500, 0), 1500); // Gạt phải: Đã biết
    await settle(t);
    await t.tap(find.byIcon(Icons.close));
    await settle(t);

    // ===== Luồng 7: Học theo lượt =====
    await t.drag(find.byType(ListView).first, const Offset(0, 1000)); // Về đầu trang
    await settle(t);
    await tapText(t, 'Học');
    await settle(t, 800);
    await screen(t, '07_learn_question');
    await t.tap(find.text('Bạn không biết?'));
    await settle(t, 800);
    await screen(t, '07_learn_feedback');
    await t.tap(find.byIcon(Icons.close));
    await settle(t);

    // ===== Luồng 8: Kiểm tra =====
    await tapText(t, 'Kiểm tra', last: true);
    await settle(t, 800);
    await screen(t, '08_quiz_setup');
    await tapText(t, 'Bắt đầu làm kiểm tra');
    await settle(t, 1200);
    await t.tap(find.descendant(of: find.byType(ListView), matching: find.byType(InkWell)).first); // Chọn một đáp án
    await settle(t, 800); // Tự trượt sang câu 2
    await screen(t, '08_quiz_playing');
    while (find.text('Nộp bài').evaluate().isEmpty) {
      await t.tap(find.byIcon(Icons.chevron_right)); // Bỏ qua tới màn nộp bài
      await settle(t, 500);
    }
    await screen(t, '08_quiz_end');
    await t.tap(find.text('Nộp bài'));
    await settle(t);
    await tapText(t, 'Vẫn nộp bài');
    await settle(t, 1500);
    await screen(t, '08_quiz_result');
    await t.tap(find.byTooltip('Đóng'));
    await settle(t);
    await t.pageBack();
    await settle(t, 1000);
    // Về Trang chủ
    await t.tap(find.text('Trang chủ'));
    await settle(t, 1000);
    await screen(t, '02_home_dashboard');

    // ===== Luồng 9: Ôn tập =====
    await t.scrollUntilVisible(find.text('Ôn tập ngay'), 200, scrollable: find.byType(Scrollable).first);
    await settle(t);
    await tapText(t, 'Ôn tập ngay');
    await settle(t, 800);
    await tapText(t, 'Hiện đáp án');
    await settle(t, 1000);
    await screen(t, '09_review_grades');
    await tapText(t, 'Được');
    await t.tap(find.byIcon(Icons.close));
    await settle(t);
    await tapText(t, 'Dừng');
    await settle(t, 800);
    await screen(t, '09_review_summary');
    await tapText(t, 'Về Trang chủ');

    // ===== Luồng 4: Tạo học phần =====
    await t.scrollUntilVisible(find.text('Tạo bộ thẻ mới'), 300, scrollable: find.byType(Scrollable).first);
    await tapText(t, 'Tạo bộ thẻ mới');
    await settle(t, 800);
    await t.enterText(find.byType(TextField).first, 'Bộ thẻ kiểm thử');
    await settle(t);
    await screen(t, '04_create_deck');
    await tapText(t, 'Tiếp tục: thêm thẻ');
    await settle(t, 1000);
    await tapText(t, 'Thêm thẻ đầu tiên');
    await settle(t, 800);
    final cardFields = find.byType(TextField);
    await t.enterText(cardFields.at(0), 'apple');
    await t.enterText(cardFields.at(1), 'quả táo');
    await settle(t);
    await screen(t, '04_add_card');
    await tapText(t, 'Lưu', last: true);
    await settle(t, 800);
    await screen(t, '04_deck_cards');
    await tapText(t, 'HOÀN TẤT BỘ THẺ');
    await settle(t, 1000);
    await screen(t, '04_new_deck_detail');
    await t.pageBack();
    await settle(t, 800);

    // ===== Luồng thống kê =====
    await t.tap(find.text('Thống kê'));
    await settle(t, 800);
    await screen(t, 'stats');
    await t.drag(find.byType(SingleChildScrollView).first, const Offset(0, -700));
    await screen(t, 'stats_chart');

  });
}
