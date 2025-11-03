import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'splitapp.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_name TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE splits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            split_title TEXT NOT NULL,
            amount REAL NOT NULL,
            created_by INTEGER NOT NULL,
            FOREIGN KEY (created_by) REFERENCES users(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE split_participants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            split_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            FOREIGN KEY (split_id) REFERENCES splits(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<int> deleteUser(int userId) async {
    final db = await database;
    await db.delete(
      'split_participants',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getSplits() async {
    final db = await database;
    return await db.query('splits');
  }

  Future<int> insertSplit(Map<String, dynamic> split) async {
    final db = await database;
    return await db.insert('splits', split);
  }

  Future<int> deleteSplit(int splitId) async {
    final db = await database;
    await db.delete(
      'split_participants',
      where: 'split_id = ?',
      whereArgs: [splitId],
    );
    return await db.delete('splits', where: 'id = ?', whereArgs: [splitId]);
  }

  Future<int> addParticipant(int splitId, int userId) async {
    final db = await database;
    return await db.insert('split_participants', {
      'split_id': splitId,
      'user_id': userId,
    });
  }

  Future<int> removeParticipant(int splitId, int userId) async {
    final db = await database;
    return await db.delete(
      'split_participants',
      where: 'split_id = ? AND user_id = ?',
      whereArgs: [splitId, userId],
    );
  }

  Future<List<Map<String, dynamic>>> getParticipants(int splitId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT u.id, u.user_name FROM users u
      INNER JOIN split_participants sp ON u.id = sp.user_id
      WHERE sp.split_id = ?
    ''',
      [splitId],
    );
  }

  Future<void> clearAllData() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final path = join(await getDatabasesPath(), 'splitapp.db');
    await deleteDatabase(path);
  }
}
