import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jjm_feedback.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE grievances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        description TEXT NOT NULL,
        image_path TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertGrievance(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('grievances', row);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedGrievances() async {
    final db = await database;
    return await db.query('grievances', where: 'sync_status = ?', whereArgs: [0]);
  }

  // Added this method to fetch all records for the history screen
  Future<List<Map<String, dynamic>>> getAllGrievances() async {
    final db = await database;
    return await db.query('grievances', orderBy: 'id DESC');
  }

  Future<int> markAsSynced(int id) async {
    final db = await database;
    return await db.update('grievances', {'sync_status': 1}, where: 'id = ?', whereArgs: [id]);
  }
}