import 'package:flutter/material.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../data/models/user_model.dart';
import 'chat_conversation_screen.dart';

class ChatCenterScreen extends StatefulWidget {
  final UserModel user;

  const ChatCenterScreen({super.key, required this.user});

  @override
  State<ChatCenterScreen> createState() => _ChatCenterScreenState();
}

class _ChatCenterScreenState extends State<ChatCenterScreen> with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  late TabController _tabController;
  
  List<UserModel> _students = [];
  List<UserModel> _teachers = [];
  List<ChatGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all contacts
      final contacts = await _chatService.getChatContacts(widget.user.id!, widget.user.role);
      
      // Separate students and teachers
      _students = contacts.where((user) => user.role == 'student').toList();
      _teachers = contacts.where((user) => user.role == 'teacher').toList();
      
      // Get user's groups
      _groups = await _chatService.getUserChatGroups(widget.user.id!);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Chat Center'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Students'),
            Tab(icon: Icon(Icons.person), text: 'Teachers'),
            Tab(icon: Icon(Icons.group), text: 'Groups'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStudentsList(),
                _buildTeachersList(),
                _buildGroupsList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No students available to chat with',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return _buildUserTile(student);
      },
    );
  }

  Widget _buildTeachersList() {
    if (_teachers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No teachers available to chat with',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teachers.length,
      itemBuilder: (context, index) {
        final teacher = _teachers[index];
        return _buildUserTile(teacher);
      },
    );
  }

  Widget _buildGroupsList() {
    if (_groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No groups available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to create a new group',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return _buildGroupTile(group);
      },
    );
  }

  Widget _buildUserTile(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.role == 'teacher' ? Colors.blue : Colors.green,
          child: Text(
            user.fullName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user.role == 'teacher' ? '👨‍🏫 Teacher' : '👨‍🎓 Student',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chat_bubble_outline),
        onTap: () => _openChat(user),
      ),
    );
  }

  Widget _buildGroupTile(ChatGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple,
          child: Text(
            group.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${group.memberIds.length} members • ${group.description}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.group_work),
        onTap: () => _openGroupChat(group),
      ),
    );
  }

  void _openChat(UserModel otherUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatConversationScreen(
          currentUser: widget.user,
          otherUser: otherUser,
        ),
      ),
    );
  }

  void _openGroupChat(ChatGroup group) {
    // TODO: Implement group chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group chat coming soon!')),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Study Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g., Math Study Group',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What is this group about?',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createGroup(nameController.text, descriptionController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup(String name, String description) async {
    if (name.trim().isEmpty) return;

    Navigator.pop(context);

    try {
      final groupId = await _chatService.createChatGroup(
        name: name.trim(),
        description: description.trim(),
        type: 'student_group',
        memberIds: [widget.user.id!],
      );

      if (groupId != null) {
        _loadChatData(); // Refresh the groups list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
