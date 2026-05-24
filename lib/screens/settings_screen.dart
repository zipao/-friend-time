// lib/screens/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import '../providers/app_provider.dart';
import '../models/category.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/bottom_sheets.dart';

enum ExportRange { today, week, month, all }

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 分类管理
          _SectionHeader('分类管理'),
          const SizedBox(height: 8),
          _CategoryManagementCard(),
          const SizedBox(height: 20),

          // 导出
          _SectionHeader('导出数据'),
          const SizedBox(height: 8),
          _ExportCard(),
          const SizedBox(height: 20),

          // 开发者模式（低调放最底部）
          _DeveloperSection(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.secondary.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 12,
      letterSpacing: 0.5,
    ));
  }
}

// ─── 分类管理卡片 ───

class _CategoryManagementCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ...categories.asMap().entries.map((e) {
            final cat = e.value;
            final isLast = e.key == categories.length - 1;
            return _CategoryTile(category: cat, isLast: isLast);
          }),
          // 新增按钮
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: AppColors.startGreen),
            title: Text('添加分类', style: AppTextStyles.body.copyWith(
              color: AppColors.startGreen,
            )),
            onTap: () async {
              await showAddCategorySheet(context);
              context.read<CategoryProvider>().loadCategories();
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool isLast;
  const _CategoryTile({required this.category, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: Text(category.icon, style: const TextStyle(fontSize: 18))),
          ),
          title: Text(category.name, style: AppTextStyles.body),
          subtitle: Text(
            TimeUtils.formatFullDate(category.createdAt),
            style: AppTextStyles.secondary,
          ),
          trailing: const Icon(Icons.drag_handle, color: AppColors.textHint),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 56),
      ],
    );
  }
}

// ─── 导出卡片 ───

class _ExportCard extends StatefulWidget {
  @override
  State<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends State<_ExportCard> {
  ExportRange _range = ExportRange.all;
  bool _exporting = false;

  String _rangeLabel(ExportRange r) {
    switch (r) {
      case ExportRange.today: return '今天';
      case ExportRange.week: return '本周';
      case ExportRange.month: return '本月';
      case ExportRange.all: return '全部';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('导出范围', style: AppTextStyles.secondary),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExportRange.values.map((r) {
              final isSelected = _range == r;
              return GestureDetector(
                onTap: () => setState(() => _range = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.startGreen : AppColors.cardSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _rangeLabel(r),
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            '导出字段：开始时间、结束时间、修正结束时间、分类、时长（分钟）、备注、是否补录、创建时间',
            style: AppTextStyles.secondary.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(_exporting ? '导出中...' : '导出 Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.startGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final recordsProvider = context.read<RecordsProvider>();
      final categoryProvider = context.read<CategoryProvider>();

      // 确定时间范围
      final now = DateTime.now();
      DateTime? from;
      DateTime? to;

      switch (_range) {
        case ExportRange.today:
          from = DateTime(now.year, now.month, now.day);
          to = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case ExportRange.week:
          from = TimeUtils.getWeekStart(now);
          to = now;
          break;
        case ExportRange.month:
          from = TimeUtils.getMonthStart(now);
          to = now;
          break;
        case ExportRange.all:
          from = null;
          to = null;
          break;
      }

      final records = from != null
          ? await recordsProvider.getRecordsInRange(from, to!)
          : await recordsProvider.getAllRecords();

      if (records.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该范围内没有记录')),
          );
        }
        return;
      }

      // 构建 Excel
      final excel = Excel.createExcel();
      final sheet = excel['记录'];

      // 表头
      final headers = [
        '开始时间', '结束时间（原始）', '结束时间（修正）',
        '分类', '时长（分钟）', '备注', '是否补录', '创建时间',
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      // 数据行
      for (var i = 0; i < records.length; i++) {
        final r = records[i];
        final cat = categoryProvider.getById(r.categoryId);
        final row = [
          r.startTime.toString(),
          r.rawEndTime.toString(),
          r.effectiveEndTime?.toString() ?? '',
          cat?.name ?? '未知',
          (r.durationSeconds / 60).round().toString(),
          r.note ?? '',
          r.isManual ? '是' : '否',
          r.createdAt.toString(),
        ];
        for (var j = 0; j < row.length; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
              .value = TextCellValue(row[j]);
        }
      }

      // 保存文件
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'time_tracker_${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}.xlsx';
      final file = File('${dir.path}/$fileName');
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Excel 编码失败');
      await file.writeAsBytes(bytes);

      // 分享
      await Share.shareXFiles([XFile(file.path)], text: '时间记录导出');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

// ─── 开发者区域 ───

class _DeveloperSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('开发者'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.stopRed),
            title: Text('清空全部数据', style: AppTextStyles.body.copyWith(
              color: AppColors.stopRed,
            )),
            subtitle: Text('不可恢复，谨慎操作', style: AppTextStyles.secondary),
            onTap: () => _confirmClear(context),
          ),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('清空全部数据'),
        content: const Text('这将删除所有记录和分类，不可恢复。确认吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearAllData();
              await context.read<CategoryProvider>().loadCategories();
              await context.read<RecordsProvider>().refresh();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已清空全部数据')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.stopRed),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}
