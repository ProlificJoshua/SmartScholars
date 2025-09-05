import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String? role;

  const RegistrationScreen({super.key, this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countryController = TextEditingController();

  // Student specific
  final _classGradeController = TextEditingController();

  // Teacher specific
  final _schoolController = TextEditingController();
  final List<String> _selectedSubjects = [];
  final _subjectController = TextEditingController();

  // Parent specific
  final _childNameController = TextEditingController();
  final _childClassGradeController = TextEditingController();

  // Admin specific
  final _adminSecretController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _selectedRole = '';

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role ?? AppConstants.roleStudent;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countryController.dispose();
    _classGradeController.dispose();
    _schoolController.dispose();
    _subjectController.dispose();
    _childNameController.dispose();
    _childClassGradeController.dispose();
    _adminSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Join SmartScholars as ${_getRoleDisplayName()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Fill in your details to create your account',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),

                const SizedBox(height: 32),

                // Common fields
                _buildCommonFields(),

                const SizedBox(height: 16),

                // Role-specific fields
                _buildRoleSpecificFields(),

                const SizedBox(height: 24),

                // Terms and conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'I agree to the Terms of Service and Privacy Policy',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || !_acceptTerms ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Account'),
                  ),
                ),

                const SizedBox(height: 16),

                // Login link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
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
      ),
    );
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
        // Full Name
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            if (value.length > AppConstants.maxNameLength) {
              return 'Name is too long';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!EmailValidator.validate(value)) {
              return 'Please enter a valid email';
            }
            if (value.length > AppConstants.maxEmailLength) {
              return 'Email is too long';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < AppConstants.minPasswordLength) {
              return 'Password must be at least ${AppConstants.minPasswordLength} characters';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Country
        TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(
            labelText: 'Country',
            hintText: 'Enter your country',
            prefixIcon: Icon(Icons.public),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSpecificFields() {
    switch (_selectedRole) {
      case AppConstants.roleStudent:
        return _buildStudentFields();
      case AppConstants.roleTeacher:
        return _buildTeacherFields();
      case AppConstants.roleParent:
        return _buildParentFields();
      case AppConstants.roleAdmin:
        return _buildAdminFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStudentFields() {
    return Column(
      children: [
        TextFormField(
          controller: _classGradeController,
          decoration: const InputDecoration(
            labelText: 'Class/Grade',
            hintText: 'e.g., Level 300, Grade 10',
            prefixIcon: Icon(Icons.school),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your class/grade';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTeacherFields() {
    return Column(
      children: [
        TextFormField(
          controller: _schoolController,
          decoration: const InputDecoration(
            labelText: 'School/Institution',
            hintText: 'Enter your school or institution',
            prefixIcon: Icon(Icons.business),
          ),
        ),

        const SizedBox(height: 16),

        // Subjects
        TextFormField(
          controller: _subjectController,
          decoration: InputDecoration(
            labelText: 'Add Subject',
            hintText: 'Enter a subject you teach',
            prefixIcon: const Icon(Icons.subject),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addSubject,
            ),
          ),
          onFieldSubmitted: (_) => _addSubject(),
        ),

        if (_selectedSubjects.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _selectedSubjects.map((subject) {
              return Chip(
                label: Text(subject),
                onDeleted: () {
                  setState(() {
                    _selectedSubjects.remove(subject);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildParentFields() {
    return Column(
      children: [
        TextFormField(
          controller: _childNameController,
          decoration: const InputDecoration(
            labelText: 'Child Name',
            hintText: 'Enter your child\'s name',
            prefixIcon: Icon(Icons.child_care),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your child\'s name';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _childClassGradeController,
          decoration: const InputDecoration(
            labelText: 'Child\'s Class/Grade',
            hintText: 'e.g., Level 200, Grade 8',
            prefixIcon: Icon(Icons.school),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your child\'s class/grade';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _schoolController,
          decoration: const InputDecoration(
            labelText: 'School (Optional)',
            hintText: 'Enter your child\'s school',
            prefixIcon: Icon(Icons.business),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminFields() {
    return Column(
      children: [
        TextFormField(
          controller: _adminSecretController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Admin Secret Code',
            hintText: 'Enter the admin secret code',
            prefixIcon: Icon(Icons.admin_panel_settings),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the admin secret code';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _addSubject() {
    final subject = _subjectController.text.trim();
    if (subject.isNotEmpty && !_selectedSubjects.contains(subject)) {
      setState(() {
        _selectedSubjects.add(subject);
        _subjectController.clear();
      });
    }
  }

  String _getRoleDisplayName() {
    switch (_selectedRole) {
      case AppConstants.roleStudent:
        return 'a Student';
      case AppConstants.roleTeacher:
        return 'a Teacher';
      case AppConstants.roleParent:
        return 'a Parent';
      case AppConstants.roleAdmin:
        return 'an Administrator';
      default:
        return 'a User';
    }
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService().register(
        role: _selectedRole,
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        password: _passwordController.text,
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        // Student specific
        classGrade: _selectedRole == AppConstants.roleStudent
            ? _classGradeController.text.trim()
            : null,
        // Teacher specific
        school: _selectedRole == AppConstants.roleTeacher
            ? _schoolController.text.trim()
            : null,
        subjects: _selectedRole == AppConstants.roleTeacher
            ? _selectedSubjects
            : null,
        // Parent specific
        childName: _selectedRole == AppConstants.roleParent
            ? _childNameController.text.trim()
            : null,
        childClassGrade: _selectedRole == AppConstants.roleParent
            ? _childClassGradeController.text.trim()
            : null,
        // Admin specific
        adminSecretCode: _selectedRole == AppConstants.roleAdmin
            ? _adminSecretController.text.trim()
            : null,
      );

      if (result.success && result.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please sign in.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
