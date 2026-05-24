// lib/utils/time_utils.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimeUtils {
  /// 格式化时长为"大数字小单位"汉字格式
  /// 如：2小时45分钟 / 45分钟 / 30秒
  static String formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds秒';
    }
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0) {
      return '$minutes分钟';
    }
    if (minutes == 0) {
      return '$hours小时';
    }
    return '$hours小时$minutes分钟';
  }

  /// 紧凑格式（用于柱状图）
  /// 不足1小时：45m
  /// 超过1小时：2.5h
  static String formatDurationCompact(int totalSeconds) {
    final minutes = totalSeconds / 60;
    if (minutes < 60) {
      return '${minutes.round()}m';
    }
    final hours = totalSeconds / 3600;
    return '${hours.toStringAsFixed(1)}h';
  }

  /// 计时器格式：HH:MM:SS（等宽）
  static String formatTimer(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  /// 格式化时间为 HH:mm
  static String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 格式化日期为 M月D日 周X
  static String formatDate(DateTime dt) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = weekdays[dt.weekday - 1];
    return '${dt.month}月${dt.day}日 周$weekday';
  }

  /// 格式化日期为 YYYY年M月D日
  static String formatFullDate(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日';
  }

  /// 是否是同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 获取本周第一天（周一）
  static DateTime getWeekStart(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day - (dt.weekday - 1));
  }

  /// 获取本月第一天
  static DateTime getMonthStart(DateTime dt) {
    return DateTime(dt.year, dt.month, 1);
  }

  /// 自动判断补录跨天：结束早于开始则 +1天
  static DateTime resolveManualEndTime(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      return end.add(const Duration(days: 1));
    }
    return end;
  }

  /// 验证补录时间（不超过24小时）
  static String? validateManualRecord(DateTime start, DateTime end) {
    final resolved = resolveManualEndTime(start, end);
    final diff = resolved.difference(start);
    if (diff.inSeconds <= 0) return '结束时间不能等于开始时间';
    if (diff.inHours >= 24) return '单条记录不能超过24小时';
    return null;
  }
}

/// 时长展示 Widget - 大数字小单位
class DurationDisplay extends StatelessWidget {
  final int totalSeconds;
  final double numberFontSize;
  final double unitFontSize;

  const DurationDisplay({
    super.key,
    required this.totalSeconds,
    this.numberFontSize = 32,
    this.unitFontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final numberStyle = AppTextStyles.durationNumber(fontSize: numberFontSize);
    final unitStyle = AppTextStyles.durationUnit(fontSize: unitFontSize);

    if (totalSeconds < 60) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$seconds', style: numberStyle),
          Text('秒', style: unitStyle),
        ],
      );
    }

    if (hours == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$minutes', style: numberStyle),
          Text('分钟', style: unitStyle),
        ],
      );
    }

    if (minutes == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$hours', style: numberStyle),
          Text('小时', style: unitStyle),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$hours', style: numberStyle),
        Text('小时', style: unitStyle),
        const SizedBox(width: 4),
        Text('$minutes', style: numberStyle),
        Text('分钟', style: unitStyle),
      ],
    );
  }
}
