class SessionStats {
  final String userId; // NEW
  final DateTime date;
  final int cardsReviewed;
  final int correctAnswers;
  final int timeSpent;

  SessionStats({
    required this.userId, // NEW
    required this.date,
    required this.cardsReviewed,
    required this.correctAnswers,
    required this.timeSpent,
  });

  double get retentionRate => cardsReviewed > 0 ? (correctAnswers / cardsReviewed) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'userId': userId, // NEW
    'date': date.toIso8601String(),
    'cardsReviewed': cardsReviewed,
    'correctAnswers': correctAnswers,
    'timeSpent': timeSpent,
  };

  factory SessionStats.fromJson(Map<String, dynamic> json) => SessionStats(
    userId: json['userId'], // NEW
    date: DateTime.parse(json['date']),
    cardsReviewed: json['cardsReviewed'],
    correctAnswers: json['correctAnswers'],
    timeSpent: json['timeSpent'],
  );
}