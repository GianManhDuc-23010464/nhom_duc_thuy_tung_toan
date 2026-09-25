// models/flashcard.dart
class Flashcard {
  final String term;
  final String meaning;
  String? note;
  String? imagePath;
  bool mastered;
  int? correctCount; // THÊM DÒNG NÀY

  Flashcard({
    required this.term,
    required this.meaning,
    this.note,
    this.imagePath,
    this.mastered = false,
    this.correctCount = 0, // THÊM DÒNG NÀY
  });

  // Cập nhật toJson và fromJson để bao gồm correctCount
  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'meaning': meaning,
      'note': note,
      'imagePath': imagePath,
      'mastered': mastered,
      'correctCount': correctCount, // THÊM DÒNG NÀY
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      term: json['term'],
      meaning: json['meaning'],
      note: json['note'],
      imagePath: json['imagePath'],
      mastered: json['mastered'] ?? false,
      correctCount: json['correctCount'] ?? 0, // THÊM DÒNG NÀY
    );
  }
}