// lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import '../models/time_record.dart';
import '../models/category.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';

// ─────────────── RecordingProvider ───────────────
// 管理当前正在进行的记录状态

class RecordingProvider extends ChangeNotifier {
  DateTime? _startTime;
  bool get isRecording => _startTime != null;
  DateTime? get startTime => _startTime;

  void startRecording() {
    _startTime = DateTime.now();
    notifyListeners();
  }

  /// 结束记录，返回结束时间（不保存，由调用方处理）
  DateTime stopRecording() {
    final endTime = DateTime.now();
    _startTime = null;
    notifyListeners();
    return endTime;
  }

  void cancelRecording() {
    _startTime = null;
    notifyListeners();
  }

  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }
}

// ─────────────── CategoryProvider ───────────────

class CategoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Category> _categories = [];

  List<Category> get categories => _categories;

  Future<void> loadCategories() async {
    _categories = await _db.getActiveCategories();
    notifyListeners();
  }

  Future<Category> addCategory({
    required String name,
    required String icon,
  }) async {
    // 自动取色
    final colorIndex = _categories.length % AppColors.categoryPalette.length;
    final color = AppColors.categoryPalette[colorIndex];

    final category = Category(
      name: name,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
    );
    final id = await _db.insertCategory(category);
    final saved = category.copyWith(id: id);
    _categories.add(saved);
    notifyListeners();
    return saved;
  }

  Category? getById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────── RecordsProvider ───────────────

class RecordsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<TimeRecord> _dayRecords = [];
  DateTime _viewingDay = DateTime.now();

  List<TimeRecord> get dayRecords => _dayRecords;
  DateTime get viewingDay => _viewingDay;

  Future<void> loadDay(DateTime day) async {
    _viewingDay = day;
    _dayRecords = await _db.getRecordsForDay(day);
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadDay(_viewingDay);
  }

  Future<TimeRecord> saveRecord({
    required DateTime startTime,
    required DateTime endTime,
    required int categoryId,
    String? note,
    bool isManual = false,
  }) async {
    final record = TimeRecord(
      startTime: startTime,
      rawEndTime: endTime,
      categoryId: categoryId,
      note: note?.isNotEmpty == true ? note : null,
      isManual: isManual,
      createdAt: DateTime.now(),
    );
    final id = await _db.insertRecord(record);
    final saved = record.copyWith(id: id);
    await refresh();
    return saved;
  }

  Future<void> applyEndCorrection(int recordId, DateTime correctedEnd) async {
    await _db.updateEffectiveEndTime(recordId, correctedEnd);
    await refresh();
  }

  /// 获取某天总时长（秒）
  int getTotalSecondsForDay(DateTime day) {
    return _dayRecords
        .where((r) {
          final startDay = DateTime(r.startTime.year, r.startTime.month, r.startTime.day);
          final targetDay = DateTime(day.year, day.month, day.day);
          return startDay == targetDay;
        })
        .fold(0, (sum, r) => sum + r.durationSeconds);
  }

  Future<List<TimeRecord>> getRecordsInRange(DateTime from, DateTime to) async {
    return _db.getRecordsInRange(from, to);
  }

  Future<List<TimeRecord>> getAllRecords() async {
    return _db.getAllRecords();
  }

  Future<DateTime?> getEarliestDate() async {
    return _db.getEarliestRecordDate();
  }
}
