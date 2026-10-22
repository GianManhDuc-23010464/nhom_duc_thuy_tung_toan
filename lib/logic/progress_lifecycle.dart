// logic/progress_lifecycle.dart - VÒNG ĐỜI TIẾN ĐỘ THẺ VÀ LỊCH ÔN NGẮT QUÃNG
//
// Chưa học  --(lật thẻ / trả lời)-->  Đang học  --(đúng 2 lần liên tiếp / ôn đạt)-->  Thành thạo
// Thành thạo --(sai trong Học / Quiz, hoặc chọn Quên khi ôn)--> Đang học
import '../models/card_progress.dart';
import '../utils/date_utils.dart';

enum ReviewGrade { again, hard, good, easy }

const Map<ReviewGrade, String> kGradeLabels = {
  ReviewGrade.again: 'Quên',
  ReviewGrade.hard: 'Khó',
  ReviewGrade.good: 'Được',
  ReviewGrade.easy: 'Dễ',
};

CardStage stageOf(CardProgress? p) {
  if (p == null) return CardStage.notStudied;
  return p.known ? CardStage.mastered : CardStage.learning;
}

CardProgress _fresh(DateTime today) => CardProgress(due: today);

// Lật thẻ lần đầu trong Thẻ ghi nhớ: thẻ vào trạng thái Đang học, đến hạn ôn ngày mai.
// Lật thẻ không được tính là đã nhớ.
CardProgress onFlashcardSeen(CardProgress? p, DateTime today) {
  return p ?? CardProgress(due: addDays(today, 1));
}

// Trả lời một câu trong chế độ Học theo lượt.
// [reachedMastery]: thẻ vừa đạt đúng 2 lần liên tiếp trong phiên.
CardProgress onLearnAnswer(CardProgress? p, {required bool correct, required bool reachedMastery, required DateTime today}) {
  final isNew = p == null;
  final cur = (p ?? _fresh(today)).copy();
  final day = dayOnly(today);
  cur.reps += 1;
  if (!correct) {
    // Sai: điểm thẻ về 0, ôn lại ngay hôm nay
    cur.known = false;
    cur.interval = 0;
    cur.due = day;
    return cur;
  }
  if (reachedMastery) {
    cur.known = true;
    if (cur.interval < 1) cur.interval = 1;
    if (!cur.due.isAfter(day)) cur.due = addDays(day, 1);
  } else if (isNew || !cur.due.isAfter(day)) {
    cur.due = addDays(day, 1);
  }
  return cur;
}

// Câu trả lời sai hoặc bỏ trống trong Quiz: thẻ trở về Đang học và đến hạn ôn hôm nay.
CardProgress onQuizMissed(CardProgress? p, DateTime today) {
  final cur = (p ?? _fresh(today)).copy();
  cur.known = false;
  cur.interval = 0;
  cur.due = dayOnly(today);
  return cur;
}

// Tính lịch ôn mới theo mức đánh giá (SM-2 rút gọn).
CardProgress applyReviewGrade(CardProgress? p, ReviewGrade g, DateTime today) {
  final cur = (p ?? _fresh(today)).copy();
  var interval = cur.interval;
  var ease = cur.ease;
  switch (g) {
    case ReviewGrade.again:
      interval = 0;
      ease = (ease - 0.2).clamp(1.3, double.infinity);
      break;
    case ReviewGrade.hard:
      interval = (interval * 1.2).round();
      if (interval < 1) interval = 1;
      ease = (ease - 0.15).clamp(1.3, double.infinity);
      break;
    case ReviewGrade.good:
      interval = interval == 0 ? 1 : interval < 3 ? 3 : (interval * ease).round();
      break;
    case ReviewGrade.easy:
      interval = interval == 0 ? 3 : (interval * ease * 1.3).round();
      ease += 0.15;
      break;
  }
  return CardProgress(
    interval: interval,
    ease: ease,
    reps: cur.reps + 1,
    due: addDays(today, interval),
    known: g != ReviewGrade.again,
  );
}

// Nhãn khoảng thời gian hiển thị dưới nút đánh giá
String intervalLabel(int days) {
  if (days == 0) return '< 10 phút';
  if (days == 1) return '1 ngày';
  if (days < 30) return '$days ngày';
  return '${(days / 30).round()} tháng';
}
