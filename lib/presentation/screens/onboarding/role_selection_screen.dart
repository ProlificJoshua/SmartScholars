import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/registration_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  final List<RoleOption> _roles = [
    RoleOption(
      role: AppConstants.roleStudent,
      title: 'Student',
      description:
          'Access courses, take quizzes, and track your learning progress',
      icon: Icons.school,
      color: Colors.blue,
    ),
    RoleOption(
      role: AppConstants.roleTeacher,
      title: 'Teacher',
      description:
          'Create courses, manage students, and monitor their progress',
      icon: Icons.person_outline,
      color: Colors.green,
    ),
    RoleOption(
      role: AppConstants.roleParent,
      title: 'Parent',
      description:
          'Monitor your child\'s academic progress and communicate with teachers',
      icon: Icons.family_restroom,
      color: Colors.orange,
    ),
    RoleOption(
      role: AppConstants.roleAdmin,
      title: 'Administrator',
      description: 'Manage the platform, users, content, and system settings',
      icon: Icons.admin_panel_settings,
      color: Colors.red,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Header
              const Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose the role that best describes you to get a personalized experience.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 48),

              // Role options
              Expanded(
                child: ListView.builder(
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    return _buildRoleCard(role);
                  },
                ),
              ),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedRole != null ? _continueWithRole : null,
                  child: const Text('Continue'),
                ),
              ),

              const SizedBox(height: 16),

              // Already have account
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(RoleOption role) {
    final isSelected = _selectedRole == role.role;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedRole = role.role;
            });
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(
                color: isSelected ? role.color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: role.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(role.icon, color: role.color, size: 30),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Icon(Icons.check_circle, color: role.color, size: 24)
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey[400],
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _continueWithRole() async {
    if (_selectedRole == null) return;

    // Save selected role
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySelectedRole, _selectedRole!);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RegistrationScreen(role: _selectedRole!),
        ),
      );
    }
  }
}

class RoleOption {
  final String role;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  RoleOption({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
