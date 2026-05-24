// lib/screens/trends_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../models/time_record.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

enum TrendPeriod { day, week, month }

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});
  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  TrendPeriod _period = TrendPeriod.day;
  Set<int> _selectedCategoryIds = {};
  List<TimeRecord> _allRecords = [];
  bool _loading = true;
  DateTime? _earliestDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final records = await context.read<RecordsProvider>().getAllRecords();
    final earliest = await context.read<RecordsProvider>().getEarliestDate();
    setState(() {
      _allRecords = records;
      _earliestDate = earliest;
      _loading = false;
    });
  }

  bool _isPeriodUnlocked(TrendPeriod period) {
    if (_earliestDate == null) return false;
    final now = DateTime.now();
    switch (period) {
      case TrendPeriod.day:
        return true;
      case TrendPeriod.week:
        // 至少 2 个完整自然周
        final diff = now.difference(_earliestDate!).inDays;
        return diff >= 14;
      case TrendPeriod.month:
        // 至少 2 个完整自然月
        final monthsDiff = (now.year - _earliestDate!.year) * 12 +
            now.month - _earliestDate!.month;
        return monthsDiff >= 2;
    }
  }

  // 将记录聚合为周期数据 {periodKey: {categoryId: seconds}}
  Map<String, Map<int, int>> _aggregate() {
    final result = <String, Map<int, int>>{};
    for (final r in _allRecords) {
      final key = _periodKey(r.startTime);
      result.putIfAbsent(key, () => {});
      result[key]![r.categoryId] =
          (result[key]![r.categoryId] ?? 0) + r.durationSeconds;
    }
    return result;
  }

  String _periodKey(DateTime dt) {
    switch (_period) {
      case TrendPeriod.day:
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      case TrendPeriod.week:
        final weekStart = TimeUtils.getWeekStart(dt);
        return '${weekStart.year}-W${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      case TrendPeriod.month:
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('趋势'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.startGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 周期切换
                  _PeriodSelector(
                    selected: _period,
                    isWeekUnlocked: _isPeriodUnlocked(TrendPeriod.week),
                    isMonthUnlocked: _isPeriodUnlocked(TrendPeriod.month),
                    onChanged: (p) {
                      if (!_isPeriodUnlocked(p)) return;
                      setState(() {
                        _period = p;
                        _selectedCategoryIds.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 分类勾选
                  Text('选择分类', style: AppTextStyles.secondary),
                  const SizedBox(height: 8),
                  _CategorySelector(
                    categories: categories,
                    selected: _selectedCategoryIds,
                    onToggle: (id) {
                      setState(() {
                        if (_selectedCategoryIds.contains(id)) {
                          _selectedCategoryIds.remove(id);
                        } else {
                          _selectedCategoryIds.add(id);
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 图表
                  if (_selectedCategoryIds.isEmpty)
                    _EmptyChart()
                  else
                    _TrendChart(
                      aggregated: _aggregate(),
                      selectedCategories: categories
                          .where((c) => _selectedCategoryIds.contains(c.id))
                          .toList(),
                      period: _period,
                    ),
                ],
              ),
            ),
    );
  }
}

// ─── 周期选择器 ───

class _PeriodSelector extends StatelessWidget {
  final TrendPeriod selected;
  final bool isWeekUnlocked;
  final bool isMonthUnlocked;
  final ValueChanged<TrendPeriod> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.isWeekUnlocked,
    required this.isMonthUnlocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PeriodChip(
          label: '按日',
          isSelected: selected == TrendPeriod.day,
          isEnabled: true,
          onTap: () => onChanged(TrendPeriod.day),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: '按周',
          isSelected: selected == TrendPeriod.week,
          isEnabled: isWeekUnlocked,
          lockHint: '需记录满2周',
          onTap: () => onChanged(TrendPeriod.week),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: '按月',
          isSelected: selected == TrendPeriod.month,
          isEnabled: isMonthUnlocked,
          lockHint: '需记录满2月',
          onTap: () => onChanged(TrendPeriod.month),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final String? lockHint;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    this.lockHint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : () {
        if (lockHint != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lockHint!), duration: const Duration(seconds: 2)),
          );
        }
      },
      child: Tooltip(
        message: lockHint ?? '',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.startGreen
                : isEnabled
                    ? AppColors.cardBackground
                    : AppColors.cardSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? Colors.white
                      : isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (!isEnabled) ...[
                const SizedBox(width: 4),
                const Icon(Icons.lock_outline, size: 12, color: AppColors.textHint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 分类勾选器 ───

class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text('还没有分类', style: AppTextStyles.secondary);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selected.contains(cat.id);
        return GestureDetector(
          onTap: () => onToggle(cat.id!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? cat.color : AppColors.cardSecondary,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: cat.color.withOpacity(0.8))
                  : null,
            ),
            child: Text(
              '${cat.icon} ${cat.name}',
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── 趋势图表 ───

class _TrendChart extends StatelessWidget {
  final Map<String, Map<int, int>> aggregated;
  final List<Category> selectedCategories;
  final TrendPeriod period;

  const _TrendChart({
    required this.aggregated,
    required this.selectedCategories,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (aggregated.isEmpty) {
      return _EmptyChart();
    }

    final sortedKeys = aggregated.keys.toList()..sort();
    // 只展示最近30个周期
    final displayKeys = sortedKeys.length > 30
        ? sortedKeys.sublist(sortedKeys.length - 30)
        : sortedKeys;

    final lines = selectedCategories.map((cat) {
      final spots = displayKeys.asMap().entries.map((e) {
        final seconds = aggregated[e.value]?[cat.id] ?? 0;
        return FlSpot(e.key.toDouble(), seconds / 3600.0);
      }).toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: cat.color.withOpacity(0.9),
        barWidth: 2.5,
        dotData: FlDotData(
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: 3,
            color: cat.color,
            strokeWidth: 0,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: cat.color.withOpacity(0.08),
        ),
      );
    }).toList();

    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, _) => Text(
                  '${value.toStringAsFixed(1)}h',
                  style: const TextStyle(fontSize: 9, color: AppColors.textHint),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (displayKeys.length / 5).ceilToDouble(),
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= displayKeys.length) return const SizedBox.shrink();
                  return Text(
                    _shortLabel(displayKeys[idx]),
                    style: const TextStyle(fontSize: 9, color: AppColors.textHint),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: lines,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBackgroundColor: AppColors.cardBackground,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final cat = selectedCategories[spot.barIndex];
                return LineTooltipItem(
                  '${cat.name}: ${TimeUtils.formatDurationCompact((spot.y * 3600).round())}',
                  TextStyle(color: cat.color, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _shortLabel(String key) {
    // day: 2024-01-15 → 1/15
    // week: 2024-W01-01 → 1/1
    // month: 2024-01 → 1月
    final parts = key.split('-');
    if (parts.length >= 3) {
      return '${int.parse(parts[1])}/${int.parse(parts[2])}';
    }
    if (parts.length == 2) {
      return '${int.parse(parts[1])}月';
    }
    return key;
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('勾选分类后显示趋势图', style: AppTextStyles.secondary),
    );
  }
}
