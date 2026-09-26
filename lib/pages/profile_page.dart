// pages/profile_page.dart - TRANG CÁ NHÂN HOÀN CHỈNH VỚI REAL-TIME
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flashcard_service.dart';
import '../services/auth_service.dart';
import '../../main.dart';
import 'package:flutter/foundation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlashcardService service = FlashcardService();
  final AuthService authService = AuthService();
  String userName = "Người dùng";
  int dailyGoal = 20;
  bool darkMode = false;
  Map<String, dynamic> stats = {};
  String userEmail = "";
  String joinDate = "";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();

    // Bắt đầu lắng nghe sau khi trang được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    // Dừng lắng nghe khi trang bị hủy
    if (_isListening) {
      service.removeListener(_onServiceUpdated);
    }
    super.dispose();
  }

  void _startListening() {
    if (!_isListening) {
      service.addListener(_onServiceUpdated);
      _isListening = true;
      debugPrint('🎧 ProfilePage: Bắt đầu lắng nghe thay đổi');
    }
  }

  void _onServiceUpdated() {
    debugPrint('🔄 ProfilePage: Nhận thông báo cập nhật - làm mới dữ liệu');
    if (mounted) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final name = await service.getUserName();
      final goal = await service.getDailyGoal();
      final isDark = await service.isDarkMode();
      final data = await service.getStats(forceRefresh: true);

      // Load thông tin user từ auth
      final currentUser = await authService.getCurrentUser();

      if (mounted) {
        setState(() {
          userName = name;
          dailyGoal = goal;
          darkMode = isDark;
          stats = data;
          userEmail = currentUser?.email ?? "Chưa đăng nhập";
          joinDate = currentUser?.createdAt != null
              ? "${currentUser!.createdAt.day}/${currentUser.createdAt.month}/${currentUser.createdAt.year}"
              : "---";
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Lỗi tải profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = double.tryParse(stats['progress']?.toString() ?? '0') ?? 0;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isLoggedIn = userEmail != "Chưa đăng nhập";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cá nhân"),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _showLogoutDialog,
              tooltip: "Đăng xuất",
            ),
          // THÊM: Nút refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
            tooltip: "Làm mới",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // THÔNG TIN CÁ NHÂN
              _buildProfileCard(isLoggedIn),
              const SizedBox(height: 20),

              // Thông báo nếu chưa đăng nhập
              if (!isLoggedIn) _buildLoginPrompt(),

              // MỤC TIÊU VÀ TIẾN ĐỘ
              _buildGoalCard(),
              _buildProgressCard(progress),
              const SizedBox(height: 20),

              // CÀI ĐẶT
              _buildSettingsSection(themeProvider, isLoggedIn),
              const SizedBox(height: 20),

              _buildAppVersion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isLoggedIn) {
    final streak = stats['streak'] ?? 0;
    final totalSets = stats['totalSets'] ?? 0;
    final totalCards = stats['totalCards'] ?? 0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: isLoggedIn ? Colors.purple : Colors.grey,
              child: Icon(
                isLoggedIn ? Icons.person : Icons.person_outline,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Hiển thị email và ngày tham gia
            if (isLoggedIn) ...[
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "Tham gia: $joinDate",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text("Chưa đăng nhập", style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 16),

            // THÊM: Thống kê nhanh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat("Bộ thẻ", "$totalSets", Icons.folder),
                _buildMiniStat("Thẻ", "$totalCards", Icons.credit_card),
                _buildMiniStat(
                  "Streak",
                  "$streak",
                  Icons.local_fire_department,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // Thông báo đăng nhập
  Widget _buildLoginPrompt() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Đăng nhập để đồng bộ dữ liệu",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Dữ liệu hiện tại chỉ được lưu cục bộ trên thiết bị này",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Điều hướng đến trang đăng nhập
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(Icons.login),
              label: const Text("Đăng nhập ngay"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag, color: Colors.green),
        title: const Text("Mục tiêu hàng ngày"),
        subtitle: Text("$dailyGoal thẻ/ngày"),
        trailing: const Icon(Icons.edit),
        onTap: _showGoalDialog,
      ),
    );
  }

  Widget _buildProgressCard(double progress) {
    final todayStudied = stats['todayStudied'] ?? 0;
    final remaining = dailyGoal - todayStudied > 0
        ? dailyGoal - todayStudied
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Tiến độ hôm nay",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text("$todayStudied / $dailyGoal thẻ"),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.green),
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
                  "Còn lại: $remaining thẻ",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ThemeProvider themeProvider, bool isLoggedIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Cài đặt",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        _buildSettingItem(
          Icons.dark_mode,
          "Chế độ tối",
          "Giao diện tối cho ứng dụng",
          Switch(
            value: darkMode,
            onChanged: (value) => _toggleDarkMode(value, themeProvider),
          ),
        ),
        if (isLoggedIn)
          _buildSettingItem(
            Icons.logout,
            "Đăng xuất",
            "Đăng xuất khỏi tài khoản",
            null,
            onTap: _showLogoutDialog,
            color: Colors.orange,
          ),
      ],
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    Widget? trailing, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.purple),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppVersion() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        "Phiên bản 1.0.0",
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _toggleDarkMode(bool value, ThemeProvider themeProvider) {
    setState(() {
      darkMode = value;
    });

    themeProvider.toggleTheme(value);

    // Thông báo thay đổi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? "Đã bật chế độ tối" : "Đã tắt chế độ tối"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showGoalDialog() {
    final TextEditingController controller = TextEditingController(
      text: dailyGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Mục tiêu hàng ngày"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Số thẻ bạn muốn học mỗi ngày:"),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Số thẻ/ngày",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final int? goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                await service.setDailyGoal(goal);
                if (!dialogContext.mounted) return;
                await _loadProfile(); // Load lại để cập nhật real-time
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Đã đặt mục tiêu: $goal thẻ/ngày")),
                );
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text("Vui lòng nhập số hợp lệ")),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // Hàm đăng xuất
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text(
          "Bạn có chắc muốn đăng xuất? Dữ liệu đã được đồng bộ với Firebase.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              Navigator.pop(dialogContext);
              await authService.logout();
              if (!mounted) return;
              service.clearUserData();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Đã đăng xuất!")));
              themeProvider.logout();
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }
}
