import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/database/database_helper.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  // Experience points for different activities
  static const Map<String, int> activityPoints = {
    'quiz_completed': 50,
    'quiz_perfect_score': 100,
    'lesson_completed': 30,
    'daily_login': 10,
    'streak_bonus': 25,
    'help_classmate': 20,
    'upload_assignment': 15,
    'participate_discussion': 10,
  };

  // Badge definitions
  static const List<Badge> availableBadges = [
    Badge(
      id: 'first_quiz',
      name: 'First Steps',
      description: 'Complete your first quiz',
      icon: '🎯',
      requirement: 'Complete 1 quiz',
      points: 1,
    ),
    Badge(
      id: 'quiz_master',
      name: 'Quiz Master',
      description: 'Complete 10 quizzes',
      icon: '🏆',
      requirement: 'Complete 10 quizzes',
      points: 10,
    ),
    Badge(
      id: 'perfect_score',
      name: 'Perfectionist',
      description: 'Get 100% on a quiz',
      icon: '⭐',
      requirement: 'Score 100% on any quiz',
      points: 1,
    ),
    Badge(
      id: 'streak_7',
      name: 'Week Warrior',
      description: '7-day learning streak',
      icon: '🔥',
      requirement: 'Study for 7 consecutive days',
      points: 7,
    ),
    Badge(
      id: 'streak_30',
      name: 'Month Master',
      description: '30-day learning streak',
      icon: '💎',
      requirement: 'Study for 30 consecutive days',
      points: 30,
    ),
    Badge(
      id: 'helpful_student',
      name: 'Helpful Student',
      description: 'Help 5 classmates',
      icon: '🤝',
      requirement: 'Help 5 different students',
      points: 5,
    ),
    Badge(
      id: 'math_genius',
      name: 'Math Genius',
      description: 'Excel in mathematics',
      icon: '🧮',
      requirement: 'Complete 5 math quizzes with 90%+ score',
      points: 5,
    ),
    Badge(
      id: 'science_explorer',
      name: 'Science Explorer',
      description: 'Discover the world of science',
      icon: '🔬',
      requirement: 'Complete 5 science lessons',
      points: 5,
    ),
  ];

  // Level thresholds (experience points needed for each level)
  static const List<int> levelThresholds = [
    0,     // Level 1
    100,   // Level 2
    250,   // Level 3
    450,   // Level 4
    700,   // Level 5
    1000,  // Level 6
    1350,  // Level 7
    1750,  // Level 8
    2200,  // Level 9
    2700,  // Level 10
    3250,  // Level 11
    3850,  // Level 12
    4500,  // Level 13
    5200,  // Level 14
    5950,  // Level 15
    6750,  // Level 16
    7600,  // Level 17
    8500,  // Level 18
    9450,  // Level 19
    10450, // Level 20
  ];

  // Award points for activity
  Future<PointsAward> awardPoints({
    required int userId,
    required String activity,
    int? customPoints,
    String? description,
  }) async {
    try {
      final points = customPoints ?? activityPoints[activity] ?? 0;
      
      if (points <= 0) {
        return PointsAward(
          userId: userId,
          activity: activity,
          pointsAwarded: 0,
          totalPoints: await getUserTotalPoints(userId),
          levelBefore: await getUserLevel(userId),
          levelAfter: await getUserLevel(userId),
          isLevelUp: false,
        );
      }

      final db = await DatabaseHelper().database;
      
      // Get current user stats
      final currentStats = await getUserStats(userId);
      final newTotalPoints = currentStats.totalPoints + points;
      final levelBefore = currentStats.level;
      final levelAfter = calculateLevel(newTotalPoints);
      
      // Update user points
      await db.execute('''
        INSERT OR REPLACE INTO user_gamification 
        (user_id, total_points, level, badges_earned, streak_days, last_activity)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        userId,
        newTotalPoints,
        levelAfter,
        currentStats.badgesEarned.join(','),
        currentStats.streakDays,
        DateTime.now().millisecondsSinceEpoch,
      ]);

      // Record activity
      await db.insert('gamification_activities', {
        'user_id': userId,
        'activity': activity,
        'points_awarded': points,
        'description': description ?? activity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final isLevelUp = levelAfter > levelBefore;
      
      // Check for new badges
      await _checkAndAwardBadges(userId);

      return PointsAward(
        userId: userId,
        activity: activity,
        pointsAwarded: points,
        totalPoints: newTotalPoints,
        levelBefore: levelBefore,
        levelAfter: levelAfter,
        isLevelUp: isLevelUp,
        description: description,
      );
    } catch (e) {
      debugPrint('Error awarding points: $e');
      return PointsAward(
        userId: userId,
        activity: activity,
        pointsAwarded: 0,
        totalPoints: 0,
        levelBefore: 1,
        levelAfter: 1,
        isLevelUp: false,
        error: e.toString(),
      );
    }
  }

  // Get user gamification stats
  Future<UserGamificationStats> getUserStats(int userId) async {
    try {
      final db = await DatabaseHelper().database;
      
      final result = await db.query(
        'user_gamification',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) {
        // Create initial stats
        await db.insert('user_gamification', {
          'user_id': userId,
          'total_points': 0,
          'level': 1,
          'badges_earned': '',
          'streak_days': 0,
          'last_activity': DateTime.now().millisecondsSinceEpoch,
        });

        return UserGamificationStats(
          userId: userId,
          totalPoints: 0,
          level: 1,
          badgesEarned: [],
          streakDays: 0,
          lastActivity: DateTime.now(),
        );
      }

      final data = result.first;
      final badgesString = data['badges_earned'] as String? ?? '';
      final badges = badgesString.isEmpty ? <String>[] : badgesString.split(',');

      return UserGamificationStats(
        userId: userId,
        totalPoints: data['total_points'] as int,
        level: data['level'] as int,
        badgesEarned: badges,
        streakDays: data['streak_days'] as int,
        lastActivity: DateTime.fromMillisecondsSinceEpoch(data['last_activity'] as int),
      );
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return UserGamificationStats(
        userId: userId,
        totalPoints: 0,
        level: 1,
        badgesEarned: [],
        streakDays: 0,
        lastActivity: DateTime.now(),
      );
    }
  }

  // Calculate level from total points
  int calculateLevel(int totalPoints) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (totalPoints >= levelThresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  // Get points needed for next level
  int getPointsForNextLevel(int currentPoints) {
    final currentLevel = calculateLevel(currentPoints);
    if (currentLevel >= levelThresholds.length) {
      return 0; // Max level reached
    }
    return levelThresholds[currentLevel] - currentPoints;
  }

  // Get user's total points
  Future<int> getUserTotalPoints(int userId) async {
    final stats = await getUserStats(userId);
    return stats.totalPoints;
  }

  // Get user's level
  Future<int> getUserLevel(int userId) async {
    final stats = await getUserStats(userId);
    return stats.level;
  }

  // Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    try {
      final db = await DatabaseHelper().database;
      
      final result = await db.rawQuery('''
        SELECT ug.user_id, ug.total_points, ug.level, u.full_name
        FROM user_gamification ug
        JOIN users u ON ug.user_id = u.id
        ORDER BY ug.total_points DESC
        LIMIT ?
      ''', [limit]);

      return result.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        
        return LeaderboardEntry(
          rank: index + 1,
          userId: data['user_id'] as int,
          userName: data['full_name'] as String,
          totalPoints: data['total_points'] as int,
          level: data['level'] as int,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  // Check and award badges
  Future<List<Badge>> _checkAndAwardBadges(int userId) async {
    try {
      final stats = await getUserStats(userId);
      final newBadges = <Badge>[];

      // Check each badge requirement
      for (final badge in availableBadges) {
        if (stats.badgesEarned.contains(badge.id)) continue;

        bool shouldAward = false;

        switch (badge.id) {
          case 'first_quiz':
            shouldAward = await _hasCompletedQuizzes(userId, 1);
            break;
          case 'quiz_master':
            shouldAward = await _hasCompletedQuizzes(userId, 10);
            break;
          case 'perfect_score':
            shouldAward = await _hasPerfectScore(userId);
            break;
          case 'streak_7':
            shouldAward = stats.streakDays >= 7;
            break;
          case 'streak_30':
            shouldAward = stats.streakDays >= 30;
            break;
          // Add more badge checks as needed
        }

        if (shouldAward) {
          newBadges.add(badge);
          stats.badgesEarned.add(badge.id);
        }
      }

      // Update badges in database
      if (newBadges.isNotEmpty) {
        final db = await DatabaseHelper().database;
        await db.update(
          'user_gamification',
          {'badges_earned': stats.badgesEarned.join(',')},
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }

      return newBadges;
    } catch (e) {
      debugPrint('Error checking badges: $e');
      return [];
    }
  }

  // Helper methods for badge requirements
  Future<bool> _hasCompletedQuizzes(int userId, int count) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM quiz_attempts WHERE user_id = ?
      ''', [userId]);
      
      final completedCount = result.first['count'] as int;
      return completedCount >= count;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasPerfectScore(int userId) async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM quiz_attempts 
        WHERE user_id = ? AND score = total_questions
      ''', [userId]);
      
      final perfectCount = result.first['count'] as int;
      return perfectCount > 0;
    } catch (e) {
      return false;
    }
  }

  // Update daily streak
  Future<void> updateDailyStreak(int userId) async {
    try {
      final stats = await getUserStats(userId);
      final now = DateTime.now();
      final lastActivity = stats.lastActivity;
      
      final daysDifference = now.difference(lastActivity).inDays;
      
      int newStreakDays = stats.streakDays;
      
      if (daysDifference == 1) {
        // Consecutive day
        newStreakDays++;
      } else if (daysDifference > 1) {
        // Streak broken
        newStreakDays = 1;
      }
      // If same day, keep current streak
      
      final db = await DatabaseHelper().database;
      await db.update(
        'user_gamification',
        {
          'streak_days': newStreakDays,
          'last_activity': now.millisecondsSinceEpoch,
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String requirement;
  final int points;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.points,
  });
}

class UserGamificationStats {
  final int userId;
  final int totalPoints;
  final int level;
  final List<String> badgesEarned;
  final int streakDays;
  final DateTime lastActivity;

  UserGamificationStats({
    required this.userId,
    required this.totalPoints,
    required this.level,
    required this.badgesEarned,
    required this.streakDays,
    required this.lastActivity,
  });

  List<Badge> get badges {
    return GamificationService.availableBadges
        .where((badge) => badgesEarned.contains(badge.id))
        .toList();
  }
}

class PointsAward {
  final int userId;
  final String activity;
  final int pointsAwarded;
  final int totalPoints;
  final int levelBefore;
  final int levelAfter;
  final bool isLevelUp;
  final String? description;
  final String? error;

  PointsAward({
    required this.userId,
    required this.activity,
    required this.pointsAwarded,
    required this.totalPoints,
    required this.levelBefore,
    required this.levelAfter,
    required this.isLevelUp,
    this.description,
    this.error,
  });

  bool get hasError => error != null;
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String userName;
  final int totalPoints;
  final int level;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.totalPoints,
    required this.level,
  });

  String get rankDisplay {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}
