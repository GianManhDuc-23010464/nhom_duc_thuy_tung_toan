// pages/answer_review_page.dart - XEM LẠI ĐÁP ÁN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/quiz.dart';
import '../services/flashcard_service.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';

class AnswerReviewPage extends StatefulWidget {
  final String attemptId;
  const AnswerReviewPage({super.key, required this.attemptId});

  @override
  State<AnswerReviewPage> createState() => _AnswerReviewPageState();
}

class _AnswerReviewPageState extends State<AnswerReviewPage> {
  String _filter = 'all'; // 'all' | 'wrong' | 'blank'

  @override
  Widget build(BuildContext context) {
    final a = context.read<FlashcardService>().attemptById(widget.attemptId);
    if (a == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Xem lại đáp án")),
        body: const EmptyState(icon: Icons.error_outline, title: "Không tìm thấy bài làm"),
      );
    }

    final items = <(int, QuizAnswerItem)>[
      for (var i = 0; i < a.items.length; i++)
        if (_filter == 'all' || (_filter == 'wrong' && a.items[i].isWrong) || (_filter == 'blank' && a.items[i].isBlank))
          (i, a.items[i]),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Xem lại đáp án"),
            Text(
              "${a.deckTitle} · ${formatRelativeDay(a.takenAt, DateTime.now())} ${formatTime(a.takenAt)}",
              style: TextStyle(fontSize: 12, color: context.palette.textMuted),
            ),
          ],
        ),
      ),
      body: ResponsiveBody(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final f in [('all', "Tất cả (${a.total})"), ('wrong', "Sai (${a.wrong})"), ('blank', "Bỏ trống (${a.blank})")])
                ChoiceChip(
                  label: Text(f.$2),
                  selected: _filter == f.$1,
                  onSelected: (_) => setState(() => _filter = f.$1),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            EmptyState(
              icon: Icons.check_circle,
              title: _filter == 'wrong' ? "Không có câu sai" : "Không có câu bỏ trống",
              message: "Bạn đã làm tốt ở phần này.",
            )
          else
            for (final (i, x) in items) _buildItem(i, x),
          const SizedBox(height: 8),
          Text("Xem lại không làm thay đổi điểm đã lưu.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
        ],
      )),
    );
  }

  Widget _buildItem(int i, QuizAnswerItem x) {
    final q = x.question;
    final (label, color) = x.isCorrect
        ? ("Đúng", context.palette.success)
        : x.isBlank
        ? ("Bỏ trống", context.palette.warning)
        : ("Sai", context.palette.error);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Câu ${i + 1}", style: TextStyle(color: context.palette.textMuted)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(q.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (x.isBlank)
              Text("Bạn chưa chọn đáp án", style: TextStyle(color: context.palette.textMuted))
            else
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Bạn chọn: "),
                TextSpan(
                  text: x.chosenText ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, color: x.isCorrect ? context.palette.success : context.palette.error),
                ),
              ])),
            if (!x.isCorrect)
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Đáp án đúng: "),
                TextSpan(
                  text: q.correctText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ])),
            if ((q.explain ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(q.explain!, style: TextStyle(color: context.palette.textMuted, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
