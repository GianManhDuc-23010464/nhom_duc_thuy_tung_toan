import '../entities/Genericclass.dart';

/// Lớp Flashcard kế thừa Genericclass<String>
/// Kế thừa các thuộc tính chung:
/// - id: mã định danh thẻ
/// - name: từ vựng/thuật ngữ (term)
/// - description: ý nghĩa/miêu tả (meaning)
/// Kế thừa các phương thức chung: getId(), getName(), getDescription(), setId(), setName(), setDescription()
class Flashcard extends Genericclass<String> {
  String? note;
  String? imagePath;
  bool mastered;
  int? correctCount;

  Flashcard({
    String? id,
    String? name,
    String? description,
    String? term,
    String? meaning,
    this.note,
    this.imagePath,
    this.mastered = false,
    this.correctCount = 0,
  }) : super(
          id: id ?? term ?? name ?? DateTime.now().microsecondsSinceEpoch.toString(),
          name: name ?? term ?? '',
          description: description ?? meaning ?? '',
        );

  // Getter & Setter cho term và meaning để tương thích code cũ
  String get term => name;
  set term(String val) => name = val;

  String get meaning => description;
  set meaning(String val) => description = val;

  // Phương thức riêng cho Flashcard
  String? getNote() => note;
  void setNote(String? newNote) => note = newNote;

  String? getImagePath() => imagePath;
  void setImagePath(String? path) => imagePath = path;

  bool getMastered() => mastered;
  void setMastered(bool val) => mastered = val;

  int getCorrectCount() => correctCount ?? 0;
  void setCorrectCount(int count) => correctCount = count;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'meaning': meaning,
      'name': name,
      'description': description,
      'note': note,
      'imagePath': imagePath,
      'mastered': mastered,
      'correctCount': correctCount,
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      term: json['term'] ?? json['name'] ?? '',
      meaning: json['meaning'] ?? json['description'] ?? '',
      name: json['name'] ?? json['term'] ?? '',
      description: json['description'] ?? json['meaning'] ?? '',
      note: json['note'],
      imagePath: json['imagePath'],
      mastered: json['mastered'] ?? false,
      correctCount: json['correctCount'] ?? 0,
    );
  }
}