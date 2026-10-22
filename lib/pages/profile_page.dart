// pages/profile_page.dart - TRANG CÁ NHÂN VÀ CÀI ĐẶT
import 'package:flutter/material.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../services/flashcard_service.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import '../../main.dart';
import 'edit_profile_page.dart';
import 'forgot_password_page.dart';
import 'quiz_history_page.dart';
import '../services/reminder_service.dart';
import 'ListFlashcardSet.dart';
import 'ListQuizAttempt.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Map<ThemeMode, String> _themeLabels = {
    ThemeMode.system: "Theo hệ thống",
    ThemeMode.light: "Sáng",
    ThemeMode.dark: "Tối",
  };

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FlashcardService>();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final stats = service.stats;

    return BaseScaffold(
      title: "Cá nhân",
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _showLogoutDialog,
          tooltip: "Đăng xuất",
        ),
      ],
      body: ResponsiveBody(child: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // THÔNG TIN CÁ NHÂN
                  _buildProfileCard(service),
                  const SizedBox(height: 20),

                  // MỤC TIÊU VÀ TIẾN ĐỘ
                  _buildGoalCard(service.dailyGoal),
                  _buildProgressCard(stats.todayCount, service.dailyGoal),
                  const SizedBox(height: 20),

                  // CÀI ĐẶT
                  _buildSettingsSection(service, themeProvider),
                  const SizedBox(height: 20),

                  _buildAppVersion(),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildProfileCard(FlashcardService service) {
    final user = service.user;
    final stats = service.stats;
    final name = user?.username ?? "Người dùng";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: context.palette.brand,
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: const TextStyle(fontSize: 44, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? "",
              style: TextStyle(color: context.palette.textMuted, fontSize: 14),
            ),
            if (user != null) ...[
              const SizedBox(height: 4),
              Text(
                "Tham gia: ${formatDate(user.createdAt)}",
                style: TextStyle(color: context.palette.textMuted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text("Chỉnh sửa hồ sơ"),
            ),
            const SizedBox(height: 16),

            // Thống kê nhanh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat("Ngày liên tiếp", "${stats.streak}", Icons.local_fire_department),
                _buildMiniStat("Lượt học thẻ", "${stats.totalCardViews}", Icons.credit_card),
                _buildMiniStat("Bài quiz", "${stats.quizCount}", Icons.quiz),
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
            color: context.palette.brandSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: context.palette.brandText),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: context.palette.textMuted),
        ),
      ],
    );
  }

  Widget _buildGoalCard(int dailyGoal) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag),
        title: const Text("Mục tiêu hàng ngày"),
        subtitle: Text("$dailyGoal thẻ/ngày"),
        trailing: const Icon(Icons.edit),
        onTap: () => _showGoalDialog(dailyGoal),
      ),
    );
  }

  Widget _buildProgressCard(int todayStudied, int dailyGoal) {
    final remaining = dailyGoal - todayStudied > 0 ? dailyGoal - todayStudied : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: context.palette.brandText),
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
              value: dailyGoal > 0 ? (todayStudied / dailyGoal).clamp(0, 1).toDouble() : 0,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(FlashcardService service, ThemeProvider themeProvider) {
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
          Icons.history,
          "Lịch sử Quiz",
          "${service.history.length} lần làm bài",
          null,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizHistoryPage())),
        ),
        _buildSettingItem(
          Icons.folder_copy_outlined,
          "Quản lý bộ thẻ",
          "${service.myDecks.length} bộ thẻ · thêm, sửa, xóa",
          null,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListFlashcardSet())),
        ),
        _buildSettingItem(
          Icons.fact_check_outlined,
          "Quản lý kết quả kiểm tra",
          "Xem, xóa kết quả hoặc làm bài mới",
          null,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListQuizAttempt())),
        ),
        _buildSettingItem(
          Icons.dark_mode,
          "Giao diện",
          _themeLabels[themeProvider.themeMode]!,
          null,
          onTap: () => _showThemeDialog(themeProvider),
        ),
        _buildSettingItem(
          Icons.notifications,
          "Nhắc ôn tập hằng ngày",
          service.remindEnabled ? "Lúc ${service.remindTime} mỗi ngày · chạm để đổi giờ" : "Đang tắt",
          Switch(
            value: service.remindEnabled,
            onChanged: (v) => _setReminder(service, v),
          ),
          onTap: service.remindEnabled ? () => _pickReminderTime(service) : null,
        ),
        _buildSettingItem(
          Icons.lock_reset,
          "Gửi email đặt lại mật khẩu",
          service.user?.email ?? "",
          null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ForgotPasswordPage(initialEmail: service.user?.email ?? '', signedIn: true),
            ),
          ),
        ),
        _buildSettingItem(
          Icons.info,
          "Giới thiệu ứng dụng",
          "Phiên bản, công nghệ sử dụng",
          null,
          onTap: _showAbout,
        ),
        _buildSettingItem(
          Icons.logout,
          "Đăng xuất",
          "Đăng xuất khỏi tài khoản",
          null,
          onTap: _showLogoutDialog,
          color: context.palette.error,
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
        leading: Icon(icon, color: color ?? context.palette.brandText),
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
        style: TextStyle(color: context.palette.textMuted, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Giao diện"),
        content: RadioGroup<ThemeMode>(
          groupValue: themeProvider.themeMode,
          onChanged: (mode) {
            if (mode == null) return;
            themeProvider.setThemeMode(mode);
            Navigator.pop(ctx);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in _themeLabels.entries)
                RadioListTile<ThemeMode>(value: e.key, title: Text(e.value)),
            ],
          ),
        ),
      ),
    );
  }

  // Bật: xin quyền thông báo rồi đặt lịch lặp hằng ngày; tắt: hủy lịch
  Future<void> _setReminder(FlashcardService service, bool enabled) async {
    final reminders = context.read<ReminderService>();
    if (enabled && !await reminders.requestPermission()) {
      if (mounted) showSnack(context, "Chưa có quyền gửi thông báo. Hãy bật thông báo cho ứng dụng trong Cài đặt của máy.");
      return;
    }
    if (!await service.setReminder(enabled: enabled)) {
      if (mounted) showSaveError(context, () => _setReminder(service, enabled));
      return;
    }
    enabled ? await reminders.scheduleDaily(service.remindTime) : await reminders.cancel();
    if (mounted) {
      showSnack(context, enabled ? "Sẽ nhắc ôn tập lúc ${service.remindTime} mỗi ngày" : "Đã tắt nhắc ôn tập");
    }
  }

  Future<void> _pickReminderTime(FlashcardService service) async {
    final parts = service.remindTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked == null) return;
    final time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (!mounted) return;
    final reminders = context.read<ReminderService>();
    if (await service.setReminder(enabled: true, time: time)) {
      await reminders.scheduleDaily(time);
      if (mounted) showSnack(context, "Đã đổi giờ nhắc thành $time");
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: "Flashcard And Quizz",
      applicationVersion: "1.0.0",
      applicationIcon: Icon(Icons.library_books, size: 48, color: context.palette.brandText),
      children: const [
        Text(
          "Ứng dụng học tập bằng Flashcard, Quiz và ôn tập ngắt quãng.\n\n"
              "Công nghệ: Flutter, Provider, Firebase Authentication, Cloud Firestore.",
        ),
      ],
    );
  }

  void _showGoalDialog(int dailyGoal) {
    final TextEditingController controller = TextEditingController(text: dailyGoal.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final int? goal = int.tryParse(controller.text);
              if (goal != null && goal > 0 && goal <= 1000) {
                final ok = await context.read<FlashcardService>().setDailyGoal(goal);
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                if (ok) {
                  showSnack(context, "Đã đặt mục tiêu: $goal thẻ/ngày");
                } else {
                  showSaveError(context, () => context.read<FlashcardService>().setDailyGoal(goal));
                }
              } else {
                showSnack(ctx, "Vui lòng nhập số từ 1 đến 1000");
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // Hàm đăng xuất
  void _showLogoutDialog() async {
    final ok = await confirmDialog(
      context,
      title: "Đăng xuất?",
      content: "Dữ liệu vẫn được lưu cho tài khoản này. Lần sau bạn cần đăng nhập lại.",
      confirmLabel: "Đăng xuất",
      danger: true,
    );
    if (!ok || !mounted) return;
    await Provider.of<ThemeProvider>(context, listen: false).logout();
  }
}
