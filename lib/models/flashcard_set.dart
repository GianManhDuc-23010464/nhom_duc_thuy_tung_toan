import '../entities/Genericclass.dart';
import 'flashcard.dart';

/// Lớp FlashcardSet kế thừa Genericclass<String>
/// Kế thừa các thuộc tính chung: id, name (tên bộ thẻ/tiêu đề), description (mô tả)
/// Kế thừa các phương thức chung: getId(), getName(), getDescription(), setId(), setName(), setDescription()
class FlashcardSet extends Genericclass<String> {
  final String userId; // Liên kết với user
  final List<Flashcard> cards;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardSet({
    required String id,
    String? name,
    String? title,
    String description = '',
    required this.userId,
    required this.cards,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        super(
          id: id,
          name: name ?? title ?? '',
          description: description,
        );

  // Getter và setter cho title để tương thích hoàn toàn với code cũ
  String get title => name;
  set title(String val) => name = val;

  // Các phương thức riêng của FlashcardSet
  List<Flashcard> getCards() => cards;
  int get cardCount => cards.length;
  String getUserId() => userId;
  DateTime getCreatedAt() => createdAt;
  DateTime getUpdatedAt() => updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'name': name,
    'description': description,
    'cards': cards.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FlashcardSet.fromJson(Map<String, dynamic> json) => FlashcardSet(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    title: json['title'] ?? json['name'] ?? '',
    name: json['name'] ?? json['title'] ?? '',
    description: json['description'] ?? '',
    cards: json['cards'] != null
        ? (json['cards'] as List).map((c) => Flashcard.fromJson(c)).toList()
        : [],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now(),
  );
}