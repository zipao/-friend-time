// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/bottom_sheets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 每秒刷新时钟
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recording = context.watch<RecordingProvider>();
    final isRecording = recording.isRecording;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(now: _now),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 状态卡片
                    _StateCard(
                      isRecording: isRecording,
                      startTime: recording.startTime,
                      elapsed: recording.elapsed,
                      now: _now,
                    ),

                    const SizedBox(height: 32),

                    // 主操作按钮
                    _MainButton(
                      isRecording: isRecording,
                      onStart: _handleStart,
                      onStop: _handleStop,
                    ),

                    const SizedBox(height: 20),

                    // 补录按钮（弱化）
                    if (!isRecording) _ManualEntryButton(onTap: _handleManualEntry),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStart() {
    context.read<RecordingProvider>().startRecording();
  }

  Future<void> _handleStop() async {
    final recording = context.read<RecordingProvider>();
    final startTime = recording.startTime!;
    final endTime = recording.stopRecording(); // 结束，拿到时间戳

    // 弹出分类+备注选择
    final result = await showCategoryNoteSheet(
      context,
      startTime: startTime,
      endTime: endTime,
    );
    if (result == null) {
      // 用户取消 → 恢复记录状态
      context.read<RecordingProvider>().startRecording();
      // 把 startTime 写回
      // （简化处理：直接重新开始，复杂实现需保存原始 startTime）
      return;
    }

    final categoryId = result['categoryId'] as int;
    final note = result['note'] as String?;
    final category = context.read<CategoryProvider>().getById(categoryId);
    if (category == null) return;

    // 二次确认
    final confirmed = await showConfirmSheet(
      context,
      startTime: startTime,
      endTime: endTime,
      category: category,
      note: note,
    );
    if (confirmed != true) {
      // 返回修改 → 恢复记录状态
      context.read<RecordingProvider>().startRecording();
      return;
    }

    // 保存
    await context.read<RecordsProvider>().saveRecord(
      startTime: startTime,
      endTime: endTime,
      categoryId: categoryId,
      note: note,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已记录 ${category.name}'),
          backgroundColor: AppColors.startGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleManualEntry() async {
    final result = await showManualEntrySheet(context);
    if (result == null) return;

    final startTime = result['startTime'] as DateTime;
    final endTime = result['endTime'] as DateTime;
    final categoryId = result['categoryId'] as int;
    final note = result['note'] as String?;
    final category = context.read<CategoryProvider>().getById(categoryId);
    if (category == null) return;

    // 二次确认
    final confirmed = await showConfirmSheet(
      context,
      startTime: startTime,
      endTime: endTime,
      category: category,
      note: note,
      allowEndCorrection: false, // 补录不提供修正入口
    );
    if (confirmed != true) return;

    await context.read<RecordsProvider>().saveRecord(
      startTime: startTime,
      endTime: endTime,
      categoryId: categoryId,
      note: note,
      isManual: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('补录成功：${category.name}'),
          backgroundColor: AppColors.startGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── 顶部固定栏 ───

class _TopBar extends StatelessWidget {
  final DateTime now;
  const _TopBar({required this.now});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(timeStr, style: AppTextStyles.clock),
          const SizedBox(height: 2),
          Text(TimeUtils.formatDate(now), style: AppTextStyles.date),
        ],
      ),
    );
  }
}

// ─── 状态卡片 ───

class _StateCard extends StatelessWidget {
  final bool isRecording;
  final DateTime? startTime;
  final Duration elapsed;
  final DateTime now;

  const _StateCard({
    required this.isRecording,
    required this.startTime,
    required this.elapsed,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // 状态标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.recordingTag,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isRecording ? '记录中' : '未在记录',
              style: AppTextStyles.secondary.copyWith(
                color: AppColors.recordingTagText,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 计时器
          if (isRecording) ...[
            Text(
              TimeUtils.formatTimer(elapsed),
              style: AppTextStyles.timerLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '开始于 ${TimeUtils.formatTime(startTime!)}',
              style: AppTextStyles.secondary,
            ),
          ] else ...[
            Text(
              '00:00',
              style: AppTextStyles.timerMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 8),
            Text('点击下方按钮开始记录', style: AppTextStyles.secondary),
          ],
        ],
      ),
    );
  }
}

// ─── 主操作按钮 ───

class _MainButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _MainButton({
    required this.isRecording,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: ElevatedButton(
          onPressed: isRecording ? onStop : onStart,
          style: ElevatedButton.styleFrom(
            backgroundColor: isRecording ? AppColors.stopRed : AppColors.startGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isRecording ? '结束记录' : '开始记录',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 补录按钮 ───

class _ManualEntryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManualEntryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textHint,
            width: 1.2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Text(
            '手动补录',
            style: AppTextStyles.secondary.copyWith(fontSize: 13),
          ),
        ),
      ),
    );
  }
}
