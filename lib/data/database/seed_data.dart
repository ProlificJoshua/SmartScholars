import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import 'database_helper.dart';

class SeedData {
  static final SeedData _instance = SeedData._internal();
  factory SeedData() => _instance;
  SeedData._internal();

  Future<void> seedDatabase() async {
    final db = await DatabaseHelper().database;
    
    // Check if data already exists
    final userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    if (userCount != null && userCount > 0) {
      return; // Data already seeded
    }

    await _seedUsers(db);
    await _seedCourses(db);
    await _seedEnrollments(db);
    await _seedModulesAndLessons(db);
    await _seedQuizzes(db);
    await _seedMessages(db);
    await _seedAnnouncements(db);
    await _seedProgress(db);
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _seedUsers(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Admin user
    await db.insert('users', {
      'id': 1,
      'role': AppConstants.roleAdmin,
      'email': 'admin@smartscholars.com',
      'fullName': 'System Administrator',
      'passwordHash': _hashPassword('admin123'),
      'country': 'Cameroon',
      'status': AppConstants.statusActive,
      'createdAt': now,
      'updatedAt': now,
    });

    // Teacher user
    await db.insert('users', {
      'id': 2,
      'role': AppConstants.roleTeacher,
      'email': 'teacher@smartscholars.com',
      'fullName': 'Dr. Sarah Johnson',
      'passwordHash': _hashPassword('teacher123'),
      'country': 'Cameroon',
      'status': AppConstants.statusActive,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('teachers', {
      'userId': 2,
      'school': 'University of Buea',
      'subjects': json.encode(['Mathematics', 'Computer Science']),
    });

    // Student users
    await db.insert('users', {
      'id': 3,
      'role': AppConstants.roleStudent,
      'email': 'student1@smartscholars.com',
      'fullName': 'Prince Excellence',
      'passwordHash': _hashPassword('student123'),
      'country': 'Cameroon',
      'status': AppConstants.statusActive,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('students', {
      'userId': 3,
      'classGrade': 'Level 300',
      'guardianUserId': null,
    });

    await db.insert('users', {
      'id': 4,
      'role': AppConstants.roleStudent,
      'email': 'student2@smartscholars.com',
      'fullName': 'Lankoko Raissa',
      'passwordHash': _hashPassword('student123'),
      'country': 'Cameroon',
      'status': AppConstants.statusActive,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('students', {
      'userId': 4,
      'classGrade': 'Level 200',
      'guardianUserId': 5, // Parent user
    });

    // Parent user
    await db.insert('users', {
      'id': 5,
      'role': AppConstants.roleParent,
      'email': 'parent@smartscholars.com',
      'fullName': 'Mary Lankoko',
      'passwordHash': _hashPassword('parent123'),
      'country': 'Cameroon',
      'status': AppConstants.statusActive,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('parents', {
      'userId': 5,
      'childName': 'Lankoko Raissa',
      'childClassGrade': 'Level 200',
      'school': 'University of Buea',
      'linkedStudentUserId': 4,
    });
  }

  Future<void> _seedCourses(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert('courses', {
      'id': 1,
      'title': 'Real Analysis 1',
      'description': 'Introduction to real analysis covering limits, continuity, and differentiation',
      'category': 'Mathematics',
      'createdByUserId': 2,
      'isPublished': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('courses', {
      'id': 2,
      'title': 'Programming in Python',
      'description': 'Learn Python programming from basics to advanced concepts',
      'category': 'Computer Science',
      'createdByUserId': 2,
      'isPublished': 1,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> _seedEnrollments(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Enroll students in courses
    await db.insert('enrollments', {
      'courseId': 1,
      'userId': 3,
      'roleAtEnrollment': AppConstants.roleStudent,
      'enrolledAt': now,
    });

    await db.insert('enrollments', {
      'courseId': 2,
      'userId': 3,
      'roleAtEnrollment': AppConstants.roleStudent,
      'enrolledAt': now,
    });

    await db.insert('enrollments', {
      'courseId': 1,
      'userId': 4,
      'roleAtEnrollment': AppConstants.roleStudent,
      'enrolledAt': now,
    });

    await db.insert('enrollments', {
      'courseId': 2,
      'userId': 4,
      'roleAtEnrollment': AppConstants.roleStudent,
      'enrolledAt': now,
    });
  }

  Future<void> _seedModulesAndLessons(Database db) async {
    // Real Analysis modules
    await db.insert('modules', {
      'id': 1,
      'courseId': 1,
      'title': 'Introduction to Limits',
      'orderIndex': 1,
    });

    await db.insert('modules', {
      'id': 2,
      'courseId': 1,
      'title': 'Continuity and Derivatives',
      'orderIndex': 2,
    });

    // Python modules
    await db.insert('modules', {
      'id': 3,
      'courseId': 2,
      'title': 'Python Basics',
      'orderIndex': 1,
    });

    await db.insert('modules', {
      'id': 4,
      'courseId': 2,
      'title': 'Object-Oriented Programming',
      'orderIndex': 2,
    });

    // Lessons for Real Analysis
    await db.insert('lessons', {
      'moduleId': 1,
      'title': 'What are Limits?',
      'content': 'Introduction to the concept of limits in calculus...',
      'durationMins': 45,
      'orderIndex': 1,
    });

    await db.insert('lessons', {
      'moduleId': 1,
      'title': 'Limit Laws',
      'content': 'Understanding the fundamental laws of limits...',
      'durationMins': 60,
      'orderIndex': 2,
    });

    await db.insert('lessons', {
      'moduleId': 1,
      'title': 'Evaluating Limits',
      'content': 'Techniques for evaluating limits...',
      'durationMins': 50,
      'orderIndex': 3,
    });

    // Lessons for Python
    await db.insert('lessons', {
      'moduleId': 3,
      'title': 'Variables and Data Types',
      'content': 'Learn about Python variables and basic data types...',
      'durationMins': 40,
      'orderIndex': 1,
    });

    await db.insert('lessons', {
      'moduleId': 3,
      'title': 'Control Structures',
      'content': 'If statements, loops, and control flow in Python...',
      'durationMins': 55,
      'orderIndex': 2,
    });

    await db.insert('lessons', {
      'moduleId': 3,
      'title': 'Functions',
      'content': 'Creating and using functions in Python...',
      'durationMins': 50,
      'orderIndex': 3,
    });
  }

  Future<void> _seedQuizzes(Database db) async {
    // Real Analysis Quiz
    await db.insert('quizzes', {
      'id': 1,
      'courseId': 1,
      'title': 'Limits Quiz',
      'description': 'Test your understanding of limits',
      'difficulty': 'Medium',
      'isPublished': 1,
    });

    await db.insert('questions', {
      'quizId': 1,
      'type': AppConstants.questionTypeMCQ,
      'prompt': 'What is the limit of x as x approaches 2 for the function f(x) = x + 1?',
      'options': json.encode(['1', '2', '3', '4']),
      'correctAnswer': '3',
      'points': 10,
    });

    await db.insert('questions', {
      'quizId': 1,
      'type': AppConstants.questionTypeTrueFalse,
      'prompt': 'The limit of a function always equals the function value at that point.',
      'options': json.encode(['True', 'False']),
      'correctAnswer': 'False',
      'points': 5,
    });

    // Python Quiz
    await db.insert('quizzes', {
      'id': 2,
      'courseId': 2,
      'title': 'Python Basics Quiz',
      'description': 'Test your Python fundamentals',
      'difficulty': 'Easy',
      'isPublished': 1,
    });

    await db.insert('questions', {
      'quizId': 2,
      'type': AppConstants.questionTypeMCQ,
      'prompt': 'Which of the following is the correct way to declare a variable in Python?',
      'options': json.encode(['var x = 5', 'int x = 5', 'x = 5', 'declare x = 5']),
      'correctAnswer': 'x = 5',
      'points': 10,
    });
  }

  Future<void> _seedMessages(Database db) async {
    final now = DateTime.now();
    
    await db.insert('messages', {
      'fromUserId': 3,
      'toUserId': 2,
      'body': 'Hello Dr. Johnson, I have a question about the limits assignment.',
      'sentAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
      'isRead': 1,
      'isFlagged': 0,
    });

    await db.insert('messages', {
      'fromUserId': 2,
      'toUserId': 3,
      'body': 'Hi Prince! I\'d be happy to help. What specific part are you struggling with?',
      'sentAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
      'isRead': 0,
      'isFlagged': 0,
    });

    await db.insert('messages', {
      'fromUserId': 4,
      'toUserId': 2,
      'body': 'Could you please explain the Python function syntax again?',
      'sentAt': now.subtract(const Duration(minutes: 30)).toIso8601String(),
      'isRead': 0,
      'isFlagged': 0,
    });
  }

  Future<void> _seedAnnouncements(Database db) async {
    final now = DateTime.now();

    await db.insert('announcements', {
      'title': 'Welcome to SmartScholars!',
      'body': 'Welcome to our learning platform. We\'re excited to have you here!',
      'targetRole': null, // Global announcement
      'targetCourseId': null,
      'startAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      'endAt': now.add(const Duration(days: 30)).toIso8601String(),
      'createdByUserId': 1,
    });

    await db.insert('announcements', {
      'title': 'Real Analysis Assignment Due',
      'body': 'Don\'t forget that your limits assignment is due this Friday.',
      'targetRole': AppConstants.roleStudent,
      'targetCourseId': 1,
      'startAt': now.toIso8601String(),
      'endAt': now.add(const Duration(days: 3)).toIso8601String(),
      'createdByUserId': 2,
    });
  }

  Future<void> _seedProgress(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Student 1 progress
    await db.insert('progress', {
      'userId': 3,
      'courseId': 1,
      'completedLessons': 2,
      'totalLessons': 3,
      'lastUpdatedAt': now,
    });

    await db.insert('progress', {
      'userId': 3,
      'courseId': 2,
      'completedLessons': 1,
      'totalLessons': 3,
      'lastUpdatedAt': now,
    });

    // Student 2 progress
    await db.insert('progress', {
      'userId': 4,
      'courseId': 1,
      'completedLessons': 1,
      'totalLessons': 3,
      'lastUpdatedAt': now,
    });

    await db.insert('progress', {
      'userId': 4,
      'courseId': 2,
      'completedLessons': 3,
      'totalLessons': 3,
      'lastUpdatedAt': now,
    });
  }
}
