import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/user_model.dart';
import '../utils/password_hasher.dart';

/// This app has exactly one admin account (seeded in [AppDatabase]), so
/// every method here operates on "the" user rather than taking an id.
class UserRepository {
  Future<UserModel?> getPrimaryUser() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(UsersTable.table, limit: 1);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  /// Returns the user if [username]/[password] match, otherwise null.
  Future<UserModel?> verifyCredentials(String username, String password) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      UsersTable.table,
      where: '${UsersTable.username} = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final user = UserModel.fromMap(rows.first);
    if (!PasswordHasher.matches(password, user.passwordHash)) return null;
    return user;
  }

  Future<void> updateUsername(int userId, String newUsername) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      UsersTable.table,
      {
        UsersTable.username: newUsername,
        UsersTable.updatedAt: DateTime.now().toIso8601String(),
      },
      where: '${UsersTable.id} = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updatePassword(int userId, String newPassword) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      UsersTable.table,
      {
        UsersTable.passwordHash: PasswordHasher.hash(newPassword),
        UsersTable.updatedAt: DateTime.now().toIso8601String(),
      },
      where: '${UsersTable.id} = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateSecurityQuestion(
    int userId,
    String question,
    String answer,
  ) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      UsersTable.table,
      {
        UsersTable.securityQuestion: question,
        UsersTable.securityAnswerHash: PasswordHasher.hash(
          _normalizeAnswer(answer),
        ),
        UsersTable.updatedAt: DateTime.now().toIso8601String(),
      },
      where: '${UsersTable.id} = ?',
      whereArgs: [userId],
    );
  }

  bool verifySecurityAnswer(UserModel user, String answer) {
    if (user.securityAnswerHash == null) return false;
    return PasswordHasher.matches(
      _normalizeAnswer(answer),
      user.securityAnswerHash!,
    );
  }

  /// Case/whitespace-insensitive so "Blue" and " blue " hash the same.
  String _normalizeAnswer(String answer) => answer.trim().toLowerCase();
}
