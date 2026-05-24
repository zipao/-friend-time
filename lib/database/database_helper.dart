// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/time_record.dart';
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'time_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE time_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        raw_end_time INTEGER NOT NULL,
        effective_end_time INTEGER,
        category_id INTEGER NOT NULL,
        note TEXT,
        is_manual INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
  }

  // ─────────────── Category CRUD ───────────────

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<List<Category>> getActiveCategories() async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'is_archived = 0',
      orderBy: 'created_at ASC',
    );
    return maps.map(Category.fromMap).toList();
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'created_at ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<void> archiveCategory(int id) async {
    final db = await database;
    await db.update(
      'categories',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCategoryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM categories WHERE is_archived = 0');
    return result.first['count'] as int;
  }

  // ─────────────── TimeRecord CRUD ───────────────

  Future<int> insertRecord(TimeRecord record) async {
    final db = await database;
    return db.insert('time_records', record.toMap());
  }

  Future<List<TimeRecord>> getRecordsForDay(DateTime day) async {
    final db = await database;
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    // 查询当天开始或结束的记录
    final maps = await db.rawQuery('''
      SELECT * FROM time_records
      WHERE (start_time >= ? AND start_time <= ?)
         OR (COALESCE(effective_end_time, raw_end_time) >= ? AND COALESCE(effective_end_time, raw_end_time) <= ?)
         OR (start_time <= ? AND COALESCE(effective_end_time, raw_end_time) >= ?)
      ORDER BY start_time ASC
    ''', [start, end, start, end, start, end]);
    return maps.map(TimeRecord.fromMap).toList();
  }

  Future<List<TimeRecord>> getRecordsInRange(DateTime from, DateTime to) async {
    final db = await database;
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;
    final maps = await db.rawQuery('''
      SELECT * FROM time_records
      WHERE start_time >= ? AND start_time <= ?
      ORDER BY start_time ASC
    ''', [fromMs, toMs]);
    return maps.map(TimeRecord.fromMap).toList();
  }

  Future<List<TimeRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('time_records', orderBy: 'start_time ASC');
    return maps.map(TimeRecord.fromMap).toList();
  }

  Future<TimeRecord?> getRecordById(int id) async {
    final db = await database;
    final maps = await db.query('time_records', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return TimeRecord.fromMap(maps.first);
  }

  /// 仅允许更新修正结束时间
  Future<void> updateEffectiveEndTime(int id, DateTime effectiveEnd) async {
    final db = await database;
    await db.update(
      'time_records',
      {'effective_end_time': effectiveEnd.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 开发者模式 - 清空所有数据
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('time_records');
    await db.delete('categories');
  }

  /// 获取最早记录日期（用于图表门槛判断）
  Future<DateTime?> getEarliestRecordDate() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MIN(start_time) as min_time FROM time_records'
    );
    final minTime = result.first['min_time'];
    if (minTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(minTime as int);
  }
}
