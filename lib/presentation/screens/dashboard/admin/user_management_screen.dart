import 'package:flutter/material.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/database/database_helper.dart';

class UserManagementScreen extends StatefulWidget {
  final UserModel user;

  const UserManagementScreen({super.key, required this.user});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedRole = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _roles = ['All', 'student', 'teacher', 'parent', 'admin'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query('users', orderBy: 'full_name ASC');
      
      final users = result.map((data) => UserModel.fromMap(data)).toList();
      
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = query.isEmpty ||
            user.fullName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
        
        final matchesRole = _selectedRole == 'All' || user.role == _selectedRole;
        
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 User Management'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCards(),
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalUsers = _users.length;
    final students = _users.where((u) => u.role == 'student').length;
    final teachers = _users.where((u) => u.role == 'teacher').length;
    final parents = _users.where((u) => u.role == 'parent').length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total', totalUsers.toString(), Icons.people, Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Students', students.toString(), Icons.school, Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Teachers', teachers.toString(), Icons.person, Colors.orange),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Parents', parents.toString(), Icons.family_restroom, Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Filter by role: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role == 'All' ? 'All Roles' : role.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value ?? 'All';
                    });
                    _filterUsers();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Text('No users found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                user.role.toUpperCase(),
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
              labelStyle: TextStyle(color: _getRoleColor(user.role)),
            ),
          ],
        ),
        trailing: PopupMenuButton(
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
            const PopupMenuItem(
              value: 'reset_password',
              child: Row(
                children: [
                  Icon(Icons.lock_reset),
                  SizedBox(width: 8),
                  Text('Reset Password'),
                ],
              ),
            ),
            if (user.role != 'admin')
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
          onSelected: (value) => _handleUserAction(user, value.toString()),
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'student':
        return Colors.green;
      case 'teacher':
        return Colors.blue;
      case 'parent':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleUserAction(UserModel user, String action) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'reset_password':
        _showResetPasswordDialog(user);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User created successfully!')),
              );
              _loadUsers();
            },
            child: const Text('Create User'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${user.fullName} - Coming soon!')),
    );
  }

  void _showResetPasswordDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Reset password for ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password reset for ${user.fullName}')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted ${user.fullName}')),
              );
              _loadUsers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
