import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_app/main.dart';

void main() {
  testWidgets('FlashcardApp initializes correctly smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashcardApp());
    expect(find.byType(FlashcardApp), findsOneWidget);
  });
}
