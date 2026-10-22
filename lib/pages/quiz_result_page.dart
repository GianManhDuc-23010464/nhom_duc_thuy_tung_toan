// pages/quiz_result_page.dart - KẾT QUẢ BÀI KIỂM TRA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/quiz_engine.dart';
import '../models/quiz.dart';
import '../services/flashcard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'learn_rounds_page.dart';
import 'quiz_setup_page.dart';
import 'test_page.dart';

class QuizResultPage extends StatefulWidget {
  final String attemptId;
  const QuizResultPage({super.key, required this.attemptId});

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  bool _onlyWrong = false; // Lọc danh sách đáp án: chỉ câu sai / bỏ trống

  // Làm lại ngay một bài chỉ gồm các câu sai, giữ các dạng câu hỏi của bài vừa làm
  Future<void> _retakeMissed(QuizAttempt a) async {
    final service = context.read<FlashcardService>();
    final deck = service.deckById(a.deckId);
    if (deck == null) return;
    final missed = a.missedCardIds.toSet();
    final draft = QuizDraft(
      deckId: deck.id,
      questions: buildQuestions(
        deck,
        count: missed.length,
        onlyCardIds: missed,
        types: a.items.map((x) => x.question.type).toSet(),
      ),
    );
    if (!await service.saveQuizDraft(draft) || !mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TestPage(draft: draft)));
  }

  @override
  Widget build(BuildContext context) {
    final attemptId = widget.attemptId;
    final service = context.watch<FlashcardService>();
    final p = context.palette;
    final a = service.attemptById(attemptId);
    if (a == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Kết quả kiểm tra")),
        body: const EmptyState(icon: Icons.error_outline, title: "Không tìm thấy kết quả bài làm"),
      );
    }

    final pct = a.percent;
    final wrong = a.total - a.correct; // Bỏ trống tính là sai
    final headline = pct == 100
        ? "Xuất sắc!"
        : pct >= 80
        ? "Làm tốt lắm!"
        : pct >= 50
        ? "Khá ổn rồi!"
        : "Bạn đang tiến bộ!";
    final deckExists = service.isAvailable(service.deckById(a.deckId));
    const sectionStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 28),
          tooltip: "Đóng",
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${a.total} / ${a.total}",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textMuted),
        ),
        centerTitle: true,
        shape: const Border(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: 1, minHeight: 4, valueColor: AlwaysStoppedAnimation(p.textMuted)),
        ),
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            if (a.pendingSync)
              Card(
                color: p.warningBg,
                child: ListTile(
                  leading: Icon(Icons.wifi_off, color: p.warning),
                  title: Text(
                    "Đã chấm điểm trên máy. Kết quả sẽ được đồng bộ khi có mạng.",
                    style: TextStyle(color: p.text, fontSize: 14),
                  ),
                ),
              ),
            Text(
              headline,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: p.text),
            ),
            const SizedBox(height: 28),
            const Text("Kết quả của bạn", style: sectionStyle),
            const SizedBox(height: 16),
            Row(
              children: [
                // Vòng tròn: phần xanh là câu đúng, phần cam là câu sai
                SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Vòng và số % chạy dần từ 0
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: a.ratio),
                        duration: motion(context, 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: v,
                              strokeWidth: 14,
                              backgroundColor: p.warning,
                              valueColor: AlwaysStoppedAnimation(p.success),
                            ),
                            Center(
                              child: Text(
                                "${(v * 100).round()}%",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    children: [
                      _countRow("Đúng", a.correct, p.success, p.successBg),
                      const SizedBox(height: 16),
                      _countRow("Sai", wrong, p.warning, p.warningBg),
                    ],
                  ),
                ),
              ],
            ),
            if (deckExists) ...[
              const SizedBox(height: 32),
              const Text("Bước tiếp theo", style: sectionStyle),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LearnRoundsPage(deckId: a.deckId)),
                ),
                icon: const Icon(Icons.autorenew),
                label: const Text("Ôn luyện bằng chế độ Học"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => QuizSetupPage(deckId: a.deckId)),
                ),
                icon: Icon(Icons.description, color: p.brandText),
                label: const Text("Làm bài kiểm tra mới"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: const StadiumBorder(),
                  backgroundColor: p.brandSoft,
                  foregroundColor: p.text,
                ),
              ),
              if (wrong > 0)
                TextButton.icon(
                  onPressed: () => _retakeMissed(a),
                  icon: const Icon(Icons.replay),
                  label: Text("Làm lại $wrong câu sai"),
                ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Text("Đáp án của bạn", style: sectionStyle)),
                if (wrong > 0)
                  ChoiceChip(
                    label: Text("Chỉ câu sai ($wrong)"),
                    selected: _onlyWrong,
                    onSelected: (v) => setState(() => _onlyWrong = v),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < a.items.length; i++)
              if (!_onlyWrong || !a.items[i].isCorrect) _AnswerCard(index: i, item: a.items[i]),
          ],
        ),
      ),
    );
  }

  Widget _countRow(String label, int n, Color fg, Color bg) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withValues(alpha: 0.6)),
          ),
          child: Text(
            "$n",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ],
    );
  }
}

// Một câu trong danh sách đáp án: câu hỏi, câu trả lời của bạn, đáp án đúng nếu sai
class _AnswerCard extends StatelessWidget {
  final int index;
  final QuizAnswerItem item;
  const _AnswerCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = item.question;
    final ok = item.isCorrect;

    Widget answerRow(String text, bool good) => Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: good ? p.successBg : p.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: good ? p.success : p.error, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 15, color: p.text)),
          ),
          Icon(good ? Icons.check : Icons.close, color: good ? p.success : p.error),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Câu ${index + 1}",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textMuted),
              ),
              const Spacer(),
              Text(
                ok
                    ? "Đúng"
                    : item.isBlank
                    ? "Bỏ trống"
                    : "Sai",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ok ? p.success : p.warning),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(q.question, style: TextStyle(fontSize: 17, color: p.text, height: 1.35)),
          if (q.isTrueFalse) ...[
            const SizedBox(height: 6),
            Text(q.statement ?? '', style: TextStyle(fontSize: 15, color: p.textMuted)),
          ],
          const SizedBox(height: 4),
          if (!item.isBlank) answerRow(item.chosenText ?? '', ok),
          if (!ok) ...[
            const SizedBox(height: 8),
            Text(
              "Đáp án đúng",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textMuted),
            ),
            answerRow(q.correctText, true),
          ],
          if ((q.explain ?? '').isNotEmpty && !ok) ...[
            const SizedBox(height: 8),
            Text(q.explain!, style: TextStyle(fontSize: 13, color: p.textMuted)),
          ],
        ],
      ),
    );
  }
}
