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
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'split_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE split (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        split_title TEXT NOT NULL,
        amount REAL NOT NULL,
        created_by INTEGER,
        FOREIGN KEY (created_by) REFERENCES user (id)
      )
    ''');
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('user', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('user');
  }

  Future<int> insertSplit(Map<String, dynamic> split) async {
    final db = await database;
    return await db.insert('split', split);
  }

  Future<List<Map<String, dynamic>>> getSplits() async {
    final db = await database;
    return await db.query('split');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
