// models/card_progress.dart - TIẾN ĐỘ HỌC CỦA MỘT NGƯỜI DÙNG VỚI MỘT THẺ
import '../utils/date_utils.dart';
import 'base_entity.dart';

// Ba trạng thái của thẻ
enum CardStage { notStudied, learning, mastered }

class CardProgress {
  int interval; // Số ngày đến lần ôn tiếp theo
  double ease; // Hệ số dễ (SM-2), tối thiểu 1.3
  int reps; // Số lần đã trả lời / ôn
  DateTime due; // Ngày đến hạn ôn (chỉ phần ngày)
  bool known; // true: Thành thạo, false: Đang học

  CardProgress({
    this.interval = 0,
    this.ease = 2.5,
    this.reps = 0,
    required DateTime due,
    this.known = false,
  }) : due = dayOnly(due);

  CardProgress copy() =>
      CardProgress(interval: interval, ease: ease, reps: reps, due: due, known: known);

  bool isDue(DateTime today) => !due.isAfter(dayOnly(today));

  Map<String, dynamic> toJson() => {
    'interval': interval,
    'ease': ease,
    'reps': reps,
    'due': dayKey(due),
    'known': known,
  };

  // Firestore: users/{uid}/progress/{cardId}
  Map<String, dynamic> toFirestore() => {
    'interval': interval,
    'ease': ease,
    'reps': reps,
    'due': toTimestamp(due),
    'known': known,
  };

  factory CardProgress.fromFirestore(Map<String, dynamic> data) => CardProgress(
    interval: data['interval'] ?? 0,
    ease: (data['ease'] ?? 2.5).toDouble(),
    reps: data['reps'] ?? 0,
    due: fromTimestamp(data['due']) ?? dayOnly(DateTime.now()),
    known: data['known'] ?? false,
  );

  factory CardProgress.fromJson(Map<String, dynamic> json) => CardProgress(
    interval: json['interval'] ?? 0,
    ease: (json['ease'] ?? 2.5).toDouble(),
    reps: json['reps'] ?? 0,
    due: parseDayKey(json['due']) ?? dayOnly(DateTime.now()),
    known: json['known'] ?? false,
  );
}
