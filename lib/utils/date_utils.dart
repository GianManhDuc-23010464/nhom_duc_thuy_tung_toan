// utils/date_utils.dart - TIỆN ÍCH NGÀY THÁNG
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseDayKey(String? key) {
  if (key == null) return null;
  final d = DateTime.tryParse(key);
  return d == null ? null : dayOnly(d);
}

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

const List<String> kWeekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String formatRelativeDay(DateTime d, DateTime today) {
  final diff = dayOnly(d).difference(dayOnly(today)).inDays;
  if (diff == 0) return 'Hôm nay';
  if (diff == -1) return 'Hôm qua';
  if (diff == 1) return 'Ngày mai';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

// 0:00 dạng m:ss
String formatDuration(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

String formatDurationLong(int seconds) {
  final m = seconds ~/ 60, s = seconds % 60;
  return m > 0 ? '$m phút $s giây' : '$s giây';
}
