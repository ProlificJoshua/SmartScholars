import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/user_model.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  // Get all available courses
  Future<List<Course>> getAllCourses() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT c.*, u.full_name as teacher_name
        FROM courses c
        LEFT JOIN users u ON c.createdByUserId = u.id
        ORDER BY c.title ASC
      ''');

      return result.map((data) => Course.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting courses: $e');
      return [];
    }
  }

  // Get courses by teacher
  Future<List<Course>> getCoursesByTeacher(int teacherId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT c.*, u.full_name as teacher_name
        FROM courses c
        LEFT JOIN users u ON c.createdByUserId = u.id
        WHERE c.createdByUserId = ?
        ORDER BY c.title ASC
      ''', [teacherId]);

      return result.map((data) => Course.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting teacher courses: $e');
      return [];
    }
  }

  // Get enrolled courses for student
  Future<List<Course>> getEnrolledCourses(int studentId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT c.*, u.full_name as teacher_name, e.enrolled_at, e.progress
        FROM courses c
        LEFT JOIN users u ON c.createdByUserId = u.id
        JOIN enrollments e ON c.id = e.course_id
        WHERE e.user_id = ?
        ORDER BY c.title ASC
      ''', [studentId]);

      return result.map((data) => Course.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting enrolled courses: $e');
      return [];
    }
  }

  // Enroll student in course
  Future<bool> enrollInCourse(int studentId, int courseId) async {
    try {
      final db = await DatabaseHelper().database;
      
      // Check if already enrolled
      final existing = await db.query(
        'enrollments',
        where: 'user_id = ? AND course_id = ?',
        whereArgs: [studentId, courseId],
      );

      if (existing.isNotEmpty) {
        return false; // Already enrolled
      }

      await db.insert('enrollments', {
        'user_id': studentId,
        'course_id': courseId,
        'enrolled_at': DateTime.now().millisecondsSinceEpoch,
        'progress': 0,
      });

      return true;
    } catch (e) {
      debugPrint('Error enrolling in course: $e');
      return false;
    }
  }

  // Get course progress for student
  Future<double> getCourseProgress(int studentId, int courseId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'enrollments',
        columns: ['progress'],
        where: 'user_id = ? AND course_id = ?',
        whereArgs: [studentId, courseId],
      );

      if (result.isNotEmpty) {
        return (result.first['progress'] as int).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error getting course progress: $e');
      return 0.0;
    }
  }

  // Update course progress
  Future<void> updateCourseProgress(int studentId, int courseId, double progress) async {
    try {
      final db = await DatabaseHelper().database;
      await db.update(
        'enrollments',
        {'progress': progress.round()},
        where: 'user_id = ? AND course_id = ?',
        whereArgs: [studentId, courseId],
      );
    } catch (e) {
      debugPrint('Error updating course progress: $e');
    }
  }

  // Get students enrolled in course
  Future<List<UserModel>> getCourseStudents(int courseId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT u.*, e.enrolled_at, e.progress
        FROM users u
        JOIN enrollments e ON u.id = e.user_id
        WHERE e.course_id = ? AND u.role = 'student'
        ORDER BY u.full_name ASC
      ''', [courseId]);

      return result.map((data) => UserModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting course students: $e');
      return [];
    }
  }

  // Get teachers for course (including assistants)
  Future<List<UserModel>> getCourseTeachers(int courseId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT DISTINCT u.*
        FROM users u
        WHERE u.role = 'teacher' AND (
          u.id = (SELECT createdByUserId FROM courses WHERE id = ?) OR
          u.id IN (SELECT teacher_id FROM course_teachers WHERE course_id = ?)
        )
        ORDER BY u.full_name ASC
      ''', [courseId, courseId]);

      return result.map((data) => UserModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting course teachers: $e');
      return [];
    }
  }

  // Create new course
  Future<int?> createCourse({
    required String title,
    required String description,
    required int teacherId,
    String? category,
    String? difficulty,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      final courseId = await db.insert('courses', {
        'title': title,
        'description': description,
        'createdByUserId': teacherId,
        'category': category ?? 'General',
        'difficulty': difficulty ?? 'Beginner',
        'isPublished': 1,
      });

      return courseId;
    } catch (e) {
      debugPrint('Error creating course: $e');
      return null;
    }
  }

  // Get course by ID
  Future<Course?> getCourseById(int courseId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT c.*, u.full_name as teacher_name
        FROM courses c
        LEFT JOIN users u ON c.createdByUserId = u.id
        WHERE c.id = ?
      ''', [courseId]);

      if (result.isNotEmpty) {
        return Course.fromMap(result.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting course by ID: $e');
      return null;
    }
  }

  // Search courses
  Future<List<Course>> searchCourses(String query) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT c.*, u.full_name as teacher_name
        FROM courses c
        LEFT JOIN users u ON c.createdByUserId = u.id
        WHERE c.title LIKE ? OR c.description LIKE ? OR c.category LIKE ?
        ORDER BY c.title ASC
      ''', ['%$query%', '%$query%', '%$query%']);

      return result.map((data) => Course.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error searching courses: $e');
      return [];
    }
  }

  // Get course categories
  Future<List<String>> getCourseCategories() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT DISTINCT category FROM courses WHERE category IS NOT NULL
        ORDER BY category ASC
      ''');

      return result.map((data) => data['category'] as String).toList();
    } catch (e) {
      debugPrint('Error getting course categories: $e');
      return ['General', 'Mathematics', 'Science', 'Language', 'History', 'Arts'];
    }
  }
}

class Course {
  final int id;
  final String title;
  final String description;
  final int createdByUserId;
  final String? teacherName;
  final String category;
  final String difficulty;
  final bool isPublished;
  final DateTime? enrolledAt;
  final double progress;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.createdByUserId,
    this.teacherName,
    required this.category,
    required this.difficulty,
    required this.isPublished,
    this.enrolledAt,
    this.progress = 0.0,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      createdByUserId: map['createdByUserId'],
      teacherName: map['teacher_name'],
      category: map['category'] ?? 'General',
      difficulty: map['difficulty'] ?? 'Beginner',
      isPublished: (map['isPublished'] ?? 1) == 1,
      enrolledAt: map['enrolled_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['enrolled_at'])
          : null,
      progress: (map['progress'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdByUserId': createdByUserId,
      'category': category,
      'difficulty': difficulty,
      'isPublished': isPublished ? 1 : 0,
    };
  }

  String get difficultyIcon {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return '🟢';
      case 'intermediate':
        return '🟡';
      case 'advanced':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'mathematics':
        return '🧮';
      case 'science':
        return '🔬';
      case 'language':
        return '📚';
      case 'history':
        return '🏛️';
      case 'arts':
        return '🎨';
      default:
        return '📖';
    }
  }
}
