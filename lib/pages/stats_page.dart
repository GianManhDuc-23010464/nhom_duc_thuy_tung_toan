// pages/stats_page.dart
import 'package:flutter/material.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../logic/stats_calculator.dart';
import '../main.dart' show TabNavigator;
import '../services/flashcard_service.dart';
import '../widgets/common.dart';
import 'quiz_history_page.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _weekly = false; // Biểu đồ theo ngày / tuần

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FlashcardService>();
    return BaseScaffold(
      title: "Thống kê học tập",
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: ResponsiveBody(child: _buildBody(service))),
        ],
      ),
    );
  }

  Widget _buildBody(FlashcardService service) {
    if (!service.isLoaded) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải thống kê...'),
          ],
        ),
      );
    }

    // Số liệu được tính trực tiếp từ dữ liệu học thật của người dùng
    final stats = service.stats;
    if (!stats.hasData) {
      return EmptyState(
        icon: Icons.bar_chart,
        title: "Chưa có dữ liệu học tập",
        message: "Số liệu được tính từ các phiên học và bài quiz thật của bạn. Hoàn thành một phiên học để xem thống kê.",
        actions: [
          ElevatedButton(
            onPressed: () => context.read<TabNavigator>().openLibrary(tab: 'mine'),
            child: const Text("Bắt đầu học"),
          ),
        ],
      );
    }

    final recent = service.history.reversed.take(3).toList();

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOverviewCards(stats),
            const SizedBox(height: 24),
            _buildProgressChart(stats.todayCount, stats.dailyGoal),
            const SizedBox(height: 24),
            _buildActivityChart(stats),
            const SizedBox(height: 24),
            _buildStudyStats(stats, service.myDecks.length),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text("Quiz gần đây", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (recent.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizHistoryPage())),
                    child: const Text("Xem lịch sử"),
                  ),
              ],
            ),
            if (recent.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("Chưa làm bài quiz nào.", style: TextStyle(color: context.palette.textMuted)),
              )
            else
              for (final a in recent) QuizHistoryTile(attempt: a),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(StatsSnapshot stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Lượt học thẻ",
                value: "${stats.totalCardViews}",
                icon: Icons.credit_card,
                color: context.palette.brandText,
                subtitle: "tổng cộng",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Phiên học",
                value: "${stats.sessions}",
                icon: Icons.school,
                color: context.palette.brandText,
                subtitle: "đã hoàn thành",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Bài quiz",
                value: "${stats.quizCount}",
                icon: Icons.quiz,
                color: context.palette.brandText,
                subtitle: "đã nộp",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Điểm trung bình",
                value: stats.averageScore == null ? "–" : "${stats.averageScore}%",
                icon: Icons.grade,
                color: context.palette.yellow,
                subtitle: "các bài quiz",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressChart(int todayStudied, int dailyGoal) {
    final studiedPercent = dailyGoal > 0 ? (todayStudied / dailyGoal * 100).clamp(0, 100) : 0;
    final remainingPercent = 100 - studiedPercent;
    final remaining = dailyGoal - todayStudied > 0 ? dailyGoal - todayStudied : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tiến độ hôm nay",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$todayStudied/$dailyGoal thẻ đã học",
              style: TextStyle(
                fontSize: 14,
                color: context.palette.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            if (dailyGoal > 0) ...[
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: studiedPercent.toDouble(),
                        color: context.palette.brand,
                        title: studiedPercent > 5 ? '${studiedPercent.round()}%' : '',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: remainingPercent.toDouble(),
                        color: context.palette.border,
                        title: remainingPercent > 10 ? '${remainingPercent.round()}%' : '',
                        radius: 50,
                        titleStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.palette.textMuted,
                        ),
                      ),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: studiedPercent / 100,
                backgroundColor: context.palette.border,
                color: context.palette.brand,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text("Đã học: $todayStudied thẻ", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                  const SizedBox(width: 8),
                  Flexible(child: Text("Còn lại: $remaining thẻ", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.palette.textMuted))),
                ],
              ),
            ] else ...[
              Center(
                child: Text(
                  "Chưa có mục tiêu học tập",
                  style: TextStyle(color: context.palette.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Biểu đồ cột lượt học thẻ theo 7 ngày / 4 tuần gần nhất
  Widget _buildActivityChart(StatsSnapshot stats) {
    final bars = _weekly ? stats.last4Weeks : stats.last7Days;
    final maxV = bars.fold<int>(1, (m, b) => b.value > m ? b.value : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text("Lượt học thẻ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text("Ngày")),
                    ButtonSegment(value: true, label: Text("Tuần")),
                  ],
                  selected: {_weekly},
                  onSelectionChanged: (s) => setState(() => _weekly = s.first),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxV * 1.25,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (v, _) => Text(
                          "${bars[v.toInt()].value}",
                          style: TextStyle(fontSize: 12, color: context.palette.textMuted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(bars[v.toInt()].label, style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
                        ),
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: [
                    for (var i = 0; i < bars.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: bars[i].value.toDouble(),
                            width: _weekly ? 28 : 18,
                            color: bars[i].isCurrent ? context.palette.brand : context.palette.brand.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyStats(StatsSnapshot stats, int totalSets) {
    final retention = stats.retentionRate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Thống kê học tập",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow("Số bộ thẻ của tôi", "$totalSets bộ", Icons.folder),
            const Divider(),
            _buildStatRow("Tỷ lệ ghi nhớ", retention == null ? "–" : "$retention%", Icons.trending_up),
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 4),
              child: Text(
                "${stats.knownCards}/${stats.trackedCards} thẻ đã học đang ở trạng thái thành thạo",
                style: TextStyle(fontSize: 12, color: context.palette.textMuted),
              ),
            ),
            const Divider(),
            _buildStatRow("Chuỗi ngày học", "${stats.streak} ngày", Icons.local_fire_department),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.palette.brandSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.palette.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: context.palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.palette.brandText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.palette.brandText,
            ),
          ),
        ],
      ),
    );
  }
}
