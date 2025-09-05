import 'package:flutter/material.dart';
import '../../../../core/services/quiz_service.dart';
import '../../../../core/services/course_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../data/models/user_model.dart';
import 'quiz_taking_screen.dart';

class QuizListScreen extends StatefulWidget {
  final Course course;
  final UserModel user;

  const QuizListScreen({super.key, required this.course, required this.user});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final QuizService _quizService = QuizService();
  final OfflineService _offlineService = OfflineService();

  List<Quiz> _quizzes = [];
  List<QuizAttempt> _attempts = [];
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _checkConnectivity();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);

    try {
      final quizzes = await _quizService.getQuizzesByCourse(widget.course.id);
      final attempts = await _quizService.getUserQuizAttempts(widget.user.id!);

      setState(() {
        _quizzes = quizzes;
        _attempts = attempts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading quizzes: $e')));
      }
    }
  }

  Future<void> _checkConnectivity() async {
    await _offlineService.initialize();
    _offlineService.connectivityStream.listen((isOnline) {
      setState(() {
        _isOnline = isOnline;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.course.title} - Quizzes'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (!_isOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'OFFLINE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
          ? _buildEmptyState()
          : _buildQuizzesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No quizzes available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new quizzes',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return _buildQuizCard(quiz);
      },
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    final attempt = _attempts.where((a) => a.quizId == quiz.id).isNotEmpty
        ? _attempts.where((a) => a.quizId == quiz.id).first
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.quiz,
                    color: Colors.purple.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quiz.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'download',
                      enabled: _isOnline,
                      child: Row(
                        children: [
                          Icon(
                            Icons.download,
                            color: _isOnline ? null : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Download for Offline',
                            style: TextStyle(
                              color: _isOnline ? null : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'download') {
                      _downloadQuiz(quiz);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quiz info
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.speed,
                  label: quiz.difficulty,
                  color: _getDifficultyColor(quiz.difficulty),
                ),
                const SizedBox(width: 8),
                if (attempt != null)
                  _buildInfoChip(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    color: Colors.green,
                  ),
              ],
            ),

            if (attempt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.grade, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Last Score: ${attempt.score}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(attempt.completedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _takeQuiz(quiz),
                    icon: Icon(
                      attempt != null ? Icons.refresh : Icons.play_arrow,
                    ),
                    label: Text(attempt != null ? 'Retake Quiz' : 'Take Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (attempt != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _viewResults(quiz, attempt),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Results'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontSize: 12),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _takeQuiz(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizTakingScreen(quiz: quiz, user: widget.user),
      ),
    ).then((_) => _loadQuizzes()); // Refresh after taking quiz
  }

  void _viewResults(Quiz quiz, QuizAttempt attempt) {
    // TODO: Implement quiz results screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz results screen coming soon!')),
    );
  }

  Future<void> _downloadQuiz(Quiz quiz) async {
    try {
      final success = await _quizService.downloadQuizForOffline(
        quiz.id,
        widget.user.id!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${quiz.title} downloaded for offline use!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download quiz')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
