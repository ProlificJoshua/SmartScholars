import 'package:flutter/material.dart';
import '../../../../core/services/course_service.dart';
import '../../../../core/services/quiz_service.dart';
import '../../../../data/models/user_model.dart';

class CourseManagementScreen extends StatefulWidget {
  final UserModel user;

  const CourseManagementScreen({super.key, required this.user});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final CourseService _courseService = CourseService();
  final QuizService _quizService = QuizService();
  
  List<Course> _courses = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    
    try {
      final courses = await _courseService.getAllCourses();
      final categories = await _courseService.getCourseCategories();
      
      setState(() {
        _courses = courses;
        _categories = ['All', ...categories];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
      }
    }
  }

  List<Course> get _filteredCourses {
    if (_selectedFilter == 'All') return _courses;
    return _courses.where((course) => course.category == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Course Management'),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateCourseDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCards(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCoursesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalCourses = _courses.length;
    final publishedCourses = _courses.where((c) => c.isPublished).length;
    final totalCategories = _categories.length - 1; // Exclude 'All'

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Courses',
              totalCourses.toString(),
              Icons.book,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Published',
              publishedCourses.toString(),
              Icons.publish,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Categories',
              totalCategories.toString(),
              Icons.category,
              Colors.orange,
            ),
          ),
        ],
      ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('Filter by category: '),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedFilter,
              isExpanded: true,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value ?? 'All';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    final filteredCourses = _filteredCourses;
    
    if (filteredCourses.isEmpty) {
      return const Center(
        child: Text('No courses found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        final course = filteredCourses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  course.categoryIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (course.teacherName != null)
                        Text(
                          'by ${course.teacherName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: course.isPublished ? 'unpublish' : 'publish',
                      child: Row(
                        children: [
                          Icon(course.isPublished ? Icons.visibility_off : Icons.visibility),
                          const SizedBox(width: 8),
                          Text(course.isPublished ? 'Unpublish' : 'Publish'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleCourseAction(course, value.toString()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              course.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(course.category),
                  backgroundColor: Colors.blue.shade100,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(course.difficulty),
                  backgroundColor: Colors.orange.shade100,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(course.isPublished ? 'Published' : 'Draft'),
                  backgroundColor: course.isPublished 
                      ? Colors.green.shade100 
                      : Colors.grey.shade200,
                ),
                const Spacer(),
                FutureBuilder<List<UserModel>>(
                  future: _courseService.getCourseStudents(course.id),
                  builder: (context, snapshot) {
                    final studentCount = snapshot.data?.length ?? 0;
                    return Text(
                      '$studentCount students',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleCourseAction(Course course, String action) {
    switch (action) {
      case 'edit':
        _showEditCourseDialog(course);
        break;
      case 'publish':
      case 'unpublish':
        _toggleCoursePublishStatus(course);
        break;
      case 'delete':
        _showDeleteConfirmation(course);
        break;
    }
  }

  void _showCreateCourseDialog() {
    // TODO: Implement create course dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create course dialog coming soon!')),
    );
  }

  void _showEditCourseDialog(Course course) {
    // TODO: Implement edit course dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${course.title} coming soon!')),
    );
  }

  void _toggleCoursePublishStatus(Course course) {
    // TODO: Implement publish/unpublish functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${course.isPublished ? 'Unpublished' : 'Published'} ${course.title}',
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${course.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted ${course.title}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
