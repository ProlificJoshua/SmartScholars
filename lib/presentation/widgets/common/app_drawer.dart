import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../screens/auth/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final UserModel user;

  const AppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user.fullName
                          .split(' ')
                          .map((name) => name[0])
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Role
                  Text(
                    _getRoleDisplayName(user.role),
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _buildDrawerItem(
                  icon: Icons.message,
                  title: 'Messages',
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Navigate to messages
                  },
                ),
                if (user.role == AppConstants.roleStudent) ...[
                  _buildDrawerItem(
                    icon: Icons.book,
                    title: 'My Courses',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to courses
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.quiz,
                    title: 'Quizzes',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to quizzes
                    },
                  ),
                ],
                if (user.role == AppConstants.roleTeacher) ...[
                  _buildDrawerItem(
                    icon: Icons.school,
                    title: 'My Classes',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to classes
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.assignment,
                    title: 'Assignments',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to assignments
                    },
                  ),
                ],
                if (user.role == AppConstants.roleAdmin) ...[
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'User Management',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to user management
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'System Settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to settings
                    },
                  ),
                ],
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Navigate to notifications
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Navigate to help
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info,
                  title: 'About',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),

          // Logout
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      onTap: onTap,
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.roleStudent:
        return 'Student';
      case AppConstants.roleTeacher:
        return 'Teacher';
      case AppConstants.roleParent:
        return 'Parent';
      case AppConstants.roleAdmin:
        return 'Administrator';
      default:
        return 'User';
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Icon(
        Icons.school,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          'SmartScholars is a comprehensive mobile learning platform designed for students, teachers, parents, and administrators.',
        ),
      ],
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
