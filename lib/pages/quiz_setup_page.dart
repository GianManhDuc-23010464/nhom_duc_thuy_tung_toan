// pages/quiz_setup_page.dart - THIẾT LẬP BÀI QUIZ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../logic/quiz_engine.dart';
import '../models/flashcard_set.dart';
import '../models/quiz.dart';
import '../services/flashcard_service.dart';
import '../widgets/common.dart';
import 'add_edit_flashcard_page.dart';
import 'test_page.dart';

class QuizSetupPage extends StatefulWidget {
  final String deckId;
  const QuizSetupPage({super.key, required this.deckId});

  @override
  State<QuizSetupPage> createState() => _QuizSetupPageState();
}

class _QuizSetupPageState extends State<QuizSetupPage> {
  static const _answerLabels = {
    AnswerWith.meaning: "Định nghĩa",
    AnswerWith.term: "Thuật ngữ",
    AnswerWith.both: "Định nghĩa và Thuật ngữ",
  };
  late final FlashcardService _service = context.read<FlashcardService>();
  late int _count;
  bool _instantFeedback = false;
  AnswerWith _answerWith = AnswerWith.meaning;
  final Set<String> _types = {QuestionType.multipleChoice};
  bool _starredOnly = false;
  bool _starting = false;

  Set<String> _starredIds(FlashcardSet deck) => deck.validCards.map((c) => c.id).where(_service.isStarred).toSet();

  @override
  void initState() {
    super.initState();
    final n = _service.deckById(widget.deckId)?.validCards.length ?? 0;
    _count = n < 20 ? n : 20;
  }

  Future<void> _start() async {
    if (_starting || _types.isEmpty) return;
    final deck = _service.deckById(widget.deckId)!;
    final existing = _service.quizDraft;
    if (existing != null) {
      final replace = await confirmDialog(
        context,
        title: "Thay bài đang làm dở?",
        content:
            "Bạn có một bài kiểm tra đang làm dở (${existing.answeredCount}/${existing.questions.length} câu). Bắt đầu bài mới sẽ xóa bản nháp đó.",
        confirmLabel: "Bắt đầu bài mới",
        danger: true,
      );
      if (!replace || !mounted) return;
    }
    setState(() => _starting = true);
    final questions = buildQuestions(
      deck,
      count: _count,
      types: _types,
      answerWith: _answerWith,
      onlyCardIds: _starredOnly ? _starredIds(deck) : null,
    );
    final draft = QuizDraft(deckId: deck.id, questions: questions, instantFeedback: _instantFeedback);
    await _service.saveQuizDraft(draft);
    await _service.setLastDeck(deck.id);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TestPage(draft: draft)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final deck = _service.deckById(widget.deckId);
    final n = deck?.validCards.length ?? 0;

    if (deck == null || n < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text("Thiết lập bài kiểm tra")),
        body: EmptyState(
          icon: Icons.quiz,
          title: "Chưa đủ thẻ để kiểm tra",
          message: "Bài kiểm tra cần ít nhất 2 thẻ có đủ mặt trước và mặt sau.",
          actions: [
            if (_service.isOwner(deck))
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditFlashcardPage(deckId: deck!.id)),
                ),
                child: const Text("Thêm thẻ"),
              ),
          ],
        ),
      );
    }

    final starred = _starredIds(deck).length;
    final pool = _starredOnly ? starred : n;
    final counts = <int>{
      ...[5, 10, 15, 20, 30, 40, 50].where((x) => x < pool),
      pool,
    }.toList();
    const labelStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

    Widget typeSwitch(String label, String type) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: labelStyle),
      value: _types.contains(type),
      onChanged: (v) => setState(() => v ? _types.add(type) : _types.remove(type)),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 28),
          tooltip: "Đóng",
          onPressed: () => Navigator.pop(context),
        ),
        shape: const Border(),
        backgroundColor: p.background,
      ),
      backgroundColor: p.background,
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Thiết lập bài kiểm tra",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: p.text, height: 1.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: p.brand, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.description, color: Colors.white, size: 36),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Số câu hỏi
            Row(
              children: [
                const Expanded(child: Text("Số câu hỏi", style: labelStyle)),
                PopupMenuButton<int>(
                  initialValue: _count,
                  onSelected: (v) => setState(() => _count = v),
                  itemBuilder: (_) => [
                    for (final c in counts) PopupMenuItem(value: c, child: Text(c == pool ? "$c (tất cả)" : "$c")),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          "$_count",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.brandText),
                        ),
                        Icon(Icons.arrow_drop_down, color: p.brandText, size: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (starred >= 2)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Chỉ thẻ gắn sao ($starred)", style: labelStyle),
                value: _starredOnly,
                onChanged: (v) => setState(() {
                  _starredOnly = v;
                  final max = v ? starred : n;
                  if (_count > max) _count = max;
                }),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Hiển thị đáp án ngay", style: labelStyle),
              value: _instantFeedback,
              onChanged: (v) => setState(() => _instantFeedback = v),
            ),
            // Trả lời bằng
            PopupMenuButton<AnswerWith>(
              initialValue: _answerWith,
              onSelected: (v) => setState(() => _answerWith = v),
              itemBuilder: (_) => [
                for (final e in _answerLabels.entries) PopupMenuItem(value: e.key, child: Text(e.value)),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Trả lời bằng", style: labelStyle),
                          const SizedBox(height: 4),
                          Text(_answerLabels[_answerWith]!, style: TextStyle(fontSize: 17, color: p.text)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: p.brandText, size: 32),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: p.border),
            const SizedBox(height: 8),
            typeSwitch("Đúng/sai", QuestionType.trueFalse),
            typeSwitch("Nhiều lựa chọn", QuestionType.multipleChoice),
            typeSwitch("Tự luận", QuestionType.written),
            if (_types.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Chọn ít nhất một dạng câu hỏi.", style: TextStyle(color: p.error)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ResponsiveBody(
            child: ElevatedButton(
              onPressed: _starting || _types.isEmpty ? null : _start,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              child: const Text("Bắt đầu làm kiểm tra"),
            ),
          ),
        ),
      ),
    );
  }
}
