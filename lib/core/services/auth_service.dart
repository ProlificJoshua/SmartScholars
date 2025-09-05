import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  String get currentUserRole => _currentUser?.role ?? '';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
    final userId = prefs.getInt(AppConstants.keyCurrentUserId);

    if (isLoggedIn && userId != null) {
      await _loadCurrentUser(userId);
    }
  }

  Future<void> _loadCurrentUser(int userId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'users',
        where: 'id = ? AND status = ?',
        whereArgs: [userId, AppConstants.statusActive],
      );

      if (result.isNotEmpty) {
        _currentUser = UserModel.fromMap(result.first);
      }
    } catch (e) {
      // Log error - in production, use proper logging framework
      debugPrint('Error loading current user: $e');
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AuthResult> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      final hashedPassword = _hashPassword(password);

      final result = await db.query(
        'users',
        where: 'email = ? AND passwordHash = ? AND status = ?',
        whereArgs: [
          email.toLowerCase(),
          hashedPassword,
          AppConstants.statusActive,
        ],
      );

      if (result.isEmpty) {
        return AuthResult(success: false, message: 'Invalid email or password');
      }

      _currentUser = UserModel.fromMap(result.first);
      await _saveLoginState(rememberMe);

      return AuthResult(
        success: true,
        message: 'Login successful',
        user: _currentUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> register({
    required String role,
    required String email,
    required String fullName,
    required String password,
    String? country,
    // Student specific
    String? classGrade,
    int? guardianUserId,
    // Teacher specific
    String? school,
    List<String>? subjects,
    // Parent specific
    String? childName,
    String? childClassGrade,
    int? linkedStudentUserId,
    // Admin specific
    String? adminSecretCode,
  }) async {
    try {
      // Validate admin secret code if registering as admin
      if (role == AppConstants.roleAdmin) {
        if (adminSecretCode != AppConstants.adminSecretCode) {
          return AuthResult(
            success: false,
            message: 'Invalid admin secret code',
          );
        }
      }

      final db = await DatabaseHelper().database;

      // Check if email already exists
      final existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (existingUser.isNotEmpty) {
        return AuthResult(success: false, message: 'Email already registered');
      }

      final now = DateTime.now();
      final hashedPassword = _hashPassword(password);

      // Insert user
      final userId = await db.insert('users', {
        'role': role,
        'email': email.toLowerCase(),
        'fullName': fullName,
        'passwordHash': hashedPassword,
        'country': country,
        'status': AppConstants.statusActive,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      // Insert role-specific data
      switch (role) {
        case AppConstants.roleStudent:
          await db.insert('students', {
            'userId': userId,
            'classGrade': classGrade ?? '',
            'guardianUserId': guardianUserId,
          });
          break;

        case AppConstants.roleTeacher:
          await db.insert('teachers', {
            'userId': userId,
            'school': school,
            'subjects': json.encode(subjects ?? []),
          });
          break;

        case AppConstants.roleParent:
          await db.insert('parents', {
            'userId': userId,
            'childName': childName ?? '',
            'childClassGrade': childClassGrade ?? '',
            'school': school,
            'linkedStudentUserId': linkedStudentUserId,
          });
          break;
      }

      // Load the created user
      final userResult = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      _currentUser = UserModel.fromMap(userResult.first);

      await _saveLoginState(true);

      return AuthResult(
        success: true,
        message: 'Registration successful',
        user: _currentUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  Future<void> _saveLoginState(bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setInt(AppConstants.keyCurrentUserId, _currentUser!.id!);
    await prefs.setBool(AppConstants.keyRememberMe, rememberMe);
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyIsLoggedIn);
    await prefs.remove(AppConstants.keyCurrentUserId);
    await prefs.remove(AppConstants.keyRememberMe);
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) return false;

    try {
      final db = await DatabaseHelper().database;
      final currentHashedPassword = _hashPassword(currentPassword);

      // Verify current password
      final result = await db.query(
        'users',
        where: 'id = ? AND passwordHash = ?',
        whereArgs: [_currentUser!.id, currentHashedPassword],
      );

      if (result.isEmpty) {
        return false; // Current password is incorrect
      }

      // Update password
      final newHashedPassword = _hashPassword(newPassword);
      await db.update(
        'users',
        {
          'passwordHash': newHashedPassword,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile({String? fullName, String? country}) async {
    if (_currentUser == null) return false;

    try {
      final db = await DatabaseHelper().database;
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['fullName'] = fullName;
      if (country != null) updates['country'] = country;

      await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      // Reload current user
      await _loadCurrentUser(_currentUser!.id!);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  bool hasAnyRole(List<String> roles) {
    return roles.contains(_currentUser?.role);
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (result.isEmpty) {
        return 'Email not found';
      }

      // In a real app, you would send a reset email
      // For now, we'll just return a hint
      final user = UserModel.fromMap(result.first);
      return 'Password hint: Your password starts with "${user.fullName.split(' ').first.toLowerCase()}"';
    } catch (e) {
      return 'Error processing request';
    }
  }
}

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  AuthResult({required this.success, required this.message, this.user});
}
