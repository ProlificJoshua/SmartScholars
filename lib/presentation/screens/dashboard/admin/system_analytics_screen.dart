import 'package:flutter/material.dart';
import '../../../../core/services/course_service.dart';
import '../../../../core/services/quiz_service.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../data/database/database_helper.dart';
import '../../../../data/models/user_model.dart';

class SystemAnalyticsScreen extends StatefulWidget {
  final UserModel user;

  const SystemAnalyticsScreen({super.key, required this.user});

  @override
  State<SystemAnalyticsScreen> createState() => _SystemAnalyticsScreenState();
}

class _SystemAnalyticsScreenState extends State<SystemAnalyticsScreen> {
  final CourseService _courseService = CourseService();
  final QuizService _quizService = QuizService();
  final GamificationService _gamificationService = GamificationService();
  
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final db = await DatabaseHelper().database;
      
      // User statistics
      final userStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_users,
          SUM(CASE WHEN role = 'student' THEN 1 ELSE 0 END) as students,
          SUM(CASE WHEN role = 'teacher' THEN 1 ELSE 0 END) as teachers,
          SUM(CASE WHEN role = 'parent' THEN 1 ELSE 0 END) as parents
        FROM users
      ''');

      // Course statistics
      final courseStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_courses,
          SUM(CASE WHEN isPublished = 1 THEN 1 ELSE 0 END) as published_courses,
          COUNT(DISTINCT category) as categories
        FROM courses
      ''');

      // Quiz statistics
      final quizStats = await db.rawQuery('''
        SELECT 
          COUNT(DISTINCT q.id) as total_quizzes,
          COUNT(qa.id) as total_attempts,
          AVG(qa.score) as average_score,
          COUNT(DISTINCT qa.user_id) as active_students
        FROM quizzes q
        LEFT JOIN quiz_attempts qa ON q.id = qa.quiz_id
      ''');

      // Enrollment statistics
      final enrollmentStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_enrollments,
          AVG(progress) as average_progress
        FROM enrollments
      ''');

      // Recent activity
      final recentActivity = await db.rawQuery('''
        SELECT 
          'Quiz Attempt' as activity_type,
          u.full_name as user_name,
          q.title as item_name,
          qa.completed_at as timestamp
        FROM quiz_attempts qa
        JOIN users u ON qa.user_id = u.id
        JOIN quizzes q ON qa.quiz_id = q.id
        ORDER BY qa.completed_at DESC
        LIMIT 10
      ''');

      // Top performing students
      final topStudents = await db.rawQuery('''
        SELECT 
          u.full_name,
          ug.total_points,
          ug.level,
          COUNT(qa.id) as quiz_attempts,
          AVG(qa.score) as average_score
        FROM users u
        LEFT JOIN user_gamification ug ON u.id = ug.user_id
        LEFT JOIN quiz_attempts qa ON u.id = qa.user_id
        WHERE u.role = 'student'
        GROUP BY u.id
        ORDER BY ug.total_points DESC
        LIMIT 5
      ''');

      // Course popularity
      final popularCourses = await db.rawQuery('''
        SELECT 
          c.title,
          c.category,
          COUNT(e.id) as enrollment_count,
          AVG(e.progress) as average_progress
        FROM courses c
        LEFT JOIN enrollments e ON c.id = e.course_id
        GROUP BY c.id
        ORDER BY enrollment_count DESC
        LIMIT 5
      ''');

      setState(() {
        _analytics = {
          'users': userStats.first,
          'courses': courseStats.first,
          'quizzes': quizStats.first,
          'enrollments': enrollmentStats.first,
          'recent_activity': recentActivity,
          'top_students': topStudents,
          'popular_courses': popularCourses,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 System Analytics'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCards(),
                  const SizedBox(height: 24),
                  _buildChartsSection(),
                  const SizedBox(height: 24),
                  _buildRecentActivity(),
                  const SizedBox(height: 24),
                  _buildTopPerformers(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final users = _analytics['users'] ?? {};
    final courses = _analytics['courses'] ?? {};
    final quizzes = _analytics['quizzes'] ?? {};
    final enrollments = _analytics['enrollments'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Users',
                '${users['total_users'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Active Courses',
                '${courses['published_courses'] ?? 0}',
                Icons.school,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Quiz Attempts',
                '${quizzes['total_attempts'] ?? 0}',
                Icons.quiz,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Avg Score',
                '${((quizzes['average_score'] ?? 0) as double).toStringAsFixed(1)}%',
                Icons.grade,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    final users = _analytics['users'] ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Distribution',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildUserDistributionBar(
                  'Students',
                  users['students'] ?? 0,
                  users['total_users'] ?? 1,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildUserDistributionBar(
                  'Teachers',
                  users['teachers'] ?? 0,
                  users['total_users'] ?? 1,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildUserDistributionBar(
                  'Parents',
                  users['parents'] ?? 0,
                  users['total_users'] ?? 1,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDistributionBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count (${(percentage * 100).toStringAsFixed(1)}%)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final activities = _analytics['recent_activity'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: activities.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No recent activity'),
                    )
                  ]
                : activities.map((activity) {
                    return ListTile(
                      leading: const Icon(Icons.quiz, color: Colors.blue),
                      title: Text(activity['user_name'] ?? 'Unknown User'),
                      subtitle: Text(activity['item_name'] ?? 'Unknown Item'),
                      trailing: Text(
                        _formatTimestamp(activity['timestamp']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformers() {
    final topStudents = _analytics['top_students'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Students',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: topStudents.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No student data available'),
                    )
                  ]
                : topStudents.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value;
                    final rank = index + 1;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRankColor(rank),
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(student['full_name'] ?? 'Unknown Student'),
                      subtitle: Text(
                        'Level ${student['level'] ?? 0} • ${student['quiz_attempts'] ?? 0} quizzes',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${student['total_points'] ?? 0} pts',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${((student['average_score'] ?? 0) as double).toStringAsFixed(1)}% avg',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
