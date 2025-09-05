class AppConstants {
  // App Info
  static const String appName = 'SmartScholars';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'smart_scholars.db';
  static const int databaseVersion = 1;
  
  // User Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleParent = 'parent';
  static const String roleAdmin = 'admin';
  
  static const List<String> allRoles = [
    roleStudent,
    roleTeacher,
    roleParent,
    roleAdmin,
  ];
  
  // User Status
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  
  // Quiz Question Types
  static const String questionTypeMCQ = 'mcq';
  static const String questionTypeTrueFalse = 'truefalse';
  static const String questionTypeShort = 'short';
  
  // Report Status
  static const String reportStatusOpen = 'open';
  static const String reportStatusClosed = 'closed';
  
  // Report Target Types
  static const String reportTargetMessage = 'message';
  static const String reportTargetUser = 'user';
  static const String reportTargetContent = 'content';
  
  // SharedPreferences Keys
  static const String keyOnboardingSeen = 'onboarding_seen';
  static const String keySelectedRole = 'selected_role';
  static const String keyCurrentUserId = 'current_user_id';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyRememberMe = 'remember_me';
  
  // Admin Settings
  static const String adminSecretCode = 'SMARTSCHOLARS2024';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 255;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
  
  // Colors (Material 3 Indigo)
  static const int primaryColorValue = 0xFF3F51B5;
  static const int secondaryColorValue = 0xFF303F9F;
  static const int accentColorValue = 0xFF536DFE;
}
