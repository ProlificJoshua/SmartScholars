# SmartScholars

A comprehensive mobile learning platform built with Flutter and SQLite, supporting four distinct user roles: Students, Teachers, Parents, and Admins.

## Features

### 🎓 For Students
- Course enrollment and progress tracking
- Interactive quizzes and assessments
- Messaging with teachers and peers
- Personal dashboard with learning analytics

### 👨‍🏫 For Teachers
- Course creation and management
- Student progress monitoring
- Quiz and assessment tools
- Communication with students and parents

### 👨‍👩‍👧‍👦 For Parents
- Child's academic progress monitoring
- Communication with teachers
- Course enrollment oversight
- Performance analytics

### 🔧 For Admins
- User management across all roles
- Content moderation and approval
- Platform analytics and reporting
- System configuration and settings

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Database**: SQLite (offline-first)
- **State Management**: Provider
- **Navigation**: GoRouter
- **Architecture**: Clean Architecture with Repository Pattern

## Getting Started

1. **Prerequisites**
   - Flutter SDK (>=3.9.0)
   - Dart SDK
   - Android Studio / VS Code

2. **Installation**
   ```bash
   git clone <repository-url>
   cd SmartScholars
   flutter pub get
   flutter run
   ```

3. **Database Setup**
   The app uses SQLite for local data storage. Database tables are automatically created on first run with seed data for testing.

## Project Structure

```
lib/
├── core/           # Core utilities, constants, and base classes
├── data/           # Data layer (repositories, data sources, models)
├── domain/         # Business logic and entities
├── presentation/   # UI layer (screens, widgets, providers)
└── main.dart       # App entry point
```

## Role-Based Access

The app implements comprehensive role-based access control:
- **Authentication**: Secure login/registration for each role
- **Authorization**: Feature access based on user role
- **Navigation**: Role-specific dashboards and navigation flows
- **Data Access**: Filtered data based on user permissions

## Offline-First Architecture

SmartScholars is designed to work offline-first:
- All core data stored locally in SQLite
- Seamless offline functionality
- Data synchronization ready for future server integration

## Contributing

This project follows clean architecture principles and Flutter best practices. Please ensure all contributions maintain code quality and include appropriate tests.
