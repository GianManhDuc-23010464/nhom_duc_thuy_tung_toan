// pages/stats_page.dart
import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final FlashcardService _service = FlashcardService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadStats();

    // Bắt đầu lắng nghe sau khi trang được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    // Dừng lắng nghe khi trang bị hủy
    if (_isListening) {
      _service.removeListener(_onServiceUpdated);
    }
    super.dispose();
  }

  void _startListening() {
    if (!_isListening) {
      _service.addListener(_onServiceUpdated);
      _isListening = true;
      debugPrint('🎧 StatsPage: Bắt đầu lắng nghe thay đổi');
    }
  }

  void _onServiceUpdated() {
    debugPrint('🔄 StatsPage: Nhận thông báo cập nhật - làm mới dữ liệu');
    if (mounted) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Luôn force refresh để có data mới nhất
      final data = await _service.getStats(forceRefresh: true);

      if (mounted) {
        setState(() {
          _stats = data;
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      debugPrint('❌ Lỗi tải thống kê: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải dữ liệu thống kê';
        });
      }
    }
  }

  // Hàm force reload
  Future<void> _forceReload() async {
    await _loadStats();
  }

  // Hàm lấy giá trị an toàn từ stats
  dynamic _getStat(String key, {dynamic defaultValue = 0}) {
    return _stats[key] ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống kê học tập"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceReload,
            tooltip: "Làm mới",
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _forceReload,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Lấy dữ liệu an toàn
    final totalSets = _getStat('totalSets');
    final totalCards = _getStat('totalCards');
    final todayStudied = _getStat('todayStudied');
    final dailyGoal = _getStat('dailyGoal');
    final progress = _getStat('progress');
    final streak = _getStat('streak');
    final rememberRate = _getStat('rememberRate');

    return RefreshIndicator(
      onRefresh: _forceReload,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOverviewCards(totalSets, totalCards, todayStudied, dailyGoal, progress, streak),
            const SizedBox(height: 24),
            _buildProgressChart(todayStudied, dailyGoal),
            const SizedBox(height: 24),
            _buildStudyStats(rememberRate, streak, totalSets),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(int totalSets, int totalCards, int todayStudied, int dailyGoal, String progress, int streak) {
    return Column(
      children: [
        // Hàng 1: Tổng quan
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Tổng bộ",
                value: "$totalSets",
                icon: Icons.folder,
                color: Colors.blue,
                subtitle: "bộ",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Tổng thẻ",
                value: "$totalCards",
                icon: Icons.credit_card,
                color: Colors.purple,
                subtitle: "thẻ",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Hàng 2: Tiến độ và streak
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Học hôm nay",
                value: "$todayStudied",
                icon: Icons.today,
                color: Colors.green,
                subtitle: "/$dailyGoal thẻ",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Streak",
                value: "$streak",
                icon: Icons.local_fire_department,
                color: Colors.red,
                subtitle: "ngày liên tiếp",
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📊 Tiến độ hôm nay",
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
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            if (dailyGoal > 0) ...[
              // Biểu đồ Pie Chart
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: studiedPercent.toDouble(),
                        color: Colors.green,
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
                        color: Colors.grey.shade300,
                        title: remainingPercent > 10 ? '${remainingPercent.round()}%' : '',
                        radius: 50,
                        titleStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),

              // Thanh progress bar
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: studiedPercent / 100,
                backgroundColor: Colors.grey.shade300,
                color: Colors.green,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Đã học: $todayStudied thẻ",
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                  Text(
                    "Còn lại: ${dailyGoal - todayStudied} thẻ",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ] else ...[
              const Center(
                child: Text(
                  "Chưa có mục tiêu học tập",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudyStats(int rememberRate, int streak, int totalSets) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📈 Thống kê học tập",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildStatRow("Số bộ thẻ", "$totalSets bộ", Icons.folder),
            const Divider(),
            _buildStatRow("Tỷ lệ ghi nhớ", "$rememberRate%", Icons.trending_up),
            const Divider(),
            _buildStatRow("Chuỗi ngày học", "$streak ngày", Icons.local_fire_department),
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
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
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}