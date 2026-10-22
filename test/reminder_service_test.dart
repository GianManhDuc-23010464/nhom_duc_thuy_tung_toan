// ReminderService với plugin thông báo giả: lịch lặp hằng ngày đúng giờ, đổi giờ thay lịch cũ, hủy được
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flashcard_app/services/reminder_service.dart';

class FakeNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  final Map<int, ({tz.TZDateTime date, DateTimeComponents? repeat, String? title})> scheduled = {};
  int initCount = 0;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
  }) async {
    initCount++;
    return true;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async =>
      scheduled[id] = (date: scheduledDate, repeat: matchDateTimeComponents, title: title);

  @override
  Future<void> cancel({required int id, String? tag}) async => scheduled.remove(id);

  @override
  T? resolvePlatformSpecificImplementation<T extends FlutterLocalNotificationsPlatform>() => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeNotificationsPlugin plugin;
  late ReminderService reminders;

  setUp(() {
    plugin = FakeNotificationsPlugin();
    reminders = ReminderService(plugin: plugin);
  });

  test('đặt nhắc lặp mỗi ngày đúng giờ, lần đầu trong vòng 24 giờ tới', () async {
    await reminders.scheduleDaily('20:30');
    expect(plugin.scheduled.length, 1);
    final s = plugin.scheduled.values.single;
    expect(s.repeat, DateTimeComponents.time);
    expect([s.date.hour, s.date.minute], [20, 30]);
    final now = tz.TZDateTime.now(tz.local);
    expect(s.date.isAfter(now), isTrue);
    expect(s.date.difference(now).inHours, lessThan(24));
    expect(s.title, 'Đến giờ ôn tập rồi!');
  });

  test('đổi giờ thay lịch cũ; hủy thì không còn lịch; chỉ khởi tạo plugin một lần', () async {
    await reminders.scheduleDaily('20:30');
    await reminders.scheduleDaily('07:05');
    final s = plugin.scheduled.values.single;
    expect([s.date.hour, s.date.minute], [7, 5]);
    await reminders.cancel();
    expect(plugin.scheduled, isEmpty);
    expect(plugin.initCount, 1);
  });
}
