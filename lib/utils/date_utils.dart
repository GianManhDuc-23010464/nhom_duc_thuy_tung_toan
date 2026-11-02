// utils/date_utils.dart - TIỆN ÍCH NGÀY THÁNG
// Bỏ phần giờ, chỉ giữ ngày
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// Khóa ngày dạng yyyy-MM-dd, dùng trong bản đồ hoạt động học
String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// Đọc khóa ngày; chuỗi không hợp lệ trả về null
DateTime? parseDayKey(String? key) {
  if (key == null) return null;
  final d = DateTime.tryParse(key);
  return d == null ? null : dayOnly(d);
}

// Cộng n ngày, n âm là lùi ngày
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

// Nhãn thứ trong tuần, từ thứ Hai đến Chủ nhật
const List<String> kWeekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

// Định dạng dd/MM/yyyy
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// Định dạng HH:mm
String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

// Hôm nay / Hôm qua / Ngày mai, các ngày khác dạng dd/MM
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

// Thời lượng dạng "m phút s giây"
String formatDurationLong(int seconds) {
  final m = seconds ~/ 60, s = seconds % 60;
  return m > 0 ? '$m phút $s giây' : '$s giây';
}
