import 'package:flutter/material.dart';
import '../../../../core/services/course_service.dart';
import '../../../../core/services/quiz_service.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../data/models/user_model.dart';
import 'quiz_list_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final UserModel user;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.user,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseService _courseService = CourseService();
  final QuizService _quizService = QuizService();
  final GamificationService _gamificationService = GamificationService();

  bool _isEnrolled = false;
  bool _isLoading = true;
  double _progress = 0.0;
  List<Quiz> _courseQuizzes = [];
  List<UserModel> _courseStudents = [];
  List<UserModel> _courseTeachers = [];

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    setState(() => _isLoading = true);

    try {
      // Check enrollment status
      final enrolledCourses = await _courseService.getEnrolledCourses(
        widget.user.id!,
      );
      _isEnrolled = enrolledCourses.any(
        (course) => course.id == widget.course.id,
      );

      if (_isEnrolled) {
        _progress = await _courseService.getCourseProgress(
          widget.user.id!,
          widget.course.id,
        );
      }

      // Load course data
      final quizzes = await _quizService.getQuizzesByCourse(widget.course.id);
      final students = await _courseService.getCourseStudents(widget.course.id);
      final teachers = await _courseService.getCourseTeachers(widget.course.id);

      setState(() {
        _courseQuizzes = quizzes;
        _courseStudents = students;
        _courseTeachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading course data: $e')),
        );
      }
    }
  }

  Future<void> _enrollInCourse() async {
    try {
      final success = await _courseService.enrollInCourse(
        widget.user.id!,
        widget.course.id,
      );

      if (success) {
        // Award points for enrollment
        await _gamificationService.awardPoints(
          userId: widget.user.id!,
          activity: 'course_enrollment',
          customPoints: 25,
          description: 'Enrolled in ${widget.course.title}',
        );

        setState(() {
          _isEnrolled = true;
          _progress = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully enrolled in course!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already enrolled in this course')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enrollment failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseHeader(),
                  const SizedBox(height: 24),
                  _buildCourseDescription(),
                  const SizedBox(height: 24),
                  if (_isEnrolled) ...[
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildQuizzesSection(),
                  const SizedBox(height: 24),
                  _buildPeopleSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildCourseHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.course.categoryIcon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.course.teacherName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Instructor: ${widget.course.teacherName}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.category,
                  label: widget.course.category,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.speed,
                  label: widget.course.difficulty,
                  color: _getDifficultyColor(widget.course.difficulty),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.people,
                  label: '${_courseStudents.length} students',
                  color: Colors.green,
                ),
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
      labelStyle: TextStyle(color: color),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCourseDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.course.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '${_progress.toStringAsFixed(0)}% Complete',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Course Quizzes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_courseQuizzes.isNotEmpty && _isEnrolled)
                  TextButton(
                    onPressed: () => _viewAllQuizzes(),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_courseQuizzes.isEmpty)
              Text(
                'No quizzes available yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                children: _courseQuizzes.take(3).map((quiz) {
                  return ListTile(
                    leading: const Icon(Icons.quiz),
                    title: Text(quiz.title),
                    subtitle: Text(quiz.difficulty),
                    trailing: _isEnrolled
                        ? const Icon(Icons.arrow_forward_ios)
                        : const Icon(Icons.lock, color: Colors.grey),
                    onTap: _isEnrolled ? () => _viewAllQuizzes() : null,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Community',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_courseTeachers.isNotEmpty) ...[
              Text(
                'Instructors (${_courseTeachers.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...(_courseTeachers
                  .take(2)
                  .map(
                    (teacher) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(teacher.fullName.substring(0, 1)),
                      ),
                      title: Text(teacher.fullName),
                      subtitle: const Text('👨‍🏫 Instructor'),
                      dense: true,
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            Text(
              'Students (${_courseStudents.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_courseStudents.isEmpty)
              Text(
                'No students enrolled yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...(_courseStudents
                  .take(3)
                  .map(
                    (student) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(student.fullName.substring(0, 1)),
                      ),
                      title: Text(student.fullName),
                      subtitle: const Text('👨‍🎓 Student'),
                      dense: true,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!_isEnrolled)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _enrollInCourse,
              icon: const Icon(Icons.add),
              label: const Text('Enroll in Course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          )
        else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _viewAllQuizzes,
              icon: const Icon(Icons.quiz),
              label: const Text('Take Quizzes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement course materials
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Course materials coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.book),
              label: const Text('Course Materials'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _viewAllQuizzes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuizListScreen(course: widget.course, user: widget.user),
      ),
    );
  }
}
