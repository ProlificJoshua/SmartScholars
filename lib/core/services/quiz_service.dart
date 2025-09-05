import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/database/database_helper.dart';
import 'course_service.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  // Get quizzes by course
  Future<List<Quiz>> getQuizzesByCourse(int courseId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT q.*, c.title as course_title
        FROM quizzes q
        LEFT JOIN courses c ON q.courseId = c.id
        WHERE q.courseId = ? AND q.isPublished = 1
        ORDER BY q.title ASC
      ''', [courseId]);

      return result.map((data) => Quiz.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting quizzes by course: $e');
      return [];
    }
  }

  // Get all available quizzes for student
  Future<List<Quiz>> getAvailableQuizzes(int studentId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT q.*, c.title as course_title
        FROM quizzes q
        LEFT JOIN courses c ON q.courseId = c.id
        JOIN enrollments e ON q.courseId = e.course_id
        WHERE e.user_id = ? AND q.isPublished = 1
        ORDER BY c.title ASC, q.title ASC
      ''', [studentId]);

      return result.map((data) => Quiz.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting available quizzes: $e');
      return [];
    }
  }

  // Get quiz by ID with questions
  Future<QuizWithQuestions?> getQuizWithQuestions(int quizId) async {
    try {
      final db = await DatabaseHelper().database;
      
      // Get quiz details
      final quizResult = await db.rawQuery('''
        SELECT q.*, c.title as course_title
        FROM quizzes q
        LEFT JOIN courses c ON q.courseId = c.id
        WHERE q.id = ?
      ''', [quizId]);

      if (quizResult.isEmpty) return null;

      final quiz = Quiz.fromMap(quizResult.first);

      // Get questions
      final questionsResult = await db.query(
        'questions',
        where: 'quizId = ?',
        whereArgs: [quizId],
        orderBy: 'id ASC',
      );

      final questions = questionsResult.map((data) => QuizQuestion.fromMap(data)).toList();

      return QuizWithQuestions(quiz: quiz, questions: questions);
    } catch (e) {
      debugPrint('Error getting quiz with questions: $e');
      return null;
    }
  }

  // Submit quiz attempt
  Future<QuizResult> submitQuizAttempt({
    required int quizId,
    required int userId,
    required Map<int, String> answers,
    required int timeTaken,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      
      // Get quiz with questions
      final quizWithQuestions = await getQuizWithQuestions(quizId);
      if (quizWithQuestions == null) {
        throw Exception('Quiz not found');
      }

      // Calculate score
      int correctAnswers = 0;
      final questionResults = <QuestionResult>[];

      for (final question in quizWithQuestions.questions) {
        final userAnswer = answers[question.id] ?? '';
        final isCorrect = userAnswer.toLowerCase().trim() == 
                         question.correctAnswer.toLowerCase().trim();
        
        if (isCorrect) correctAnswers++;

        questionResults.add(QuestionResult(
          questionId: question.id,
          question: question.question,
          userAnswer: userAnswer,
          correctAnswer: question.correctAnswer,
          isCorrect: isCorrect,
          points: isCorrect ? question.points : 0,
        ));
      }

      final totalQuestions = quizWithQuestions.questions.length;
      final score = totalQuestions > 0 ? (correctAnswers * 100 / totalQuestions).round() : 0;
      final totalPoints = questionResults.fold(0, (sum, result) => sum + result.points);

      // Save attempt to database
      final attemptId = await db.insert('quiz_attempts', {
        'quiz_id': quizId,
        'user_id': userId,
        'score': score,
        'total_questions': totalQuestions,
        'completed_at': DateTime.now().millisecondsSinceEpoch,
        'time_taken': timeTaken,
        'answers': jsonEncode(answers),
      });

      return QuizResult(
        attemptId: attemptId,
        quizId: quizId,
        userId: userId,
        score: score,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        totalPoints: totalPoints,
        timeTaken: timeTaken,
        completedAt: DateTime.now(),
        questionResults: questionResults,
      );
    } catch (e) {
      debugPrint('Error submitting quiz attempt: $e');
      rethrow;
    }
  }

  // Get quiz attempts for user
  Future<List<QuizAttempt>> getUserQuizAttempts(int userId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT qa.*, q.title as quiz_title, c.title as course_title
        FROM quiz_attempts qa
        LEFT JOIN quizzes q ON qa.quiz_id = q.id
        LEFT JOIN courses c ON q.courseId = c.id
        WHERE qa.user_id = ?
        ORDER BY qa.completed_at DESC
      ''', [userId]);

      return result.map((data) => QuizAttempt.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting user quiz attempts: $e');
      return [];
    }
  }

  // Get quiz statistics for teacher
  Future<QuizStatistics> getQuizStatistics(int quizId) async {
    try {
      final db = await DatabaseHelper().database;
      
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_attempts,
          AVG(score) as average_score,
          MAX(score) as highest_score,
          MIN(score) as lowest_score,
          COUNT(DISTINCT user_id) as unique_students
        FROM quiz_attempts
        WHERE quiz_id = ?
      ''', [quizId]);

      final data = result.first;
      
      return QuizStatistics(
        quizId: quizId,
        totalAttempts: data['total_attempts'] as int,
        averageScore: (data['average_score'] as double?) ?? 0.0,
        highestScore: data['highest_score'] as int? ?? 0,
        lowestScore: data['lowest_score'] as int? ?? 0,
        uniqueStudents: data['unique_students'] as int,
      );
    } catch (e) {
      debugPrint('Error getting quiz statistics: $e');
      return QuizStatistics(
        quizId: quizId,
        totalAttempts: 0,
        averageScore: 0.0,
        highestScore: 0,
        lowestScore: 0,
        uniqueStudents: 0,
      );
    }
  }

  // Download quiz for offline use
  Future<bool> downloadQuizForOffline(int quizId, int userId) async {
    try {
      final quizWithQuestions = await getQuizWithQuestions(quizId);
      if (quizWithQuestions == null) return false;

      final db = await DatabaseHelper().database;
      
      // Save offline quiz
      await db.insert('offline_quizzes', {
        'quiz_id': quizId,
        'user_id': userId,
        'quiz_data': jsonEncode(quizWithQuestions.toMap()),
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      debugPrint('Error downloading quiz for offline: $e');
      return false;
    }
  }

  // Get offline quizzes
  Future<List<QuizWithQuestions>> getOfflineQuizzes(int userId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'offline_quizzes',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'downloaded_at DESC',
      );

      return result.map((data) {
        final quizData = jsonDecode(data['quiz_data'] as String);
        return QuizWithQuestions.fromMap(quizData);
      }).toList();
    } catch (e) {
      debugPrint('Error getting offline quizzes: $e');
      return [];
    }
  }
}

class Quiz {
  final int id;
  final int courseId;
  final String title;
  final String description;
  final String difficulty;
  final bool isPublished;
  final String? courseTitle;

  Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.isPublished,
    this.courseTitle,
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      courseId: map['courseId'],
      title: map['title'],
      description: map['description'] ?? '',
      difficulty: map['difficulty'] ?? 'Easy',
      isPublished: (map['isPublished'] ?? 1) == 1,
      courseTitle: map['course_title'],
    );
  }

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
}

class QuizQuestion {
  final int id;
  final int quizId;
  final String question;
  final String type;
  final List<String> options;
  final String correctAnswer;
  final int points;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.points,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'],
      quizId: map['quizId'],
      question: map['question'],
      type: map['type'] ?? 'multiple_choice',
      options: (map['options'] as String).split('|'),
      correctAnswer: map['correctAnswer'],
      points: map['points'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'question': question,
      'type': type,
      'options': options.join('|'),
      'correctAnswer': correctAnswer,
      'points': points,
    };
  }
}

class QuizWithQuestions {
  final Quiz quiz;
  final List<QuizQuestion> questions;

  QuizWithQuestions({
    required this.quiz,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'quiz': quiz.toMap(),
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  factory QuizWithQuestions.fromMap(Map<String, dynamic> map) {
    return QuizWithQuestions(
      quiz: Quiz.fromMap(map['quiz']),
      questions: (map['questions'] as List)
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
    );
  }
}

class QuizResult {
  final int attemptId;
  final int quizId;
  final int userId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int totalPoints;
  final int timeTaken;
  final DateTime completedAt;
  final List<QuestionResult> questionResults;

  QuizResult({
    required this.attemptId,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalPoints,
    required this.timeTaken,
    required this.completedAt,
    required this.questionResults,
  });

  String get scorePercentage => '$score%';
  String get grade {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }
}

class QuestionResult {
  final int questionId;
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int points;

  QuestionResult({
    required this.questionId,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.points,
  });
}

class QuizAttempt {
  final int id;
  final int quizId;
  final int userId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final int timeTaken;
  final String? quizTitle;
  final String? courseTitle;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.timeTaken,
    this.quizTitle,
    this.courseTitle,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: map['id'],
      quizId: map['quiz_id'],
      userId: map['user_id'],
      score: map['score'],
      totalQuestions: map['total_questions'],
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completed_at']),
      timeTaken: map['time_taken'],
      quizTitle: map['quiz_title'],
      courseTitle: map['course_title'],
    );
  }
}

class QuizStatistics {
  final int quizId;
  final int totalAttempts;
  final double averageScore;
  final int highestScore;
  final int lowestScore;
  final int uniqueStudents;

  QuizStatistics({
    required this.quizId,
    required this.totalAttempts,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.uniqueStudents,
  });
}
