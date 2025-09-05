import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

class MockDatabaseHelper {
  static final MockDatabaseHelper _instance = MockDatabaseHelper._internal();
  factory MockDatabaseHelper() => _instance;
  MockDatabaseHelper._internal();

  // In-memory storage for demo purposes
  static final List<Map<String, dynamic>> _users = [];
  static bool _initialized = false;

  Future<void> initializeDatabase() async {
    if (!_initialized) {
      await _seedUsers();
      _initialized = true;
    }
  }

  Future<void> _seedUsers() async {
    _users.clear();
    _users.addAll([
      {
        'id': 1,
        'email': 'admin@smartscholars.com',
        'password': 'admin123',
        'full_name': 'System Administrator',
        'role': AppConstants.roleAdmin,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'email': 'teacher@smartscholars.com',
        'password': 'teacher123',
        'full_name': 'Dr. Sarah Johnson',
        'role': AppConstants.roleTeacher,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 3,
        'email': 'student1@smartscholars.com',
        'password': 'student123',
        'full_name': 'Prince Excellence',
        'role': AppConstants.roleStudent,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 4,
        'email': 'parent@smartscholars.com',
        'password': 'parent123',
        'full_name': 'Mary Lankoko',
        'role': AppConstants.roleParent,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    ]);
    debugPrint('Mock database initialized with ${_users.length} users');
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      return _users.firstWhere((user) => user['email'] == email);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    try {
      return _users.firstWhere((user) => user['id'] == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final id = _users.length + 1;
    user['id'] = id;
    user['created_at'] = DateTime.now().toIso8601String();
    _users.add(user);
    return id;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return List.from(_users);
  }

  Future<void> updateUser(int id, Map<String, dynamic> user) async {
    final index = _users.indexWhere((u) => u['id'] == id);
    if (index != -1) {
      _users[index] = {..._users[index], ...user};
    }
  }

  Future<void> deleteUser(int id) async {
    _users.removeWhere((user) => user['id'] == id);
  }

  // Mock methods for other tables
  Future<List<Map<String, dynamic>>> getCourses() async => [];
  Future<List<Map<String, dynamic>>> getQuizzes() async => [];
  Future<List<Map<String, dynamic>>> getMessages() async => [];
  Future<List<Map<String, dynamic>>> getAnnouncements() async => [];
}
