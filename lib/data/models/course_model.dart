class CourseModel {
  final int? id;
  final String title;
  final String? description;
  final String? category;
  final int createdByUserId;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseModel({
    this.id,
    required this.title,
    this.description,
    this.category,
    required this.createdByUserId,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'createdByUserId': createdByUserId,
      'isPublished': isPublished ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      description: map['description'],
      category: map['category'],
      createdByUserId: map['createdByUserId']?.toInt() ?? 0,
      isPublished: map['isPublished'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  CourseModel copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    int? createdByUserId,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EnrollmentModel {
  final int? id;
  final int courseId;
  final int userId;
  final String roleAtEnrollment;
  final DateTime enrolledAt;

  EnrollmentModel({
    this.id,
    required this.courseId,
    required this.userId,
    required this.roleAtEnrollment,
    required this.enrolledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'userId': userId,
      'roleAtEnrollment': roleAtEnrollment,
      'enrolledAt': enrolledAt.toIso8601String(),
    };
  }

  factory EnrollmentModel.fromMap(Map<String, dynamic> map) {
    return EnrollmentModel(
      id: map['id']?.toInt(),
      courseId: map['courseId']?.toInt() ?? 0,
      userId: map['userId']?.toInt() ?? 0,
      roleAtEnrollment: map['roleAtEnrollment'] ?? '',
      enrolledAt: DateTime.parse(map['enrolledAt']),
    );
  }
}

class ModuleModel {
  final int? id;
  final int courseId;
  final String title;
  final int orderIndex;

  ModuleModel({
    this.id,
    required this.courseId,
    required this.title,
    required this.orderIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'orderIndex': orderIndex,
    };
  }

  factory ModuleModel.fromMap(Map<String, dynamic> map) {
    return ModuleModel(
      id: map['id']?.toInt(),
      courseId: map['courseId']?.toInt() ?? 0,
      title: map['title'] ?? '',
      orderIndex: map['orderIndex']?.toInt() ?? 0,
    );
  }
}

class LessonModel {
  final int? id;
  final int moduleId;
  final String title;
  final String? content;
  final int? durationMins;
  final int orderIndex;

  LessonModel({
    this.id,
    required this.moduleId,
    required this.title,
    this.content,
    this.durationMins,
    required this.orderIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'moduleId': moduleId,
      'title': title,
      'content': content,
      'durationMins': durationMins,
      'orderIndex': orderIndex,
    };
  }

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id']?.toInt(),
      moduleId: map['moduleId']?.toInt() ?? 0,
      title: map['title'] ?? '',
      content: map['content'],
      durationMins: map['durationMins']?.toInt(),
      orderIndex: map['orderIndex']?.toInt() ?? 0,
    );
  }
}

class ProgressModel {
  final int? id;
  final int userId;
  final int courseId;
  final int completedLessons;
  final int totalLessons;
  final DateTime lastUpdatedAt;

  ProgressModel({
    this.id,
    required this.userId,
    required this.courseId,
    required this.completedLessons,
    required this.totalLessons,
    required this.lastUpdatedAt,
  });

  double get completionPercentage {
    if (totalLessons == 0) return 0.0;
    return (completedLessons / totalLessons) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      id: map['id']?.toInt(),
      userId: map['userId']?.toInt() ?? 0,
      courseId: map['courseId']?.toInt() ?? 0,
      completedLessons: map['completedLessons']?.toInt() ?? 0,
      totalLessons: map['totalLessons']?.toInt() ?? 0,
      lastUpdatedAt: DateTime.parse(map['lastUpdatedAt']),
    );
  }
}
