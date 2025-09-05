import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/user_model.dart';

class ChatMessage {
  final int? id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime timestamp;
  final String
  chatType; // 'direct', 'group', 'teacher_student', 'parent_teacher'
  final int? groupId;
  final bool isRead;

  ChatMessage({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.chatType,
    this.groupId,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'chat_type': chatType,
      'group_id': groupId,
      'is_read': isRead ? 1 : 0,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      message: map['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      chatType: map['chat_type'],
      groupId: map['group_id'],
      isRead: map['is_read'] == 1,
    );
  }
}

class ChatGroup {
  final int? id;
  final String name;
  final String description;
  final String type; // 'student_group', 'teacher_group', 'class_group'
  final DateTime createdAt;
  final List<int> memberIds;

  ChatGroup({
    this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.memberIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'created_at': createdAt.millisecondsSinceEpoch,
      'member_ids': memberIds.join(','),
    };
  }

  factory ChatGroup.fromMap(Map<String, dynamic> map) {
    return ChatGroup(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: map['type'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      memberIds: map['member_ids']
          .toString()
          .split(',')
          .map((e) => int.tryParse(e) ?? 0)
          .toList(),
    );
  }
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final StreamController<List<ChatMessage>> _messagesController =
      StreamController<List<ChatMessage>>.broadcast();
  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;

  // Send a message
  Future<bool> sendMessage({
    required int senderId,
    required int receiverId,
    required String message,
    required String chatType,
    int? groupId,
  }) async {
    try {
      final db = await DatabaseHelper().database;

      final chatMessage = ChatMessage(
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        chatType: chatType,
        groupId: groupId,
      );

      await db.insert('chat_messages', chatMessage.toMap());

      // Refresh messages stream
      _refreshMessages(senderId, receiverId);

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Get messages between two users
  Future<List<ChatMessage>> getMessages(int userId1, int userId2) async {
    try {
      final db = await DatabaseHelper().database;

      final List<Map<String, dynamic>> maps = await db.query(
        'chat_messages',
        where:
            '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
        whereArgs: [userId1, userId2, userId2, userId1],
        orderBy: 'timestamp ASC',
      );

      return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  // Get group messages
  Future<List<ChatMessage>> getGroupMessages(int groupId) async {
    try {
      final db = await DatabaseHelper().database;

      final List<Map<String, dynamic>> maps = await db.query(
        'chat_messages',
        where: 'group_id = ?',
        whereArgs: [groupId],
        orderBy: 'timestamp ASC',
      );

      return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting group messages: $e');
      return [];
    }
  }

  // Get chat contacts for a user
  Future<List<UserModel>> getChatContacts(int userId, String userRole) async {
    try {
      final db = await DatabaseHelper().database;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      switch (userRole) {
        case 'student':
          // Students can chat with other students and teachers
          whereClause = 'role IN (?, ?) AND id != ?';
          whereArgs = ['student', 'teacher', userId];
          break;
        case 'teacher':
          // Teachers can chat with students and other teachers
          whereClause = 'role IN (?, ?) AND id != ?';
          whereArgs = ['student', 'teacher', userId];
          break;
        case 'parent':
          // Parents can chat with teachers
          whereClause = 'role = ?';
          whereArgs = ['teacher'];
          break;
        default:
          whereClause = 'id != ?';
          whereArgs = [userId];
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'full_name ASC',
      );

      return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting chat contacts: $e');
      return [];
    }
  }

  // Create a chat group
  Future<int?> createChatGroup({
    required String name,
    required String description,
    required String type,
    required List<int> memberIds,
  }) async {
    try {
      final db = await DatabaseHelper().database;

      final group = ChatGroup(
        name: name,
        description: description,
        type: type,
        createdAt: DateTime.now(),
        memberIds: memberIds,
      );

      final id = await db.insert('chat_groups', group.toMap());
      return id;
    } catch (e) {
      debugPrint('Error creating chat group: $e');
      return null;
    }
  }

  // Get user's chat groups
  Future<List<ChatGroup>> getUserChatGroups(int userId) async {
    try {
      final db = await DatabaseHelper().database;

      final List<Map<String, dynamic>> maps = await db.query(
        'chat_groups',
        where: 'member_ids LIKE ?',
        whereArgs: ['%$userId%'],
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) => ChatGroup.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting user chat groups: $e');
      return [];
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(int senderId, int receiverId) async {
    try {
      final db = await DatabaseHelper().database;

      await db.update(
        'chat_messages',
        {'is_read': 1},
        where: 'sender_id = ? AND receiver_id = ? AND is_read = 0',
        whereArgs: [senderId, receiverId],
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount(int userId) async {
    try {
      final db = await DatabaseHelper().database;

      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chat_messages WHERE receiver_id = ? AND is_read = 0',
        [userId],
      );

      return result.first['count'] ?? 0;
    } catch (e) {
      debugPrint('Error getting unread message count: $e');
      return 0;
    }
  }

  // Refresh messages stream
  void _refreshMessages(int userId1, int userId2) async {
    final messages = await getMessages(userId1, userId2);
    _messagesController.add(messages);
  }

  // Dispose
  void dispose() {
    _messagesController.close();
  }
}
