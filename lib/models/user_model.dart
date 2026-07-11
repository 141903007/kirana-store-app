import '../database/db_tables.dart';

class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String? securityQuestion;
  final String? securityAnswerHash;
  final String createdAt;
  final String updatedAt;

  const UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    this.securityQuestion,
    this.securityAnswerHash,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? securityQuestion,
    String? securityAnswerHash,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      UsersTable.id: id,
      UsersTable.username: username,
      UsersTable.passwordHash: passwordHash,
      UsersTable.securityQuestion: securityQuestion,
      UsersTable.securityAnswerHash: securityAnswerHash,
      UsersTable.createdAt: createdAt,
      UsersTable.updatedAt: updatedAt,
    };
  }

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map[UsersTable.id] as int?,
      username: map[UsersTable.username] as String,
      passwordHash: map[UsersTable.passwordHash] as String,
      securityQuestion: map[UsersTable.securityQuestion] as String?,
      securityAnswerHash: map[UsersTable.securityAnswerHash] as String?,
      createdAt: map[UsersTable.createdAt] as String,
      updatedAt: map[UsersTable.updatedAt] as String,
    );
  }
}
