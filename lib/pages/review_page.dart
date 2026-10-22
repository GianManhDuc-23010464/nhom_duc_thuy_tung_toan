// pages/review_page.dart - ÔN TẬP NGẮT QUÃNG (chỉ hiện thẻ đến hạn)
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../logic/progress_lifecycle.dart';
import '../main.dart' show TabNavigator;
import '../services/flashcard_service.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import '../widgets/flip_card.dart';
import 'review_summary_page.dart';

class ReviewPage extends StatefulWidget {
  final String? deckId; // null: ôn tất cả bộ thẻ
  const ReviewPage({super.key, this.deckId});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  // Nền nút đánh giá (chữ trắng): dùng bản màu sáng để đạt tương phản ở cả hai chế độ
  static final Map<ReviewGrade, Color> _gradeColors = {
    ReviewGrade.again: AppPalette.light.error,
    ReviewGrade.hard: AppPalette.light.warning,
    ReviewGrade.good: AppPalette.light.brand,
    ReviewGrade.easy: AppPalette.light.success,
  };

  late final FlashcardService _service = context.read<FlashcardService>();
  final FlipCardController _flip = FlipCardController();
  late final List<DueItem> _queue = _service.dueList(deckId: widget.deckId);
  final Set<String> _seen = {};
  final DateTime _start = DateTime.now();
  int _index = 0;
  int _again = 0;
  bool _shown = false;
  bool _grading = false;

  Future<void> _grade(ReviewGrade g) async {
    if (_grading) return; // Tránh chấm hai lần cùng một thẻ
    _grading = true;
    final item = _queue[_index];
    final ok = await _service.gradeReview(item.cardId, g, firstTime: _seen.add(item.cardId));
    _grading = false;
    if (!mounted) return;
    if (!ok) {
      _seen.remove(item.cardId);
      showSaveError(context, () => _grade(g));
      return;
    }
    if (g == ReviewGrade.again) {
      _again++;
      _queue.add(item); // Hỏi lại cuối phiên
    }
    if (_index + 1 >= _queue.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _shown = false;
    });
  }

  void _finish() {
    if (_seen.isNotEmpty) _service.completeSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewSummaryPage(
          reviewed: _seen.length,
          again: _again,
          durationSeconds: DateTime.now().difference(_start).inSeconds,
        ),
      ),
    );
  }

  Future<void> _close() async {
    if (_seen.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final stop = await confirmDialog(
      context,
      title: "Dừng ôn tập?",
      content: "Bạn đã ôn ${_seen.length} thẻ. Lịch ôn của các thẻ này đã được cập nhật.",
      cancelLabel: "Ôn tiếp",
      confirmLabel: "Dừng",
    );
    if (stop && mounted) _finish();
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      final tomorrow = _service.dueOn(addDays(_service.today, 1));
      return Scaffold(
        appBar: AppBar(title: const Text("Ôn tập hôm nay")),
        body: EmptyState(
          icon: Icons.check_circle,
          title: "Không có thẻ cần ôn hôm nay",
          message: tomorrow > 0
              ? "Ngày mai có $tomorrow thẻ đến hạn. Bạn có thể học thêm thẻ mới bằng Flashcard."
              : "Học flashcard để thêm thẻ vào lịch ôn tập.",
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (r) => r.isFirst);
                context.read<TabNavigator>().openLibrary(tab: 'mine');
              },
              child: const Text("Chọn bộ thẻ để học"),
            ),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Quay lại")),
          ],
        ),
      );
    }

    final item = _queue[_index];
    final deck = _service.deckById(item.deckId);
    final card = deck?.cards.where((c) => c.id == item.cardId).firstOrNull;
    if (deck == null || card == null) {
      // Thẻ bị xóa trong lúc ôn: bỏ qua
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_index + 1 >= _queue.length) {
          _finish();
        } else {
          setState(() => _index++);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = _service.progressOf(card.id);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
          title: const Text("Ôn tập ngắt quãng"),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text("Còn ${_queue.length - _index}"),
              ),
            ),
          ],
        ),
        body: ResponsiveBody(child: Column(
          children: [
            const OfflineBanner(),
            LinearProgressIndicator(
              value: _index / _queue.length,
              backgroundColor: context.palette.border,
              color: context.palette.brandText,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Flexible(child: Chip(label: Text(deck.title, overflow: TextOverflow.ellipsis))),
                        const Spacer(),
                        Text("Đã ôn ${_seen.length} · Lặp lại $_again",
                            style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FlipCard(
                    key: ValueKey('review_$_index'),
                    controller: _flip,
                    frontText: card.term,
                    backText: card.meaning,
                    imagePath: card.imagePath,
                    explain: card.note,
                    onFlip: (back) => setState(() => _shown = true),
                  ),
                  const SizedBox(height: 20),
                  if (!_shown)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _flip.flip,
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                            child: const Text("Hiện đáp án"),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Tự nhớ lại đáp án trước khi lật. Đánh giá càng thật, lịch ôn càng chính xác.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: context.palette.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text("Bạn nhớ thẻ này ở mức nào? Lần ôn tiếp theo:",
                              style: TextStyle(color: context.palette.textMuted)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final g in ReviewGrade.values)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () => _grade(g),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _gradeColors[g],
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(kGradeLabels[g]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(
                                            intervalLabel(applyReviewGrade(progress, g, _service.today).interval),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }
}
