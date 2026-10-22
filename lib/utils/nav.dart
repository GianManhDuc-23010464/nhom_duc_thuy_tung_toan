// utils/nav.dart - ĐIỀU HƯỚNG DÙNG CHUNG GIỮA CÁC MÀN HÌNH
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/learn_page.dart';
import '../pages/quiz_setup_page.dart';
import '../pages/review_page.dart';
import '../pages/set_detail_page.dart';
import '../pages/test_page.dart';
import '../services/flashcard_service.dart';
import '../widgets/common.dart';

// Route của Chi tiết bộ thẻ có tên riêng để có thể quay lại đúng màn hình
Route<void> deckRoute(String deckId) => MaterialPageRoute(
      settings: RouteSettings(name: 'deck/$deckId'),
      builder: (_) => SetDetailPage(deckId: deckId),
    );

Future<void> openDeck(BuildContext context, String deckId) => Navigator.push(context, deckRoute(deckId));

// Quay về Chi tiết bộ thẻ: lùi lại nếu đã có trong ngăn xếp, nếu không thì mở mới
void backToDeck(BuildContext context, String deckId) {
  final navigator = Navigator.of(context); // context có thể bị gỡ sau popUntil
  var found = false;
  navigator.popUntil((route) {
    if (route.settings.name == 'deck/$deckId') found = true;
    return found || route.isFirst;
  });
  if (!found) navigator.push(deckRoute(deckId));
}

// Học thẻ ghi nhớ; resume = tiếp tục từ vị trí đã ghi nhớ
Future<void> startFlashcards(BuildContext context, String deckId, {bool resume = true, int? startIndex, List<String>? cardIds}) {
  final service = context.read<FlashcardService>();
  final deck = service.deckById(deckId);
  if (deck == null || deck.validCards.isEmpty) {
    showSnack(context, "Bộ thẻ chưa có thẻ hợp lệ để học.");
    return Future.value();
  }
  final index = startIndex ?? (resume && cardIds == null ? service.positionOf(deckId) : 0);
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => LearnPage(deckId: deckId, cardIds: cardIds, startIndex: index)),
  );
}

Future<void> openQuizSetup(BuildContext context, String deckId) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => QuizSetupPage(deckId: deckId)));

Future<void> resumeQuiz(BuildContext context) {
  final service = context.read<FlashcardService>();
  final draft = service.quizDraft;
  if (draft == null) return Future.value();
  if (service.deckById(draft.deckId) == null) {
    service.clearQuizDraft();
    showSnack(context, "Bộ thẻ của bài quiz này không còn tồn tại.");
    return Future.value();
  }
  return Navigator.push(context, MaterialPageRoute(builder: (_) => TestPage(draft: draft)));
}

Future<void> discardQuizDraft(BuildContext context) async {
  final service = context.read<FlashcardService>();
  final ok = await confirmDialog(
    context,
    title: "Hủy bài quiz đang làm dở?",
    content: "Bản nháp sẽ bị xóa.",
    cancelLabel: "Giữ lại",
    confirmLabel: "Hủy bài",
    danger: true,
  );
  if (!ok) return;
  if (await service.clearQuizDraft()) {
    if (context.mounted) showSnack(context, "Đã hủy bản nháp quiz");
  } else if (context.mounted) {
    showSaveError(context, service.clearQuizDraft);
  }
}

Future<void> startReview(BuildContext context, {String? deckId}) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewPage(deckId: deckId)));
