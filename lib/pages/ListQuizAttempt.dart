// ignore_for_file: file_names
// pages/ListQuizAttempt.dart - DANH SÁCH CRUD KẾT QUẢ KIỂM TRA
// Thêm mới = chọn bộ thẻ trong bottom sheet để làm bài; xem chi tiết; xóa có xác nhận.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz.dart';
import '../services/flashcard_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/common.dart';
import 'quiz_result_page.dart';
import 'quiz_setup_page.dart';

class ListQuizAttempt extends StatelessWidget {
  const ListQuizAttempt({super.key});

  // Bottom sheet chọn bộ thẻ (đủ 2 thẻ) để làm bài kiểm tra mới
  Future<void> _showNew(BuildContext context) async {
    final service = context.read<FlashcardService>();
    final decks = service.recentDecks.where((d) => d.validCards.length >= 2).toList();
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: decks.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text("Chưa có bộ thẻ nào đủ 2 thẻ để làm bài kiểm tra.", textAlign: TextAlign.center),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text("Làm bài kiểm tra mới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  for (final d in decks)
                    ListTile(
                      leading: const Icon(Icons.quiz),
                      title: Text(d.title),
                      subtitle: Text("${d.validCards.length} thẻ"),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizSetupPage(deckId: d.id)));
                      },
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, QuizAttempt a) async {
    final service = context.read<FlashcardService>();
    final ok = await confirmDialog(
      context,
      title: "Xóa kết quả?",
      content: "Kết quả bài kiểm tra \"${a.deckTitle}\" ngày ${formatDate(a.takenAt)} sẽ bị xóa khỏi lịch sử.",
      confirmLabel: "Xóa",
      danger: true,
    );
    if (!ok) return;
    final done = await service.deleteAttempt(a.id);
    if (!context.mounted) return;
    done ? showSnack(context, "Đã xóa kết quả") : showSaveError(context, () => _delete(context, a));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FlashcardService>();
    final p = context.palette;
    final attempts = service.history.reversed.toList();

    return BaseScaffold(
      title: "Kết quả kiểm tra",
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNew(context),
        tooltip: "Làm bài kiểm tra mới",
        child: const Icon(Icons.add),
      ),
      body: attempts.isEmpty
          ? const EmptyState(icon: Icons.history, title: "Chưa có kết quả nào", message: "Bấm + để làm bài kiểm tra.")
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: attempts.length,
              itemBuilder: (context, i) {
                final a = attempts[i];
                final color = a.percent >= 80
                    ? p.success
                    : a.percent >= 50
                    ? p.warning
                    : p.error;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizResultPage(attemptId: a.id))),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Text(
                              "${a.percent}%",
                              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.deckTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  "${a.correct}/${a.total} câu đúng · ${formatDate(a.takenAt)}${a.pendingSync ? " · chờ đồng bộ" : ""}",
                                  style: TextStyle(fontSize: 13, color: p.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: p.error),
                            tooltip: "Xóa",
                            onPressed: () => _delete(context, a),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
