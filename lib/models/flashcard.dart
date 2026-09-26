import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Flashcard {
  final String id;
  final String term;
  final String meaning;
  String? note;
  String? imageUrl;
  bool mastered;
  int correctCount;
  final DateTime createdAt;
  DateTime updatedAt;

  Flashcard({
    String? id,
    required this.term,
    required this.meaning,
    this.note,
    this.imageUrl,
    this.mastered = false,
    this.correctCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Flashcard copyWith({
    String? term,
    String? meaning,
    String? note,
    String? imageUrl,
    bool? mastered,
    int? correctCount,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id,
      term: term ?? this.term,
      meaning: meaning ?? this.meaning,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
      mastered: mastered ?? this.mastered,
      correctCount: correctCount ?? this.correctCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'term': term,
      'meaning': meaning,
      'note': note,
      'imageUrl': imageUrl,
      'mastered': mastered,
      'correctCount': correctCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Flashcard.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return Flashcard(
      id: data['id'] as String? ?? documentId,
      term: data['term'] as String? ?? '',
      meaning: data['meaning'] as String? ?? '',
      note: data['note'] as String?,
      imageUrl: data['imageUrl'] as String?,
      mastered: data['mastered'] as bool? ?? false,
      correctCount: (data['correctCount'] as num?)?.toInt() ?? 0,
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  static DateTime _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
