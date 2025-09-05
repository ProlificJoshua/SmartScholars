import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/services/auth_service.dart';
import 'data/database/seed_data.dart';
import 'data/models/user_model.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize database factory for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Initialize database with seed data
    await SeedData().seedDatabase();
    debugPrint('✅ Database initialized successfully');
  } catch (e) {
    debugPrint('❌ Database initialization error: $e');
    // Continue without database for now
  }

  runApp(const SmartScholarsApp());
}

class SmartScholarsApp extends StatelessWidget {
  const SmartScholarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartScholars',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isFirstTime = true;
  bool _isLoggedIn = false;
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;

      if (!isFirstTime) {
        await AuthService().initialize();
        final currentUser = AuthService().currentUser;
        setState(() {
          _isFirstTime = false;
          _isLoggedIn = currentUser != null;
          _currentUser = currentUser;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isFirstTime = true;
          _isLoggedIn = false;
          _currentUser = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isFirstTime) {
      return const OnboardingScreen();
    }

    if (!_isLoggedIn) {
      return const LoginScreen();
    }

    // Navigate to appropriate dashboard based on user role
    if (_currentUser == null) {
      return const LoginScreen();
    }

    return DashboardRouter(user: _currentUser!);
  }
}
