import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import 'student/student_dashboard.dart';
import 'teacher/teacher_dashboard.dart';
import 'parent/parent_dashboard.dart';
import 'admin/admin_dashboard.dart';

class DashboardRouter extends StatelessWidget {
  final UserModel user;

  const DashboardRouter({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case AppConstants.roleStudent:
        return StudentDashboard(user: user);
      case AppConstants.roleTeacher:
        return TeacherDashboard(user: user);
      case AppConstants.roleParent:
        return ParentDashboard(user: user);
      case AppConstants.roleAdmin:
        return AdminDashboard(user: user);
      default:
        return _buildErrorScreen(context);
    }
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Invalid user role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please contact support for assistance.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
