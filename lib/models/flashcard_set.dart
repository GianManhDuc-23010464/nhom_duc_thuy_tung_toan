import 'package:cloud_firestore/cloud_firestore.dart';

import 'flashcard.dart';

class FlashcardSet {
  final String id;
  final String userId;
  final String title;
  final List<Flashcard> cards;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardSet({
    required this.id,
    required this.userId,
    required this.title,
    required this.cards,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  FlashcardSet copyWith({
    String? title,
    List<Flashcard>? cards,
    DateTime? updatedAt,
  }) {
    return FlashcardSet(
      id: id,
      userId: userId,
      title: title ?? this.title,
      cards: cards ?? this.cards,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FlashcardSet.fromFirestore(
    String documentId,
    String userId,
    Map<String, dynamic> data,
    List<Flashcard> cards,
  ) {
    return FlashcardSet(
      id: data['id'] as String? ?? documentId,
      userId: data['userId'] as String? ?? userId,
      title: data['title'] as String? ?? '',
      cards: cards,
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  static DateTime _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
