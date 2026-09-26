import 'package:flashcard_app/pages/register_page.dart';
import 'package:flashcard_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flashcard app registration screen smoke test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(onRegisterSuccess: () {}, onNavigateToLogin: () {}),
      ),
    );

    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
    expect(find.text('ĐĂNG KÝ'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('Login screen opens forgot password dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onLoginSuccess: () async {},
          onNavigateToRegister: () {},
        ),
      ),
    );

    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Nhập email đã đăng ký. Firebase sẽ gửi đường dẫn để bạn tạo mật khẩu mới.',
      ),
      findsOneWidget,
    );
    expect(find.text('Gửi email'), findsOneWidget);
  });
}
