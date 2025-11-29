import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'dhan_ai.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone_number TEXT NOT NULL UNIQUE,
        preferred_language TEXT NOT NULL,
        occupation_category TEXT NOT NULL,
        income_range TEXT NOT NULL,
        monthly_obligations TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Insert a new user
  Future<int> insertUser(UserProfile user) async {
    final db = await database;
    try {
      return await db.insert('users', user.toMap());
    } catch (e) {
      // If user already exists (UNIQUE constraint), throw error
      throw Exception('User with this phone number already exists');
    }
  }

  /// Get user by phone number
  Future<UserProfile?> getUserByPhone(String phoneNumber) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserProfile.fromMap(results.first);
  }

  /// Check if user exists
  Future<bool> userExists(String phoneNumber) async {
    final user = await getUserByPhone(phoneNumber);
    return user != null;
  }

  /// Get all users (for debugging)
  Future<List<UserProfile>> getAllUsers() async {
    final db = await database;
    final results = await db.query('users');
    return results.map((map) => UserProfile.fromMap(map)).toList();
  }

  /// Delete user (for testing)
  Future<void> deleteUser(String phoneNumber) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

