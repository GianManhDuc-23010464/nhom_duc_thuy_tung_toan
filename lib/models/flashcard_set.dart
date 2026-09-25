import 'flashcard.dart';

class FlashcardSet {
  final String id;
  final String userId; // NEW: Liên kết với user
  final String title;
  final List<Flashcard> cards;
  final DateTime createdAt; // NEW
  final DateTime updatedAt; // NEW

  FlashcardSet({
    required this.id,
    required this.userId, // NEW
    required this.title,
    required this.cards,
    DateTime? createdAt, // NEW
    DateTime? updatedAt, // NEW
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId, // NEW
    'title': title,
    'cards': cards.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(), // NEW
    'updatedAt': updatedAt.toIso8601String(), // NEW
  };

  factory FlashcardSet.fromJson(Map<String, dynamic> json) => FlashcardSet(
    id: json['id'],
    userId: json['userId'], // NEW
    title: json['title'],
    cards: (json['cards'] as List).map((c) => Flashcard.fromJson(c)).toList(),
    createdAt: DateTime.parse(json['createdAt']), // NEW
    updatedAt: DateTime.parse(json['updatedAt']), // NEW
  );
}