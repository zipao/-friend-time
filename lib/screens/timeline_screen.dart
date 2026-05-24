// lib/screens/timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/time_record.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/bottom_sheets.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late DateTime _viewingDay;
  late PageController _pageController;

  // 以今天为基准，允许向前翻 365 天
  static const int _totalPages = 366;
  static const int _initialPage = 365;

  @override
  void initState() {
    super.initState();
    _viewingDay = _dayOf(DateTime.now());
    _pageController = PageController(initialPage: _initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsProvider>().loadDay(_viewingDay);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _pageToDay(int page) {
    final today = _dayOf(DateTime.now());
    return today.add(Duration(days: page - _initialPage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时间轴'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 日期导航条
          _DateNavBar(
            viewingDay: _viewingDay,
            onPrev: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            onNext: _viewingDay.isBefore(_dayOf(DateTime.now()))
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
            onToday: () {
              _pageController.animateToPage(
                _initialPage,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              );
            },
          ),

          // 时间轴页面
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              reverse: false,
              onPageChanged: (page) {
                final day = _pageToDay(page);
                setState(() => _viewingDay = day);
                context.read<RecordsProvider>().loadDay(day);
              },
              itemCount: _totalPages,
              itemBuilder: (ctx, page) {
                final day = _pageToDay(page);
                return _DayTimeline(day: day);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 日期导航条 ───

class _DateNavBar extends StatelessWidget {
  final DateTime viewingDay;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onToday;

  const _DateNavBar({
    required this.viewingDay,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = TimeUtils.isSameDay(viewingDay, DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: isToday ? null : onToday,
                child: Column(
                  children: [
                    Text(
                      TimeUtils.formatDate(viewingDay),
                      style: AppTextStyles.title,
                    ),
                    if (!isToday)
                      Text('回到今天', style: AppTextStyles.secondary.copyWith(
                        color: AppColors.accentWarm,
                        fontSize: 11,
                      )),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            color: onNext != null ? AppColors.textPrimary : AppColors.textHint,
          ),
        ],
      ),
    );
  }
}

// ─── 单日时间轴 ───

class _DayTimeline extends StatelessWidget {
  final DateTime day;
  const _DayTimeline({required this.day});

  @override
  Widget build(BuildContext context) {
    final recordsProvider = context.watch<RecordsProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    if (!TimeUtils.isSameDay(recordsProvider.viewingDay, day)) {
      return const SizedBox.shrink();
    }

    final records = recordsProvider.dayRecords;
    final totalSeconds = records.fold<int>(0, (sum, r) => sum + r.durationSeconds);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当日总时长
          if (records.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text('今日已记录 ', style: AppTextStyles.secondary),
                  DurationDisplay(
                    totalSeconds: totalSeconds,
                    numberFontSize: 18,
                    unitFontSize: 12,
                  ),
                ],
              ),
            ),
          ],

          // 时间轴主体
          _TimelineChart(
            day: day,
            records: records,
            categoryProvider: categoryProvider,
          ),

          const SizedBox(height: 20),

          // 记录列表
          if (records.isEmpty)
            const _EmptyState()
          else
            ...records.map((r) {
              final cat = categoryProvider.getById(r.categoryId);
              if (cat == null) return const SizedBox.shrink();
              return _RecordListItem(
                record: r,
                category: cat,
                onTap: () => showRecordDetailSheet(context, record: r, category: cat),
              );
            }),
        ],
      ),
    );
  }
}

// ─── 时间轴图表（横向24小时色块） ───

class _TimelineChart extends StatelessWidget {
  final DateTime day;
  final List<TimeRecord> records;
  final CategoryProvider categoryProvider;

  const _TimelineChart({
    required this.day,
    required this.records,
    required this.categoryProvider,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = TimeUtils.isSameDay(day, now);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间轴主体
          SizedBox(
            height: 56,
            child: Stack(
              children: [
                // 背景条
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // 记录色块
                ...records.map((r) => _buildBlock(r, day)),
                // 当前时间竖线（仅今天）
                if (isToday)
                  Positioned(
                    left: _timeToFraction(now, day) *
                        (MediaQuery.of(context).size.width - 56),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: AppColors.stopRed,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 时间刻度
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              Text('6', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              Text('12', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              Text('18', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              Text('24', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlock(TimeRecord record, DateTime day) {
    final cat = categoryProvider.getById(record.categoryId);
    if (cat == null) return const SizedBox.shrink();

    // 计算色块在当日的起止比例
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final blockStart = record.startTime.isBefore(dayStart)
        ? dayStart
        : record.startTime;
    final blockEnd = record.actualEndTime.isAfter(dayEnd)
        ? dayEnd
        : record.actualEndTime;

    if (blockEnd.isBefore(blockStart)) return const SizedBox.shrink();

    final startFrac = blockStart.difference(dayStart).inSeconds / 86400;
    final endFrac = blockEnd.difference(dayStart).inSeconds / 86400;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final left = startFrac * w;
          final width = (endFrac - startFrac) * w;
          if (width < 1) return const SizedBox.shrink();
          return Positioned(
            left: left,
            width: width,
            top: 0,
            bottom: 0,
            child: Tooltip(
              message: cat.name,
              child: Container(
                decoration: BoxDecoration(
                  color: cat.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _timeToFraction(DateTime time, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    return time.difference(dayStart).inSeconds / 86400;
  }
}

// ─── 记录列表项 ───

class _RecordListItem extends StatelessWidget {
  final TimeRecord record;
  final Category category;
  final VoidCallback onTap;

  const _RecordListItem({
    required this.record,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(category.icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(category.name, style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      )),
                      if (record.isManual) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.cardSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('补录', style: AppTextStyles.secondary.copyWith(fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${TimeUtils.formatTime(record.startTime)} → ${TimeUtils.formatTime(record.actualEndTime)}',
                    style: AppTextStyles.secondary,
                  ),
                ],
              ),
            ),
            DurationDisplay(
              totalSeconds: record.durationSeconds,
              numberFontSize: 16,
              unitFontSize: 11,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          children: [
            const Text('—', style: TextStyle(fontSize: 32, color: AppColors.textHint)),
            const SizedBox(height: 8),
            Text('这天没有记录', style: AppTextStyles.secondary),
          ],
        ),
      ),
    );
  }
}
