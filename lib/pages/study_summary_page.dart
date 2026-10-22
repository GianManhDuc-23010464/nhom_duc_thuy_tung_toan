// pages/study_summary_page.dart - TỔNG KẾT PHIÊN HỌC THẺ GHI NHỚ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flashcard_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/nav.dart';
import '../widgets/common.dart';
import 'learn_page.dart';
import 'quiz_setup_page.dart';

class StudySummaryPage extends StatelessWidget {
  final String deckId;
  final int total;
  final int seen;
  final int knownCount; // Gạt phải: Đã biết
  final List<String> learningIds; // Gạt trái: Đang học
  final List<String> starredIds;
  final int durationSeconds;

  const StudySummaryPage({
    super.key,
    required this.deckId,
    required this.total,
    required this.seen,
    this.knownCount = 0,
    this.learningIds = const [],
    required this.starredIds,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final deck = context.read<FlashcardService>().deckById(deckId);
    final canQuiz = (deck?.validCards.length ?? 0) >= 2;

    return Scaffold(
      appBar: AppBar(title: const Text("Hoàn thành phiên học")),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Center(
              child: PopIn(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: p.successBg, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 48, color: p.success),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Bạn đã xem hết $total thẻ",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "${deck?.title ?? ''} · ${formatDurationLong(durationSeconds)}",
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ResultTile("Đã biết", "$knownCount", p.success),
                ResultTile("Đang học", "${learningIds.length}", p.warning),
                ResultTile("Gắn sao", "${starredIds.length}", null),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(context, color: p.brandSoft, borderColor: Colors.transparent),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: p.brandText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Muốn biết mình nhớ đến đâu, hãy làm Quiz hoặc Ôn tập. Lật thẻ không được tính là đã nhớ.",
                      style: TextStyle(color: p.text, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (learningIds.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LearnPage(deckId: deckId, cardIds: learningIds),
                  ),
                ),
                icon: const Icon(Icons.replay),
                label: Text("Học lại ${learningIds.length} thẻ đang học"),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: starredIds.isEmpty
                  ? null
                  : () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LearnPage(deckId: deckId, cardIds: starredIds),
                      ),
                    ),
              icon: const Icon(Icons.star),
              label: Text(starredIds.isEmpty ? "Chưa có thẻ gắn sao" : "Học lại ${starredIds.length} thẻ gắn sao"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: deck == null
                  ? null
                  : () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LearnPage(deckId: deckId)),
                    ),
              icon: const Icon(Icons.restart_alt),
              label: const Text("Học lại toàn bộ"),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: canQuiz
                        ? () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => QuizSetupPage(deckId: deckId)),
                          )
                        : null,
                    child: const Text("Làm Quiz"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(onPressed: () => backToDeck(context, deckId), child: const Text("Về bộ thẻ")),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
