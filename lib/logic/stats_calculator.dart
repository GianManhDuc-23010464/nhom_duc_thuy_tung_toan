// logic/stats_calculator.dart - THỐNG KÊ TÍNH TỪ THAO TÁC THỰC TẾ
import '../models/user_data.dart';
import '../utils/date_utils.dart';

class ChartBar {
  final String label;
  final int value;
  final bool isCurrent;
  const ChartBar(this.label, this.value, this.isCurrent);
}

class StatsSnapshot {
  final int totalCardViews; // Tổng lượt học thẻ
  final int todayCount;
  final int dailyGoal;
  final int streak;
  final int sessions;
  final int quizCount;
  final int? averageScore; // % trung bình các bài quiz
  final int trackedCards; // Số thẻ đã có tiến độ
  final int knownCards; // Số thẻ ở trạng thái Thành thạo
  final List<ChartBar> last7Days;
  final List<ChartBar> last4Weeks;

  const StatsSnapshot({
    required this.totalCardViews,
    required this.todayCount,
    required this.dailyGoal,
    required this.streak,
    required this.sessions,
    required this.quizCount,
    required this.averageScore,
    required this.trackedCards,
    required this.knownCards,
    required this.last7Days,
    required this.last4Weeks,
  });

  int? get retentionRate => trackedCards == 0 ? null : (knownCards / trackedCards * 100).round();
  bool get hasData => totalCardViews > 0 || quizCount > 0;
}

int countOn(UserData d, DateTime day) => d.activity[dayKey(day)] ?? 0;

// Chuỗi ngày học liên tiếp tính đến hôm nay
int computeStreak(UserData d, DateTime today) {
  var streak = 0;
  for (var i = 0; i < 3650; i++) {
    final day = addDays(today, -i);
    final key = dayKey(day);
    if ((d.activity[key] ?? 0) > 0) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

StatsSnapshot computeStats(UserData d, DateTime now) {
  final today = dayOnly(now);
  final total = d.activity.values.fold(0, (s, v) => s + v);
  final history = d.quizHistory;
  final avg = history.isEmpty
      ? null
      : (history.fold<double>(0, (s, a) => s + a.ratio) / history.length * 100).round();

  final days = List.generate(7, (i) {
    final day = addDays(today, i - 6);
    return ChartBar(i == 6 ? 'Nay' : kWeekdays[day.weekday - 1], countOn(d, day), i == 6);
  });

  final weeks = List.generate(4, (i) {
    final w = 3 - i; // 3 tuần trước ... tuần này
    var v = 0;
    for (var x = 0; x < 7; x++) {
      v += countOn(d, addDays(today, -w * 7 - x));
    }
    return ChartBar(w == 0 ? 'Tuần này' : '$w tuần trước', v, w == 0);
  });

  return StatsSnapshot(
    totalCardViews: total,
    todayCount: countOn(d, today),
    dailyGoal: d.dailyGoal,
    streak: computeStreak(d, today),
    sessions: d.sessions,
    quizCount: history.length,
    averageScore: avg,
    trackedCards: d.progress.length,
    knownCards: d.progress.values.where((p) => p.known).length,
    last7Days: days,
    last4Weeks: weeks,
  );
}
