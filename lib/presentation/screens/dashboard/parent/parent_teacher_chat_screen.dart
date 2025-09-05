import 'package:flutter/material.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../data/models/user_model.dart';
import '../student/chat_conversation_screen.dart';

class ParentTeacherChatScreen extends StatefulWidget {
  final UserModel user;

  const ParentTeacherChatScreen({super.key, required this.user});

  @override
  State<ParentTeacherChatScreen> createState() =>
      _ParentTeacherChatScreenState();
}

class _ParentTeacherChatScreenState extends State<ParentTeacherChatScreen> {
  final ChatService _chatService = ChatService();

  List<UserModel> _teachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);

    try {
      // Get all teachers for parent communication
      final contacts = await _chatService.getChatContacts(
        widget.user.id!,
        widget.user.role,
      );
      _teachers = contacts.where((user) => user.role == 'teacher').toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading teachers: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍🏫 Teacher Communication'),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teachers.isEmpty
          ? _buildEmptyState()
          : _buildTeachersList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No teachers available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Teachers will appear here when they are available for communication',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersList() {
    return Column(
      children: [
        // Header with instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.teal.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect with Teachers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Communicate directly with your child\'s teachers about their progress, assignments, and any concerns.',
                style: TextStyle(fontSize: 14, color: Colors.teal.shade600),
              ),
            ],
          ),
        ),

        // Teachers list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _teachers.length,
            itemBuilder: (context, index) {
              final teacher = _teachers[index];
              return _buildTeacherCard(teacher);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherCard(UserModel teacher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade600,
                  radius: 24,
                  child: Text(
                    teacher.fullName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '👨‍🏫 Teacher',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (teacher.email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          teacher.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _showTeacherInfo(teacher),
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'Teacher Info',
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      onPressed: () => _startChat(teacher),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.teal.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can discuss your child\'s progress, homework, behavior, and any concerns with ${teacher.fullName.split(' ').first}.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startChat(UserModel teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatConversationScreen(
          currentUser: widget.user,
          otherUser: teacher,
        ),
      ),
    );
  }

  void _showTeacherInfo(UserModel teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade600,
              child: Text(
                teacher.fullName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(teacher.fullName)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Role', '👨‍🏫 Teacher'),
            _buildInfoRow('Email', teacher.email),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Communication Guidelines:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Be respectful and professional\n'
                    '• Provide specific details about concerns\n'
                    '• Allow 24-48 hours for responses\n'
                    '• Schedule meetings for complex discussions',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startChat(teacher);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
