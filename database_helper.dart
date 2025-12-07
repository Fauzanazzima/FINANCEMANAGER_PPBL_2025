// lib/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finance_manager.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel budgets: ada limit dan spent
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        limit_amount INTEGER,
        spent_amount INTEGER DEFAULT 0
      );
    ''');

    // Tabel transactions: terhubung ke budget_id
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount INTEGER,
        type TEXT,           -- income / expense
        budget_id INTEGER,   -- FOREIGN KEY ke budgets
        created_at TEXT
      );
    ''');
  }

  // =========================================================
  //                        BUDGETS
  // =========================================================

  Future<int> insertBudget(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('budgets', row);
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final db = await database;
    return await db.query('budgets', orderBy: 'id DESC');
  }

  Future<int> updateBudget(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('budgets', row, where: 'id = ?', whereArgs: [id]);
  }

  /// Tambahkan spent ketika transaksi expense dibuat
  Future<int> updateBudgetSpent(int id, int amount) async {
    final db = await database;
    return await db.rawUpdate('''
      UPDATE budgets
      SET spent_amount = spent_amount + ?
      WHERE id = ?
    ''', [amount, id]);
  }

  /// Kembalikan spent ketika transaksi lama dihapus / dikurangi
  Future<int> reduceBudgetSpent(int id, int amount) async {
    final db = await database;
    return await db.rawUpdate('''
      UPDATE budgets
      SET spent_amount = spent_amount - ?
      WHERE id = ?
    ''', [amount, id]);
  }

  /// Total expense berdasarkan kategori (menggunakan budget_id, bukan category)
  Future<int> getTotalSpentByCategory(String category) async {
    final db = await database;

    // Cari budget_id dulu
    final bud = await db.query(
      'budgets',
      where: 'category = ?',
      whereArgs: [category],
    );

    if (bud.isEmpty) return 0;
    final budgetId = bud.first['id'];

    // Hitung total expense dari budget tersebut
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "expense" AND budget_id = ?',
      [budgetId],
    );

    final value = result.first['total'];
    return value == null ? 0 : (value as num).toInt();
  }

  /// Hapus budget + HAPUS transaksi yang terkait (prevent orphan)
  Future<int> deleteBudget(int id) async {
    final db = await database;

    // Hapus semua transaksi yang memakai budget_id ini
    await db.delete('transactions', where: 'budget_id = ?', whereArgs: [id]);

    // Hapus budget
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================
  //                     TRANSACTIONS
  // =========================================================

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> getTransactionById(int id) async {
    final db = await database;
    final res = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  /// Hapus transaksi + update spent
  Future<int> deleteTransaction(int id) async {
    final db = await database;

    final trx = await getTransactionById(id);

    if (trx != null && trx['type'] == 'expense') {
      await reduceBudgetSpent(trx['budget_id'], trx['amount']);
    }

    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Update transaksi + pastikan spent_amount konsisten
  Future<int> updateTransaction(int id, Map<String, dynamic> row) async {
    final db = await database;

    final old = await getTransactionById(id);

    // Jika transaksi lama adalah expense → kembalikan spent lama
    if (old != null && old['type'] == 'expense') {
      await reduceBudgetSpent(old['budget_id'], old['amount']);
    }

    // Update transaksi
    final res = await db.update(
      'transactions',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Tambahkan spent baru jika expense
    if (row['type'] == 'expense') {
      await updateBudgetSpent(row['budget_id'], row['amount']);
    }

    return res;
  }

  // =========================================================
  //                     SUMMARY / TOTAL
  // =========================================================

  Future<int> getTotalDialokasikan() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(limit_amount) as total FROM budgets');
    final value = result.first['total'];
    return value == null ? 0 : (value as num).toInt();
  }

  Future<int> getTotalTerpakai() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense'"
    );
    final value = result.first['total'];
    return value == null ? 0 : (value as num).toInt();
  }

  Future<int> getTotalSpentByBudget(int budgetId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense' AND budget_id = ?",
      [budgetId],
    );
    final value = result.first['total'];
    return value == null ? 0 : (value as num).toInt();
  }
}