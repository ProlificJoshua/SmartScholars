class UserModel {
  final int? id;
  final String role;
  final String email;
  final String fullName;
  final String passwordHash;
  final String? country;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    required this.role,
    required this.email,
    required this.fullName,
    required this.passwordHash,
    this.country,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'email': email,
      'fullName': fullName,
      'passwordHash': passwordHash,
      'country': country,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toInt(),
      role: map['role'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      country: map['country'],
      status: map['status'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  UserModel copyWith({
    int? id,
    String? role,
    String? email,
    String? fullName,
    String? passwordHash,
    String? country,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      role: role ?? this.role,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      passwordHash: passwordHash ?? this.passwordHash,
      country: country ?? this.country,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, role: $role, email: $email, fullName: $fullName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.role == role &&
        other.email == email &&
        other.fullName == fullName &&
        other.passwordHash == passwordHash &&
        other.country == country &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        role.hashCode ^
        email.hashCode ^
        fullName.hashCode ^
        passwordHash.hashCode ^
        country.hashCode ^
        status.hashCode;
  }
}

class StudentModel {
  final int? id;
  final int userId;
  final String classGrade;
  final int? guardianUserId;

  StudentModel({
    this.id,
    required this.userId,
    required this.classGrade,
    this.guardianUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'classGrade': classGrade,
      'guardianUserId': guardianUserId,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id']?.toInt(),
      userId: map['userId']?.toInt() ?? 0,
      classGrade: map['classGrade'] ?? '',
      guardianUserId: map['guardianUserId']?.toInt(),
    );
  }

  StudentModel copyWith({
    int? id,
    int? userId,
    String? classGrade,
    int? guardianUserId,
  }) {
    return StudentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      classGrade: classGrade ?? this.classGrade,
      guardianUserId: guardianUserId ?? this.guardianUserId,
    );
  }
}

class TeacherModel {
  final int? id;
  final int userId;
  final String? school;
  final String subjects; // JSON string of subjects array

  TeacherModel({
    this.id,
    required this.userId,
    this.school,
    required this.subjects,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'school': school,
      'subjects': subjects,
    };
  }

  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    return TeacherModel(
      id: map['id']?.toInt(),
      userId: map['userId']?.toInt() ?? 0,
      school: map['school'],
      subjects: map['subjects'] ?? '',
    );
  }

  TeacherModel copyWith({
    int? id,
    int? userId,
    String? school,
    String? subjects,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      school: school ?? this.school,
      subjects: subjects ?? this.subjects,
    );
  }
}

class ParentModel {
  final int? id;
  final int userId;
  final String childName;
  final String childClassGrade;
  final String? school;
  final int? linkedStudentUserId;

  ParentModel({
    this.id,
    required this.userId,
    required this.childName,
    required this.childClassGrade,
    this.school,
    this.linkedStudentUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'childName': childName,
      'childClassGrade': childClassGrade,
      'school': school,
      'linkedStudentUserId': linkedStudentUserId,
    };
  }

  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      id: map['id']?.toInt(),
      userId: map['userId']?.toInt() ?? 0,
      childName: map['childName'] ?? '',
      childClassGrade: map['childClassGrade'] ?? '',
      school: map['school'],
      linkedStudentUserId: map['linkedStudentUserId']?.toInt(),
    );
  }

  ParentModel copyWith({
    int? id,
    int? userId,
    String? childName,
    String? childClassGrade,
    String? school,
    int? linkedStudentUserId,
  }) {
    return ParentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      childName: childName ?? this.childName,
      childClassGrade: childClassGrade ?? this.childClassGrade,
      school: school ?? this.school,
      linkedStudentUserId: linkedStudentUserId ?? this.linkedStudentUserId,
    );
  }
}
