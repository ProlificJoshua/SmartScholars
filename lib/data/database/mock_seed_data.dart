import 'package:flutter/foundation.dart';
import 'mock_database_helper.dart';

class MockSeedData {
  Future<void> seedDatabase() async {
    try {
      final dbHelper = MockDatabaseHelper();
      await dbHelper.initializeDatabase();
      debugPrint('Mock database seeded successfully');
    } catch (e) {
      debugPrint('Error seeding mock database: $e');
    }
  }
}
