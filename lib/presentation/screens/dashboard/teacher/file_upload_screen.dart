import 'package:flutter/material.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../data/models/user_model.dart';

class FileUploadScreen extends StatefulWidget {
  final UserModel user;

  const FileUploadScreen({super.key, required this.user});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> with TickerProviderStateMixin {
  final FileUploadService _fileUploadService = FileUploadService();
  late TabController _tabController;
  
  List<UploadedFile> _courseMaterials = [];
  List<UploadedFile> _quizzes = [];
  List<UploadedFile> _assignments = [];
  List<UploadedFile> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    
    try {
      final courseMaterials = await _fileUploadService.getFilesByCategory(
        'course_material',
        uploadedBy: widget.user.id,
      );
      final quizzes = await _fileUploadService.getFilesByCategory(
        'quiz',
        uploadedBy: widget.user.id,
      );
      final assignments = await _fileUploadService.getFilesByCategory(
        'assignment',
        uploadedBy: widget.user.id,
      );
      final resources = await _fileUploadService.getFilesByCategory(
        'resource',
        uploadedBy: widget.user.id,
      );

      setState(() {
        _courseMaterials = courseMaterials;
        _quizzes = quizzes;
        _assignments = assignments;
        _resources = resources;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading files: $e')),
        );
      }
    }
  }

  Future<void> _uploadFile(String category) async {
    try {
      final uploadedFile = await _fileUploadService.pickAndUploadFile(
        uploadedBy: widget.user.id!,
        category: category,
        description: await _getFileDescription(category),
      );

      if (uploadedFile != null) {
        _loadFiles(); // Refresh the file list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<String?> _getFileDescription(String category) async {
    final controller = TextEditingController();
    String? description;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload ${_getCategoryDisplayName(category)}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'Enter a brief description...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              description = controller.text.trim();
              Navigator.pop(context);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    return description;
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'course_material':
        return 'Course Material';
      case 'quiz':
        return 'Quiz';
      case 'assignment':
        return 'Assignment';
      case 'resource':
        return 'Resource';
      default:
        return 'File';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📁 File Manager'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'Materials'),
            Tab(icon: Icon(Icons.quiz), text: 'Quizzes'),
            Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
            Tab(icon: Icon(Icons.folder), text: 'Resources'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFileList(_courseMaterials, 'course_material'),
                _buildFileList(_quizzes, 'quiz'),
                _buildFileList(_assignments, 'assignment'),
                _buildFileList(_resources, 'resource'),
              ],
            ),
    );
  }

  Widget _buildFileList(List<UploadedFile> files, String category) {
    return Column(
      children: [
        // Upload button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _uploadFile(category),
            icon: const Icon(Icons.upload_file),
            label: Text('Upload ${_getCategoryDisplayName(category)}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        // Files list
        Expanded(
          child: files.isEmpty
              ? _buildEmptyState(category)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return _buildFileCard(file);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_getCategoryDisplayName(category).toLowerCase()} uploaded yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the upload button to add files',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(UploadedFile file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Text(
            _fileUploadService.getFileIcon(file.fileType),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          file.fileName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file.description != null && file.description!.isNotEmpty)
              Text(
                file.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  file.formattedFileSize,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${_formatDate(file.uploadedAt)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
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
          onSelected: (value) => _handleFileAction(value, file),
        ),
      ),
    );
  }

  void _handleFileAction(String action, UploadedFile file) {
    switch (action) {
      case 'share':
        _shareFile(file);
        break;
      case 'delete':
        _deleteFile(file);
        break;
    }
  }

  void _shareFile(UploadedFile file) {
    // TODO: Implement file sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File sharing coming soon!')),
    );
  }

  Future<void> _deleteFile(UploadedFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _fileUploadService.deleteFile(file.id!);
        if (success) {
          _loadFiles(); // Refresh the file list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File deleted successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
