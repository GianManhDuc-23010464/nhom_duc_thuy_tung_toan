import 'base_entity.dart';
import 'flashcard.dart';

// Môn học dùng cho lọc trong Thư viện: các môn hay thi trắc nghiệm (tiếng Anh, môn đại cương)
const List<String> kSubjects = [
  'Tiếng Anh',
  'Triết học',
  'Kinh tế chính trị',
  'Chủ nghĩa xã hội khoa học',
  'Tư tưởng Hồ Chí Minh',
  'Lịch sử Đảng',
  'Pháp luật đại cương',
  'Tin học đại cương',
  'Toán cao cấp',
  'Khác',
];

// Môn không nằm trong danh sách được đưa về 'Khác'
String normalizeSubject(String? subject) => kSubjects.contains(subject) ? subject! : 'Khác';

class FlashcardSet implements BaseEntity {
  @override
  final String id;
  final String userId; // Chủ sở hữu
  String ownerName;
  String title;
  @override
  String description;
  String subject;
  String visibility; // 'private' | 'public'
  String status; // 'draft' | 'ready'
  List<Flashcard> cards;
  @override
  final DateTime createdAt;
  @override
  DateTime updatedAt;

  FlashcardSet({
    required this.id,
    required this.userId,
    required this.title,
    required this.cards,
    this.ownerName = '',
    this.description = '',
    this.subject = 'Khác',
    this.visibility = 'private',
    this.status = 'ready',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @override
  String get name => title;

  bool get isPublic => visibility == 'public';
  bool get isDraft => status == 'draft';
  List<Flashcard> get validCards => cards.where((c) => c.isValid).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'ownerName': ownerName,
    'title': title,
    'description': description,
    'subject': subject,
    'visibility': visibility,
    'status': status,
    'cards': cards.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // Firestore: decks/{id} chỉ chứa thông tin bộ thẻ; thẻ nằm ở subcollection cards
  @override
  Map<String, dynamic> toMap() => toFirestore();

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'ownerName': ownerName,
    'title': title,
    'description': description,
    'subject': subject,
    'visibility': visibility,
    'status': status,
    'createdAt': toTimestamp(createdAt),
    'updatedAt': toTimestamp(updatedAt),
  };

  factory FlashcardSet.fromMap(Map<String, dynamic> data, String id) => FlashcardSet.fromFirestore(data, id);

  factory FlashcardSet.fromFirestore(Map<String, dynamic> data, String id, {List<Flashcard> cards = const []}) =>
      FlashcardSet(
        id: id,
        userId: data['userId'] ?? '',
        ownerName: data['ownerName'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        subject: normalizeSubject(data['subject']),
        visibility: data['visibility'] ?? 'private',
        status: data['status'] ?? 'ready',
        cards: List.of(cards),
        createdAt: fromTimestamp(data['createdAt']),
        updatedAt: fromTimestamp(data['updatedAt']),
      );

  factory FlashcardSet.fromJson(Map<String, dynamic> json) => FlashcardSet(
    id: json['id'],
    userId: json['userId'] ?? '',
    ownerName: json['ownerName'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    subject: normalizeSubject(json['subject']),
    visibility: json['visibility'] ?? 'private',
    status: json['status'] ?? 'ready',
    cards: (json['cards'] as List).map((c) => Flashcard.fromJson(c)).toList(),
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
  );
}
