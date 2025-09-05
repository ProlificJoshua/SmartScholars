import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static bool _initialized = false;

  static void initializeDatabaseFactory() {
    if (!_initialized) {
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        // Initialize FFI for desktop platforms
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _initialized = true;
    }
  }

  Future<Database> get database async {
    initializeDatabaseFactory();
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        fullName TEXT NOT NULL,
        passwordHash TEXT NOT NULL,
        country TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Students table
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        classGrade TEXT NOT NULL,
        guardianUserId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (guardianUserId) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // Teachers table
    await db.execute('''
      CREATE TABLE teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        school TEXT,
        subjects TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Parents table
    await db.execute('''
      CREATE TABLE parents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        childName TEXT NOT NULL,
        childClassGrade TEXT NOT NULL,
        school TEXT,
        linkedStudentUserId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (linkedStudentUserId) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // Courses table
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT,
        createdByUserId INTEGER NOT NULL,
        isPublished INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (createdByUserId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Enrollments table
    await db.execute('''
      CREATE TABLE enrollments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        roleAtEnrollment TEXT NOT NULL,
        enrolledAt TEXT NOT NULL,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(courseId, userId)
      )
    ''');

    // Modules table
    await db.execute('''
      CREATE TABLE modules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        title TEXT NOT NULL,
        orderIndex INTEGER NOT NULL,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // Lessons table
    await db.execute('''
      CREATE TABLE lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        moduleId INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        durationMins INTEGER,
        orderIndex INTEGER NOT NULL,
        FOREIGN KEY (moduleId) REFERENCES modules (id) ON DELETE CASCADE
      )
    ''');

    // Quizzes table
    await db.execute('''
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        difficulty TEXT,
        isPublished INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // Questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quizId INTEGER NOT NULL,
        type TEXT NOT NULL,
        prompt TEXT NOT NULL,
        options TEXT,
        correctAnswer TEXT NOT NULL,
        points INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (quizId) REFERENCES quizzes (id) ON DELETE CASCADE
      )
    ''');

    // Quiz attempts table
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quizId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        startedAt TEXT NOT NULL,
        completedAt TEXT,
        score REAL,
        attemptNumber INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (quizId) REFERENCES quizzes (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Progress table
    await db.execute('''
      CREATE TABLE progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        courseId INTEGER NOT NULL,
        completedLessons INTEGER NOT NULL DEFAULT 0,
        totalLessons INTEGER NOT NULL DEFAULT 0,
        lastUpdatedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE,
        UNIQUE(userId, courseId)
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fromUserId INTEGER NOT NULL,
        toUserId INTEGER NOT NULL,
        body TEXT NOT NULL,
        sentAt TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        isFlagged INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (fromUserId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (toUserId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Announcements table
    await db.execute('''
      CREATE TABLE announcements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        targetRole TEXT,
        targetCourseId INTEGER,
        startAt TEXT NOT NULL,
        endAt TEXT,
        createdByUserId INTEGER NOT NULL,
        FOREIGN KEY (targetCourseId) REFERENCES courses (id) ON DELETE CASCADE,
        FOREIGN KEY (createdByUserId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Reports table
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        targetType TEXT NOT NULL,
        targetId INTEGER NOT NULL,
        reason TEXT NOT NULL,
        createdByUserId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        resolvedByUserId INTEGER,
        FOREIGN KEY (createdByUserId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (resolvedByUserId) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        brandName TEXT NOT NULL DEFAULT 'SmartScholars',
        primaryColor TEXT NOT NULL DEFAULT '#3F51B5',
        featuresJson TEXT NOT NULL DEFAULT '{}',
        termsVersion TEXT NOT NULL DEFAULT '1.0'
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER NOT NULL,
        receiver_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        chat_type TEXT NOT NULL,
        group_id INTEGER,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (sender_id) REFERENCES users (id),
        FOREIGN KEY (receiver_id) REFERENCES users (id)
      )
    ''');

    // Chat groups table
    await db.execute('''
      CREATE TABLE chat_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        member_ids TEXT NOT NULL
      )
    ''');

    // Uploaded files table
    await db.execute('''
      CREATE TABLE uploaded_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        uploaded_by INTEGER NOT NULL,
        uploaded_at INTEGER NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        FOREIGN KEY (uploaded_by) REFERENCES users (id)
      )
    ''');

    // User gamification table
    await db.execute('''
      CREATE TABLE user_gamification (
        user_id INTEGER PRIMARY KEY,
        total_points INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        badges_earned TEXT DEFAULT '',
        streak_days INTEGER DEFAULT 0,
        last_activity INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Gamification activities table
    await db.execute('''
      CREATE TABLE gamification_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        activity TEXT NOT NULL,
        points_awarded INTEGER NOT NULL,
        description TEXT,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Offline content table
    await db.execute('''
      CREATE TABLE offline_content (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_type TEXT NOT NULL,
        content_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        downloaded_at INTEGER NOT NULL
      )
    ''');

    // Pending actions table (for offline sync)
    await db.execute('''
      CREATE TABLE pending_actions (
        id TEXT PRIMARY KEY,
        action_type TEXT NOT NULL,
        action_data TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Enrollments table
    await db.execute('''
      CREATE TABLE enrollments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        course_id INTEGER NOT NULL,
        enrolled_at INTEGER NOT NULL,
        progress INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (course_id) REFERENCES courses (id),
        UNIQUE(user_id, course_id)
      )
    ''');

    // Course teachers table (for multiple teachers per course)
    await db.execute('''
      CREATE TABLE course_teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        teacher_id INTEGER NOT NULL,
        assigned_at INTEGER NOT NULL,
        FOREIGN KEY (course_id) REFERENCES courses (id),
        FOREIGN KEY (teacher_id) REFERENCES users (id),
        UNIQUE(course_id, teacher_id)
      )
    ''');

    // Offline quizzes table
    await db.execute('''
      CREATE TABLE offline_quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        quiz_data TEXT NOT NULL,
        downloaded_at INTEGER NOT NULL,
        FOREIGN KEY (quiz_id) REFERENCES quizzes (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(quiz_id, user_id)
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);

    // Insert default settings
    await db.insert('settings', {
      'id': 1,
      'brandName': 'SmartScholars',
      'primaryColor': '#3F51B5',
      'featuresJson': '{"chat": true, "quizzes": true, "courses": true}',
      'termsVersion': '1.0',
    });
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_users_email ON users (email)');
    await db.execute('CREATE INDEX idx_users_role ON users (role)');
    await db.execute(
      'CREATE INDEX idx_enrollments_user_course ON enrollments (userId, courseId)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_from_to ON messages (fromUserId, toUserId)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_to_user ON messages (toUserId)',
    );
    await db.execute(
      'CREATE INDEX idx_progress_user_course ON progress (userId, courseId)',
    );
    await db.execute(
      'CREATE INDEX idx_quiz_attempts_user_quiz ON quiz_attempts (userId, quizId)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    // For now, we'll just recreate the database
    if (oldVersion < newVersion) {
      // Add migration logic here when needed
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
