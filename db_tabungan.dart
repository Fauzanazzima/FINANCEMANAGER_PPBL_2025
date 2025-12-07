import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB_Tabungan {
  static final DB_Tabungan _instance = DB_Tabungan._internal();
  factory DB_Tabungan() => _instance;
  DB_Tabungan._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'finance.db');

    return await openDatabase(
      path,
      version: 2, // pastikan ini versi terbaru!
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE savings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            currentAmount INTEGER,
            targetAmount INTEGER,
            category TEXT,
            startDate TEXT,
            endDate TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE savings ADD COLUMN startDate TEXT");
          await db.execute("ALTER TABLE savings ADD COLUMN endDate TEXT");
        }
      },
    );
  }

  // ===== CRUD Methods =====

  Future<int> insertSavings(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('savings', data);
  }

  Future<List<Map<String, dynamic>>> getSavings() async {
    final db = await database;
    return await db.query('savings', orderBy: 'id DESC');
  }

  Future<int> updateSavings(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'savings',
      data,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> deleteSavings(int id) async {
    final db = await database;
    return await db.delete(
      'savings',
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
