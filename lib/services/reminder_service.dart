// services/reminder_service.dart - NHẮC HỌC HẰNG NGÀY BẰNG THÔNG BÁO CỤC BỘ
// Đặt một thông báo lặp mỗi ngày đúng giờ đã chọn (theo múi giờ của máy); hủy khi tắt nhắc hoặc đăng xuất.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static const int _id = 1001; // Chỉ có một lịch nhắc
  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  ReminderService({FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  // Khởi tạo một lần: dữ liệu múi giờ + plugin (chưa xin quyền ở bước này)
  Future<void> _init() => _ready ??= () async {
        tz.initializeTimeZones();
        try {
          tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
        } catch (_) {
          tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
        }
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
        );
      }();

  // Xin quyền thông báo (Android 13+ và iOS). Trả về true nếu được phép.
  Future<bool> requestPermission() async {
    await _init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  // Đặt (hoặc đặt lại) nhắc mỗi ngày lúc "HH:mm"
  Future<void> scheduleDaily(String time) async {
    await _init();
    final parts = time.split(':');
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.cancel(id: _id);
    await _plugin.zonedSchedule(
      id: _id,
      title: 'Đến giờ ôn tập rồi!',
      body: 'Mở Flashcard And Quizz để học tiếp và giữ chuỗi ngày học.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Nhắc học hằng ngày',
          channelDescription: 'Nhắc ôn tập mỗi ngày vào giờ bạn chọn',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Không cần quyền báo thức chính xác; hệ điều hành có thể lệch vài phút để tiết kiệm pin
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Lặp lại cùng giờ mỗi ngày
    );
  }

  Future<void> cancel() async {
    await _init();
    await _plugin.cancel(id: _id);
  }
}
