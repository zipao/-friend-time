// lib/models/time_record.dart

class TimeRecord {
  final int? id;
  final DateTime startTime;
  final DateTime rawEndTime;          // 原始结束时间（不可改）
  final DateTime? effectiveEndTime;   // 修正结束时间（统计用）
  final int categoryId;
  final String? note;
  final bool isManual;                // 是否为手动补录
  final DateTime createdAt;

  const TimeRecord({
    this.id,
    required this.startTime,
    required this.rawEndTime,
    this.effectiveEndTime,
    required this.categoryId,
    this.note,
    this.isManual = false,
    required this.createdAt,
  });

  /// 统计使用的实际结束时间
  DateTime get actualEndTime => effectiveEndTime ?? rawEndTime;

  /// 统计使用的时长（秒）
  int get durationSeconds => actualEndTime.difference(startTime).inSeconds;

  /// 原始时长（秒）
  int get rawDurationSeconds => rawEndTime.difference(startTime).inSeconds;

  Map<String, dynamic> toMap() => {
    'id': id,
    'start_time': startTime.millisecondsSinceEpoch,
    'raw_end_time': rawEndTime.millisecondsSinceEpoch,
    'effective_end_time': effectiveEndTime?.millisecondsSinceEpoch,
    'category_id': categoryId,
    'note': note,
    'is_manual': isManual ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory TimeRecord.fromMap(Map<String, dynamic> map) => TimeRecord(
    id: map['id'] as int?,
    startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
    rawEndTime: DateTime.fromMillisecondsSinceEpoch(map['raw_end_time'] as int),
    effectiveEndTime: map['effective_end_time'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['effective_end_time'] as int)
        : null,
    categoryId: map['category_id'] as int,
    note: map['note'] as String?,
    isManual: (map['is_manual'] as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );

  TimeRecord copyWith({
    int? id,
    DateTime? startTime,
    DateTime? rawEndTime,
    DateTime? effectiveEndTime,
    int? categoryId,
    String? note,
    bool? isManual,
    DateTime? createdAt,
  }) => TimeRecord(
    id: id ?? this.id,
    startTime: startTime ?? this.startTime,
    rawEndTime: rawEndTime ?? this.rawEndTime,
    effectiveEndTime: effectiveEndTime ?? this.effectiveEndTime,
    categoryId: categoryId ?? this.categoryId,
    note: note ?? this.note,
    isManual: isManual ?? this.isManual,
    createdAt: createdAt ?? this.createdAt,
  );
}
