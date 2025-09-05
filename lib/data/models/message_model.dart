class MessageModel {
  final int? id;
  final int fromUserId;
  final int toUserId;
  final String body;
  final DateTime sentAt;
  final bool isRead;
  final bool isFlagged;

  MessageModel({
    this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.body,
    required this.sentAt,
    required this.isRead,
    required this.isFlagged,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'body': body,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'isFlagged': isFlagged ? 1 : 0,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id']?.toInt(),
      fromUserId: map['fromUserId']?.toInt() ?? 0,
      toUserId: map['toUserId']?.toInt() ?? 0,
      body: map['body'] ?? '',
      sentAt: DateTime.parse(map['sentAt']),
      isRead: map['isRead'] == 1,
      isFlagged: map['isFlagged'] == 1,
    );
  }

  MessageModel copyWith({
    int? id,
    int? fromUserId,
    int? toUserId,
    String? body,
    DateTime? sentAt,
    bool? isRead,
    bool? isFlagged,
  }) {
    return MessageModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }
}

class AnnouncementModel {
  final int? id;
  final String title;
  final String body;
  final String? targetRole;
  final int? targetCourseId;
  final DateTime startAt;
  final DateTime? endAt;
  final int createdByUserId;

  AnnouncementModel({
    this.id,
    required this.title,
    required this.body,
    this.targetRole,
    this.targetCourseId,
    required this.startAt,
    this.endAt,
    required this.createdByUserId,
  });

  bool get isActive {
    final now = DateTime.now();
    final isStarted = now.isAfter(startAt) || now.isAtSameMomentAs(startAt);
    final isNotExpired = endAt == null || now.isBefore(endAt!);
    return isStarted && isNotExpired;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'targetRole': targetRole,
      'targetCourseId': targetCourseId,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'createdByUserId': createdByUserId,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      targetRole: map['targetRole'],
      targetCourseId: map['targetCourseId']?.toInt(),
      startAt: DateTime.parse(map['startAt']),
      endAt: map['endAt'] != null ? DateTime.parse(map['endAt']) : null,
      createdByUserId: map['createdByUserId']?.toInt() ?? 0,
    );
  }
}

class ReportModel {
  final int? id;
  final String targetType;
  final int targetId;
  final String reason;
  final int createdByUserId;
  final DateTime createdAt;
  final String status;
  final int? resolvedByUserId;

  ReportModel({
    this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdByUserId,
    required this.createdAt,
    required this.status,
    this.resolvedByUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'resolvedByUserId': resolvedByUserId,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id']?.toInt(),
      targetType: map['targetType'] ?? '',
      targetId: map['targetId']?.toInt() ?? 0,
      reason: map['reason'] ?? '',
      createdByUserId: map['createdByUserId']?.toInt() ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? '',
      resolvedByUserId: map['resolvedByUserId']?.toInt(),
    );
  }
}

class SettingsModel {
  final int id;
  final String brandName;
  final String primaryColor;
  final String featuresJson;
  final String termsVersion;

  SettingsModel({
    required this.id,
    required this.brandName,
    required this.primaryColor,
    required this.featuresJson,
    required this.termsVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brandName': brandName,
      'primaryColor': primaryColor,
      'featuresJson': featuresJson,
      'termsVersion': termsVersion,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      id: map['id']?.toInt() ?? 1,
      brandName: map['brandName'] ?? '',
      primaryColor: map['primaryColor'] ?? '',
      featuresJson: map['featuresJson'] ?? '',
      termsVersion: map['termsVersion'] ?? '',
    );
  }
}
