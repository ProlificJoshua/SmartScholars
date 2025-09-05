import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../data/database/database_helper.dart';

class UploadedFile {
  final int? id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final int uploadedBy;
  final DateTime uploadedAt;
  final String? description;
  final String category; // 'course_material', 'quiz', 'assignment', 'resource'

  UploadedFile({
    this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedAt,
    this.description,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.millisecondsSinceEpoch,
      'description': description,
      'category': category,
    };
  }

  factory UploadedFile.fromMap(Map<String, dynamic> map) {
    return UploadedFile(
      id: map['id'],
      fileName: map['file_name'],
      filePath: map['file_path'],
      fileType: map['file_type'],
      fileSize: map['file_size'],
      uploadedBy: map['uploaded_by'],
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(map['uploaded_at']),
      description: map['description'],
      category: map['category'],
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  factory FileUploadService() => _instance;
  FileUploadService._internal();

  // Supported file types
  static const List<String> supportedFileTypes = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
  ];

  // Pick and upload file
  Future<UploadedFile?> pickAndUploadFile({
    required int uploadedBy,
    required String category,
    String? description,
    List<String>? allowedExtensions,
  }) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? supportedFileTypes,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;
        final fileExtension = path
            .extension(fileName)
            .toLowerCase()
            .replaceAll('.', '');

        // Validate file
        if (!supportedFileTypes.contains(fileExtension)) {
          throw Exception('Unsupported file type: $fileExtension');
        }

        if (fileSize > 50 * 1024 * 1024) {
          // 50MB limit
          throw Exception('File size exceeds 50MB limit');
        }

        // Save file to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final uploadsDir = Directory('${appDir.path}/uploads');
        if (!await uploadsDir.exists()) {
          await uploadsDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newFileName = '${timestamp}_$fileName';
        final newFilePath = '${uploadsDir.path}/$newFileName';

        await file.copy(newFilePath);

        // Create file record
        final uploadedFile = UploadedFile(
          fileName: fileName,
          filePath: newFilePath,
          fileType: fileExtension,
          fileSize: fileSize,
          uploadedBy: uploadedBy,
          uploadedAt: DateTime.now(),
          description: description,
          category: category,
        );

        // Save to database
        final db = await DatabaseHelper().database;
        final id = await db.insert('uploaded_files', uploadedFile.toMap());

        return UploadedFile(
          id: id,
          fileName: uploadedFile.fileName,
          filePath: uploadedFile.filePath,
          fileType: uploadedFile.fileType,
          fileSize: uploadedFile.fileSize,
          uploadedBy: uploadedFile.uploadedBy,
          uploadedAt: uploadedFile.uploadedAt,
          description: uploadedFile.description,
          category: uploadedFile.category,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  // Get files by category
  Future<List<UploadedFile>> getFilesByCategory(
    String category, {
    int? uploadedBy,
  }) async {
    try {
      final db = await DatabaseHelper().database;

      String whereClause = 'category = ?';
      List<dynamic> whereArgs = [category];

      if (uploadedBy != null) {
        whereClause += ' AND uploaded_by = ?';
        whereArgs.add(uploadedBy);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'uploaded_files',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'uploaded_at DESC',
      );

      return List.generate(maps.length, (i) => UploadedFile.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting files by category: $e');
      return [];
    }
  }

  // Get all files uploaded by user
  Future<List<UploadedFile>> getUserFiles(int userId) async {
    try {
      final db = await DatabaseHelper().database;

      final List<Map<String, dynamic>> maps = await db.query(
        'uploaded_files',
        where: 'uploaded_by = ?',
        whereArgs: [userId],
        orderBy: 'uploaded_at DESC',
      );

      return List.generate(maps.length, (i) => UploadedFile.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting user files: $e');
      return [];
    }
  }

  // Delete file
  Future<bool> deleteFile(int fileId) async {
    try {
      final db = await DatabaseHelper().database;

      // Get file info first
      final List<Map<String, dynamic>> maps = await db.query(
        'uploaded_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );

      if (maps.isNotEmpty) {
        final filePath = maps.first['file_path'];

        // Delete physical file
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }

        // Delete database record
        await db.delete('uploaded_files', where: 'id = ?', whereArgs: [fileId]);

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Get file by ID
  Future<UploadedFile?> getFileById(int fileId) async {
    try {
      final db = await DatabaseHelper().database;

      final List<Map<String, dynamic>> maps = await db.query(
        'uploaded_files',
        where: 'id = ?',
        whereArgs: [fileId],
      );

      if (maps.isNotEmpty) {
        return UploadedFile.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting file by ID: $e');
      return null;
    }
  }

  // Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get file size in readable format
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Get file icon based on extension
  String getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'ppt':
      case 'pptx':
        return '📊';
      case 'xls':
      case 'xlsx':
        return '📈';
      case 'txt':
        return '📋';
      default:
        return '📁';
    }
  }

  // Get storage usage for user
  Future<int> getUserStorageUsage(int userId) async {
    try {
      final db = await DatabaseHelper().database;

      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT SUM(file_size) as total_size FROM uploaded_files WHERE uploaded_by = ?',
        [userId],
      );

      return result.first['total_size'] ?? 0;
    } catch (e) {
      debugPrint('Error getting storage usage: $e');
      return 0;
    }
  }
}
