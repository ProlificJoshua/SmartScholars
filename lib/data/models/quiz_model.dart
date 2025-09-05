class QuizModel {
  final int? id;
  final int courseId;
  final String title;
  final String? description;
  final String? difficulty;
  final bool isPublished;

  QuizModel({
    this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.difficulty,
    required this.isPublished,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'isPublished': isPublished ? 1 : 0,
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      id: map['id']?.toInt(),
      courseId: map['courseId']?.toInt() ?? 0,
      title: map['title'] ?? '',
      description: map['description'],
      difficulty: map['difficulty'],
      isPublished: map['isPublished'] == 1,
    );
  }
}

class QuestionModel {
  final int? id;
  final int quizId;
  final String type;
  final String prompt;
  final String? options; // JSON string for MCQ options
  final String correctAnswer; // JSON string or plain text
  final int points;

  QuestionModel({
    this.id,
    required this.quizId,
    required this.type,
    required this.prompt,
    this.options,
    required this.correctAnswer,
    required this.points,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'type': type,
      'prompt': prompt,
      'options': options,
      'correctAnswer': correctAnswer,
      'points': points,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id']?.toInt(),
      quizId: map['quizId']?.toInt() ?? 0,
      type: map['type'] ?? '',
      prompt: map['prompt'] ?? '',
      options: map['options'],
      correctAnswer: map['correctAnswer'] ?? '',
      points: map['points']?.toInt() ?? 0,
    );
  }
}

class QuizAttemptModel {
  final int? id;
  final int quizId;
  final int userId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double? score;
  final int attemptNumber;

  QuizAttemptModel({
    this.id,
    required this.quizId,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    this.score,
    required this.attemptNumber,
  });

  bool get isCompleted => completedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'score': score,
      'attemptNumber': attemptNumber,
    };
  }

  factory QuizAttemptModel.fromMap(Map<String, dynamic> map) {
    return QuizAttemptModel(
      id: map['id']?.toInt(),
      quizId: map['quizId']?.toInt() ?? 0,
      userId: map['userId']?.toInt() ?? 0,
      startedAt: DateTime.parse(map['startedAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      score: map['score']?.toDouble(),
      attemptNumber: map['attemptNumber']?.toInt() ?? 1,
    );
  }
}
