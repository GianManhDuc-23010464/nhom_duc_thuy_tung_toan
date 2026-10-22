// pages/quiz_history_page.dart - LỊCH SỬ QUIZ
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../main.dart' show TabNavigator;
import '../models/quiz.dart';
import '../services/flashcard_service.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import 'answer_review_page.dart';

class QuizHistoryPage extends StatelessWidget {
  const QuizHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<FlashcardService>().history.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Lịch sử Quiz")),
      body: history.isEmpty
          ? EmptyState(
        icon: Icons.history,
        title: "Chưa có lịch sử làm quiz",
        message: "Làm quiz trong một bộ thẻ, kết quả sẽ được lưu ở đây.",
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (r) => r.isFirst);
              context.read<TabNavigator>().openLibrary(tab: 'mine');
            },
            child: const Text("Chọn bộ thẻ"),
          ),
        ],
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Chọn một lần làm bài để xem lại đáp án.", style: TextStyle(color: context.palette.textMuted)),
          const SizedBox(height: 8),
          for (final a in history) QuizHistoryTile(attempt: a),
        ],
      ),
    );
  }
}

class QuizHistoryTile extends StatelessWidget {
  final QuizAttempt attempt;
  const QuizHistoryTile({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final a = attempt;
    final color = a.ratio >= .8 ? context.palette.success : a.ratio >= .5 ? context.palette.warning : context.palette.error;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text("${a.percent}%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(a.deckTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${formatRelativeDay(a.takenAt, DateTime.now())} ${formatTime(a.takenAt)} · ${a.correct}/${a.total} câu · ${formatDuration(a.durationSeconds)}"
          "${a.pendingSync ? ' · chờ đồng bộ' : ''}",
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnswerReviewPage(attemptId: a.id))),
      ),
    );
  }
}
