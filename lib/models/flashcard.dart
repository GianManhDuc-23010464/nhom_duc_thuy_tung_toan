// models/flashcard.dart - NỘI DUNG THẺ (không chứa tiến độ học)
import 'package:uuid/uuid.dart';
import 'base_entity.dart';

class Flashcard implements BaseEntity {
  @override
  final String id; // ID ổn định, không đổi khi sửa nội dung
  String term; // Mặt trước
  String meaning; // Mặt sau
  String? note; // Giải thích, hiện sau khi lật thẻ và khi xem lại quiz
  String? imagePath;
  List<String> wrongOptions; // Phương án sai tự nhập cho quiz

  @override
  final DateTime createdAt;
  @override
  DateTime updatedAt;

  Flashcard({
    String? id,
    required this.term,
    required this.meaning,
    this.note,
    this.imagePath,
    List<String>? wrongOptions,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        wrongOptions = wrongOptions ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  @override
  String get name => term;
  @override
  String get description => meaning;

  // Thẻ hợp lệ khi có đủ mặt trước và mặt sau
  bool get isValid => term.trim().isNotEmpty && meaning.trim().isNotEmpty;

  Flashcard copyWith({String? id}) => Flashcard(
        id: id ?? this.id,
        term: term,
        meaning: meaning,
        note: note,
        imagePath: imagePath,
        wrongOptions: List.of(wrongOptions),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'meaning': meaning,
      'note': note,
      'imagePath': imagePath,
      'wrongOptions': wrongOptions,
    };
  }

  // Firestore: decks/{deckId}/cards/{id}; trường order (thứ tự trong bộ) do DataStore thêm vào
  @override
  Map<String, dynamic> toMap() => toFirestore();

  Map<String, dynamic> toFirestore({int? order}) => {
    'term': term,
    'meaning': meaning,
    'note': note,
    'imagePath': imagePath,
    'wrongOptions': wrongOptions,
    'createdAt': toTimestamp(createdAt),
    'updatedAt': toTimestamp(updatedAt),
    if (order != null) 'order': order,
  };

  factory Flashcard.fromMap(Map<String, dynamic> data, String id) => Flashcard.fromFirestore(data, id);

  factory Flashcard.fromFirestore(Map<String, dynamic> data, String id) => Flashcard(
    id: id,
    term: data['term'] ?? '',
    meaning: data['meaning'] ?? '',
    note: data['note'],
    imagePath: data['imagePath'],
    wrongOptions: (data['wrongOptions'] as List?)?.cast<String>() ?? [],
    createdAt: fromTimestamp(data['createdAt']),
    updatedAt: fromTimestamp(data['updatedAt']),
  );

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      term: json['term'] ?? '',
      meaning: json['meaning'] ?? '',
      note: json['note'],
      imagePath: json['imagePath'],
      wrongOptions: (json['wrongOptions'] as List?)?.cast<String>() ?? [],
    );
  }
}
