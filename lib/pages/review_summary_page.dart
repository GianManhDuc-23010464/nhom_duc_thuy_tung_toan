// pages/review_summary_page.dart - KẾT QUẢ ÔN TẬP
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flashcard_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import 'review_page.dart';

class ReviewSummaryPage extends StatelessWidget {
  final int reviewed;
  final int again;
  final int durationSeconds;

  const ReviewSummaryPage({
    super.key,
    required this.reviewed,
    required this.again,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final service = context.read<FlashcardService>();
    final today = service.todayCount;
    final goal = service.dailyGoal;
    final more = service.dueList().length;

    return Scaffold(
      appBar: AppBar(title: const Text("Kết quả ôn tập")),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: p.brandSoft, shape: BoxShape.circle),
                child: Icon(Icons.repeat, size: 48, color: p.brandText),
              ),
            ),
            const SizedBox(height: 12),
            Text("Đã ôn $reviewed thẻ",
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Thời gian ôn ${formatDurationLong(durationSeconds)}",
                textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
            const SizedBox(height: 16),
            Row(
              children: [
                ResultTile("Thẻ đã ôn", "$reviewed", p.brandText),
                ResultTile("Lượt chọn Quên", "$again", again > 0 ? p.error : null),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.all(4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text("Tiến độ hôm nay", style: TextStyle(fontWeight: FontWeight.bold))),
                        Text("${today > goal ? goal : today}/$goal thẻ", style: TextStyle(color: p.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: goal > 0 ? (today / goal).clamp(0, 1).toDouble() : 0,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.all(4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Lịch ôn tiếp theo", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (final d in [1, 2, 3, 7])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatRelativeDay(addDays(service.today, d), service.today),
                                style: TextStyle(color: p.textMuted),
                              ),
                            ),
                            Text("${service.dueOn(addDays(service.today, d))} thẻ"),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (more > 0) ...[
              OutlinedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ReviewPage()),
                ),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                child: Text("Ôn tiếp $more thẻ đến hạn"),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              child: const Text("Về Trang chủ"),
            ),
          ],
        ),
      ),
    );
  }
}
