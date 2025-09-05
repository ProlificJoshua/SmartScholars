import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/database/database_helper.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final List<OfflineAction> _pendingActions = [];

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  // Initialize offline service
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      _isOnline = await _checkConnectivity();
      _connectivityController.add(_isOnline);
      
      // Start connectivity monitoring
      _startConnectivityMonitoring();
      
      // Load pending actions
      await _loadPendingActions();
      
      debugPrint('✅ Offline Service initialized - Online: $_isOnline');
    } catch (e) {
      debugPrint('❌ Offline Service initialization failed: $e');
    }
  }

  // Download content for offline use
  Future<OfflineDownloadResult> downloadForOffline({
    required String contentType, // 'lesson', 'quiz', 'course'
    required int contentId,
    required String title,
  }) async {
    try {
      if (!_isOnline) {
        return OfflineDownloadResult(
          contentId: contentId,
          contentType: contentType,
          isSuccessful: false,
          error: 'No internet connection available',
        );
      }

      final offlineDir = await _getOfflineDirectory();
      final contentDir = Directory('${offlineDir.path}/$contentType');
      if (!await contentDir.exists()) {
        await contentDir.create(recursive: true);
      }

      // Simulate content download
      await Future.delayed(const Duration(seconds: 2));

      final contentData = await _fetchContentData(contentType, contentId);
      final filePath = '${contentDir.path}/$contentId.json';
      
      final file = File(filePath);
      await file.writeAsString(jsonEncode(contentData));

      // Save offline content record
      await _saveOfflineContentRecord(
        contentType: contentType,
        contentId: contentId,
        title: title,
        filePath: filePath,
        downloadedAt: DateTime.now(),
      );

      return OfflineDownloadResult(
        contentId: contentId,
        contentType: contentType,
        title: title,
        filePath: filePath,
        fileSize: await file.length(),
        isSuccessful: true,
        downloadedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Download error: $e');
      return OfflineDownloadResult(
        contentId: contentId,
        contentType: contentType,
        isSuccessful: false,
        error: e.toString(),
      );
    }
  }

  // Get offline content
  Future<Map<String, dynamic>?> getOfflineContent({
    required String contentType,
    required int contentId,
  }) async {
    try {
      final offlineDir = await _getOfflineDirectory();
      final filePath = '${offlineDir.path}/$contentType/$contentId.json';
      final file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting offline content: $e');
      return null;
    }
  }

  // Get all offline content
  Future<List<OfflineContent>> getOfflineContentList() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query('offline_content', orderBy: 'downloaded_at DESC');

      return result.map((data) => OfflineContent.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting offline content list: $e');
      return [];
    }
  }

  // Delete offline content
  Future<bool> deleteOfflineContent({
    required String contentType,
    required int contentId,
  }) async {
    try {
      final offlineDir = await _getOfflineDirectory();
      final filePath = '${offlineDir.path}/$contentType/$contentId.json';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      // Remove from database
      final db = await DatabaseHelper().database;
      await db.delete(
        'offline_content',
        where: 'content_type = ? AND content_id = ?',
        whereArgs: [contentType, contentId],
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting offline content: $e');
      return false;
    }
  }

  // Queue action for when online
  Future<void> queueOfflineAction({
    required String actionType,
    required Map<String, dynamic> actionData,
  }) async {
    try {
      final action = OfflineAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        actionType: actionType,
        actionData: actionData,
        timestamp: DateTime.now(),
      );

      _pendingActions.add(action);
      await _savePendingAction(action);

      debugPrint('📝 Queued offline action: $actionType');
    } catch (e) {
      debugPrint('Error queuing offline action: $e');
    }
  }

  // Sync pending actions when online
  Future<void> syncPendingActions() async {
    if (!_isOnline || _pendingActions.isEmpty) return;

    debugPrint('🔄 Syncing ${_pendingActions.length} pending actions...');

    final actionsToRemove = <OfflineAction>[];

    for (final action in _pendingActions) {
      try {
        final success = await _executeAction(action);
        if (success) {
          actionsToRemove.add(action);
          await _removePendingAction(action.id);
        }
      } catch (e) {
        debugPrint('Error syncing action ${action.actionType}: $e');
      }
    }

    _pendingActions.removeWhere((action) => actionsToRemove.contains(action));
    
    if (actionsToRemove.isNotEmpty) {
      debugPrint('✅ Synced ${actionsToRemove.length} actions successfully');
    }
  }

  // Get offline storage usage
  Future<OfflineStorageInfo> getStorageInfo() async {
    try {
      final offlineDir = await _getOfflineDirectory();
      int totalSize = 0;
      int fileCount = 0;

      if (await offlineDir.exists()) {
        await for (final entity in offlineDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
            fileCount++;
          }
        }
      }

      return OfflineStorageInfo(
        totalSize: totalSize,
        fileCount: fileCount,
        formattedSize: _formatBytes(totalSize),
      );
    } catch (e) {
      debugPrint('Error getting storage info: $e');
      return OfflineStorageInfo(
        totalSize: 0,
        fileCount: 0,
        formattedSize: '0 B',
      );
    }
  }

  // Clear all offline content
  Future<bool> clearAllOfflineContent() async {
    try {
      final offlineDir = await _getOfflineDirectory();
      if (await offlineDir.exists()) {
        await offlineDir.delete(recursive: true);
      }

      // Clear database records
      final db = await DatabaseHelper().database;
      await db.delete('offline_content');

      return true;
    } catch (e) {
      debugPrint('Error clearing offline content: $e');
      return false;
    }
  }

  // Private methods
  Future<bool> _checkConnectivity() async {
    try {
      // Simulate connectivity check
      await Future.delayed(const Duration(milliseconds: 100));
      return true; // For demo, assume always online
    } catch (e) {
      return false;
    }
  }

  void _startConnectivityMonitoring() {
    // Simulate connectivity changes for demo
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      final wasOnline = _isOnline;
      _isOnline = await _checkConnectivity();
      
      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
        
        if (_isOnline) {
          debugPrint('🌐 Back online - syncing pending actions...');
          await syncPendingActions();
        } else {
          debugPrint('📴 Gone offline - queuing actions...');
        }
      }
    });
  }

  Future<Directory> _getOfflineDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/offline_content');
  }

  Future<Map<String, dynamic>> _fetchContentData(String contentType, int contentId) async {
    // Simulate fetching content from server
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'id': contentId,
      'type': contentType,
      'title': 'Sample $contentType $contentId',
      'content': 'This is sample content for $contentType with ID $contentId',
      'downloadedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _saveOfflineContentRecord({
    required String contentType,
    required int contentId,
    required String title,
    required String filePath,
    required DateTime downloadedAt,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      await db.insert('offline_content', {
        'content_type': contentType,
        'content_id': contentId,
        'title': title,
        'file_path': filePath,
        'downloaded_at': downloadedAt.millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error saving offline content record: $e');
    }
  }

  Future<void> _loadPendingActions() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query('pending_actions');
      
      _pendingActions.clear();
      for (final data in result) {
        _pendingActions.add(OfflineAction.fromMap(data));
      }
      
      debugPrint('📋 Loaded ${_pendingActions.length} pending actions');
    } catch (e) {
      debugPrint('Error loading pending actions: $e');
    }
  }

  Future<void> _savePendingAction(OfflineAction action) async {
    try {
      final db = await DatabaseHelper().database;
      await db.insert('pending_actions', action.toMap());
    } catch (e) {
      debugPrint('Error saving pending action: $e');
    }
  }

  Future<void> _removePendingAction(String actionId) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('pending_actions', where: 'id = ?', whereArgs: [actionId]);
    } catch (e) {
      debugPrint('Error removing pending action: $e');
    }
  }

  Future<bool> _executeAction(OfflineAction action) async {
    try {
      // Simulate action execution
      await Future.delayed(const Duration(milliseconds: 200));
      
      switch (action.actionType) {
        case 'submit_quiz':
        case 'save_progress':
        case 'send_message':
          return true; // Simulate successful execution
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error executing action: $e');
      return false;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void dispose() {
    _connectivityController.close();
  }
}

class OfflineContent {
  final String contentType;
  final int contentId;
  final String title;
  final String filePath;
  final DateTime downloadedAt;

  OfflineContent({
    required this.contentType,
    required this.contentId,
    required this.title,
    required this.filePath,
    required this.downloadedAt,
  });

  factory OfflineContent.fromMap(Map<String, dynamic> map) {
    return OfflineContent(
      contentType: map['content_type'],
      contentId: map['content_id'],
      title: map['title'],
      filePath: map['file_path'],
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(map['downloaded_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content_type': contentType,
      'content_id': contentId,
      'title': title,
      'file_path': filePath,
      'downloaded_at': downloadedAt.millisecondsSinceEpoch,
    };
  }
}

class OfflineDownloadResult {
  final int contentId;
  final String contentType;
  final String? title;
  final String? filePath;
  final int? fileSize;
  final bool isSuccessful;
  final DateTime? downloadedAt;
  final String? error;

  OfflineDownloadResult({
    required this.contentId,
    required this.contentType,
    this.title,
    this.filePath,
    this.fileSize,
    required this.isSuccessful,
    this.downloadedAt,
    this.error,
  });

  bool get hasError => error != null;
  String get formattedFileSize => fileSize != null ? _formatBytes(fileSize!) : '0 B';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class OfflineAction {
  final String id;
  final String actionType;
  final Map<String, dynamic> actionData;
  final DateTime timestamp;

  OfflineAction({
    required this.id,
    required this.actionType,
    required this.actionData,
    required this.timestamp,
  });

  factory OfflineAction.fromMap(Map<String, dynamic> map) {
    return OfflineAction(
      id: map['id'],
      actionType: map['action_type'],
      actionData: jsonDecode(map['action_data']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action_type': actionType,
      'action_data': jsonEncode(actionData),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class OfflineStorageInfo {
  final int totalSize;
  final int fileCount;
  final String formattedSize;

  OfflineStorageInfo({
    required this.totalSize,
    required this.fileCount,
    required this.formattedSize,
  });
}
